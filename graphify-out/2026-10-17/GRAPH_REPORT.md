# Graph Report - isp_user_manager  (2026-10-17)

## Corpus Check
- 99 files · ~83,650 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 58 file(s) not represented in the graph (top: (none) 9, .xcconfig 8, .xml 7)

## Summary
- 1884 nodes · 2701 edges · 76 communities (63 shown, 13 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 17 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `7499ffde`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- cashbox_screen.dart
- my_application.cc
- expenses_screen.dart
- app.dart
- subscribers_repository.dart
- admin_shell.dart
- subscribers_screen.dart
- dashboard_screen.dart
- suppliers_screen.dart
- inbox_screen.dart
- reports_screen.dart
- package.json
- currencyProvider
- models.dart
- chat_conversation_screen.dart
- package:flutter_test/flutter_test.dart
- firebase_service.dart
- login_screen.dart
- compilerOptions
- notifications_sheet.dart
- employees_screen.dart
- .eslintrc.json
- package:flutter_riverpod/flutter_riverpod.dart
- expenses_repository.dart
- Cloud Functions
- chat_repository.dart
- cashbox_repository.dart
- cashboxRepositoryProvider
- update_screen.dart
- manifest.json
- pdf_report_service.dart
- authRepositoryProvider
- auth_repository.dart
- currentAppUserProvider
- app_localizations.dart
- constants.dart
- record_payment_sheet.dart
- history_screen.dart
- cashbox_service.dart
- win32_window.cpp
- GeneratedPluginRegistrant.swift
- app_update_repository.dart
- suppliers_repository.dart
- ConsumerState
- history_repository.dart
- subscribersRepositoryProvider
- employees_repository.dart
- preferences_providers.dart
- app_theme.dart
- app_avatar.dart
- auth_utils.dart
- StatelessWidget
- package:flutter/material.dart
- notifications_repository.dart
- utils.cpp
- ../../core/models/models.dart
- MainActivity.kt
- cashboxStreamProvider
- NotificationsSheet
- ConsumerWidget
- formatters.dart
- profile_repository.dart
- RecurringExpenseFormSheet
- _AdminBottomTabBar
- AppLocalizations
- isp_user_manager
- LaunchImage.imageset/README.md
- advance_subscription_sheet.dart
- ../../core/constants.dart
- _InboxScreenState

## God Nodes (most connected - your core abstractions)
1. `currentAppUserProvider` - 41 edges
2. `Win32Window` - 21 edges
3. `subscribersRepositoryProvider` - 18 edges
4. `compilerOptions` - 13 edges
5. `cashboxStreamProvider` - 13 edges
6. `currencyProvider` - 13 edges
7. `_InboxScreenState` - 12 edges
8. `AppCurrency` - 11 edges
9. `_DashboardScreenState` - 11 edges
10. `employeesStreamProvider` - 11 edges

## Surprising Connections (you probably didn't know these)
- `build` --references--> `currentAppUserProvider`  [EXTRACTED]
  lib/features/dashboard/admin_shell.dart → lib/features/auth/auth_repository.dart
- `build` --references--> `currentAppUserProvider`  [EXTRACTED]
  lib/features/inbox/inbox_screen.dart → lib/features/auth/auth_repository.dart
- `_submit` --references--> `currentAppUserProvider`  [EXTRACTED]
  lib/features/payments/advance_subscription_sheet.dart → lib/features/auth/auth_repository.dart
- `_save` --references--> `currentAppUserProvider`  [EXTRACTED]
  lib/features/payments/record_payment_sheet.dart → lib/features/auth/auth_repository.dart
- `_buildAdminStaffDebtsTab` --references--> `employeesStreamProvider`  [EXTRACTED]
  lib/features/finance/cashbox_screen.dart → lib/features/employees/employees_repository.dart

## Import Cycles
- None detected.

## Communities (76 total, 13 thin omitted)

### Community 0 - "cashbox_screen.dart"
Cohesion: 0.03
Nodes (72): Card, Center, Column, Container, DefaultTabController, Divider, DraggableScrollableSheet, Icon (+64 more)

### Community 1 - "my_application.cc"
Cohesion: 0.05
Nodes (14): fl_register_plugins(), main(), my_application_activate(), my_application_class_init(), my_application_dispose(), my_application_init(), my_application_local_command_line(), my_application_new() (+6 more)

### Community 2 - "expenses_screen.dart"
Cohesion: 0.03
Nodes (66): _actorLabel, Center, Color, Column, Container, Divider, Expanded, Icon (+58 more)

### Community 3 - "app.dart"
Cohesion: 0.11
Nodes (19): CircularProgressIndicator, Icon, MaterialApp, Scaffold, SizedBox, UpdateScreen, build, IspUserManagerApp (+11 more)

### Community 4 - "subscribers_repository.dart"
Cohesion: 0.06
Nodes (31): add, addDebt, addWithInitialSubscription, authUser, cancelAdvancePayment, _col, _dateFromFirestore, _db (+23 more)

### Community 5 - "admin_shell.dart"
Cohesion: 0.04
Nodes (37): CircleAvatar, FadeTransition, Function, IconButton, Material, Scaffold, SizedBox, TextStyle (+29 more)

### Community 6 - "subscribers_screen.dart"
Cohesion: 0.03
Nodes (65): Color, Column, Container, Dialog, Divider, Icon, InkWell, launchUrl (+57 more)

### Community 7 - "dashboard_screen.dart"
Cohesion: 0.05
Nodes (36): Card, CashboxScreen, Center, Container, Icon, _Kpi, _kpiGrid, _Legend (+28 more)

### Community 8 - "suppliers_screen.dart"
Cohesion: 0.05
Nodes (40): Center, Container, DefaultTabController, Expanded, launchUrl, ListTile, Padding, SafeArea (+32 more)

### Community 9 - "inbox_screen.dart"
Cohesion: 0.04
Nodes (42): Card, Center, _colorFor, Column, Divider, Expanded, _expenseDeleteRequestTile, Icon (+34 more)

### Community 10 - "reports_screen.dart"
Cohesion: 0.04
Nodes (41): actionsRow, Card, Column, fmt, ListView, Padding, PdfReportService, SizedBox (+33 more)

### Community 11 - "package.json"
Cohesion: 0.06
Nodes (34): dependencies, firebase-admin, firebase-functions, devDependencies, eslint, typescript, @typescript-eslint/eslint-plugin, @typescript-eslint/parser (+26 more)

### Community 12 - "currencyProvider"
Cohesion: 0.38
Nodes (12): build, _DashboardScreenState, expensesStreamProvider, paymentsRepositoryProvider, build, _ReportsScreenState, subscribersStreamProvider, build (+4 more)

### Community 13 - "models.dart"
Cohesion: 0.01
Nodes (133): action, active, actorName, actorPhotoUrl, actorRole, actorUid, adminUid, after (+125 more)

### Community 14 - "chat_conversation_screen.dart"
Cohesion: 0.07
Nodes (24): Align, Center, Container, Padding, SafeArea, Scaffold, SizedBox, Text (+16 more)

### Community 15 - "package:flutter_test/flutter_test.dart"
Cohesion: 0.12
Nodes (7): initializeDateFormatting, main, main, main, main, main, main

### Community 16 - "firebase_service.dart"
Cohesion: 0.06
Nodes (19): UnsupportedError, firebaseAuthProvider, firebaseMessagingProvider, FirebaseService, firebaseStorageProvider, firestoreProvider, init, initialized (+11 more)

### Community 17 - "login_screen.dart"
Cohesion: 0.09
Nodes (19): DefaultTabController, Icon, SizedBox, firebaseAvailableProvider, _adminEmail, _adminTab, build, _busy (+11 more)

### Community 18 - "compilerOptions"
Cohesion: 0.12
Nodes (15): compilerOptions, esModuleInterop, lib, module, moduleResolution, noImplicitAny, noImplicitReturns, outDir (+7 more)

### Community 19 - "notifications_sheet.dart"
Cohesion: 0.12
Nodes (13): Center, Column, Dismissible, Divider, DraggableScrollableSheet, Icon, showModalBottomSheet, SizedBox (+5 more)

### Community 20 - "employees_screen.dart"
Cohesion: 0.08
Nodes (29): Center, ListTile, Padding, Scaffold, SizedBox, SnackBar, AppUser, Employee (+21 more)

### Community 21 - ".eslintrc.json"
Cohesion: 0.12
Nodes (16): env, es2020, node, extends, ignorePatterns, parser, parserOptions, ecmaVersion (+8 more)

### Community 22 - "package:flutter_riverpod/flutter_riverpod.dart"
Cohesion: 0.17
Nodes (5): GoRouter, Scaffold, build, _RefreshOnChange, authStateProvider

### Community 23 - "expenses_repository.dart"
Cohesion: 0.06
Nodes (31): StateError, add, authUser, _col, createDeleteRequest, _db, decideDeleteRequest, delete (+23 more)

### Community 24 - "Cloud Functions"
Cohesion: 0.22
Nodes (8): Cloud Functions, `createEmployee` (callable), Deploy, Functions, Local emulator, `onSupplierPaymentRequestCreate` (Firestore trigger), `onSupplierPaymentRequestUpdated` (Firestore trigger), Setup

### Community 25 - "chat_repository.dart"
Cohesion: 0.11
Nodes (17): StateError, _chatDoc, ChatRepository, _db, _imageContentType, markMessagesAsRead, _messagesCol, _notificationsRepo (+9 more)

### Community 26 - "cashbox_repository.dart"
Cohesion: 0.05
Nodes (33): Exception, extractBalance, authUser, balanceFor, balances, cashboxDebtToStaff, cashboxDebtToStaffFor, cashboxDebtToStaffForUid (+25 more)

### Community 27 - "cashboxRepositoryProvider"
Cohesion: 0.33
Nodes (6): cashboxRepositoryProvider, _ClaimReimbursementRequestSheet, _ClaimReimbursementRequestSheetState, _DirectAdjustmentSheet, _DirectAdjustmentSheetState, _submit

### Community 28 - "update_screen.dart"
Cohesion: 0.12
Nodes (13): launchUrl, Padding, PopScope, SizedBox, Spacer, AppUpdateInfo, _Body, build (+5 more)

### Community 29 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 30 - "pdf_report_service.dart"
Cohesion: 0.04
Nodes (40): _bold, _buildCustomFooter, _buildCustomHeader, _buildEmptyBox, _buildFooter, _buildHeader, _buildInfoItem, _buildKpiCard (+32 more)

### Community 31 - "authRepositoryProvider"
Cohesion: 0.27
Nodes (7): authRepositoryProvider, _employeeSignIn, _googleSignIn, _buildDesktopShell, _buildMobileShell, _buildHeaderGreeting, unreadNotificationsCountProvider

### Community 32 - "auth_repository.dart"
Cohesion: 0.10
Nodes (18): AppUser, GoogleSignIn, StateError, addFcmToken, _auth, authStateChanges, currentAppUser, currentAppUserStream (+10 more)

### Community 33 - "currentAppUserProvider"
Cohesion: 0.10
Nodes (23): ListView, Scaffold, SizedBox, currentAppUserProvider, build, ChatConversationScreen, _ChatConversationScreenState, _markRead (+15 more)

### Community 34 - "app_localizations.dart"
Cohesion: 0.01
Nodes (131): addExpense, addNew, addSubscriber, admin, adminEmail, all, amount, approve (+123 more)

### Community 35 - "constants.dart"
Cohesion: 0.10
Nodes (18): all, code, ExpenseCategory, ExpenseEntryType, fromCode, fromName, manageSupplierPurchases, PaymentRequestStatus (+10 more)

### Community 36 - "record_payment_sheet.dart"
Cohesion: 0.12
Nodes (15): Padding, SizedBox, MoneyStorage, Subscriber, _amount, build, _busy, createState (+7 more)

### Community 37 - "history_screen.dart"
Cohesion: 0.12
Nodes (16): Column, ListTile, historyRepositoryProvider, historyStreamProvider, build, _busyEventIds, createState, _errorMessage (+8 more)

### Community 38 - "cashbox_service.dart"
Cohesion: 0.12
Nodes (13): cashboxDocId, cashboxRef, CashboxService, debtKey, ensureExists, initialData, ledgerCol, registerDirectAdjustment (+5 more)

### Community 39 - "win32_window.cpp"
Cohesion: 0.05
Nodes (20): FlutterWindow, flutter_controller_, FlutterWindow::FlutterWindow(), project_, EnableFullDpiSupportIfAvailable(), Point, x, y (+12 more)

### Community 40 - "GeneratedPluginRegistrant.swift"
Cohesion: 0.05
Nodes (28): cloud_firestore, Cocoa, connectivity_plus, file_selector_macos, firebase_analytics, firebase_auth, firebase_core, firebase_crashlytics (+20 more)

### Community 41 - "app_update_repository.dart"
Cohesion: 0.12
Nodes (14): StateError, AppUpdateRepository, appUpdateRepositoryProvider, check, currentVersion, debugMessage, downloadUrl, _firestore (+6 more)

### Community 42 - "suppliers_repository.dart"
Cohesion: 0.06
Nodes (30): StateError, add, addBalanceTransaction, addPackage, addPurchase, applyPaymentToPurchase, authUser, _balanceCol (+22 more)

### Community 43 - "ConsumerState"
Cohesion: 0.13
Nodes (18): AdminShell, _AdminShellState, DashboardScreen, _RecurringExpenseMonthsDialog, _RecurringExpenseMonthsDialogState, _SettleStaffDebtSheet, _SettleStaffDebtSheetState, ReportsScreen (+10 more)

### Community 44 - "history_repository.dart"
Cohesion: 0.09
Nodes (19): StateError, now, null, tsToDate, authUser, _db, eventData, _expenseIdFromDeleteRequestEvent (+11 more)

### Community 45 - "subscribersRepositoryProvider"
Cohesion: 0.18
Nodes (11): _syncDueDebts, _buildBody, subscribersRepositoryProvider, AddSubscriberDebtSheet, _AddSubscriberDebtSheetState, _confirmAndDeleteDebt, _confirmAndPayDebt, _exportStatement (+3 more)

### Community 46 - "employees_repository.dart"
Cohesion: 0.11
Nodes (16): authUser, _col, create, _db, delete, EmployeesRepository, _imageContentType, _logger (+8 more)

### Community 47 - "preferences_providers.dart"
Cohesion: 0.09
Nodes (20): Locale, UnimplementedError, AppColorTheme, AppCurrency, AppPreferences, appPreferencesProvider, CurrencyNotifier, _kCurrency (+12 more)

### Community 48 - "app_theme.dart"
Cohesion: 0.06
Nodes (25): AppTheme, cardBorderColor, cardColor, cardDecoration, dark, darkBorder, darkCard, darkCardBorderColor (+17 more)

### Community 49 - "app_avatar.dart"
Cohesion: 0.25
Nodes (6): AppAvatar, build, fontSize, name, photoUrl, radius

### Community 50 - "auth_utils.dart"
Cohesion: 0.29
Nodes (5): buildEmployeeEmail, bytes, cleanAdmin, cleanUser, hash

### Community 51 - "StatelessWidget"
Cohesion: 0.13
Nodes (14): _SplashScreen, _UpdateCheckErrorScreen, _AuthLoadingScreen, _FeatureChip, _AdminBottomTabItem, _AvatarMini, _ChartLegend, _ModernKpiCard (+6 more)

### Community 53 - "notifications_repository.dart"
Cohesion: 0.15
Nodes (11): _col, _db, delete, markAllAsRead, markAsRead, NotificationsRepository, ref, sendNotification (+3 more)

### Community 54 - "utils.cpp"
Cohesion: 0.19
Nodes (4): wWinMain(), CreateAndAttachConsole(), GetCommandLineArguments(), Utf8FromUtf16()

### Community 55 - "../../core/models/models.dart"
Cohesion: 0.17
Nodes (6): _authRepo, init, _messaging, NotificationService, syncUserToken, _tokenRefreshSub

### Community 58 - "cashboxStreamProvider"
Cohesion: 0.13
Nodes (20): expensesRepositoryProvider, recurringExpensesStreamProvider, build, _deleteExpense, ExpenseFormSheet, _ExpenseFormSheetState, ExpensesScreen, _ExpensesScreenState (+12 more)

### Community 59 - "NotificationsSheet"
Cohesion: 0.67
Nodes (4): notificationsRepositoryProvider, notificationsStreamProvider, build, NotificationsSheet

### Community 60 - "ConsumerWidget"
Cohesion: 0.29
Nodes (6): _PaidSubscriptionsTab, _SubscriberDebtsTab, SubscriberDetailsDialog, _PackagesTab, _SupplierBalanceTransactionsTab, SupplierDetailsScreen

### Community 61 - "formatters.dart"
Cohesion: 0.17
Nodes (9): addDays, calendarDaysBetween, CurrencyFormatter, date, DateFormatter, dateTime, format, monthLabel (+1 more)

### Community 62 - "profile_repository.dart"
Cohesion: 0.14
Nodes (11): StateError, dart:io, _auth, _db, _imageContentType, ProfileRepository, removeAvatar, _storage (+3 more)

### Community 64 - "_AdminBottomTabBar"
Cohesion: 0.40
Nodes (4): _AdminBottomTabBar, _AdminBottomTabBarState, _EmployeeAccountStatementSheet, _EmployeeAccountStatementSheetState

### Community 76 - "advance_subscription_sheet.dart"
Cohesion: 0.12
Nodes (15): AdvanceSubscriptionSheet, _AdvanceSubscriptionSheetState, _amountController, build, _busy, createState, _cycles, dispose (+7 more)

### Community 80 - "_InboxScreenState"
Cohesion: 0.27
Nodes (10): employeesStreamProvider, cashboxLedgerStreamProvider, build, CashboxScreen, _CashboxScreenState, chatThreadsStreamProvider, chatThreadStreamProvider, _buildChatsTab (+2 more)

## Knowledge Gaps
- **1190 isolated node(s):** `eslint:recommended`, `plugin:@typescript-eslint/recommended`, `@typescript-eslint/eslint-plugin`, `@typescript-eslint/parser`, `eslint` (+1185 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 1397 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **13 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Win32Window` connect `win32_window.cpp` to `flutter_window.h`?**
  _High betweenness centrality (0.034) - this node is a cross-community bridge._
- **What connects `eslint:recommended`, `plugin:@typescript-eslint/recommended`, `@typescript-eslint/eslint-plugin` to the rest of the system?**
  _1190 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `cashbox_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.02666666666666667 - nodes in this community are weakly interconnected._
- **Why does `AppCurrency` connect `preferences_providers.dart` to `cashbox_screen.dart`, `expenses_screen.dart`, `constants.dart`, `subscribers_screen.dart`, `suppliers_screen.dart`, `inbox_screen.dart`, `reports_screen.dart`, `models.dart`, `../../core/constants.dart`, `pdf_report_service.dart`?**
  _High betweenness centrality (0.029) - this node is a cross-community bridge._
- **Should `my_application.cc` be split into smaller, more focused modules?**
  _Cohesion score 0.05426356589147287 - nodes in this community are weakly interconnected._
- **Why does `AppUser` connect `employees_screen.dart` to `cashbox_screen.dart`, `expenses_screen.dart`, `admin_shell.dart`, `subscribers_screen.dart`, `suppliers_screen.dart`, `models.dart`?**
  _High betweenness centrality (0.015) - this node is a cross-community bridge._
- **Should `expenses_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.029411764705882353 - nodes in this community are weakly interconnected._