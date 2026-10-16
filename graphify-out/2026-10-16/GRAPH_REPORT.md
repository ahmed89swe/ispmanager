# Graph Report - isp_user_manager  (2026-10-16)

## Corpus Check
- 96 files · ~75,445 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 58 file(s) not represented in the graph (top: (none) 9, .xcconfig 8, .xml 7)

## Summary
- 1781 nodes · 2536 edges · 84 communities (70 shown, 14 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 17 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `ea5b86c4`
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
- currentAppUserProvider
- models.dart
- chat_conversation_screen.dart
- pdf_report_test.dart
- firebase_service.dart
- login_screen.dart
- compilerOptions
- notifications_sheet.dart
- employees_screen.dart
- .eslintrc.json
- win32_window.cpp
- expenses_repository.dart
- Cloud Functions
- chat_repository.dart
- cashbox_repository.dart
- cashboxRepositoryProvider
- update_screen.dart
- manifest.json
- pdf_report_service.dart
- formatters.dart
- auth_repository.dart
- profile_screen.dart
- app_localizations.dart
- constants.dart
- record_payment_sheet.dart
- history_screen.dart
- Win32Window
- FlutterWindow
- GeneratedPluginRegistrant.swift
- app_update_repository.dart
- suppliers_repository.dart
- ConsumerState
- history_repository.dart
- subscribersRepositoryProvider
- employees_repository.dart
- preferences_providers.dart
- cashbox_service.dart
- auth_utils.dart
- app_theme.dart
- StatelessWidget
- package:flutter/material.dart
- notifications_repository.dart
- utils.cpp
- ../../core/models/models.dart
- MainActivity.kt
- employeesStreamProvider
- .MessageHandler
- ConsumerWidget
- package:flutter_riverpod/flutter_riverpod.dart
- profile_repository.dart
- expensesRepositoryProvider
- _AdminBottomTabBar
- MaterialPageRoute
- AppLocalizations
- isp_user_manager
- LaunchImage.imageset/README.md
- authRepositoryProvider
- Point
- advance_subscription_sheet.dart
- main.dart
- payments_repository.dart
- firebase_options.dart
- _InboxScreenState
- _ChatConversationScreenState
- Map
- _RefreshOnChange

## God Nodes (most connected - your core abstractions)
1. `currentAppUserProvider` - 41 edges
2. `Win32Window` - 21 edges
3. `subscribersRepositoryProvider` - 16 edges
4. `compilerOptions` - 13 edges
5. `currencyProvider` - 13 edges
6. `_InboxScreenState` - 12 edges
7. `AppCurrency` - 11 edges
8. `_DashboardScreenState` - 11 edges
9. `employeesStreamProvider` - 11 edges
10. `cashboxStreamProvider` - 11 edges

## Surprising Connections (you probably didn't know these)
- `_submit` --references--> `currentAppUserProvider`  [EXTRACTED]
  lib/features/payments/advance_subscription_sheet.dart → lib/features/auth/auth_repository.dart
- `build` --references--> `currentAppUserProvider`  [EXTRACTED]
  lib/features/profile/profile_screen.dart → lib/features/auth/auth_repository.dart
- `_pickAvatar` --references--> `currentAppUserProvider`  [EXTRACTED]
  lib/features/profile/profile_screen.dart → lib/features/auth/auth_repository.dart
- `_saveName` --references--> `currentAppUserProvider`  [EXTRACTED]
  lib/features/profile/profile_screen.dart → lib/features/auth/auth_repository.dart
- `wWinMain()` --calls--> `CreateAndAttachConsole()`  [INFERRED]
  windows/runner/main.cpp → windows/runner/utils.cpp

## Import Cycles
- None detected.

## Communities (84 total, 14 thin omitted)

### Community 0 - "cashbox_screen.dart"
Cohesion: 0.03
Nodes (71): Card, Center, Column, Container, DefaultTabController, Divider, DraggableScrollableSheet, Icon (+63 more)

### Community 1 - "my_application.cc"
Cohesion: 0.05
Nodes (14): fl_register_plugins(), main(), my_application_activate(), my_application_class_init(), my_application_dispose(), my_application_init(), my_application_local_command_line(), my_application_new() (+6 more)

### Community 2 - "expenses_screen.dart"
Cohesion: 0.05
Nodes (41): _actorLabel, Center, Color, Column, Container, Divider, Expanded, Icon (+33 more)

### Community 3 - "app.dart"
Cohesion: 0.10
Nodes (19): CircularProgressIndicator, Icon, MaterialApp, Scaffold, SizedBox, UpdateScreen, ListView, build (+11 more)

### Community 4 - "subscribers_repository.dart"
Cohesion: 0.06
Nodes (31): add, addDebt, addWithInitialSubscription, authUser, cancelAdvancePayment, _col, _dateFromFirestore, _db (+23 more)

### Community 5 - "admin_shell.dart"
Cohesion: 0.04
Nodes (36): CircleAvatar, FadeTransition, Function, IconButton, Material, Scaffold, SizedBox, TextStyle (+28 more)

### Community 6 - "subscribers_screen.dart"
Cohesion: 0.03
Nodes (64): Color, Column, Container, Dialog, Divider, Icon, InkWell, launchUrl (+56 more)

### Community 7 - "dashboard_screen.dart"
Cohesion: 0.05
Nodes (32): Card, CashboxScreen, Center, Container, Icon, _Kpi, _kpiGrid, _Legend (+24 more)

### Community 8 - "suppliers_screen.dart"
Cohesion: 0.05
Nodes (38): Center, Container, DefaultTabController, Expanded, launchUrl, ListTile, Padding, SafeArea (+30 more)

### Community 9 - "inbox_screen.dart"
Cohesion: 0.04
Nodes (41): Card, Center, _colorFor, Column, Divider, Expanded, _expenseDeleteRequestTile, Icon (+33 more)

### Community 10 - "reports_screen.dart"
Cohesion: 0.04
Nodes (40): actionsRow, Card, Column, fmt, ListView, Padding, PdfReportService, SizedBox (+32 more)

### Community 11 - "package.json"
Cohesion: 0.06
Nodes (34): dependencies, firebase-admin, firebase-functions, devDependencies, eslint, typescript, @typescript-eslint/eslint-plugin, @typescript-eslint/parser (+26 more)

### Community 12 - "currentAppUserProvider"
Cohesion: 0.19
Nodes (20): currentAppUserProvider, build, build, DashboardScreen, _DashboardScreenState, expensesStreamProvider, build, cashboxStreamProvider (+12 more)

### Community 13 - "models.dart"
Cohesion: 0.02
Nodes (119): action, active, actorName, actorPhotoUrl, actorRole, actorUid, adminUid, after (+111 more)

### Community 14 - "chat_conversation_screen.dart"
Cohesion: 0.07
Nodes (24): Align, Center, Container, Padding, SafeArea, Scaffold, SizedBox, Text (+16 more)

### Community 15 - "pdf_report_test.dart"
Cohesion: 0.12
Nodes (7): initializeDateFormatting, main, main, main, main, main, main

### Community 16 - "firebase_service.dart"
Cohesion: 0.17
Nodes (8): firebaseAuthProvider, firebaseMessagingProvider, FirebaseService, firebaseStorageProvider, firestoreProvider, init, initialized, isAvailable

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
Nodes (25): Center, ListTile, Padding, Scaffold, SizedBox, SnackBar, AppUser, Employee (+17 more)

### Community 21 - ".eslintrc.json"
Cohesion: 0.12
Nodes (16): env, es2020, node, extends, ignorePatterns, parser, parserOptions, ecmaVersion (+8 more)

### Community 22 - "win32_window.cpp"
Cohesion: 0.18
Nodes (5): Scale(), Win32Window::Win32Window(), WindowClassRegistrar, class_registered_, instance_

### Community 23 - "expenses_repository.dart"
Cohesion: 0.11
Nodes (17): StateError, add, authUser, _col, createDeleteRequest, _db, decideDeleteRequest, delete (+9 more)

### Community 24 - "Cloud Functions"
Cohesion: 0.22
Nodes (8): Cloud Functions, `createEmployee` (callable), Deploy, Functions, Local emulator, `onSupplierPaymentRequestCreate` (Firestore trigger), `onSupplierPaymentRequestUpdated` (Firestore trigger), Setup

### Community 25 - "chat_repository.dart"
Cohesion: 0.11
Nodes (17): StateError, _chatDoc, ChatRepository, _db, _imageContentType, markMessagesAsRead, _messagesCol, _notificationsRepo (+9 more)

### Community 26 - "cashbox_repository.dart"
Cohesion: 0.06
Nodes (31): Exception, extractBalance, authUser, balanceFor, balances, cashboxDebtToStaff, cashboxDebtToStaffFor, cashboxDebtToStaffForUid (+23 more)

### Community 27 - "cashboxRepositoryProvider"
Cohesion: 0.25
Nodes (8): cashboxRepositoryProvider, _ClaimReimbursementRequestSheet, _ClaimReimbursementRequestSheetState, _DirectAdjustmentSheet, _DirectAdjustmentSheetState, _SettleStaffDebtSheet, _SettleStaffDebtSheetState, _submit

### Community 28 - "update_screen.dart"
Cohesion: 0.12
Nodes (13): launchUrl, Padding, PopScope, SizedBox, Spacer, AppUpdateInfo, _Body, build (+5 more)

### Community 29 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 30 - "pdf_report_service.dart"
Cohesion: 0.04
Nodes (40): _bold, _buildCustomFooter, _buildCustomHeader, _buildEmptyBox, _buildFooter, _buildHeader, _buildInfoItem, _buildKpiCard (+32 more)

### Community 31 - "formatters.dart"
Cohesion: 0.17
Nodes (9): addDays, calendarDaysBetween, CurrencyFormatter, date, DateFormatter, dateTime, format, monthLabel (+1 more)

### Community 32 - "auth_repository.dart"
Cohesion: 0.11
Nodes (17): AppUser, GoogleSignIn, StateError, addFcmToken, _auth, authStateChanges, currentAppUser, currentAppUserStream (+9 more)

### Community 33 - "profile_screen.dart"
Cohesion: 0.12
Nodes (16): ListView, Scaffold, SizedBox, dart:io, profileRepositoryProvider, build, _busy, createState (+8 more)

### Community 34 - "app_localizations.dart"
Cohesion: 0.01
Nodes (131): addExpense, addNew, addSubscriber, admin, adminEmail, all, amount, approve (+123 more)

### Community 35 - "constants.dart"
Cohesion: 0.10
Nodes (18): all, code, ExpenseCategory, ExpenseEntryType, fromCode, fromName, manageSupplierPurchases, PaymentRequestStatus (+10 more)

### Community 36 - "record_payment_sheet.dart"
Cohesion: 0.12
Nodes (14): Padding, SizedBox, MoneyStorage, Subscriber, _amount, build, _busy, createState (+6 more)

### Community 37 - "history_screen.dart"
Cohesion: 0.12
Nodes (16): Column, ListTile, historyRepositoryProvider, historyStreamProvider, build, _busyEventIds, createState, _errorMessage (+8 more)

### Community 38 - "Win32Window"
Cohesion: 0.24
Nodes (4): Win32Window, child_content_, quit_on_close_, window_handle_

### Community 39 - "FlutterWindow"
Cohesion: 0.11
Nodes (4): FlutterWindow, flutter_controller_, FlutterWindow::FlutterWindow(), project_

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
Cohesion: 0.17
Nodes (16): PermissionsSheet, _PermissionsSheetState, suppliersRepositoryProvider, PackageFormSheet, _PackageFormSheetState, _save, SupplierBalanceTransactionSheet, _SupplierBalanceTransactionSheetState (+8 more)

### Community 44 - "history_repository.dart"
Cohesion: 0.09
Nodes (19): StateError, now, null, tsToDate, authUser, _db, eventData, _expenseIdFromDeleteRequestEvent (+11 more)

### Community 45 - "subscribersRepositoryProvider"
Cohesion: 0.14
Nodes (14): _syncDueDebts, subscribersRepositoryProvider, AddSubscriberDebtSheet, _AddSubscriberDebtSheetState, _confirmAndDeleteDebt, _confirmAndPayDebt, _exportStatement, _exportSubscriberStatement (+6 more)

### Community 46 - "employees_repository.dart"
Cohesion: 0.12
Nodes (13): authUser, _col, create, _db, delete, EmployeesRepository, _logger, _notificationsRepo (+5 more)

### Community 47 - "preferences_providers.dart"
Cohesion: 0.10
Nodes (16): Locale, UnimplementedError, AppCurrency, AppPreferences, appPreferencesProvider, CurrencyNotifier, _kCurrency, _kLocale (+8 more)

### Community 48 - "cashbox_service.dart"
Cohesion: 0.13
Nodes (13): cashboxDocId, cashboxRef, CashboxService, debtKey, ensureExists, initialData, ledgerCol, registerDirectAdjustment (+5 more)

### Community 49 - "auth_utils.dart"
Cohesion: 0.25
Nodes (5): buildEmployeeEmail, bytes, cleanAdmin, cleanUser, hash

### Community 50 - "app_theme.dart"
Cohesion: 0.22
Nodes (5): AppTheme, dark, light, _scheme, _subThemesData

### Community 51 - "StatelessWidget"
Cohesion: 0.14
Nodes (13): _SplashScreen, _UpdateCheckErrorScreen, _AuthLoadingScreen, _FeatureChip, _AdminBottomTabItem, _AvatarMini, _ChartLegend, _ModernKpiCard (+5 more)

### Community 53 - "notifications_repository.dart"
Cohesion: 0.15
Nodes (16): _col, _db, delete, markAllAsRead, markAsRead, NotificationsRepository, notificationsRepositoryProvider, notificationsStreamProvider (+8 more)

### Community 54 - "utils.cpp"
Cohesion: 0.19
Nodes (4): wWinMain(), CreateAndAttachConsole(), GetCommandLineArguments(), Utf8FromUtf16()

### Community 55 - "../../core/models/models.dart"
Cohesion: 0.17
Nodes (6): _authRepo, init, _messaging, NotificationService, syncUserToken, _tokenRefreshSub

### Community 58 - "employeesStreamProvider"
Cohesion: 0.33
Nodes (7): employeesStreamProvider, build, cashboxLedgerStreamProvider, build, _buildAdminStaffDebtsTab, CashboxScreen, _CashboxScreenState

### Community 60 - "ConsumerWidget"
Cohesion: 0.33
Nodes (5): _PaidSubscriptionsTab, _SubscriberDebtsTab, SubscriberDetailsDialog, _PackagesTab, SupplierDetailsScreen

### Community 61 - "package:flutter_riverpod/flutter_riverpod.dart"
Cohesion: 0.20
Nodes (3): GoRouter, Scaffold, build

### Community 62 - "profile_repository.dart"
Cohesion: 0.14
Nodes (10): StateError, _auth, _db, _imageContentType, ProfileRepository, removeAvatar, _storage, updateDisplayName (+2 more)

### Community 63 - "expensesRepositoryProvider"
Cohesion: 0.29
Nodes (7): expensesRepositoryProvider, _deleteExpense, ExpenseFormSheet, _ExpenseFormSheetState, ExpensesScreen, _ExpensesScreenState, _save

### Community 64 - "_AdminBottomTabBar"
Cohesion: 0.40
Nodes (4): _AdminBottomTabBar, _AdminBottomTabBarState, _EmployeeAccountStatementSheet, _EmployeeAccountStatementSheetState

### Community 65 - "MaterialPageRoute"
Cohesion: 0.33
Nodes (5): _buildEmployeeDashboardCard, _buildGeneralCashboxSummaryCard, _buildHeroLiquidityCard, _buildQuickActions, _openImagePreview

### Community 70 - "authRepositoryProvider"
Cohesion: 0.27
Nodes (7): authRepositoryProvider, _employeeSignIn, _googleSignIn, AdminShell, _AdminShellState, _buildDesktopShell, _buildMobileShell

### Community 71 - "Point"
Cohesion: 0.21
Nodes (6): Point, x, y, Size, height, width

### Community 76 - "advance_subscription_sheet.dart"
Cohesion: 0.12
Nodes (15): AdvanceSubscriptionSheet, _AdvanceSubscriptionSheetState, _amountController, build, _busy, createState, _cycles, dispose (+7 more)

### Community 77 - "main.dart"
Cohesion: 0.15
Nodes (5): _firebaseMessagingBackgroundHandler, init, main, prefs, setPreferredOrientations

### Community 78 - "payments_repository.dart"
Cohesion: 0.17
Nodes (8): HistoryLogger, _db, _logger, _notificationsRepo, PaymentsRepository, record, watchAll, watchForSubscriber

### Community 79 - "firebase_options.dart"
Cohesion: 0.20
Nodes (6): UnsupportedError, android, DefaultFirebaseOptions, ios, web, windows

### Community 80 - "_InboxScreenState"
Cohesion: 0.29
Nodes (7): reimbursementRequestsStreamProvider, chatThreadsStreamProvider, chatThreadStreamProvider, _buildChatsTab, _buildRequestsTab, InboxScreen, _InboxScreenState

### Community 81 - "_ChatConversationScreenState"
Cohesion: 0.29
Nodes (7): build, ChatConversationScreen, _ChatConversationScreenState, _markRead, _sendMessage, chatMessagesStreamProvider, chatRepositoryProvider

## Knowledge Gaps
- **1114 isolated node(s):** `eslint:recommended`, `plugin:@typescript-eslint/recommended`, `@typescript-eslint/eslint-plugin`, `@typescript-eslint/parser`, `eslint` (+1109 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 1320 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **14 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `AppCurrency` connect `preferences_providers.dart` to `cashbox_screen.dart`, `expenses_screen.dart`, `constants.dart`, `app.dart`, `subscribers_screen.dart`, `suppliers_screen.dart`, `inbox_screen.dart`, `reports_screen.dart`, `models.dart`, `pdf_report_service.dart`?**
  _High betweenness centrality (0.035) - this node is a cross-community bridge._
- **What connects `eslint:recommended`, `plugin:@typescript-eslint/recommended`, `@typescript-eslint/eslint-plugin` to the rest of the system?**
  _1114 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `cashbox_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.02702702702702703 - nodes in this community are weakly interconnected._
- **Why does `Win32Window` connect `Win32Window` to `Point`, `FlutterWindow`, `win32_window.cpp`, `flutter_window.h`, `.MessageHandler`?**
  _High betweenness centrality (0.028) - this node is a cross-community bridge._
- **Should `my_application.cc` be split into smaller, more focused modules?**
  _Cohesion score 0.05426356589147287 - nodes in this community are weakly interconnected._
- **Why does `AppUser` connect `employees_screen.dart` to `cashbox_screen.dart`, `expenses_screen.dart`, `admin_shell.dart`, `subscribers_screen.dart`, `suppliers_screen.dart`, `models.dart`?**
  _High betweenness centrality (0.018) - this node is a cross-community bridge._
- **Should `expenses_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.046511627906976744 - nodes in this community are weakly interconnected._