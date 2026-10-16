import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/firestore_helpers.dart';
import '../utils/formatters.dart';
import '../constants.dart';

class AppUser {
  final String uid;
  final String? email;
  final String displayName;
  final UserRole role;
  final String
      adminUid; // for employees: their admin's uid; for admin: their own uid
  final Set<Permission> permissions;
  final String? photoUrl;
  final List<String> fcmTokens;

  AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    required this.adminUid,
    required this.permissions,
    this.photoUrl,
    this.fcmTokens = const [],
  });

  bool get isAdmin => role == UserRole.admin;
  bool can(Permission p) => isAdmin || permissions.contains(p);

  AppUser copyWith({
    List<String>? fcmTokens,
  }) {
    return AppUser(
      uid: uid,
      email: email,
      displayName: displayName,
      role: role,
      adminUid: adminUid,
      permissions: permissions,
      photoUrl: photoUrl,
      fcmTokens: fcmTokens ?? this.fcmTokens,
    );
  }
}

class Subscriber {
  final String id;
  final String name;
  final String? phone;
  final String? supplierId;
  final String? supplierName;
  final String? packageId;
  final String? packageName;
  final String? planName;
  final num monthlyFee;
  final num packageAgentPrice;
  final AppCurrency currency;
  final num balance;
  final SubscriberStatus status;
  final DateTime joinedAt;
  final DateTime subscriptionEndsAt;
  final bool autoRenew;

  Subscriber({
    required this.id,
    required this.name,
    this.phone,
    this.supplierId,
    this.supplierName,
    this.packageId,
    this.packageName,
    this.planName,
    required this.monthlyFee,
    this.packageAgentPrice = 0,
    required this.currency,
    required this.balance,
    required this.status,
    required this.joinedAt,
    DateTime? subscriptionEndsAt,
    this.autoRenew = true,
  }) : subscriptionEndsAt =
            subscriptionEndsAt ?? DateFormatter.addDays(joinedAt, 30);

  factory Subscriber.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Subscriber(
      id: doc.id,
      name: (d['name'] ?? '') as String,
      phone: d['phone'] as String?,
      supplierId: d['supplierId'] as String?,
      supplierName: d['supplierName'] as String?,
      packageId: d['packageId'] as String?,
      packageName: d['packageName'] as String?,
      planName: (d['planName'] ?? d['packageName']) as String?,
      monthlyFee: (d['monthlyFee'] ?? 0) as num,
      packageAgentPrice:
          (d['packageAgentPrice'] ?? d['agentPrice'] ?? 0) as num,
      currency: AppCurrency.fromCode((d['currency'] ?? 'IQD') as String),
      balance: (d['balance'] ?? 0) as num,
      status: enumFromName(SubscriberStatus.values, d['status'] as String?) ??
          SubscriberStatus.active,
      joinedAt: tsToDate(d['joinedAt']),
      subscriptionEndsAt: d['subscriptionEndsAt'] == null
          ? DateFormatter.addDays(tsToDate(d['joinedAt']), 30)
          : tsToDate(d['subscriptionEndsAt']),
      autoRenew: (d['autoRenew'] ?? true) as bool,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'phone': phone,
        'supplierId': supplierId,
        'supplierName': supplierName,
        'packageId': packageId,
        'packageName': packageName,
        'planName': packageName ?? planName,
        'monthlyFee': monthlyFee,
        'packageAgentPrice': packageAgentPrice,
        'currency': currency.code,
        'balance': balance,
        'status': status.name,
        'joinedAt': Timestamp.fromDate(joinedAt),
        'subscriptionEndsAt': Timestamp.fromDate(subscriptionEndsAt),
        'autoRenew': autoRenew,
      };

  Subscriber copyWith({
    String? id,
    String? name,
    String? phone,
    String? supplierId,
    String? supplierName,
    String? packageId,
    String? packageName,
    String? planName,
    num? monthlyFee,
    num? packageAgentPrice,
    AppCurrency? currency,
    num? balance,
    SubscriberStatus? status,
    DateTime? joinedAt,
    DateTime? subscriptionEndsAt,
    bool? autoRenew,
  }) =>
      Subscriber(
        id: id ?? this.id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        supplierId: supplierId ?? this.supplierId,
        supplierName: supplierName ?? this.supplierName,
        packageId: packageId ?? this.packageId,
        packageName: packageName ?? this.packageName,
        planName: planName ?? this.planName,
        monthlyFee: monthlyFee ?? this.monthlyFee,
        packageAgentPrice: packageAgentPrice ?? this.packageAgentPrice,
        currency: currency ?? this.currency,
        balance: balance ?? this.balance,
        status: status ?? this.status,
        joinedAt: joinedAt ?? this.joinedAt,
        subscriptionEndsAt: subscriptionEndsAt ?? this.subscriptionEndsAt,
        autoRenew: autoRenew ?? this.autoRenew,
      );
}

class SubscriberDebt {
  final String id;
  final String subscriberId;
  final String? supplierId;
  final String? packageId;
  final String? packageName;
  final num amount;
  final num paidAmount;
  final num agentCost;
  final AppCurrency currency;
  final DateTime periodStart;
  final DateTime periodEnd;
  final SubscriptionDebtStatus status;
  final String? note;
  final String recordedBy;
  final DateTime createdAt;
  final DateTime? paidAt;
  final String? paidBy;

  SubscriberDebt({
    required this.id,
    required this.subscriberId,
    this.supplierId,
    this.packageId,
    this.packageName,
    required this.amount,
    this.paidAmount = 0,
    required this.agentCost,
    required this.currency,
    required this.periodStart,
    required this.periodEnd,
    required this.status,
    this.note,
    required this.recordedBy,
    required this.createdAt,
    this.paidAt,
    this.paidBy,
  });

  bool get isPaid => status == SubscriptionDebtStatus.paid;
  num get remaining => (amount - paidAmount).clamp(0, double.infinity);
  num get profit => amount - agentCost;

  factory SubscriberDebt.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc,
      {String? subscriberId}) {
    final d = doc.data() ?? {};
    final parentSubscriberId = doc.reference.parent.parent?.id;
    return SubscriberDebt(
      id: doc.id,
      subscriberId: (d['subscriberId'] ??
          subscriberId ??
          parentSubscriberId ??
          '') as String,
      supplierId: d['supplierId'] as String?,
      packageId: d['packageId'] as String?,
      packageName: d['packageName'] as String?,
      amount: (d['amount'] ?? 0) as num,
      paidAmount: (d['paidAmount'] ?? 0) as num,
      agentCost: (d['agentCost'] ?? d['packageAgentPrice'] ?? 0) as num,
      currency: AppCurrency.fromCode((d['currency'] ?? 'IQD') as String),
      periodStart: tsToDate(d['periodStart']),
      periodEnd: tsToDate(d['periodEnd']),
      status:
          enumFromName(SubscriptionDebtStatus.values, d['status'] as String?) ??
              SubscriptionDebtStatus.unpaid,
      note: d['note'] as String?,
      recordedBy: (d['recordedBy'] ?? '') as String,
      createdAt: tsToDate(d['createdAt']),
      paidAt: d['paidAt'] == null ? null : tsToDate(d['paidAt']),
      paidBy: d['paidBy'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'subscriberId': subscriberId,
        'supplierId': supplierId,
        'packageId': packageId,
        'packageName': packageName,
        'amount': amount,
        'paidAmount': paidAmount,
        'agentCost': agentCost,
        'currency': currency.code,
        'periodStart': Timestamp.fromDate(periodStart),
        'periodEnd': Timestamp.fromDate(periodEnd),
        'status': status.name,
        'note': note,
        'recordedBy': recordedBy,
        'createdAt': Timestamp.fromDate(createdAt),
        'paidAt': paidAt == null ? null : Timestamp.fromDate(paidAt!),
        'paidBy': paidBy,
      };
}

class Payment {
  final String id;
  final String subscriberId;
  final num amount;
  final AppCurrency currency;
  final MoneyStorage receivedIn;
  final String? method;
  final String? note;
  final String recordedBy;
  final DateTime recordedAt;

  Payment({
    required this.id,
    required this.subscriberId,
    required this.amount,
    required this.currency,
    this.receivedIn = MoneyStorage.cashbox,
    this.method,
    this.note,
    required this.recordedBy,
    required this.recordedAt,
  });

  factory Payment.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Payment(
      id: doc.id,
      subscriberId: (d['subscriberId'] ?? '') as String,
      amount: (d['amount'] ?? 0) as num,
      currency: AppCurrency.fromCode((d['currency'] ?? 'IQD') as String),
      receivedIn:
          enumFromName(MoneyStorage.values, d['receivedIn'] as String?) ??
              MoneyStorage.cashbox,
      method: d['method'] as String?,
      note: d['note'] as String?,
      recordedBy: (d['recordedBy'] ?? '') as String,
      recordedAt: tsToDate(d['recordedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'subscriberId': subscriberId,
        'amount': amount,
        'currency': currency.code,
        'receivedIn': receivedIn.name,
        'method': method,
        'note': note,
        'recordedBy': recordedBy,
        'recordedAt': Timestamp.fromDate(recordedAt),
      };
}

class Supplier {
  final String id;
  final String name;
  final String? contactPhone;
  final String? contactEmail;
  final String? logoUrl;
  final String? notes;
  final bool active;
  final DateTime createdAt;

  Supplier({
    required this.id,
    required this.name,
    this.contactPhone,
    this.contactEmail,
    this.logoUrl,
    this.notes,
    required this.active,
    required this.createdAt,
  });

  factory Supplier.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Supplier(
      id: doc.id,
      name: (d['name'] ?? '') as String,
      contactPhone: d['contactPhone'] as String?,
      contactEmail: d['contactEmail'] as String?,
      logoUrl: d['logoUrl'] as String?,
      notes: d['notes'] as String?,
      active: (d['active'] ?? true) as bool,
      createdAt: tsToDate(d['createdAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'contactPhone': contactPhone,
        'contactEmail': contactEmail,
        'logoUrl': logoUrl,
        'notes': notes,
        'active': active,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

class SupplierPackageTemplate {
  final String id;
  final String supplierId;
  final String name;
  final num agentPrice;
  final num subscriberPrice;
  final AppCurrency currency;
  final bool active;

  SupplierPackageTemplate({
    required this.id,
    required this.supplierId,
    required this.name,
    required this.agentPrice,
    required this.subscriberPrice,
    required this.currency,
    required this.active,
  });

  num get price => agentPrice;

  factory SupplierPackageTemplate.fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc, String supplierId) {
    final d = doc.data() ?? {};
    return SupplierPackageTemplate(
      id: doc.id,
      supplierId: supplierId,
      name: (d['name'] ?? '') as String,
      agentPrice: (d['agentPrice'] ?? d['price'] ?? 0) as num,
      subscriberPrice:
          (d['subscriberPrice'] ?? d['monthlyFee'] ?? d['price'] ?? 0) as num,
      currency: AppCurrency.fromCode((d['currency'] ?? 'IQD') as String),
      active: (d['active'] ?? true) as bool,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'agentPrice': agentPrice,
        'subscriberPrice': subscriberPrice,
        'price': agentPrice,
        'currency': currency.code,
        'active': active,
      };
}

class SupplierPurchase {
  final String id;
  final String supplierId;
  final String? packageId;
  final num qty;
  final num unitPrice;
  final num totalPrice;
  final num paid;
  final num remaining;
  final AppCurrency currency;
  final String? note;
  final DateTime date;
  final String recordedBy;

  SupplierPurchase({
    required this.id,
    required this.supplierId,
    this.packageId,
    required this.qty,
    required this.unitPrice,
    required this.totalPrice,
    required this.paid,
    required this.remaining,
    required this.currency,
    this.note,
    required this.date,
    required this.recordedBy,
  });

  factory SupplierPurchase.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final total = (d['totalPrice'] ?? 0) as num;
    final paid = (d['paid'] ?? 0) as num;
    return SupplierPurchase(
      id: doc.id,
      supplierId: (d['supplierId'] ?? '') as String,
      packageId: d['packageId'] as String?,
      qty: (d['qty'] ?? 1) as num,
      unitPrice: (d['unitPrice'] ?? 0) as num,
      totalPrice: total,
      paid: paid,
      remaining: total - paid,
      currency: AppCurrency.fromCode((d['currency'] ?? 'IQD') as String),
      note: d['note'] as String?,
      date: tsToDate(d['date']),
      recordedBy: (d['recordedBy'] ?? '') as String,
    );
  }

  Map<String, dynamic> toMap() => {
        'supplierId': supplierId,
        'packageId': packageId,
        'qty': qty,
        'unitPrice': unitPrice,
        'totalPrice': totalPrice,
        'paid': paid,
        'currency': currency.code,
        'note': note,
        'date': Timestamp.fromDate(date),
        'recordedBy': recordedBy,
      };
}

class SupplierBalanceTransaction {
  final String id;
  final String supplierId;
  final SupplierBalanceTransactionType type;
  final num amount;
  final AppCurrency currency;
  final String? note;
  final DateTime date;
  final String recordedBy;
  final String recordedByName;
  final UserRole recordedByRole;
  final MoneyStorage paidFrom;
  final String? receiptUrl;

  SupplierBalanceTransaction({
    required this.id,
    required this.supplierId,
    required this.type,
    required this.amount,
    required this.currency,
    this.note,
    required this.date,
    required this.recordedBy,
    required this.recordedByName,
    required this.recordedByRole,
    this.paidFrom = MoneyStorage.cashbox,
    this.receiptUrl,
  });

  factory SupplierBalanceTransaction.fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return SupplierBalanceTransaction(
      id: doc.id,
      supplierId: (d['supplierId'] ?? '') as String,
      type: enumFromName(
              SupplierBalanceTransactionType.values, d['type'] as String?) ??
          SupplierBalanceTransactionType.recharge,
      amount: (d['amount'] ?? 0) as num,
      currency: AppCurrency.fromCode((d['currency'] ?? 'IQD') as String),
      note: d['note'] as String?,
      date: tsToDate(d['date']),
      recordedBy: (d['recordedBy'] ?? '') as String,
      recordedByName: (d['recordedByName'] ?? '') as String,
      recordedByRole:
          enumFromName(UserRole.values, d['recordedByRole'] as String?) ??
              UserRole.employee,
      paidFrom: enumFromName(MoneyStorage.values, d['paidFrom'] as String?) ??
          MoneyStorage.cashbox,
      receiptUrl: d['receiptUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'supplierId': supplierId,
        'type': type.name,
        'amount': amount,
        'currency': currency.code,
        'note': note,
        'date': Timestamp.fromDate(date),
        'recordedBy': recordedBy,
        'recordedByName': recordedByName,
        'recordedByRole': recordedByRole.name,
        'paidFrom': paidFrom.name,
        if (receiptUrl != null) 'receiptUrl': receiptUrl,
      };
}

class SupplierPaymentRequest {
  final String id;
  final String supplierId;
  final num amount;
  final AppCurrency currency;
  final String? note;
  final String byEmployeeUid;
  final String byEmployeeName;
  final PaymentRequestStatus status;
  final DateTime createdAt;
  final DateTime? decidedAt;
  final String? decidedBy;
  final String? linkedPurchaseId;
  final String? receiptUrl;

  SupplierPaymentRequest({
    required this.id,
    required this.supplierId,
    required this.amount,
    required this.currency,
    this.note,
    required this.byEmployeeUid,
    required this.byEmployeeName,
    required this.status,
    required this.createdAt,
    this.decidedAt,
    this.decidedBy,
    this.linkedPurchaseId,
    this.receiptUrl,
  });

  factory SupplierPaymentRequest.fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return SupplierPaymentRequest(
      id: doc.id,
      supplierId: (d['supplierId'] ?? '') as String,
      amount: (d['amount'] ?? 0) as num,
      currency: AppCurrency.fromCode((d['currency'] ?? 'IQD') as String),
      note: d['note'] as String?,
      byEmployeeUid: (d['byEmployeeUid'] ?? '') as String,
      byEmployeeName: (d['byEmployeeName'] ?? '') as String,
      status:
          enumFromName(PaymentRequestStatus.values, d['status'] as String?) ??
              PaymentRequestStatus.pending,
      createdAt: tsToDate(d['createdAt']),
      decidedAt: d['decidedAt'] == null ? null : tsToDate(d['decidedAt']),
      decidedBy: d['decidedBy'] as String?,
      linkedPurchaseId: d['linkedPurchaseId'] as String?,
      receiptUrl: d['receiptUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'supplierId': supplierId,
        'amount': amount,
        'currency': currency.code,
        'note': note,
        'byEmployeeUid': byEmployeeUid,
        'byEmployeeName': byEmployeeName,
        'status': status.name,
        'createdAt': Timestamp.fromDate(createdAt),
        'decidedAt': decidedAt == null ? null : Timestamp.fromDate(decidedAt!),
        'decidedBy': decidedBy,
        'linkedPurchaseId': linkedPurchaseId,
        if (receiptUrl != null) 'receiptUrl': receiptUrl,
      };
}

class Expense {
  final String id;
  final ExpenseEntryType type;
  final num amount;
  final AppCurrency currency;
  final MoneyStorage paidFrom;
  final ExpenseCategory category;
  final String reason;
  final DateTime date;
  final String recordedBy;
  final String? recordedByName;
  final UserRole? recordedByRole;
  final String? attachmentUrl;

  Expense({
    required this.id,
    this.type = ExpenseEntryType.expense,
    required this.amount,
    required this.currency,
    this.paidFrom = MoneyStorage.cashbox,
    required this.category,
    required this.reason,
    required this.date,
    required this.recordedBy,
    this.recordedByName,
    this.recordedByRole,
    this.attachmentUrl,
  });

  factory Expense.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Expense(
      id: doc.id,
      type: enumFromName(ExpenseEntryType.values, d['type'] as String?) ??
          ExpenseEntryType.expense,
      amount: (d['amount'] ?? 0) as num,
      currency: AppCurrency.fromCode((d['currency'] ?? 'IQD') as String),
      paidFrom: enumFromName(MoneyStorage.values, d['paidFrom'] as String?) ??
          MoneyStorage.cashbox,
      category:
          enumFromName(ExpenseCategory.values, d['category'] as String?) ??
              ExpenseCategory.other,
      reason: (d['reason'] ?? '') as String,
      date: tsToDate(d['date']),
      recordedBy: (d['recordedBy'] ?? '') as String,
      recordedByName: d['recordedByName'] as String?,
      recordedByRole:
          enumFromName(UserRole.values, d['recordedByRole'] as String?),
      attachmentUrl: d['attachmentUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'type': type.name,
        'amount': amount,
        'currency': currency.code,
        'paidFrom': paidFrom.name,
        'category': category.name,
        'reason': reason,
        'date': Timestamp.fromDate(date),
        'recordedBy': recordedBy,
        'recordedByName': recordedByName,
        'recordedByRole': recordedByRole?.name,
        'attachmentUrl': attachmentUrl,
      };
}

class ExpenseDeleteRequest {
  final String id;
  final String expenseId;
  final String expenseReason;
  final num amount;
  final AppCurrency currency;
  final String byEmployeeUid;
  final String byEmployeeName;
  final PaymentRequestStatus status;
  final DateTime createdAt;
  final DateTime? decidedAt;
  final String? decidedBy;

  ExpenseDeleteRequest({
    required this.id,
    required this.expenseId,
    required this.expenseReason,
    required this.amount,
    required this.currency,
    required this.byEmployeeUid,
    required this.byEmployeeName,
    required this.status,
    required this.createdAt,
    this.decidedAt,
    this.decidedBy,
  });

  factory ExpenseDeleteRequest.fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return ExpenseDeleteRequest(
      id: doc.id,
      expenseId: (d['expenseId'] ?? '') as String,
      expenseReason: (d['expenseReason'] ?? '') as String,
      amount: (d['amount'] ?? 0) as num,
      currency: AppCurrency.fromCode((d['currency'] ?? 'IQD') as String),
      byEmployeeUid: (d['byEmployeeUid'] ?? '') as String,
      byEmployeeName: (d['byEmployeeName'] ?? '') as String,
      status:
          enumFromName(PaymentRequestStatus.values, d['status'] as String?) ??
              PaymentRequestStatus.pending,
      createdAt: tsToDate(d['createdAt']),
      decidedAt: d['decidedAt'] == null ? null : tsToDate(d['decidedAt']),
      decidedBy: d['decidedBy'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'expenseId': expenseId,
        'expenseReason': expenseReason,
        'amount': amount,
        'currency': currency.code,
        'byEmployeeUid': byEmployeeUid,
        'byEmployeeName': byEmployeeName,
        'status': status.name,
        'createdAt': Timestamp.fromDate(createdAt),
        'decidedAt': decidedAt == null ? null : Timestamp.fromDate(decidedAt!),
        'decidedBy': decidedBy,
      };
}

class Employee {
  final String id; // doc id (often == uid)
  final String uid;
  final String username;
  final String email;
  final String displayName;
  final Set<Permission> permissions;
  final bool active;
  final String? photoUrl;
  final DateTime createdAt;

  Employee({
    required this.id,
    required this.uid,
    required this.username,
    required this.email,
    required this.displayName,
    required this.permissions,
    required this.active,
    this.photoUrl,
    required this.createdAt,
  });

  factory Employee.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final perms = (d['permissions'] as List?)
            ?.cast<String>()
            .map(Permission.fromName)
            .whereType<Permission>()
            .toSet() ??
        <Permission>{};
    return Employee(
      id: doc.id,
      uid: (d['uid'] ?? doc.id) as String,
      username: (d['username'] ?? '') as String,
      email: (d['email'] ?? '') as String,
      displayName: (d['displayName'] ?? d['username'] ?? '') as String,
      permissions: perms,
      active: (d['active'] ?? true) as bool,
      photoUrl: d['photoUrl'] as String?,
      createdAt: tsToDate(d['createdAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'username': username,
        'email': email,
        'displayName': displayName,
        'permissions': permissions.map((p) => p.name).toList(),
        'active': active,
        'photoUrl': photoUrl,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

class HistoryEvent {
  final String id;
  final String actorUid;
  final String actorName;
  final UserRole actorRole;
  final String? actorPhotoUrl;
  final String action;
  final String targetType;
  final String? targetId;
  final String summary;
  final Map<String, dynamic>? before;
  final Map<String, dynamic>? after;
  final DateTime ts;

  HistoryEvent({
    required this.id,
    required this.actorUid,
    required this.actorName,
    required this.actorRole,
    this.actorPhotoUrl,
    required this.action,
    required this.targetType,
    this.targetId,
    required this.summary,
    this.before,
    this.after,
    required this.ts,
  });

  factory HistoryEvent.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final actor = (d['actor'] as Map?)?.cast<String, dynamic>() ?? {};
    return HistoryEvent(
      id: doc.id,
      actorUid: (actor['uid'] ?? '') as String,
      actorName: (actor['displayName'] ?? '') as String,
      actorRole: enumFromName(UserRole.values, actor['role'] as String?) ??
          UserRole.employee,
      actorPhotoUrl: actor['photoUrl'] as String?,
      action: (d['action'] ?? '') as String,
      targetType: (d['targetType'] ?? '') as String,
      targetId: d['targetId'] as String?,
      summary: (d['summary'] ?? '') as String,
      before: (d['before'] as Map?)?.cast<String, dynamic>(),
      after: (d['after'] as Map?)?.cast<String, dynamic>(),
      ts: tsToDate(d['ts']),
    );
  }

  Map<String, dynamic> toMap() => {
        'actor': {
          'uid': actorUid,
          'displayName': actorName,
          'role': actorRole.name,
          'photoUrl': actorPhotoUrl,
        },
        'action': action,
        'targetType': targetType,
        'targetId': targetId,
        'summary': summary,
        'before': before,
        'after': after,
        'ts': Timestamp.fromDate(ts),
      };
}

class CashboxLedgerEntry {
  final String id;
  final String kind;
  final String effect;
  final num amount;
  final AppCurrency currency;
  final String actorUid;
  final String actorName;
  final String actorRole;
  final String? subscriberId;
  final String? subscriberName;
  final String? supplierId;
  final String? supplierName;
  final String? expenseId;
  final String? paymentId;
  final String? reason;
  final String? note;
  final String? paidFrom;
  final bool reverse;
  final DateTime createdAt;

  CashboxLedgerEntry({
    required this.id,
    required this.kind,
    required this.effect,
    required this.amount,
    required this.currency,
    required this.actorUid,
    required this.actorName,
    required this.actorRole,
    this.subscriberId,
    this.subscriberName,
    this.supplierId,
    this.supplierName,
    this.expenseId,
    this.paymentId,
    this.reason,
    this.note,
    this.paidFrom,
    this.reverse = false,
    required this.createdAt,
  });

  bool get isDirectCashIncrease => effect.contains('cashboxIncrease');
  bool get isDirectCashDecrease => effect.contains('cashboxDecrease');
  bool get isStaffDebtToCashbox => effect.contains('staffDebtToCashbox');
  bool get isCashboxDebtToStaff => effect.contains('cashboxDebtToStaff');
  bool get isSettlement =>
      kind == 'staffSettlement' || kind == 'staffReimbursement';

  MoneyStorage? get paidFromStorage =>
      paidFrom == null ? null : enumFromName(MoneyStorage.values, paidFrom);
  bool get isPaidFromPersonal =>
      paidFrom == 'personal' || isCashboxDebtToStaff;
  bool get isPaidFromCashbox =>
      paidFrom == 'cashbox' || isDirectCashDecrease;
  bool get isCustodyPayment =>
      (kind == 'subscriptionPayment' && paidFrom == 'personal') ||
      isStaffDebtToCashbox;

  factory CashboxLedgerEntry.fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return CashboxLedgerEntry(
      id: doc.id,
      kind: (d['kind'] ?? '') as String,
      effect: (d['effect'] ?? '') as String,
      amount: (d['amount'] ?? 0) as num,
      currency: AppCurrency.fromCode((d['currency'] ?? 'IQD') as String),
      actorUid: (d['actorUid'] ?? '') as String,
      actorName: (d['actorName'] ?? '') as String,
      actorRole: (d['actorRole'] ?? '') as String,
      subscriberId: d['subscriberId'] as String?,
      subscriberName: d['subscriberName'] as String?,
      supplierId: d['supplierId'] as String?,
      supplierName: d['supplierName'] as String?,
      expenseId: d['expenseId'] as String?,
      paymentId: d['paymentId'] as String?,
      reason: d['reason'] as String?,
      note: d['note'] as String?,
      paidFrom: d['paidFrom'] as String?,
      reverse: (d['reverse'] ?? false) as bool,
      createdAt: tsToDate(d['createdAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'kind': kind,
        'effect': effect,
        'amount': amount,
        'currency': currency.code,
        'actorUid': actorUid,
        'actorName': actorName,
        'actorRole': actorRole,
        'subscriberId': subscriberId,
        'subscriberName': subscriberName,
        'supplierId': supplierId,
        'supplierName': supplierName,
        'expenseId': expenseId,
        'paymentId': paymentId,
        'reason': reason,
        'note': note,
        'paidFrom': paidFrom,
        'reverse': reverse,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

class StaffReimbursementRequest {
  final String id;
  final num amount;
  final AppCurrency currency;
  final String? note;
  final String byEmployeeUid;
  final String byEmployeeName;
  final UserRole byEmployeeRole;
  final PaymentRequestStatus status;
  final DateTime createdAt;
  final DateTime? decidedAt;
  final String? decidedBy;

  StaffReimbursementRequest({
    required this.id,
    required this.amount,
    required this.currency,
    this.note,
    required this.byEmployeeUid,
    required this.byEmployeeName,
    required this.byEmployeeRole,
    required this.status,
    required this.createdAt,
    this.decidedAt,
    this.decidedBy,
  });

  factory StaffReimbursementRequest.fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return StaffReimbursementRequest(
      id: doc.id,
      amount: (d['amount'] ?? 0) as num,
      currency: AppCurrency.fromCode((d['currency'] ?? 'IQD') as String),
      note: d['note'] as String?,
      byEmployeeUid: (d['byEmployeeUid'] ?? '') as String,
      byEmployeeName: (d['byEmployeeName'] ?? '') as String,
      byEmployeeRole:
          enumFromName(UserRole.values, d['byEmployeeRole'] as String?) ??
              UserRole.employee,
      status: enumFromName(PaymentRequestStatus.values, d['status'] as String?) ??
          PaymentRequestStatus.pending,
      createdAt: tsToDate(d['createdAt']),
      decidedAt: d['decidedAt'] == null ? null : tsToDate(d['decidedAt']),
      decidedBy: d['decidedBy'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'amount': amount,
        'currency': currency.code,
        'note': note,
        'byEmployeeUid': byEmployeeUid,
        'byEmployeeName': byEmployeeName,
        'byEmployeeRole': byEmployeeRole.name,
        'status': status.name,
        'createdAt': Timestamp.fromDate(createdAt),
        'decidedAt': decidedAt == null ? null : Timestamp.fromDate(decidedAt!),
        'decidedBy': decidedBy,
      };
}

class ChatMessage {
  final String id;
  final String senderUid;
  final String senderName;
  final UserRole senderRole;
  final String text;
  final String? imageUrl;
  final DateTime createdAt;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.senderUid,
    required this.senderName,
    required this.senderRole,
    required this.text,
    this.imageUrl,
    required this.createdAt,
    this.isRead = false,
  });

  factory ChatMessage.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return ChatMessage(
      id: doc.id,
      senderUid: (d['senderUid'] ?? '') as String,
      senderName: (d['senderName'] ?? '') as String,
      senderRole: enumFromName(UserRole.values, d['senderRole'] as String?) ??
          UserRole.employee,
      text: (d['text'] ?? '') as String,
      imageUrl: d['imageUrl'] as String?,
      createdAt: tsToDate(d['createdAt']),
      isRead: (d['isRead'] ?? false) as bool,
    );
  }

  Map<String, dynamic> toMap() => {
        'senderUid': senderUid,
        'senderName': senderName,
        'senderRole': senderRole.name,
        'text': text,
        if (imageUrl != null) 'imageUrl': imageUrl,
        'createdAt': Timestamp.fromDate(createdAt),
        'isRead': isRead,
      };
}

class AppNotification {
  final String id;
  final String title;
  final String body;
  final String type; // reimbursement_request, supplier_request, expense_delete_request, chat_message, financial_alert, etc.
  final String recipientUid; // Specific user or 'admin'
  final String actorUid;
  final String actorName;
  final DateTime createdAt;
  final bool isRead;
  final String? targetId;
  final String? targetType;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.recipientUid,
    required this.actorUid,
    required this.actorName,
    required this.createdAt,
    this.isRead = false,
    this.targetId,
    this.targetType,
  });

  factory AppNotification.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return AppNotification(
      id: doc.id,
      title: (d['title'] ?? '') as String,
      body: (d['body'] ?? '') as String,
      type: (d['type'] ?? 'system') as String,
      recipientUid: (d['recipientUid'] ?? '') as String,
      actorUid: (d['actorUid'] ?? '') as String,
      actorName: (d['actorName'] ?? '') as String,
      createdAt: tsToDate(d['createdAt']),
      isRead: (d['isRead'] ?? false) as bool,
      targetId: d['targetId'] as String?,
      targetType: d['targetType'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'body': body,
        'type': type,
        'recipientUid': recipientUid,
        'actorUid': actorUid,
        'actorName': actorName,
        'createdAt': Timestamp.fromDate(createdAt),
        'isRead': isRead,
        'targetId': targetId,
        'targetType': targetType,
      };
}

