/**
 * Cloud Functions for ISP User Manager.
 *
 * Core Responsibilities:
 *   - onNotificationCreated (Firestore trigger): Central push notification engine.
 *     Fires whenever any notification is saved to admins/{adminUid}/notifications/{notificationId}.
 *     Delivers high-priority FCM notifications with heads-up banners, sound, and vibration
 *     even when the app is closed/terminated. Automatically cleans up stale tokens.
 *   - onSupplierPaymentRequestCreate (Firestore trigger): logs notification when payment requested.
 *   - onSupplierPaymentRequestUpdated (Firestore trigger): applies payment to linked purchase.
 */

import { initializeApp } from "firebase-admin/app";
import { getFirestore, FieldValue, Timestamp } from "firebase-admin/firestore";
import { getMessaging, MulticastMessage } from "firebase-admin/messaging";
import {
  onDocumentCreated,
  onDocumentUpdated,
} from "firebase-functions/v2/firestore";
import { logger, setGlobalOptions } from "firebase-functions/v2";

initializeApp();
setGlobalOptions({ region: "us-central1", maxInstances: 10 });

const db = getFirestore();

/**
 * Helper to fetch all valid FCM tokens for a recipient.
 */
async function getTokensForRecipient(
  adminUid: string,
  recipientUid: string,
  actorUid?: string
): Promise<{
  tokens: string[];
  tokenToDocMap: Map<string, FirebaseFirestore.DocumentReference>;
}> {
  const tokenMap = new Map<string, FirebaseFirestore.DocumentReference>();

  if (recipientUid === "admin") {
    const adminSnap = await db.doc(`admins/${adminUid}`).get();
    if (adminSnap.exists) {
      const tokens = (adminSnap.get("fcmTokens") || []) as string[];
      for (const t of tokens) {
        if (t && typeof t === "string") {
          tokenMap.set(t, adminSnap.ref);
        }
      }
    }
  } else if (recipientUid === "all") {
    // Admin
    const adminSnap = await db.doc(`admins/${adminUid}`).get();
    if (adminSnap.exists && actorUid !== adminUid) {
      const tokens = (adminSnap.get("fcmTokens") || []) as string[];
      for (const t of tokens) {
        if (t && typeof t === "string") {
          tokenMap.set(t, adminSnap.ref);
        }
      }
    }

    // Employees
    const empsSnap = await db
      .collection(`admins/${adminUid}/employees`)
      .where("active", "==", true)
      .get();
    for (const doc of empsSnap.docs) {
      if (doc.id === actorUid) continue; // Don't notify the user who initiated the action
      const tokens = (doc.get("fcmTokens") || []) as string[];
      for (const t of tokens) {
        if (t && typeof t === "string") {
          tokenMap.set(t, doc.ref);
        }
      }
    }
  } else {
    // Specific employee
    const empSnap = await db
      .doc(`admins/${adminUid}/employees/${recipientUid}`)
      .get();
    if (empSnap.exists) {
      const tokens = (empSnap.get("fcmTokens") || []) as string[];
      for (const t of tokens) {
        if (t && typeof t === "string") {
          tokenMap.set(t, empSnap.ref);
        }
      }
    }
  }

  return {
    tokens: Array.from(tokenMap.keys()),
    tokenToDocMap: tokenMap,
  };
}

/**
 * Universal Push Notification Trigger
 * Fires whenever ANY notification is created in Firestore.
 * Delivers OS-level alerts across closed and backgrounded apps.
 */
export const onNotificationCreated = onDocumentCreated(
  "admins/{adminUid}/notifications/{notificationId}",
  async (event) => {
    const adminUid = event.params.adminUid;
    const notificationId = event.params.notificationId;
    const data = event.data?.data();
    if (!data) return;

    const recipientUid = String(data.recipientUid || "admin");
    const actorUid = data.actorUid ? String(data.actorUid) : undefined;
    const title = String(data.title || "إشعار جديد");
    const body = String(data.body || "");
    const type = String(data.type || "general");
    const targetId = String(data.targetId || "");
    const targetType = String(data.targetType || "");

    try {
      const { tokens, tokenToDocMap } = await getTokensForRecipient(
        adminUid,
        recipientUid,
        actorUid
      );

      if (tokens.length === 0) {
        logger.info("No FCM tokens found for recipient", {
          adminUid,
          recipientUid,
        });
        return;
      }

      logger.info(`Sending FCM notification to ${tokens.length} token(s)`, {
        adminUid,
        recipientUid,
        title,
      });

      const message: MulticastMessage = {
        tokens,
        notification: {
          title,
          body,
        },
        android: {
          priority: "high",
          notification: {
            channelId: "high_importance_channel",
            sound: "default",
            defaultSound: true,
            defaultVibrateTimings: true,
            priority: "max",
            visibility: "public",
            clickAction: "FLUTTER_NOTIFICATION_CLICK",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
              contentAvailable: true,
            },
          },
        },
        data: {
          title,
          body,
          type,
          targetId,
          targetType,
          adminUid,
          notificationId,
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
      };

      const response = await getMessaging().sendEachForMulticast(message);
      logger.info("FCM multicast result", {
        successCount: response.successCount,
        failureCount: response.failureCount,
      });

      // Cleanup dead/unregistered tokens automatically
      if (response.failureCount > 0) {
        const deadTokensByDoc = new Map<
          FirebaseFirestore.DocumentReference,
          string[]
        >();
        response.responses.forEach((resp, idx) => {
          if (!resp.success && resp.error) {
            const errCode = resp.error.code;
            if (
              errCode === "messaging/registration-token-not-registered" ||
              errCode === "messaging/invalid-registration-token" ||
              errCode === "messaging/invalid-argument"
            ) {
              const deadToken = tokens[idx];
              const docRef = tokenToDocMap.get(deadToken);
              if (docRef) {
                const arr = deadTokensByDoc.get(docRef) || [];
                arr.push(deadToken);
                deadTokensByDoc.set(docRef, arr);
              }
            }
          }
        });

        for (const [docRef, deadTokens] of deadTokensByDoc.entries()) {
          try {
            await docRef.update({
              fcmTokens: FieldValue.arrayRemove(...deadTokens),
            });
            logger.info("Cleaned up dead FCM tokens", {
              path: docRef.path,
              count: deadTokens.length,
            });
          } catch (e) {
            logger.error("Failed cleaning dead tokens", e);
          }
        }
      }
    } catch (err) {
      logger.error("Error processing onNotificationCreated", err);
    }
  }
);

/**
 * When employee requests payment from supplier
 */
export const onSupplierPaymentRequestCreate = onDocumentCreated(
  "admins/{adminUid}/supplierPaymentRequests/{reqId}",
  async (event) => {
    const adminUid = event.params.adminUid;
    const reqId = event.params.reqId;
    const data = event.data?.data();
    if (!data) return;

    // Writing to notifications automatically triggers onNotificationCreated!
    await db.collection(`admins/${adminUid}/notifications`).add({
      type: "supplierPaymentRequest",
      recipientUid: "admin",
      title: "طلب تسديد جديد للمجهز",
      body: `طلب ${data.byEmployeeName || "الموظف"} تسديد مبلغ ${data.amount} ${data.currency}`,
      targetId: reqId,
      targetType: "supplierPaymentRequest",
      actorUid: data.byEmployeeUid,
      actorName: data.byEmployeeName,
      read: false,
      createdAt: FieldValue.serverTimestamp(),
    });

    logger.info("New supplier payment request created", { adminUid, reqId });
  }
);

/**
 * When admin approves/rejects payment request
 */
export const onSupplierPaymentRequestUpdated = onDocumentUpdated(
  "admins/{adminUid}/supplierPaymentRequests/{reqId}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;
    if (before.status === after.status) return;
    if (after.status !== "approved") return;

    const adminUid = event.params.adminUid;
    const linkedPurchaseId: string | undefined = after.linkedPurchaseId;
    const amount = Number(after.amount ?? 0);

    if (linkedPurchaseId && amount > 0) {
      const ref = db.doc(
        `admins/${adminUid}/supplierPurchases/${linkedPurchaseId}`
      );
      await db.runTransaction(async (tx) => {
        const snap = await tx.get(ref);
        if (!snap.exists) return;
        const paid = Number(snap.get("paid") ?? 0);
        tx.update(ref, { paid: paid + amount });
      });
    }

    await db.collection(`admins/${adminUid}/history`).add({
      actor: {
        uid: after.decidedBy ?? "system",
        displayName: "Admin",
        role: "admin",
        photoUrl: null,
      },
      action: "supplier.payment.approve",
      targetType: "paymentRequest",
      targetId: event.params.reqId,
      summary: `Approved supplier payment ${amount} ${after.currency}`,
      ts: FieldValue.serverTimestamp(),
      decidedAt: Timestamp.now(),
    });

    const empUid = after.byEmployeeUid;
    if (empUid) {
      // Writing to notifications triggers onNotificationCreated to notify employee!
      await db.collection(`admins/${adminUid}/notifications`).add({
        type: "supplierPaymentApproved",
        recipientUid: empUid,
        title: "تمت الموافقة على طلب التسديد",
        body: `تمت الموافقة على طلبك لتسديد مبلغ ${amount} ${after.currency}`,
        targetId: event.params.reqId,
        targetType: "supplierPaymentRequest",
        actorUid: after.decidedBy ?? "admin",
        actorName: "الإدارة",
        read: false,
        createdAt: FieldValue.serverTimestamp(),
      });
    }
  }
);
