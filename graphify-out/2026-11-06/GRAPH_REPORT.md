# Graph Report - isp_user_manager  (2026-11-06)

## Corpus Check
- 103 files · ~125,904 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 58 file(s) not represented in the graph (top: (none) 9, .xcconfig 8, .xml 7)

## Summary
- 2033 nodes · 2899 edges · 88 communities (71 shown, 17 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 17 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `20512403`
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
- _DashboardScreenState
- models.dart
- chat_conversation_screen.dart
- package:flutter_test/flutter_test.dart
- win32_window.cpp
- login_screen.dart
- compilerOptions
- firebase_service.dart
- employees_screen.dart
- .eslintrc.json
- router.dart
- expenses_repository.dart
- Cloud Functions
- chat_repository.dart
- cashbox_repository.dart
- ../auth/auth_repository.dart
- ../../l10n/app_localizations.dart
- manifest.json
- pdf_report_service.dart
- authRepositoryProvider
- auth_repository.dart
- profile_screen.dart
- app_localizations.dart
- constants.dart
- record_payment_sheet.dart
- notifications_sheet.dart
- cashbox_service.dart
- FlutterWindow
- GeneratedPluginRegistrant.swift
- app_update_repository.dart
- suppliers_repository.dart
- cashboxRepositoryProvider
- history_repository.dart
- subscribersRepositoryProvider
- employees_repository.dart
- app.dart
- app_theme.dart
- currentAppUserProvider
- _InboxScreenState
- StatelessWidget
- package:flutter/material.dart
- image_preview_dialog.dart
- utils.cpp
- profile_repository.dart
- MainActivity.kt
- cashboxStreamProvider
- advance_subscription_sheet.dart
- ConsumerState
- formatters.dart
- auth_utils.dart
- package:flutter_riverpod/flutter_riverpod.dart
- receipt_editor_dialog.dart
- MaterialPageRoute
- AppLocalizations
- isp_user_manager
- LaunchImage.imageset/README.md
- Win32Window
- _AdminShellState
- _AddSubscriberDebtSheetState
- Map
- _SubscriberFormSheetState
- web_notification_helper_web.dart
- _SubscribersScreenState
- web_notification_helper.dart
- .MessageHandler
- Point
- web_notification_helper_stub.dart
- Size
- _ShiftAutoRenewalDialogState

## God Nodes (most connected - your core abstractions)
1. `currentAppUserProvider` - 45 edges
2. `subscribersRepositoryProvider` - 23 edges
3. `Win32Window` - 21 edges
4. `compilerOptions` - 13 edges
5. `cashboxStreamProvider` - 13 edges
6. `currencyProvider` - 13 edges
7. `expensesRepositoryProvider` - 12 edges
8. `_InboxScreenState` - 12 edges
9. `AppCurrency` - 11 edges
10. `_DashboardScreenState` - 11 edges

## Surprising Connections (you probably didn't know these)
- `_saveName` --references--> `currentAppUserProvider`  [EXTRACTED]
  lib/features/profile/profile_screen.dart → lib/features/auth/auth_repository.dart
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

## Communities (88 total, 17 thin omitted)

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
Cohesion: 0.07
Nodes (36): ListView, Locale, UnimplementedError, build, IspUserManagerApp, _MainAppRouter, routerProvider, AppColorTheme (+28 more)

### Community 4 - "subscribers_repository.dart"
Cohesion: 0.06
Nodes (35): add, addDebt, addWithInitialSubscription, cancelAdvancePayment, _col, _dateFromFirestore, _db, _debtCol (+27 more)

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
Nodes (41): Card, Center, _colorFor, Column, Divider, Expanded, _expenseDeleteRequestTile, Icon (+33 more)

### Community 10 - "reports_screen.dart"
Cohesion: 0.04
Nodes (55): actionsRow, Card, Column, fmt, ListView, Padding, PdfReportService, SizedBox (+47 more)

### Community 11 - "package.json"
Cohesion: 0.06
Nodes (34): dependencies, firebase-admin, firebase-functions, devDependencies, eslint, typescript, @typescript-eslint/eslint-plugin, @typescript-eslint/parser (+26 more)

### Community 12 - "_DashboardScreenState"
Cohesion: 0.25
Nodes (14): build, DashboardScreen, _DashboardScreenState, expensesStreamProvider, paymentsRepositoryProvider, build, ReportsScreen, _ReportsScreenState (+6 more)

### Community 13 - "models.dart"
Cohesion: 0.01
Nodes (138): action, active, actorName, actorPhotoUrl, actorRole, actorUid, adminUid, after (+130 more)

### Community 14 - "chat_conversation_screen.dart"
Cohesion: 0.07
Nodes (28): Align, Center, Container, Padding, SafeArea, Scaffold, SizedBox, Text (+20 more)

### Community 15 - "package:flutter_test/flutter_test.dart"
Cohesion: 0.12
Nodes (7): initializeDateFormatting, main, main, main, main, main, main

### Community 16 - "win32_window.cpp"
Cohesion: 0.18
Nodes (5): Scale(), Win32Window::Win32Window(), WindowClassRegistrar, class_registered_, instance_

### Community 17 - "login_screen.dart"
Cohesion: 0.08
Nodes (23): DefaultTabController, Icon, SizedBox, firebaseAvailableProvider, _adminEmail, _adminTab, build, _busy (+15 more)

### Community 18 - "compilerOptions"
Cohesion: 0.12
Nodes (15): compilerOptions, esModuleInterop, lib, module, moduleResolution, noImplicitAny, noImplicitReturns, outDir (+7 more)

### Community 19 - "firebase_service.dart"
Cohesion: 0.07
Nodes (19): UnsupportedError, firebaseAuthProvider, firebaseMessagingProvider, FirebaseService, firebaseStorageProvider, firestoreProvider, init, initialized (+11 more)

### Community 20 - "employees_screen.dart"
Cohesion: 0.05
Nodes (41): Center, ListTile, Padding, Scaffold, SizedBox, SnackBar, Column, ListTile (+33 more)

### Community 21 - ".eslintrc.json"
Cohesion: 0.12
Nodes (16): env, es2020, node, extends, ignorePatterns, parser, parserOptions, ecmaVersion (+8 more)

### Community 22 - "router.dart"
Cohesion: 0.18
Nodes (4): GoRouter, Scaffold, _AuthLoadingScreen, build

### Community 23 - "expenses_repository.dart"
Cohesion: 0.06
Nodes (30): StateError, add, _col, createDeleteRequest, _db, decideDeleteRequest, delete, deleteRecurringExpense (+22 more)

### Community 24 - "Cloud Functions"
Cohesion: 0.22
Nodes (8): Cloud Functions, `createEmployee` (callable), Deploy, Functions, Local emulator, `onSupplierPaymentRequestCreate` (Firestore trigger), `onSupplierPaymentRequestUpdated` (Firestore trigger), Setup

### Community 25 - "chat_repository.dart"
Cohesion: 0.11
Nodes (17): StateError, _chatDoc, ChatRepository, _db, _imageContentType, markMessagesAsRead, _messagesCol, _notificationsRepo (+9 more)

### Community 26 - "cashbox_repository.dart"
Cohesion: 0.06
Nodes (31): Exception, extractBalance, balanceFor, balances, cashboxDebtToStaff, cashboxDebtToStaffFor, cashboxDebtToStaffForUid, CashboxRepository (+23 more)

### Community 27 - "../auth/auth_repository.dart"
Cohesion: 0.11
Nodes (14): now, null, tsToDate, _col, _db, delete, markAllAsRead, markAsRead (+6 more)

### Community 28 - "../../l10n/app_localizations.dart"
Cohesion: 0.12
Nodes (12): launchUrl, Padding, PopScope, SizedBox, Spacer, AppUpdateInfo, _Body, build (+4 more)

### Community 29 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 30 - "pdf_report_service.dart"
Cohesion: 0.04
Nodes (40): _bold, _buildCustomFooter, _buildCustomHeader, _buildEmptyBox, _buildFooter, _buildHeader, _buildInfoItem, _buildKpiCard (+32 more)

### Community 31 - "authRepositoryProvider"
Cohesion: 0.31
Nodes (6): authRepositoryProvider, _employeeSignIn, _googleSignIn, _buildDesktopShell, _buildMobileShell, _buildHeaderGreeting

### Community 32 - "auth_repository.dart"
Cohesion: 0.10
Nodes (19): AppUser, GoogleSignIn, StateError, addFcmToken, _auth, authStateChanges, currentAppUser, currentAppUserStream (+11 more)

### Community 33 - "profile_screen.dart"
Cohesion: 0.13
Nodes (14): ListView, Scaffold, SizedBox, dart:io, profileRepositoryProvider, _busy, createState, dispose (+6 more)

### Community 34 - "app_localizations.dart"
Cohesion: 0.01
Nodes (131): addExpense, addNew, addSubscriber, admin, adminEmail, all, amount, approve (+123 more)

### Community 35 - "constants.dart"
Cohesion: 0.09
Nodes (19): all, code, ExpenseCategory, ExpenseEntryType, fromCode, fromName, manageSupplierPurchases, MoneyStorage (+11 more)

### Community 36 - "record_payment_sheet.dart"
Cohesion: 0.10
Nodes (18): Padding, SizedBox, AppUser, AuthRepository, _amount, _busy, by, createState (+10 more)

### Community 37 - "notifications_sheet.dart"
Cohesion: 0.11
Nodes (18): Center, Column, Dismissible, Divider, DraggableScrollableSheet, Icon, showModalBottomSheet, SizedBox (+10 more)

### Community 38 - "cashbox_service.dart"
Cohesion: 0.11
Nodes (15): cashboxDocId, cashboxRef, CashboxService, clearStaffDebtWithoutCashbox, debtKey, ensureExists, initialData, ledgerCol (+7 more)

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
Cohesion: 0.07
Nodes (29): StateError, add, addBalanceTransaction, addPackage, addPurchase, applyPaymentToPurchase, _balanceCol, _col (+21 more)

### Community 43 - "cashboxRepositoryProvider"
Cohesion: 0.18
Nodes (11): cashboxRepositoryProvider, reimbursementRequestsStreamProvider, _ClaimReimbursementRequestSheet, _ClaimReimbursementRequestSheetState, _confirmAndClearStaffDebtWithoutCashbox, _DirectAdjustmentSheet, _DirectAdjustmentSheetState, _SettleStaffDebtSheet (+3 more)

### Community 44 - "history_repository.dart"
Cohesion: 0.11
Nodes (17): StateError, _db, eventData, _expenseIdFromDeleteRequestEvent, historyLoggerProvider, HistoryRepository, isSubscriptionPaymentAction, _isUndoable (+9 more)

### Community 45 - "subscribersRepositoryProvider"
Cohesion: 0.13
Nodes (17): _syncDueDebts, _buildBody, subscribersRepositoryProvider, _confirmAndDeleteDebt, _confirmAndPayDebt, _confirmAndUndoPayment, _confirmAndUnpayDebt, _exportStatement (+9 more)

### Community 46 - "employees_repository.dart"
Cohesion: 0.12
Nodes (15): _col, create, _db, delete, EmployeesRepository, _imageContentType, _logger, _notificationsRepo (+7 more)

### Community 47 - "app.dart"
Cohesion: 0.12
Nodes (8): CircularProgressIndicator, Icon, MaterialApp, Scaffold, SizedBox, UpdateScreen, message, onRetry

### Community 48 - "app_theme.dart"
Cohesion: 0.06
Nodes (25): AppTheme, cardBorderColor, cardColor, cardDecoration, dark, darkBorder, darkCard, darkCardBorderColor (+17 more)

### Community 49 - "currentAppUserProvider"
Cohesion: 0.15
Nodes (13): _RefreshOnChange, authStateProvider, currentAppUserProvider, _markRead, _sendMessage, chatRepositoryProvider, build, build (+5 more)

### Community 50 - "_InboxScreenState"
Cohesion: 0.24
Nodes (11): employeesStreamProvider, cashboxLedgerStreamProvider, build, _buildAdminStaffDebtsTab, CashboxScreen, _CashboxScreenState, chatThreadsStreamProvider, chatThreadStreamProvider (+3 more)

### Community 51 - "StatelessWidget"
Cohesion: 0.13
Nodes (14): _SplashScreen, _UpdateCheckErrorScreen, UpdateScreen, _FeatureChip, _AdminBottomTabItem, _AvatarMini, _ChartLegend, _ModernKpiCard (+6 more)

### Community 52 - "package:flutter/material.dart"
Cohesion: 0.17
Nodes (7): AppAvatar, build, fontSize, name, photoUrl, radius, main

### Community 53 - "image_preview_dialog.dart"
Cohesion: 0.17
Nodes (9): build, _buildErrorCard, _buildImage, _FullScreenImageViewer, heroTag, imageUrl, _openExternal, showFullScreenImage (+1 more)

### Community 54 - "utils.cpp"
Cohesion: 0.19
Nodes (4): wWinMain(), CreateAndAttachConsole(), GetCommandLineArguments(), Utf8FromUtf16()

### Community 55 - "profile_repository.dart"
Cohesion: 0.14
Nodes (10): StateError, _auth, _db, _imageContentType, ProfileRepository, removeAvatar, _storage, updateDisplayName (+2 more)

### Community 58 - "cashboxStreamProvider"
Cohesion: 0.16
Nodes (15): expensesRepositoryProvider, recurringExpensesStreamProvider, build, _deleteExpense, ExpenseFormSheet, _ExpenseFormSheetState, ExpensesScreen, _ExpensesScreenState (+7 more)

### Community 59 - "advance_subscription_sheet.dart"
Cohesion: 0.11
Nodes (17): Subscriber, AdvanceSubscriptionSheet, _AdvanceSubscriptionSheetState, _amountController, _busy, by, createState, _cycles (+9 more)

### Community 60 - "ConsumerState"
Cohesion: 0.14
Nodes (19): PermissionsSheet, _PermissionsSheetState, RecurringExpenseFormSheet, _RecurringExpenseFormSheetState, _RecurringExpenseMonthsDialog, _RecurringExpenseMonthsDialogState, suppliersRepositoryProvider, PackageFormSheet (+11 more)

### Community 61 - "formatters.dart"
Cohesion: 0.17
Nodes (9): addDays, calendarDaysBetween, CurrencyFormatter, date, DateFormatter, dateTime, format, monthLabel (+1 more)

### Community 62 - "auth_utils.dart"
Cohesion: 0.29
Nodes (5): buildEmployeeEmail, bytes, cleanAdmin, cleanUser, hash

### Community 63 - "package:flutter_riverpod/flutter_riverpod.dart"
Cohesion: 0.17
Nodes (6): _authRepo, init, _messaging, NotificationService, syncUserToken, _tokenRefreshSub

### Community 64 - "receipt_editor_dialog.dart"
Cohesion: 0.05
Nodes (37): _activeHandle, _applyAndSave, build, _buildCropCanvas, createState, _CropHandle, _CropOverlayPainter, _cropRect (+29 more)

### Community 65 - "MaterialPageRoute"
Cohesion: 0.33
Nodes (5): _buildEmployeeDashboardCard, _buildGeneralCashboxSummaryCard, _buildHeroLiquidityCard, _buildQuickActions, _openImagePreview

### Community 70 - "Win32Window"
Cohesion: 0.24
Nodes (4): Win32Window, child_content_, quit_on_close_, window_handle_

### Community 71 - "_AdminShellState"
Cohesion: 0.40
Nodes (5): AdminShell, _AdminShellState, build, initState, webNotificationsEnabledProvider

### Community 79 - "web_notification_helper_web.dart"
Cohesion: 0.29
Nodes (4): getWebNotificationPermissionImpl, _playNotificationChime, requestWebNotificationPermissionImpl, showWebBrowserNotificationImpl

### Community 81 - "web_notification_helper.dart"
Cohesion: 0.29
Nodes (4): getPermission, requestPermission, showNotification, WebNotificationHelper

### Community 83 - "Point"
Cohesion: 0.50
Nodes (3): Point, x, y

### Community 84 - "web_notification_helper_stub.dart"
Cohesion: 0.50
Nodes (3): getWebNotificationPermissionImpl, requestWebNotificationPermissionImpl, showWebBrowserNotificationImpl

### Community 85 - "Size"
Cohesion: 0.50
Nodes (3): Size, height, width

## Knowledge Gaps
- **1301 isolated node(s):** `eslint:recommended`, `plugin:@typescript-eslint/recommended`, `@typescript-eslint/eslint-plugin`, `@typescript-eslint/parser`, `eslint` (+1296 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 1519 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **17 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `AppCurrency` connect `preferences_providers.dart` to `cashbox_screen.dart`, `expenses_screen.dart`, `constants.dart`, `subscribers_screen.dart`, `suppliers_screen.dart`, `inbox_screen.dart`, `reports_screen.dart`, `models.dart`, `pdf_report_service.dart`?**
  _High betweenness centrality (0.029) - this node is a cross-community bridge._
- **What connects `eslint:recommended`, `plugin:@typescript-eslint/recommended`, `@typescript-eslint/eslint-plugin` to the rest of the system?**
  _1301 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `cashbox_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.02631578947368421 - nodes in this community are weakly interconnected._
- **Why does `Win32Window` connect `Win32Window` to `FlutterWindow`, `win32_window.cpp`, `.MessageHandler`, `Point`, `Size`, `string`?**
  _High betweenness centrality (0.023) - this node is a cross-community bridge._
- **Should `my_application.cc` be split into smaller, more focused modules?**
  _Cohesion score 0.05426356589147287 - nodes in this community are weakly interconnected._
- **Why does `AppUser` connect `record_payment_sheet.dart` to `cashbox_screen.dart`, `expenses_screen.dart`, `admin_shell.dart`, `subscribers_screen.dart`, `suppliers_screen.dart`, `models.dart`, `employees_screen.dart`, `advance_subscription_sheet.dart`?**
  _High betweenness centrality (0.014) - this node is a cross-community bridge._
- **Should `expenses_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.02857142857142857 - nodes in this community are weakly interconnected._