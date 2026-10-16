# Graph Report - isp_user_manager  (2026-10-17)

## Corpus Check
- 99 files · ~76,440 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 58 file(s) not represented in the graph (top: (none) 9, .xcconfig 8, .xml 7)

## Summary
- 1798 nodes · 2570 edges · 75 communities (62 shown, 13 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 17 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `46d7f365`
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
- app_avatar.dart
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
- ../auth/auth_repository.dart
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
- Map
- StatelessWidget
- package:flutter/material.dart
- notifications_repository.dart
- utils.cpp
- ../../core/models/models.dart
- MainActivity.kt
- .MessageHandler
- ConsumerWidget
- profile_repository.dart
- _AdminBottomTabBar
- MaterialPageRoute
- AppLocalizations
- isp_user_manager
- LaunchImage.imageset/README.md
- Point
- advance_subscription_sheet.dart
- package:flutter_riverpod/flutter_riverpod.dart
- _InboxScreenState
- _ChatConversationScreenState

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
- `wWinMain()` --calls--> `CreateAndAttachConsole()`  [INFERRED]
  windows/runner/main.cpp → windows/runner/utils.cpp
- `_MainAppRouter` --references--> `currentAppUserProvider`  [EXTRACTED]
  lib/app/app.dart → lib/features/auth/auth_repository.dart
- `build` --references--> `currentAppUserProvider`  [EXTRACTED]
  lib/app/app.dart → lib/features/auth/auth_repository.dart
- `_RefreshOnChange` --references--> `currentAppUserProvider`  [EXTRACTED]
  lib/app/router.dart → lib/features/auth/auth_repository.dart
- `_AdminShellState` --references--> `authRepositoryProvider`  [EXTRACTED]
  lib/features/dashboard/admin_shell.dart → lib/features/auth/auth_repository.dart

## Import Cycles
- None detected.

## Communities (75 total, 13 thin omitted)

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
Cohesion: 0.07
Nodes (24): CircularProgressIndicator, Icon, MaterialApp, Scaffold, SizedBox, UpdateScreen, GoRouter, Scaffold (+16 more)

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
Nodes (31): Card, CashboxScreen, Center, Container, Icon, _Kpi, _kpiGrid, _Legend (+23 more)

### Community 8 - "suppliers_screen.dart"
Cohesion: 0.05
Nodes (47): Center, Container, DefaultTabController, Expanded, launchUrl, ListTile, Padding, SafeArea (+39 more)

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
Cohesion: 0.13
Nodes (28): build, DashboardScreen, _DashboardScreenState, employeesStreamProvider, expensesRepositoryProvider, expensesStreamProvider, build, _deleteExpense (+20 more)

### Community 13 - "models.dart"
Cohesion: 0.02
Nodes (119): action, active, actorName, actorPhotoUrl, actorRole, actorUid, adminUid, after (+111 more)

### Community 14 - "chat_conversation_screen.dart"
Cohesion: 0.07
Nodes (24): Align, Center, Container, Padding, SafeArea, Scaffold, SizedBox, Text (+16 more)

### Community 15 - "app_avatar.dart"
Cohesion: 0.06
Nodes (19): initializeDateFormatting, buildEmployeeEmail, bytes, cleanAdmin, cleanUser, hash, AppAvatar, build (+11 more)

### Community 16 - "firebase_service.dart"
Cohesion: 0.09
Nodes (14): UnsupportedError, firebaseAuthProvider, firebaseMessagingProvider, FirebaseService, firebaseStorageProvider, firestoreProvider, init, initialized (+6 more)

### Community 17 - "login_screen.dart"
Cohesion: 0.07
Nodes (30): DefaultTabController, Icon, SizedBox, firebaseAvailableProvider, authRepositoryProvider, _adminEmail, _adminTab, build (+22 more)

### Community 18 - "compilerOptions"
Cohesion: 0.12
Nodes (15): compilerOptions, esModuleInterop, lib, module, moduleResolution, noImplicitAny, noImplicitReturns, outDir (+7 more)

### Community 19 - "notifications_sheet.dart"
Cohesion: 0.12
Nodes (13): Center, Column, Dismissible, Divider, DraggableScrollableSheet, Icon, showModalBottomSheet, SizedBox (+5 more)

### Community 20 - "employees_screen.dart"
Cohesion: 0.08
Nodes (27): Center, ListTile, Padding, Scaffold, SizedBox, SnackBar, AppUser, Employee (+19 more)

### Community 21 - ".eslintrc.json"
Cohesion: 0.12
Nodes (16): env, es2020, node, extends, ignorePatterns, parser, parserOptions, ecmaVersion (+8 more)

### Community 22 - "win32_window.cpp"
Cohesion: 0.18
Nodes (5): Scale(), Win32Window::Win32Window(), WindowClassRegistrar, class_registered_, instance_

### Community 23 - "expenses_repository.dart"
Cohesion: 0.07
Nodes (24): StateError, add, authUser, _col, createDeleteRequest, _db, decideDeleteRequest, delete (+16 more)

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
Cohesion: 0.13
Nodes (12): launchUrl, Padding, PopScope, SizedBox, Spacer, AppUpdateInfo, build, info (+4 more)

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
Nodes (18): AppUser, GoogleSignIn, StateError, addFcmToken, _auth, authStateChanges, currentAppUser, currentAppUserStream (+10 more)

### Community 33 - "currentAppUserProvider"
Cohesion: 0.11
Nodes (21): ListView, Scaffold, SizedBox, dart:io, currentAppUserProvider, build, build, _submit (+13 more)

### Community 34 - "app_localizations.dart"
Cohesion: 0.01
Nodes (131): addExpense, addNew, addSubscriber, admin, adminEmail, all, amount, approve (+123 more)

### Community 35 - "constants.dart"
Cohesion: 0.10
Nodes (18): all, code, ExpenseCategory, ExpenseEntryType, fromCode, fromName, manageSupplierPurchases, PaymentRequestStatus (+10 more)

### Community 36 - "../auth/auth_repository.dart"
Cohesion: 0.13
Nodes (11): Padding, SizedBox, Subscriber, _amount, build, _busy, createState, dispose (+3 more)

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
Cohesion: 0.16
Nodes (16): AdminShell, _AdminShellState, PermissionsSheet, _PermissionsSheetState, ExpensesScreen, _ExpensesScreenState, AdvanceSubscriptionSheet, _AdvanceSubscriptionSheetState (+8 more)

### Community 44 - "history_repository.dart"
Cohesion: 0.09
Nodes (20): StateError, now, null, tsToDate, authUser, _db, eventData, _expenseIdFromDeleteRequestEvent (+12 more)

### Community 45 - "subscribersRepositoryProvider"
Cohesion: 0.17
Nodes (12): _syncDueDebts, subscribersRepositoryProvider, AddSubscriberDebtSheet, _AddSubscriberDebtSheetState, _confirmAndDeleteDebt, _confirmAndPayDebt, _exportStatement, _exportSubscriberStatement (+4 more)

### Community 46 - "employees_repository.dart"
Cohesion: 0.12
Nodes (16): authUser, _col, create, _db, delete, EmployeesRepository, _imageContentType, _logger (+8 more)

### Community 47 - "preferences_providers.dart"
Cohesion: 0.07
Nodes (21): Locale, UnimplementedError, AppTheme, dark, light, _scheme, _subThemesData, AppCurrency (+13 more)

### Community 48 - "cashbox_service.dart"
Cohesion: 0.13
Nodes (13): cashboxDocId, cashboxRef, CashboxService, debtKey, ensureExists, initialData, ledgerCol, registerDirectAdjustment (+5 more)

### Community 51 - "StatelessWidget"
Cohesion: 0.14
Nodes (13): _SplashScreen, _UpdateCheckErrorScreen, _Body, _FeatureChip, _AdminBottomTabItem, _AvatarMini, _ChartLegend, _ModernKpiCard (+5 more)

### Community 53 - "notifications_repository.dart"
Cohesion: 0.15
Nodes (11): _col, _db, delete, markAllAsRead, markAsRead, NotificationsRepository, ref, sendNotification (+3 more)

### Community 54 - "utils.cpp"
Cohesion: 0.19
Nodes (4): wWinMain(), CreateAndAttachConsole(), GetCommandLineArguments(), Utf8FromUtf16()

### Community 55 - "../../core/models/models.dart"
Cohesion: 0.17
Nodes (6): _authRepo, init, _messaging, NotificationService, syncUserToken, _tokenRefreshSub

### Community 60 - "ConsumerWidget"
Cohesion: 0.33
Nodes (5): _PaidSubscriptionsTab, _SubscriberDebtsTab, SubscriberDetailsDialog, _PackagesTab, SupplierDetailsScreen

### Community 62 - "profile_repository.dart"
Cohesion: 0.14
Nodes (10): StateError, _auth, _db, _imageContentType, ProfileRepository, removeAvatar, _storage, updateDisplayName (+2 more)

### Community 64 - "_AdminBottomTabBar"
Cohesion: 0.40
Nodes (4): _AdminBottomTabBar, _AdminBottomTabBarState, _EmployeeAccountStatementSheet, _EmployeeAccountStatementSheetState

### Community 65 - "MaterialPageRoute"
Cohesion: 0.33
Nodes (5): _buildEmployeeDashboardCard, _buildGeneralCashboxSummaryCard, _buildHeroLiquidityCard, _buildQuickActions, _openImagePreview

### Community 71 - "Point"
Cohesion: 0.21
Nodes (6): Point, x, y, Size, height, width

### Community 76 - "advance_subscription_sheet.dart"
Cohesion: 0.12
Nodes (13): MoneyStorage, _amountController, build, _busy, createState, _cycles, dispose, initState (+5 more)

### Community 77 - "package:flutter_riverpod/flutter_riverpod.dart"
Cohesion: 0.13
Nodes (6): ListView, _firebaseMessagingBackgroundHandler, init, main, prefs, setPreferredOrientations

### Community 80 - "_InboxScreenState"
Cohesion: 0.29
Nodes (7): reimbursementRequestsStreamProvider, chatThreadsStreamProvider, chatThreadStreamProvider, _buildChatsTab, _buildRequestsTab, InboxScreen, _InboxScreenState

### Community 81 - "_ChatConversationScreenState"
Cohesion: 0.29
Nodes (7): build, ChatConversationScreen, _ChatConversationScreenState, _markRead, _sendMessage, chatMessagesStreamProvider, chatRepositoryProvider

## Knowledge Gaps
- **1123 isolated node(s):** `eslint:recommended`, `plugin:@typescript-eslint/recommended`, `@typescript-eslint/eslint-plugin`, `@typescript-eslint/parser`, `eslint` (+1118 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 1330 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **13 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Win32Window` connect `Win32Window` to `Point`, `FlutterWindow`, `win32_window.cpp`, `flutter_window.h`, `.MessageHandler`?**
  _High betweenness centrality (0.034) - this node is a cross-community bridge._
- **What connects `eslint:recommended`, `plugin:@typescript-eslint/recommended`, `@typescript-eslint/eslint-plugin` to the rest of the system?**
  _1123 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `cashbox_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.02702702702702703 - nodes in this community are weakly interconnected._
- **Why does `AppCurrency` connect `preferences_providers.dart` to `cashbox_screen.dart`, `expenses_screen.dart`, `constants.dart`, `subscribers_screen.dart`, `suppliers_screen.dart`, `inbox_screen.dart`, `reports_screen.dart`, `models.dart`, `package:flutter_riverpod/flutter_riverpod.dart`, `pdf_report_service.dart`?**
  _High betweenness centrality (0.031) - this node is a cross-community bridge._
- **Should `my_application.cc` be split into smaller, more focused modules?**
  _Cohesion score 0.05426356589147287 - nodes in this community are weakly interconnected._
- **Why does `FlutterWindow` connect `FlutterWindow` to `flutter_window.h`, `Win32Window`?**
  _High betweenness centrality (0.015) - this node is a cross-community bridge._
- **Should `expenses_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.046511627906976744 - nodes in this community are weakly interconnected._