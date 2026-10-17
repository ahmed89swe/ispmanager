# Graph Report - isp_user_manager  (2026-10-17)

## Corpus Check
- 102 files · ~90,489 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 58 file(s) not represented in the graph (top: (none) 9, .xcconfig 8, .xml 7)

## Summary
- 1970 nodes · 2812 edges · 85 communities (68 shown, 17 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 17 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `8ed507cc`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- cashbox_screen.dart
- my_application.cc
- expenses_screen.dart
- preferences_providers.dart
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
- package:flutter_test/flutter_test.dart
- history_screen.dart
- login_screen.dart
- compilerOptions
- notifications_sheet.dart
- employees_screen.dart
- .eslintrc.json
- router.dart
- expenses_repository.dart
- Cloud Functions
- chat_repository.dart
- cashbox_repository.dart
- RecurringExpenseFormSheet
- ../../l10n/app_localizations.dart
- manifest.json
- pdf_report_service.dart
- _buildMobileShell
- auth_repository.dart
- profile_screen.dart
- app_localizations.dart
- constants.dart
- record_payment_sheet.dart
- _AddSubscriberDebtSheetState
- cashbox_service.dart
- FlutterWindow
- GeneratedPluginRegistrant.swift
- app_update_repository.dart
- suppliers_repository.dart
- ConsumerState
- history_repository.dart
- subscribersRepositoryProvider
- employees_repository.dart
- app.dart
- app_theme.dart
- app_avatar.dart
- auth_utils.dart
- StatelessWidget
- _ShiftAutoRenewalDialogState
- win32_window.cpp
- utils.cpp
- package:flutter_riverpod/flutter_riverpod.dart
- MainActivity.kt
- cashboxStreamProvider
- advance_subscription_sheet.dart
- Win32Window
- formatters.dart
- profile_repository.dart
- ../../core/models/models.dart
- _AdminBottomTabBar
- build
- AppLocalizations
- isp_user_manager
- LaunchImage.imageset/README.md
- AppCurrency
- .MessageHandler
- package:flutter/material.dart
- Map
- Point
- web_notification_helper_web.dart
- _InboxScreenState
- web_notification_helper.dart
- MaterialPageRoute
- widget_test.dart
- web_notification_helper_stub.dart

## God Nodes (most connected - your core abstractions)
1. `currentAppUserProvider` - 41 edges
2. `subscribersRepositoryProvider` - 21 edges
3. `Win32Window` - 21 edges
4. `compilerOptions` - 13 edges
5. `cashboxStreamProvider` - 13 edges
6. `currencyProvider` - 13 edges
7. `expensesRepositoryProvider` - 12 edges
8. `_InboxScreenState` - 12 edges
9. `AppCurrency` - 11 edges
10. `_DashboardScreenState` - 11 edges

## Surprising Connections (you probably didn't know these)
- `build` --references--> `currentAppUserProvider`  [EXTRACTED]
  lib/features/inbox/inbox_screen.dart → lib/features/auth/auth_repository.dart
- `_submit` --references--> `currentAppUserProvider`  [EXTRACTED]
  lib/features/payments/advance_subscription_sheet.dart → lib/features/auth/auth_repository.dart
- `_save` --references--> `currentAppUserProvider`  [EXTRACTED]
  lib/features/payments/record_payment_sheet.dart → lib/features/auth/auth_repository.dart
- `build` --references--> `currentAppUserProvider`  [EXTRACTED]
  lib/features/profile/profile_screen.dart → lib/features/auth/auth_repository.dart
- `_pickAvatar` --references--> `currentAppUserProvider`  [EXTRACTED]
  lib/features/profile/profile_screen.dart → lib/features/auth/auth_repository.dart

## Import Cycles
- None detected.

## Communities (85 total, 17 thin omitted)

### Community 0 - "cashbox_screen.dart"
Cohesion: 0.03
Nodes (73): Card, Center, Column, Container, DefaultTabController, Divider, DraggableScrollableSheet, Icon (+65 more)

### Community 1 - "my_application.cc"
Cohesion: 0.05
Nodes (14): fl_register_plugins(), main(), my_application_activate(), my_application_class_init(), my_application_dispose(), my_application_init(), my_application_local_command_line(), my_application_new() (+6 more)

### Community 2 - "expenses_screen.dart"
Cohesion: 0.03
Nodes (67): _actorLabel, Center, Color, Column, Container, Divider, Expanded, Icon (+59 more)

### Community 3 - "preferences_providers.dart"
Cohesion: 0.10
Nodes (17): Locale, UnimplementedError, AppPreferences, appPreferencesProvider, _kCurrency, _kLocale, _kThemeMode, _kWebColorTheme (+9 more)

### Community 4 - "subscribers_repository.dart"
Cohesion: 0.06
Nodes (33): add, addDebt, addWithInitialSubscription, authUser, cancelAdvancePayment, _col, _dateFromFirestore, _db (+25 more)

### Community 5 - "admin_shell.dart"
Cohesion: 0.04
Nodes (42): CircleAvatar, FadeTransition, Function, IconButton, Material, Scaffold, SizedBox, TextStyle (+34 more)

### Community 6 - "subscribers_screen.dart"
Cohesion: 0.02
Nodes (85): Color, Column, Container, Dialog, Divider, Icon, InkWell, launchUrl (+77 more)

### Community 7 - "dashboard_screen.dart"
Cohesion: 0.05
Nodes (31): Card, CashboxScreen, Center, Container, Icon, _Kpi, _kpiGrid, _Legend (+23 more)

### Community 8 - "suppliers_screen.dart"
Cohesion: 0.05
Nodes (38): Center, Container, DefaultTabController, Expanded, launchUrl, ListTile, Padding, SafeArea (+30 more)

### Community 9 - "inbox_screen.dart"
Cohesion: 0.04
Nodes (42): Card, Center, _colorFor, Column, Divider, Expanded, _expenseDeleteRequestTile, Icon (+34 more)

### Community 10 - "reports_screen.dart"
Cohesion: 0.03
Nodes (56): actionsRow, Card, Column, fmt, ListView, Padding, PdfReportService, SizedBox (+48 more)

### Community 11 - "package.json"
Cohesion: 0.06
Nodes (34): dependencies, firebase-admin, firebase-functions, devDependencies, eslint, typescript, @typescript-eslint/eslint-plugin, @typescript-eslint/parser (+26 more)

### Community 12 - "currentAppUserProvider"
Cohesion: 0.19
Nodes (22): currentAppUserProvider, build, _DashboardScreenState, expensesStreamProvider, recurringExpensesStreamProvider, build, ExpensesScreen, _ExpensesScreenState (+14 more)

### Community 13 - "models.dart"
Cohesion: 0.01
Nodes (134): action, active, actorName, actorPhotoUrl, actorRole, actorUid, adminUid, after (+126 more)

### Community 14 - "chat_conversation_screen.dart"
Cohesion: 0.06
Nodes (31): Align, Center, Container, Padding, SafeArea, Scaffold, SizedBox, Text (+23 more)

### Community 15 - "package:flutter_test/flutter_test.dart"
Cohesion: 0.14
Nodes (6): initializeDateFormatting, main, main, main, main, main

### Community 16 - "history_screen.dart"
Cohesion: 0.12
Nodes (16): Column, ListTile, historyRepositoryProvider, historyStreamProvider, build, _busyEventIds, createState, _errorMessage (+8 more)

### Community 17 - "login_screen.dart"
Cohesion: 0.09
Nodes (22): DefaultTabController, Icon, SizedBox, firebaseAvailableProvider, authRepositoryProvider, _adminEmail, _adminTab, build (+14 more)

### Community 18 - "compilerOptions"
Cohesion: 0.12
Nodes (15): compilerOptions, esModuleInterop, lib, module, moduleResolution, noImplicitAny, noImplicitReturns, outDir (+7 more)

### Community 19 - "notifications_sheet.dart"
Cohesion: 0.11
Nodes (17): Center, Column, Dismissible, Divider, DraggableScrollableSheet, Icon, showModalBottomSheet, SizedBox (+9 more)

### Community 20 - "employees_screen.dart"
Cohesion: 0.08
Nodes (29): Center, ListTile, Padding, Scaffold, SizedBox, SnackBar, AppUser, Employee (+21 more)

### Community 21 - ".eslintrc.json"
Cohesion: 0.12
Nodes (16): env, es2020, node, extends, ignorePatterns, parser, parserOptions, ecmaVersion (+8 more)

### Community 22 - "router.dart"
Cohesion: 0.14
Nodes (6): GoRouter, Scaffold, _AuthLoadingScreen, build, _RefreshOnChange, authStateProvider

### Community 23 - "expenses_repository.dart"
Cohesion: 0.06
Nodes (31): StateError, add, authUser, _col, createDeleteRequest, _db, decideDeleteRequest, delete (+23 more)

### Community 24 - "Cloud Functions"
Cohesion: 0.22
Nodes (8): Cloud Functions, `createEmployee` (callable), Deploy, Functions, Local emulator, `onSupplierPaymentRequestCreate` (Firestore trigger), `onSupplierPaymentRequestUpdated` (Firestore trigger), Setup

### Community 25 - "chat_repository.dart"
Cohesion: 0.06
Nodes (31): StateError, now, null, tsToDate, _chatDoc, ChatRepository, _db, _imageContentType (+23 more)

### Community 26 - "cashbox_repository.dart"
Cohesion: 0.06
Nodes (31): Exception, extractBalance, authUser, balanceFor, balances, cashboxDebtToStaff, cashboxDebtToStaffFor, cashboxDebtToStaffForUid (+23 more)

### Community 28 - "../../l10n/app_localizations.dart"
Cohesion: 0.13
Nodes (11): launchUrl, Padding, PopScope, SizedBox, Spacer, _Body, build, info (+3 more)

### Community 29 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 30 - "pdf_report_service.dart"
Cohesion: 0.04
Nodes (40): _bold, _buildCustomFooter, _buildCustomHeader, _buildEmptyBox, _buildFooter, _buildHeader, _buildInfoItem, _buildKpiCard (+32 more)

### Community 31 - "_buildMobileShell"
Cohesion: 0.40
Nodes (4): _buildDesktopShell, _buildMobileShell, _buildHeaderGreeting, unreadNotificationsCountProvider

### Community 32 - "auth_repository.dart"
Cohesion: 0.10
Nodes (18): AppUser, GoogleSignIn, StateError, addFcmToken, _auth, authStateChanges, currentAppUser, currentAppUserStream (+10 more)

### Community 33 - "profile_screen.dart"
Cohesion: 0.12
Nodes (16): ListView, Scaffold, SizedBox, dart:io, profileRepositoryProvider, build, _busy, createState (+8 more)

### Community 34 - "app_localizations.dart"
Cohesion: 0.01
Nodes (131): addExpense, addNew, addSubscriber, admin, adminEmail, all, amount, approve (+123 more)

### Community 35 - "constants.dart"
Cohesion: 0.09
Nodes (19): all, code, ExpenseCategory, ExpenseEntryType, fromCode, fromName, manageSupplierPurchases, MoneyStorage (+11 more)

### Community 36 - "record_payment_sheet.dart"
Cohesion: 0.11
Nodes (16): Padding, SizedBox, Subscriber, _amount, build, _busy, createState, dispose (+8 more)

### Community 38 - "cashbox_service.dart"
Cohesion: 0.12
Nodes (14): cashboxDocId, cashboxRef, CashboxService, debtKey, ensureExists, initialData, ledgerCol, registerDirectAdjustment (+6 more)

### Community 39 - "FlutterWindow"
Cohesion: 0.11
Nodes (4): FlutterWindow, flutter_controller_, FlutterWindow::FlutterWindow(), project_

### Community 40 - "GeneratedPluginRegistrant.swift"
Cohesion: 0.05
Nodes (28): cloud_firestore, Cocoa, connectivity_plus, file_selector_macos, firebase_analytics, firebase_auth, firebase_core, firebase_crashlytics (+20 more)

### Community 41 - "app_update_repository.dart"
Cohesion: 0.11
Nodes (15): StateError, AppUpdateInfo, AppUpdateRepository, appUpdateRepositoryProvider, check, currentVersion, debugMessage, downloadUrl (+7 more)

### Community 42 - "suppliers_repository.dart"
Cohesion: 0.06
Nodes (30): StateError, add, addBalanceTransaction, addPackage, addPurchase, applyPaymentToPurchase, authUser, _balanceCol (+22 more)

### Community 43 - "ConsumerState"
Cohesion: 0.12
Nodes (19): AdminShell, _AdminShellState, DashboardScreen, _RecurringExpenseMonthsDialog, _RecurringExpenseMonthsDialogState, _DirectAdjustmentSheet, _DirectAdjustmentSheetState, ReportsScreen (+11 more)

### Community 44 - "history_repository.dart"
Cohesion: 0.10
Nodes (18): StateError, authUser, _db, eventData, _expenseIdFromDeleteRequestEvent, historyLoggerProvider, HistoryRepository, isSubscriptionPaymentAction (+10 more)

### Community 45 - "subscribersRepositoryProvider"
Cohesion: 0.12
Nodes (17): _syncDueDebts, _buildBody, subscribersRepositoryProvider, _confirmAndDeleteDebt, _confirmAndPayDebt, _confirmAndUnpayDebt, _exportStatement, _exportSubscriberStatement (+9 more)

### Community 46 - "employees_repository.dart"
Cohesion: 0.06
Nodes (30): UnsupportedError, firebaseAuthProvider, firebaseMessagingProvider, FirebaseService, firebaseStorageProvider, firestoreProvider, init, initialized (+22 more)

### Community 47 - "app.dart"
Cohesion: 0.12
Nodes (9): CircularProgressIndicator, Icon, MaterialApp, Scaffold, SizedBox, UpdateScreen, message, onRetry (+1 more)

### Community 48 - "app_theme.dart"
Cohesion: 0.06
Nodes (25): AppTheme, cardBorderColor, cardColor, cardDecoration, dark, darkBorder, darkCard, darkCardBorderColor (+17 more)

### Community 49 - "app_avatar.dart"
Cohesion: 0.25
Nodes (6): AppAvatar, build, fontSize, name, photoUrl, radius

### Community 50 - "auth_utils.dart"
Cohesion: 0.18
Nodes (6): buildEmployeeEmail, bytes, cleanAdmin, cleanUser, hash, main

### Community 51 - "StatelessWidget"
Cohesion: 0.14
Nodes (13): _UpdateCheckErrorScreen, UpdateScreen, _FeatureChip, _AdminBottomTabItem, _AvatarMini, _ChartLegend, _ModernKpiCard, _QuickActionButton (+5 more)

### Community 53 - "win32_window.cpp"
Cohesion: 0.18
Nodes (5): Scale(), Win32Window::Win32Window(), WindowClassRegistrar, class_registered_, instance_

### Community 54 - "utils.cpp"
Cohesion: 0.19
Nodes (4): wWinMain(), CreateAndAttachConsole(), GetCommandLineArguments(), Utf8FromUtf16()

### Community 55 - "package:flutter_riverpod/flutter_riverpod.dart"
Cohesion: 0.11
Nodes (6): ListView, _firebaseMessagingBackgroundHandler, init, main, prefs, setPreferredOrientations

### Community 58 - "cashboxStreamProvider"
Cohesion: 0.18
Nodes (15): expensesRepositoryProvider, _deleteExpense, ExpenseFormSheet, _ExpenseFormSheetState, _PayRecurringMonthDialog, _PayRecurringMonthDialogState, _save, _submit (+7 more)

### Community 59 - "advance_subscription_sheet.dart"
Cohesion: 0.10
Nodes (17): AdvanceSubscriptionSheet, _AdvanceSubscriptionSheetState, _amountController, build, _busy, createState, _cycles, dispose (+9 more)

### Community 60 - "Win32Window"
Cohesion: 0.16
Nodes (7): Size, height, width, Win32Window, child_content_, quit_on_close_, window_handle_

### Community 61 - "formatters.dart"
Cohesion: 0.17
Nodes (9): addDays, calendarDaysBetween, CurrencyFormatter, date, DateFormatter, dateTime, format, monthLabel (+1 more)

### Community 62 - "profile_repository.dart"
Cohesion: 0.14
Nodes (10): StateError, _auth, _db, _imageContentType, ProfileRepository, removeAvatar, _storage, updateDisplayName (+2 more)

### Community 63 - "../../core/models/models.dart"
Cohesion: 0.17
Nodes (6): _authRepo, init, _messaging, NotificationService, syncUserToken, _tokenRefreshSub

### Community 64 - "_AdminBottomTabBar"
Cohesion: 0.40
Nodes (4): _AdminBottomTabBar, _AdminBottomTabBarState, _EmployeeAccountStatementSheet, _EmployeeAccountStatementSheetState

### Community 65 - "build"
Cohesion: 0.29
Nodes (14): build, IspUserManagerApp, _MainAppRouter, routerProvider, notificationServiceProvider, appUpdateProvider, build, initState (+6 more)

### Community 70 - "AppCurrency"
Cohesion: 0.20
Nodes (7): AppColorTheme, AppCurrency, CurrencyNotifier, LocaleNotifier, ThemeModeNotifier, WebColorThemeNotifier, WebNotificationsEnabledNotifier

### Community 78 - "Point"
Cohesion: 0.50
Nodes (3): Point, x, y

### Community 79 - "web_notification_helper_web.dart"
Cohesion: 0.29
Nodes (4): getWebNotificationPermissionImpl, _playNotificationChime, requestWebNotificationPermissionImpl, showWebBrowserNotificationImpl

### Community 80 - "_InboxScreenState"
Cohesion: 0.21
Nodes (13): employeesStreamProvider, cashboxRepositoryProvider, reimbursementRequestsStreamProvider, _ClaimReimbursementRequestSheet, _ClaimReimbursementRequestSheetState, _SettleStaffDebtSheet, _SettleStaffDebtSheetState, chatThreadsStreamProvider (+5 more)

### Community 81 - "web_notification_helper.dart"
Cohesion: 0.29
Nodes (4): getPermission, requestPermission, showNotification, WebNotificationHelper

### Community 82 - "MaterialPageRoute"
Cohesion: 0.33
Nodes (5): _buildEmployeeDashboardCard, _buildGeneralCashboxSummaryCard, _buildHeroLiquidityCard, _buildQuickActions, _openImagePreview

### Community 84 - "web_notification_helper_stub.dart"
Cohesion: 0.50
Nodes (3): getWebNotificationPermissionImpl, requestWebNotificationPermissionImpl, showWebBrowserNotificationImpl

## Knowledge Gaps
- **1255 isolated node(s):** `eslint:recommended`, `plugin:@typescript-eslint/recommended`, `@typescript-eslint/eslint-plugin`, `@typescript-eslint/parser`, `eslint` (+1250 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 1468 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **17 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `AppCurrency` connect `AppCurrency` to `cashbox_screen.dart`, `expenses_screen.dart`, `constants.dart`, `subscribers_screen.dart`, `suppliers_screen.dart`, `inbox_screen.dart`, `reports_screen.dart`, `models.dart`, `package:flutter_riverpod/flutter_riverpod.dart`, `pdf_report_service.dart`?**
  _High betweenness centrality (0.029) - this node is a cross-community bridge._
- **What connects `eslint:recommended`, `plugin:@typescript-eslint/recommended`, `@typescript-eslint/eslint-plugin` to the rest of the system?**
  _1255 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `cashbox_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.02631578947368421 - nodes in this community are weakly interconnected._
- **Why does `Win32Window` connect `Win32Window` to `.MessageHandler`, `FlutterWindow`, `Point`, `win32_window.cpp`, `string`?**
  _High betweenness centrality (0.020) - this node is a cross-community bridge._
- **Should `my_application.cc` be split into smaller, more focused modules?**
  _Cohesion score 0.05426356589147287 - nodes in this community are weakly interconnected._
- **Why does `AppUser` connect `employees_screen.dart` to `cashbox_screen.dart`, `expenses_screen.dart`, `admin_shell.dart`, `subscribers_screen.dart`, `suppliers_screen.dart`, `models.dart`?**
  _High betweenness centrality (0.014) - this node is a cross-community bridge._
- **Should `expenses_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.02857142857142857 - nodes in this community are weakly interconnected._