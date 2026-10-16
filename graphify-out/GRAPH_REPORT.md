# Graph Report - isp_user_manager  (2026-10-16)

## Corpus Check
- 94 files · ~73,543 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 58 file(s) not represented in the graph (top: (none) 9, .xcconfig 8, .xml 7)

## Summary
- 1757 nodes · 2494 edges · 79 communities (67 shown, 12 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 17 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `907fc75b`
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
- currentAppUserProvider
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
- ../auth/auth_repository.dart
- utils.cpp
- ../../core/models/models.dart
- MainActivity.kt
- _InboxScreenState
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
- Size
- main.dart
- cashboxStreamProvider

## God Nodes (most connected - your core abstractions)
1. `currentAppUserProvider` - 39 edges
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
- `_save` --references--> `currentAppUserProvider`  [EXTRACTED]
  lib/features/payments/record_payment_sheet.dart → lib/features/auth/auth_repository.dart
- `wWinMain()` --calls--> `CreateAndAttachConsole()`  [INFERRED]
  windows/runner/main.cpp → windows/runner/utils.cpp
- `_MainAppRouter` --references--> `currentAppUserProvider`  [EXTRACTED]
  lib/app/app.dart → lib/features/auth/auth_repository.dart
- `build` --references--> `currentAppUserProvider`  [EXTRACTED]
  lib/app/app.dart → lib/features/auth/auth_repository.dart
- `_LoginScreenState` --references--> `authRepositoryProvider`  [EXTRACTED]
  lib/features/auth/login_screen.dart → lib/features/auth/auth_repository.dart

## Import Cycles
- None detected.

## Communities (79 total, 12 thin omitted)

### Community 0 - "cashbox_screen.dart"
Cohesion: 0.03
Nodes (71): Card, Center, Column, Container, DefaultTabController, Divider, DraggableScrollableSheet, Icon (+63 more)

### Community 1 - "my_application.cc"
Cohesion: 0.06
Nodes (13): fl_register_plugins(), main(), my_application_activate(), my_application_class_init(), my_application_dispose(), my_application_init(), my_application_local_command_line(), my_application_new() (+5 more)

### Community 2 - "expenses_screen.dart"
Cohesion: 0.05
Nodes (41): _actorLabel, Center, Color, Column, Container, Divider, Expanded, Icon (+33 more)

### Community 3 - "app.dart"
Cohesion: 0.11
Nodes (18): CircularProgressIndicator, Icon, MaterialApp, Scaffold, SizedBox, UpdateScreen, build, IspUserManagerApp (+10 more)

### Community 4 - "subscribers_repository.dart"
Cohesion: 0.07
Nodes (29): add, addDebt, addWithInitialSubscription, authUser, _col, _dateFromFirestore, _db, _debtCol (+21 more)

### Community 5 - "admin_shell.dart"
Cohesion: 0.04
Nodes (36): CircleAvatar, FadeTransition, Function, IconButton, Material, Scaffold, SizedBox, TextStyle (+28 more)

### Community 6 - "subscribers_screen.dart"
Cohesion: 0.03
Nodes (63): Color, Column, Container, Dialog, Divider, Icon, InkWell, launchUrl (+55 more)

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

### Community 12 - "currencyProvider"
Cohesion: 0.23
Nodes (16): build, DashboardScreen, _DashboardScreenState, expensesStreamProvider, ExpenseFormSheet, _ExpenseFormSheetState, paymentsRepositoryProvider, build (+8 more)

### Community 13 - "models.dart"
Cohesion: 0.02
Nodes (118): action, active, actorName, actorPhotoUrl, actorRole, actorUid, adminUid, after (+110 more)

### Community 14 - "chat_conversation_screen.dart"
Cohesion: 0.06
Nodes (31): Align, Center, Container, Padding, SafeArea, Scaffold, SizedBox, Text (+23 more)

### Community 15 - "pdf_report_test.dart"
Cohesion: 0.12
Nodes (6): initializeDateFormatting, main, main, main, main, main

### Community 16 - "firebase_service.dart"
Cohesion: 0.10
Nodes (14): UnsupportedError, firebaseAuthProvider, firebaseMessagingProvider, FirebaseService, firebaseStorageProvider, firestoreProvider, init, initialized (+6 more)

### Community 17 - "login_screen.dart"
Cohesion: 0.09
Nodes (19): DefaultTabController, Icon, SizedBox, firebaseAvailableProvider, _adminEmail, _adminTab, build, _busy (+11 more)

### Community 18 - "compilerOptions"
Cohesion: 0.12
Nodes (15): compilerOptions, esModuleInterop, lib, module, moduleResolution, noImplicitAny, noImplicitReturns, outDir (+7 more)

### Community 19 - "notifications_sheet.dart"
Cohesion: 0.11
Nodes (18): Center, Column, Dismissible, Divider, DraggableScrollableSheet, Icon, showModalBottomSheet, SizedBox (+10 more)

### Community 20 - "employees_screen.dart"
Cohesion: 0.08
Nodes (26): Center, ListTile, Padding, Scaffold, SizedBox, SnackBar, AppUser, Employee (+18 more)

### Community 21 - ".eslintrc.json"
Cohesion: 0.12
Nodes (16): env, es2020, node, extends, ignorePatterns, parser, parserOptions, ecmaVersion (+8 more)

### Community 22 - "win32_window.cpp"
Cohesion: 0.18
Nodes (5): Scale(), Win32Window::Win32Window(), WindowClassRegistrar, class_registered_, instance_

### Community 23 - "expenses_repository.dart"
Cohesion: 0.07
Nodes (25): StateError, add, authUser, _col, createDeleteRequest, _db, decideDeleteRequest, delete (+17 more)

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
Cohesion: 0.20
Nodes (10): cashboxRepositoryProvider, reimbursementRequestsStreamProvider, _ClaimReimbursementRequestSheet, _ClaimReimbursementRequestSheetState, _DirectAdjustmentSheet, _DirectAdjustmentSheetState, _SettleStaffDebtSheet, _SettleStaffDebtSheetState (+2 more)

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

### Community 33 - "currentAppUserProvider"
Cohesion: 0.11
Nodes (20): ListView, Scaffold, SizedBox, _RefreshOnChange, authStateProvider, currentAppUserProvider, build, build (+12 more)

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

### Community 38 - "Win32Window"
Cohesion: 0.19
Nodes (5): RegisterPlugins(), Win32Window, child_content_, quit_on_close_, window_handle_

### Community 39 - "FlutterWindow"
Cohesion: 0.11
Nodes (4): FlutterWindow, flutter_controller_, FlutterWindow::FlutterWindow(), project_

### Community 40 - "GeneratedPluginRegistrant.swift"
Cohesion: 0.05
Nodes (28): cloud_firestore, Cocoa, connectivity_plus, file_selector_macos, firebase_analytics, firebase_auth, firebase_core, firebase_crashlytics (+20 more)

### Community 41 - "app_update_repository.dart"
Cohesion: 0.11
Nodes (14): StateError, AppUpdateRepository, appUpdateRepositoryProvider, check, currentVersion, debugMessage, downloadUrl, _firestore (+6 more)

### Community 42 - "suppliers_repository.dart"
Cohesion: 0.06
Nodes (30): StateError, add, addBalanceTransaction, addPackage, addPurchase, applyPaymentToPurchase, authUser, _balanceCol (+22 more)

### Community 43 - "ConsumerState"
Cohesion: 0.21
Nodes (11): PermissionsSheet, _PermissionsSheetState, InboxScreen, PackageFormSheet, _PackageFormSheetState, SupplierFormSheet, _SupplierFormSheetState, SupplierPaymentRequestSheet (+3 more)

### Community 44 - "history_repository.dart"
Cohesion: 0.09
Nodes (19): StateError, now, null, tsToDate, authUser, _db, eventData, _expenseIdFromDeleteRequestEvent (+11 more)

### Community 45 - "subscribersRepositoryProvider"
Cohesion: 0.14
Nodes (14): _syncDueDebts, subscribersRepositoryProvider, AddSubscriberDebtSheet, _AddSubscriberDebtSheetState, _confirmAndDeleteDebt, _confirmAndPayDebt, _exportStatement, _exportSubscriberStatement (+6 more)

### Community 46 - "employees_repository.dart"
Cohesion: 0.13
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

### Community 53 - "../auth/auth_repository.dart"
Cohesion: 0.15
Nodes (11): _col, _db, delete, markAllAsRead, markAsRead, NotificationsRepository, ref, sendNotification (+3 more)

### Community 54 - "utils.cpp"
Cohesion: 0.19
Nodes (4): wWinMain(), CreateAndAttachConsole(), GetCommandLineArguments(), Utf8FromUtf16()

### Community 55 - "../../core/models/models.dart"
Cohesion: 0.17
Nodes (6): _authRepo, init, _messaging, NotificationService, syncUserToken, _tokenRefreshSub

### Community 58 - "_InboxScreenState"
Cohesion: 0.24
Nodes (10): employeesStreamProvider, cashboxLedgerStreamProvider, build, _buildAdminStaffDebtsTab, CashboxScreen, _CashboxScreenState, chatThreadsStreamProvider, chatThreadStreamProvider (+2 more)

### Community 60 - "ConsumerWidget"
Cohesion: 0.33
Nodes (5): _PaidSubscriptionsTab, _SubscriberDebtsTab, SubscriberDetailsDialog, _PackagesTab, SupplierDetailsScreen

### Community 61 - "package:flutter_riverpod/flutter_riverpod.dart"
Cohesion: 0.22
Nodes (3): GoRouter, Scaffold, build

### Community 62 - "profile_repository.dart"
Cohesion: 0.13
Nodes (11): StateError, dart:io, _auth, _db, _imageContentType, ProfileRepository, removeAvatar, _storage (+3 more)

### Community 63 - "expensesRepositoryProvider"
Cohesion: 0.40
Nodes (5): expensesRepositoryProvider, _deleteExpense, ExpensesScreen, _ExpensesScreenState, _save

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
Cohesion: 0.50
Nodes (3): Point, x, y

### Community 76 - "Size"
Cohesion: 0.50
Nodes (3): Size, height, width

### Community 77 - "main.dart"
Cohesion: 0.17
Nodes (5): _firebaseMessagingBackgroundHandler, init, main, prefs, setPreferredOrientations

### Community 78 - "cashboxStreamProvider"
Cohesion: 0.32
Nodes (8): build, cashboxStreamProvider, suppliersRepositoryProvider, build, _save, SupplierBalanceTransactionSheet, _SupplierBalanceTransactionSheetState, _SupplierBalanceTransactionsTab

## Knowledge Gaps
- **1097 isolated node(s):** `eslint:recommended`, `plugin:@typescript-eslint/recommended`, `@typescript-eslint/eslint-plugin`, `@typescript-eslint/parser`, `eslint` (+1092 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 1302 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **12 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Win32Window` connect `Win32Window` to `Point`, `FlutterWindow`, `Size`, `win32_window.cpp`, `flutter_window.h`, `.MessageHandler`?**
  _High betweenness centrality (0.050) - this node is a cross-community bridge._
- **What connects `eslint:recommended`, `plugin:@typescript-eslint/recommended`, `@typescript-eslint/eslint-plugin` to the rest of the system?**
  _1097 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `cashbox_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.02702702702702703 - nodes in this community are weakly interconnected._
- **Why does `AppCurrency` connect `preferences_providers.dart` to `cashbox_screen.dart`, `expenses_screen.dart`, `constants.dart`, `subscribers_screen.dart`, `suppliers_screen.dart`, `inbox_screen.dart`, `reports_screen.dart`, `models.dart`, `package:flutter/material.dart`, `pdf_report_service.dart`?**
  _High betweenness centrality (0.039) - this node is a cross-community bridge._
- **Should `my_application.cc` be split into smaller, more focused modules?**
  _Cohesion score 0.05731707317073171 - nodes in this community are weakly interconnected._
- **Why does `Size` connect `Size` to `Win32Window`, `win32_window.cpp`?**
  _High betweenness centrality (0.020) - this node is a cross-community bridge._
- **Should `expenses_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.046511627906976744 - nodes in this community are weakly interconnected._