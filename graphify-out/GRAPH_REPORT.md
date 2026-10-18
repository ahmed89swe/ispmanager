# Graph Report - isp_user_manager  (2026-10-18)

## Corpus Check
- 103 files · ~122,180 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 58 file(s) not represented in the graph (top: (none) 9, .xcconfig 8, .xml 7)

## Summary
- 2030 nodes · 2893 edges · 80 communities (64 shown, 16 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 17 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `597570e0`
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
- Point
- employees_screen.dart
- .eslintrc.json
- package:flutter/material.dart
- expenses_repository.dart
- Cloud Functions
- chat_repository.dart
- cashbox_repository.dart
- AppUser
- ../../l10n/app_localizations.dart
- manifest.json
- pdf_report_service.dart
- _buildMobileShell
- auth_repository.dart
- profile_screen.dart
- app_localizations.dart
- constants.dart
- record_payment_sheet.dart
- ../auth/auth_repository.dart
- cashbox_service.dart
- FlutterWindow
- GeneratedPluginRegistrant.swift
- package:flutter_riverpod/flutter_riverpod.dart
- suppliers_repository.dart
- ConsumerState
- history_repository.dart
- subscribersRepositoryProvider
- employees_repository.dart
- app.dart
- app_theme.dart
- _ShiftAutoRenewalDialogState
- _InboxScreenState
- StatelessWidget
- app_avatar.dart
- win32_window.cpp
- utils.cpp
- profile_repository.dart
- MainActivity.kt
- expensesRepositoryProvider
- advance_subscription_sheet.dart
- Win32Window
- formatters.dart
- cashboxRepositoryProvider
- ../../core/models/models.dart
- receipt_editor_dialog.dart
- AppLocalizations
- isp_user_manager
- LaunchImage.imageset/README.md
- .MessageHandler
- _AddSubscriberDebtSheetState
- Map
- web_notification_helper_web.dart
- web_notification_helper.dart
- web_notification_helper_stub.dart

## God Nodes (most connected - your core abstractions)
1. `currentAppUserProvider` - 45 edges
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
- `build` --references--> `currentAppUserProvider`  [EXTRACTED]
  lib/features/payments/advance_subscription_sheet.dart → lib/features/auth/auth_repository.dart
- `_submit` --references--> `currentAppUserProvider`  [EXTRACTED]
  lib/features/payments/advance_subscription_sheet.dart → lib/features/auth/auth_repository.dart
- `build` --references--> `currentAppUserProvider`  [EXTRACTED]
  lib/features/payments/record_payment_sheet.dart → lib/features/auth/auth_repository.dart
- `_save` --references--> `currentAppUserProvider`  [EXTRACTED]
  lib/features/payments/record_payment_sheet.dart → lib/features/auth/auth_repository.dart

## Import Cycles
- None detected.

## Communities (80 total, 16 thin omitted)

### Community 0 - "cashbox_screen.dart"
Cohesion: 0.03
Nodes (72): Card, Center, Column, Container, DefaultTabController, Divider, DraggableScrollableSheet, Icon (+64 more)

### Community 1 - "my_application.cc"
Cohesion: 0.05
Nodes (14): fl_register_plugins(), main(), my_application_activate(), my_application_class_init(), my_application_dispose(), my_application_init(), my_application_local_command_line(), my_application_new() (+6 more)

### Community 2 - "expenses_screen.dart"
Cohesion: 0.03
Nodes (67): _actorLabel, Center, Color, Column, Container, Divider, Expanded, Icon (+59 more)

### Community 3 - "preferences_providers.dart"
Cohesion: 0.06
Nodes (38): ListView, Locale, UnimplementedError, build, IspUserManagerApp, _MainAppRouter, routerProvider, AppColorTheme (+30 more)

### Community 4 - "subscribers_repository.dart"
Cohesion: 0.06
Nodes (34): add, addDebt, addWithInitialSubscription, authUser, cancelAdvancePayment, _col, _dateFromFirestore, _db (+26 more)

### Community 5 - "admin_shell.dart"
Cohesion: 0.04
Nodes (42): CircleAvatar, FadeTransition, Function, IconButton, Material, Scaffold, SizedBox, TextStyle (+34 more)

### Community 6 - "subscribers_screen.dart"
Cohesion: 0.02
Nodes (85): Color, Column, Container, Dialog, Divider, Icon, InkWell, launchUrl (+77 more)

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
Cohesion: 0.03
Nodes (56): actionsRow, Card, Column, fmt, ListView, Padding, PdfReportService, SizedBox (+48 more)

### Community 11 - "package.json"
Cohesion: 0.06
Nodes (34): dependencies, firebase-admin, firebase-functions, devDependencies, eslint, typescript, @typescript-eslint/eslint-plugin, @typescript-eslint/parser (+26 more)

### Community 12 - "currentAppUserProvider"
Cohesion: 0.25
Nodes (21): currentAppUserProvider, build, _DashboardScreenState, employeesStreamProvider, expensesStreamProvider, build, _ExpenseFormSheetState, cashboxLedgerStreamProvider (+13 more)

### Community 13 - "models.dart"
Cohesion: 0.01
Nodes (136): action, active, actorName, actorPhotoUrl, actorRole, actorUid, adminUid, after (+128 more)

### Community 14 - "chat_conversation_screen.dart"
Cohesion: 0.05
Nodes (40): Align, Center, Container, Padding, SafeArea, Scaffold, SizedBox, Text (+32 more)

### Community 15 - "package:flutter_test/flutter_test.dart"
Cohesion: 0.12
Nodes (7): initializeDateFormatting, main, main, main, main, main, main

### Community 16 - "history_screen.dart"
Cohesion: 0.12
Nodes (16): Column, ListTile, historyRepositoryProvider, historyStreamProvider, build, _busyEventIds, createState, _errorMessage (+8 more)

### Community 17 - "login_screen.dart"
Cohesion: 0.08
Nodes (26): DefaultTabController, Icon, SizedBox, firebaseAvailableProvider, authRepositoryProvider, _adminEmail, _adminTab, build (+18 more)

### Community 18 - "compilerOptions"
Cohesion: 0.12
Nodes (15): compilerOptions, esModuleInterop, lib, module, moduleResolution, noImplicitAny, noImplicitReturns, outDir (+7 more)

### Community 19 - "Point"
Cohesion: 0.50
Nodes (3): Point, x, y

### Community 20 - "employees_screen.dart"
Cohesion: 0.09
Nodes (27): Center, ListTile, Padding, Scaffold, SizedBox, SnackBar, Employee, employeesRepositoryProvider (+19 more)

### Community 21 - ".eslintrc.json"
Cohesion: 0.12
Nodes (16): env, es2020, node, extends, ignorePatterns, parser, parserOptions, ecmaVersion (+8 more)

### Community 22 - "package:flutter/material.dart"
Cohesion: 0.13
Nodes (5): GoRouter, Scaffold, _AuthLoadingScreen, build, main

### Community 23 - "expenses_repository.dart"
Cohesion: 0.06
Nodes (31): StateError, add, authUser, _col, createDeleteRequest, _db, decideDeleteRequest, delete (+23 more)

### Community 24 - "Cloud Functions"
Cohesion: 0.22
Nodes (8): Cloud Functions, `createEmployee` (callable), Deploy, Functions, Local emulator, `onSupplierPaymentRequestCreate` (Firestore trigger), `onSupplierPaymentRequestUpdated` (Firestore trigger), Setup

### Community 25 - "chat_repository.dart"
Cohesion: 0.08
Nodes (20): StateError, now, null, tsToDate, _chatDoc, ChatRepository, _db, _imageContentType (+12 more)

### Community 26 - "cashbox_repository.dart"
Cohesion: 0.06
Nodes (31): Exception, extractBalance, authUser, balanceFor, balances, cashboxDebtToStaff, cashboxDebtToStaffFor, cashboxDebtToStaffForUid (+23 more)

### Community 28 - "../../l10n/app_localizations.dart"
Cohesion: 0.12
Nodes (12): launchUrl, Padding, PopScope, SizedBox, Spacer, _Body, build, info (+4 more)

### Community 29 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 30 - "pdf_report_service.dart"
Cohesion: 0.04
Nodes (40): _bold, _buildCustomFooter, _buildCustomHeader, _buildEmptyBox, _buildFooter, _buildHeader, _buildInfoItem, _buildKpiCard (+32 more)

### Community 31 - "_buildMobileShell"
Cohesion: 0.50
Nodes (3): _buildDesktopShell, _buildMobileShell, _buildHeaderGreeting

### Community 32 - "auth_repository.dart"
Cohesion: 0.08
Nodes (20): AppUser, GoogleSignIn, StateError, _RefreshOnChange, addFcmToken, _auth, authStateChanges, authStateProvider (+12 more)

### Community 33 - "profile_screen.dart"
Cohesion: 0.12
Nodes (15): ListView, Scaffold, SizedBox, profileRepositoryProvider, build, _busy, createState, dispose (+7 more)

### Community 34 - "app_localizations.dart"
Cohesion: 0.01
Nodes (131): addExpense, addNew, addSubscriber, admin, adminEmail, all, amount, approve (+123 more)

### Community 35 - "constants.dart"
Cohesion: 0.09
Nodes (19): all, code, ExpenseCategory, ExpenseEntryType, fromCode, fromName, manageSupplierPurchases, MoneyStorage (+11 more)

### Community 36 - "record_payment_sheet.dart"
Cohesion: 0.10
Nodes (18): Padding, SizedBox, _amount, build, _busy, by, createState, dispose (+10 more)

### Community 37 - "../auth/auth_repository.dart"
Cohesion: 0.07
Nodes (28): Center, Column, Dismissible, Divider, DraggableScrollableSheet, Icon, showModalBottomSheet, SizedBox (+20 more)

### Community 38 - "cashbox_service.dart"
Cohesion: 0.12
Nodes (14): cashboxDocId, cashboxRef, CashboxService, debtKey, ensureExists, initialData, ledgerCol, registerDirectAdjustment (+6 more)

### Community 39 - "FlutterWindow"
Cohesion: 0.11
Nodes (4): FlutterWindow, flutter_controller_, FlutterWindow::FlutterWindow(), project_

### Community 40 - "GeneratedPluginRegistrant.swift"
Cohesion: 0.05
Nodes (28): cloud_firestore, Cocoa, connectivity_plus, file_selector_macos, firebase_analytics, firebase_auth, firebase_core, firebase_crashlytics (+20 more)

### Community 41 - "package:flutter_riverpod/flutter_riverpod.dart"
Cohesion: 0.07
Nodes (20): StateError, AppUpdateInfo, AppUpdateRepository, appUpdateRepositoryProvider, check, currentVersion, debugMessage, downloadUrl (+12 more)

### Community 42 - "suppliers_repository.dart"
Cohesion: 0.06
Nodes (30): StateError, add, addBalanceTransaction, addPackage, addPurchase, applyPaymentToPurchase, authUser, _balanceCol (+22 more)

### Community 43 - "ConsumerState"
Cohesion: 0.11
Nodes (23): AdminShell, _AdminShellState, DashboardScreen, ExpenseFormSheet, _PayRecurringMonthDialog, _PayRecurringMonthDialogState, RecurringExpenseFormSheet, _RecurringExpenseFormSheetState (+15 more)

### Community 44 - "history_repository.dart"
Cohesion: 0.10
Nodes (19): StateError, authUser, _db, eventData, _expenseIdFromDeleteRequestEvent, HistoryLogger, historyLoggerProvider, HistoryRepository (+11 more)

### Community 45 - "subscribersRepositoryProvider"
Cohesion: 0.12
Nodes (17): _syncDueDebts, _buildBody, subscribersRepositoryProvider, _confirmAndDeleteDebt, _confirmAndPayDebt, _confirmAndUnpayDebt, _exportStatement, _exportSubscriberStatement (+9 more)

### Community 46 - "employees_repository.dart"
Cohesion: 0.05
Nodes (31): UnsupportedError, firebaseAuthProvider, firebaseMessagingProvider, FirebaseService, firebaseStorageProvider, firestoreProvider, init, initialized (+23 more)

### Community 47 - "app.dart"
Cohesion: 0.12
Nodes (8): CircularProgressIndicator, Icon, MaterialApp, Scaffold, SizedBox, UpdateScreen, message, onRetry

### Community 48 - "app_theme.dart"
Cohesion: 0.06
Nodes (25): AppTheme, cardBorderColor, cardColor, cardDecoration, dark, darkBorder, darkCard, darkCardBorderColor (+17 more)

### Community 50 - "_InboxScreenState"
Cohesion: 0.18
Nodes (12): recurringExpensesStreamProvider, ExpensesScreen, _ExpensesScreenState, reimbursementRequestsStreamProvider, chatThreadsStreamProvider, chatThreadStreamProvider, _buildChatsTab, _buildRequestsTab (+4 more)

### Community 51 - "StatelessWidget"
Cohesion: 0.14
Nodes (13): _SplashScreen, _UpdateCheckErrorScreen, _FeatureChip, _AdminBottomTabItem, _AvatarMini, _ChartLegend, _ModernKpiCard, _QuickActionButton (+5 more)

### Community 52 - "app_avatar.dart"
Cohesion: 0.25
Nodes (6): AppAvatar, build, fontSize, name, photoUrl, radius

### Community 53 - "win32_window.cpp"
Cohesion: 0.18
Nodes (5): Scale(), Win32Window::Win32Window(), WindowClassRegistrar, class_registered_, instance_

### Community 54 - "utils.cpp"
Cohesion: 0.19
Nodes (4): wWinMain(), CreateAndAttachConsole(), GetCommandLineArguments(), Utf8FromUtf16()

### Community 55 - "profile_repository.dart"
Cohesion: 0.09
Nodes (16): StateError, dart:io, buildEmployeeEmail, bytes, cleanAdmin, cleanUser, hash, _auth (+8 more)

### Community 58 - "expensesRepositoryProvider"
Cohesion: 0.25
Nodes (8): expensesRepositoryProvider, _deleteExpense, _RecurringExpenseMonthsDialog, _RecurringExpenseMonthsDialogState, _save, _submit, _undoExistingPayment, _unpayMonth

### Community 59 - "advance_subscription_sheet.dart"
Cohesion: 0.10
Nodes (19): Subscriber, AdvanceSubscriptionSheet, _AdvanceSubscriptionSheetState, _amountController, build, _busy, by, createState (+11 more)

### Community 60 - "Win32Window"
Cohesion: 0.16
Nodes (7): Size, height, width, Win32Window, child_content_, quit_on_close_, window_handle_

### Community 61 - "formatters.dart"
Cohesion: 0.17
Nodes (9): addDays, calendarDaysBetween, CurrencyFormatter, date, DateFormatter, dateTime, format, monthLabel (+1 more)

### Community 62 - "cashboxRepositoryProvider"
Cohesion: 0.33
Nodes (6): cashboxRepositoryProvider, _ClaimReimbursementRequestSheet, _ClaimReimbursementRequestSheetState, _DirectAdjustmentSheet, _DirectAdjustmentSheetState, _submit

### Community 63 - "../../core/models/models.dart"
Cohesion: 0.15
Nodes (6): _authRepo, init, _messaging, NotificationService, syncUserToken, _tokenRefreshSub

### Community 64 - "receipt_editor_dialog.dart"
Cohesion: 0.05
Nodes (37): _activeHandle, _applyAndSave, build, _buildCropCanvas, createState, _CropHandle, _CropOverlayPainter, _cropRect (+29 more)

### Community 79 - "web_notification_helper_web.dart"
Cohesion: 0.29
Nodes (4): getWebNotificationPermissionImpl, _playNotificationChime, requestWebNotificationPermissionImpl, showWebBrowserNotificationImpl

### Community 81 - "web_notification_helper.dart"
Cohesion: 0.29
Nodes (4): getPermission, requestPermission, showNotification, WebNotificationHelper

### Community 84 - "web_notification_helper_stub.dart"
Cohesion: 0.50
Nodes (3): getWebNotificationPermissionImpl, requestWebNotificationPermissionImpl, showWebBrowserNotificationImpl

## Knowledge Gaps
- **1299 isolated node(s):** `eslint:recommended`, `plugin:@typescript-eslint/recommended`, `@typescript-eslint/eslint-plugin`, `@typescript-eslint/parser`, `eslint` (+1294 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 1518 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **16 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `AppCurrency` connect `preferences_providers.dart` to `cashbox_screen.dart`, `expenses_screen.dart`, `constants.dart`, `subscribers_screen.dart`, `suppliers_screen.dart`, `inbox_screen.dart`, `reports_screen.dart`, `models.dart`, `pdf_report_service.dart`?**
  _High betweenness centrality (0.029) - this node is a cross-community bridge._
- **What connects `eslint:recommended`, `plugin:@typescript-eslint/recommended`, `@typescript-eslint/eslint-plugin` to the rest of the system?**
  _1299 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `cashbox_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.02666666666666667 - nodes in this community are weakly interconnected._
- **Why does `Win32Window` connect `Win32Window` to `.MessageHandler`, `FlutterWindow`, `Point`, `win32_window.cpp`, `string`?**
  _High betweenness centrality (0.022) - this node is a cross-community bridge._
- **Should `my_application.cc` be split into smaller, more focused modules?**
  _Cohesion score 0.05426356589147287 - nodes in this community are weakly interconnected._
- **Why does `AppUser` connect `AppUser` to `cashbox_screen.dart`, `expenses_screen.dart`, `record_payment_sheet.dart`, `admin_shell.dart`, `subscribers_screen.dart`, `suppliers_screen.dart`, `models.dart`, `employees_screen.dart`, `advance_subscription_sheet.dart`?**
  _High betweenness centrality (0.015) - this node is a cross-community bridge._
- **Should `expenses_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.02857142857142857 - nodes in this community are weakly interconnected._