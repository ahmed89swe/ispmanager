# Cloud Functions

## Setup
```bash
cd functions
npm install
```

## Deploy
```bash
# from project root
firebase use --add        # pick project, alias "default"
firebase deploy --only firestore:rules,firestore:indexes,storage,functions
```

## Local emulator
```bash
firebase emulators:start --only auth,firestore,functions,storage
```

## Functions

### `createEmployee` (callable)
Called from `EmployeesRepository.create()`. Creates an Auth user with a synthesized internal
email (`<username>.<adminPrefix>@isp-app.local`) and the corresponding employee doc under
`/admins/{adminUid}/employees/{uid}`. Sets custom claims `role=employee, adminUid=...`.

Required payload:
```ts
{ adminUid: string, username: string, displayName: string, password: string, permissions: string[] }
```

### `onSupplierPaymentRequestCreate` (Firestore trigger)
Writes a notification under `/admins/{adminUid}/notifications` so the admin inbox can show
unread badges and (optionally) FCM can be wired to it later.

### `onSupplierPaymentRequestUpdated` (Firestore trigger)
When an admin sets `status: "approved"` on a request, applies the amount to the linked
purchase's `paid` field atomically and logs a history event.
