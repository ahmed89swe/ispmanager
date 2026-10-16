# Graph Report - isp_user_manager  (2026-10-16)

## Corpus Check
- 94 files · ~72,393 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 58 file(s) not represented in the graph (top: (none) 9, .xcconfig 8, .xml 7)

## Summary
- 1752 nodes · 2484 edges · 74 communities (61 shown, 13 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 17 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `9232ff9b`
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
- profile_repository.dart
- expenses_repository.dart
- Cloud Functions
- chat_repository.dart
- cashbox_repository.dart
- ConsumerState
- update_screen.dart
- manifest.json
- pdf_report_service.dart
- formatters.dart
- auth_repository.dart
- package:flutter/material.dart
- app_localizations.dart
- constants.dart
- record_payment_sheet.dart
- history_repository.dart
- NotificationsSheet
- FlutterWindow
- GeneratedPluginRegistrant.swift
- app_update_repository.dart
- suppliers_repository.dart
- AddSubscriberDebtSheet
- win32_window.cpp
- subscribersRepositoryProvider
- employees_repository.dart
- _SubscriberFormSheetState
- cashbox_service.dart
- auth_utils.dart
- currentAppUserProvider
- StatelessWidget
- suppliersRepositoryProvider
- notifications_repository.dart
- utils.cpp
- ../../core/models/models.dart
- MainActivity.kt
- Win32Window
- .MessageHandler
- package:flutter_riverpod/flutter_riverpod.dart
- Point
- expensesRepositoryProvider
- _AdminBottomTabBar
- MaterialPageRoute
- AppLocalizations
- isp_user_manager
- LaunchImage.imageset/README.md
- authRepositoryProvider

## God Nodes (most connected - your core abstractions)
1. `currentAppUserProvider` - 39 edges
2. `Win32Window` - 21 edges
3. `subscribersRepositoryProvider` - 14 edges
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

## Communities (74 total, 13 thin omitted)

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
Cohesion: 0.05
Nodes (35): CircularProgressIndicator, Icon, MaterialApp, Scaffold, SizedBox, UpdateScreen, ListView, Locale (+27 more)

### Community 4 - "subscribers_repository.dart"
Cohesion: 0.07
Nodes (27): add, addDebt, addWithInitialSubscription, authUser, _col, _dateFromFirestore, _db, _debtCol (+19 more)

### Community 5 - "admin_shell.dart"
Cohesion: 0.04
Nodes (36): CircleAvatar, FadeTransition, Function, IconButton, Material, Scaffold, SizedBox, TextStyle (+28 more)

### Community 6 - "subscribers_screen.dart"
Cohesion: 0.03
Nodes (60): Color, Column, Container, Dialog, Divider, Icon, InkWell, launchUrl (+52 more)

### Community 7 - "dashboard_screen.dart"
Cohesion: 0.05
Nodes (32): Card, CashboxScreen, Center, Container, Icon, _Kpi, _kpiGrid, _Legend (+24 more)

### Community 8 - "suppliers_screen.dart"
Cohesion: 0.05
Nodes (42): Center, Container, DefaultTabController, Expanded, launchUrl, ListTile, Padding, SafeArea (+34 more)

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
Cohesion: 0.20
Nodes (19): build, DashboardScreen, _DashboardScreenState, expensesStreamProvider, build, cashboxStreamProvider, paymentsRepositoryProvider, build (+11 more)

### Community 13 - "models.dart"
Cohesion: 0.02
Nodes (119): action, active, actorName, actorPhotoUrl, actorRole, actorUid, adminUid, after (+111 more)

### Community 14 - "chat_conversation_screen.dart"
Cohesion: 0.07
Nodes (24): Align, Center, Container, Padding, SafeArea, Scaffold, SizedBox, Text (+16 more)

### Community 15 - "pdf_report_test.dart"
Cohesion: 0.12
Nodes (6): initializeDateFormatting, main, main, main, main, main

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
Cohesion: 0.09
Nodes (25): Center, ListTile, Padding, Scaffold, SizedBox, SnackBar, AppUser, Employee (+17 more)

### Community 21 - ".eslintrc.json"
Cohesion: 0.12
Nodes (16): env, es2020, node, extends, ignorePatterns, parser, parserOptions, ecmaVersion (+8 more)

### Community 22 - "profile_repository.dart"
Cohesion: 0.14
Nodes (10): StateError, _auth, _db, _imageContentType, ProfileRepository, removeAvatar, _storage, updateDisplayName (+2 more)

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

### Community 27 - "ConsumerState"
Cohesion: 0.11
Nodes (24): employeesStreamProvider, PermissionsSheet, _PermissionsSheetState, cashboxLedgerStreamProvider, cashboxRepositoryProvider, reimbursementRequestsStreamProvider, build, _buildAdminStaffDebtsTab (+16 more)

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
Cohesion: 0.10
Nodes (18): AppUser, GoogleSignIn, StateError, addFcmToken, _auth, authStateChanges, authStateProvider, currentAppUser (+10 more)

### Community 33 - "package:flutter/material.dart"
Cohesion: 0.12
Nodes (14): ListView, Scaffold, SizedBox, dart:io, showFullScreenImage, profileRepositoryProvider, _busy, createState (+6 more)

### Community 34 - "app_localizations.dart"
Cohesion: 0.01
Nodes (131): addExpense, addNew, addSubscriber, admin, adminEmail, all, amount, approve (+123 more)

### Community 35 - "constants.dart"
Cohesion: 0.10
Nodes (18): all, code, ExpenseCategory, ExpenseEntryType, fromCode, fromName, manageSupplierPurchases, PaymentRequestStatus (+10 more)

### Community 36 - "record_payment_sheet.dart"
Cohesion: 0.12
Nodes (15): Padding, SizedBox, MoneyStorage, Subscriber, _amount, build, _busy, createState (+7 more)

### Community 37 - "history_repository.dart"
Cohesion: 0.05
Nodes (37): StateError, Column, ListTile, AppTheme, dark, light, _scheme, _subThemesData (+29 more)

### Community 38 - "NotificationsSheet"
Cohesion: 0.60
Nodes (5): notificationsRepositoryProvider, notificationsStreamProvider, unreadNotificationsCountProvider, build, NotificationsSheet

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

### Community 44 - "win32_window.cpp"
Cohesion: 0.18
Nodes (5): Scale(), Win32Window::Win32Window(), WindowClassRegistrar, class_registered_, instance_

### Community 45 - "subscribersRepositoryProvider"
Cohesion: 0.15
Nodes (13): _syncDueDebts, subscribersRepositoryProvider, _confirmAndPayDebt, _exportStatement, _exportSubscriberStatement, _save, _SubscriberDebtsTab, SubscriberDetailsDialog (+5 more)

### Community 46 - "employees_repository.dart"
Cohesion: 0.13
Nodes (13): authUser, _col, create, _db, delete, EmployeesRepository, _logger, _notificationsRepo (+5 more)

### Community 48 - "cashbox_service.dart"
Cohesion: 0.13
Nodes (13): cashboxDocId, cashboxRef, CashboxService, debtKey, ensureExists, initialData, ledgerCol, registerDirectAdjustment (+5 more)

### Community 49 - "auth_utils.dart"
Cohesion: 0.25
Nodes (5): buildEmployeeEmail, bytes, cleanAdmin, cleanUser, hash

### Community 50 - "currentAppUserProvider"
Cohesion: 0.18
Nodes (13): _RefreshOnChange, currentAppUserProvider, build, build, _ChatConversationScreenState, _markRead, _sendMessage, chatMessagesStreamProvider (+5 more)

### Community 51 - "StatelessWidget"
Cohesion: 0.13
Nodes (14): _SplashScreen, _UpdateCheckErrorScreen, _AuthLoadingScreen, _FeatureChip, _AdminBottomTabItem, _AvatarMini, _ChartLegend, _ModernKpiCard (+6 more)

### Community 52 - "suppliersRepositoryProvider"
Cohesion: 0.29
Nodes (7): suppliersRepositoryProvider, _save, _SupplierBalanceTransactionsTab, SupplierFormSheet, _SupplierFormSheetState, SupplierPaymentRequestSheet, _SupplierPaymentRequestSheetState

### Community 53 - "notifications_repository.dart"
Cohesion: 0.11
Nodes (14): now, null, tsToDate, _col, _db, delete, markAllAsRead, markAsRead (+6 more)

### Community 54 - "utils.cpp"
Cohesion: 0.19
Nodes (4): wWinMain(), CreateAndAttachConsole(), GetCommandLineArguments(), Utf8FromUtf16()

### Community 55 - "../../core/models/models.dart"
Cohesion: 0.15
Nodes (7): _authRepo, init, _messaging, NotificationService, syncUserToken, _tokenRefreshSub, AuthRepository

### Community 58 - "Win32Window"
Cohesion: 0.24
Nodes (4): Win32Window, child_content_, quit_on_close_, window_handle_

### Community 61 - "package:flutter_riverpod/flutter_riverpod.dart"
Cohesion: 0.20
Nodes (3): GoRouter, Scaffold, build

### Community 62 - "Point"
Cohesion: 0.21
Nodes (6): Point, x, y, Size, height, width

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

## Knowledge Gaps
- **1095 isolated node(s):** `eslint:recommended`, `plugin:@typescript-eslint/recommended`, `@typescript-eslint/eslint-plugin`, `@typescript-eslint/parser`, `eslint` (+1090 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 1300 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **13 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Win32Window` connect `Win32Window` to `FlutterWindow`, `win32_window.cpp`, `flutter_window.h`, `.MessageHandler`, `Point`?**
  _High betweenness centrality (0.038) - this node is a cross-community bridge._
- **What connects `eslint:recommended`, `plugin:@typescript-eslint/recommended`, `@typescript-eslint/eslint-plugin` to the rest of the system?**
  _1095 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `cashbox_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.02702702702702703 - nodes in this community are weakly interconnected._
- **Why does `AppCurrency` connect `app.dart` to `cashbox_screen.dart`, `expenses_screen.dart`, `constants.dart`, `subscribers_screen.dart`, `suppliers_screen.dart`, `inbox_screen.dart`, `reports_screen.dart`, `models.dart`, `pdf_report_service.dart`?**
  _High betweenness centrality (0.037) - this node is a cross-community bridge._
- **Should `my_application.cc` be split into smaller, more focused modules?**
  _Cohesion score 0.05426356589147287 - nodes in this community are weakly interconnected._
- **Why does `AppUser` connect `employees_screen.dart` to `cashbox_screen.dart`, `expenses_screen.dart`, `admin_shell.dart`, `subscribers_screen.dart`, `suppliers_screen.dart`, `models.dart`?**
  _High betweenness centrality (0.014) - this node is a cross-community bridge._
- **Should `expenses_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.046511627906976744 - nodes in this community are weakly interconnected._