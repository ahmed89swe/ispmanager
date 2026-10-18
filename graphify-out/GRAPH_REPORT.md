# Graph Report - isp_user_manager  (2026-10-18)

## Corpus Check
- 103 files · ~122,205 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 58 file(s) not represented in the graph (top: (none) 9, .xcconfig 8, .xml 7)

## Summary
- 2023 nodes · 2885 edges · 86 communities (69 shown, 17 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 17 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `211a9c63`
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
- history_screen.dart
- login_screen.dart
- compilerOptions
- main.dart
- employees_screen.dart
- .eslintrc.json
- package:flutter_riverpod/flutter_riverpod.dart
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
- win32_window.cpp
- GeneratedPluginRegistrant.swift
- app_update_repository.dart
- suppliers_repository.dart
- ConsumerState
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
- suppliersRepositoryProvider
- formatters.dart
- auth_utils.dart
- ../../core/models/models.dart
- receipt_editor_dialog.dart
- MaterialPageRoute
- AppLocalizations
- isp_user_manager
- LaunchImage.imageset/README.md
- _ExpensesScreenState
- webNotificationsEnabledProvider
- _AddSubscriberDebtSheetState
- Map
- _SubscriberFormSheetState
- web_notification_helper_web.dart
- _SubscribersScreenState
- web_notification_helper.dart
- _PackageFormSheetState
- _SuppliersScreenState
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
- `_pickAvatar` --references--> `currentAppUserProvider`  [EXTRACTED]
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

## Communities (86 total, 17 thin omitted)

### Community 0 - "cashbox_screen.dart"
Cohesion: 0.03
Nodes (71): Card, Center, Column, Container, DefaultTabController, Divider, DraggableScrollableSheet, Icon (+63 more)

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
Nodes (33): add, addDebt, addWithInitialSubscription, cancelAdvancePayment, _col, _dateFromFirestore, _db, _debtCol (+25 more)

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
Nodes (43): Card, Center, _colorFor, Column, Divider, Expanded, _expenseDeleteRequestTile, Icon (+35 more)

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
Nodes (136): action, active, actorName, actorPhotoUrl, actorRole, actorUid, adminUid, after (+128 more)

### Community 14 - "chat_conversation_screen.dart"
Cohesion: 0.07
Nodes (24): Align, Center, Container, Padding, SafeArea, Scaffold, SizedBox, Text (+16 more)

### Community 15 - "package:flutter_test/flutter_test.dart"
Cohesion: 0.12
Nodes (7): initializeDateFormatting, main, main, main, main, main, main

### Community 16 - "history_screen.dart"
Cohesion: 0.12
Nodes (16): Column, ListTile, historyRepositoryProvider, historyStreamProvider, build, _busyEventIds, createState, _errorMessage (+8 more)

### Community 17 - "login_screen.dart"
Cohesion: 0.08
Nodes (23): DefaultTabController, Icon, SizedBox, firebaseAvailableProvider, _adminEmail, _adminTab, build, _busy (+15 more)

### Community 18 - "compilerOptions"
Cohesion: 0.12
Nodes (15): compilerOptions, esModuleInterop, lib, module, moduleResolution, noImplicitAny, noImplicitReturns, outDir (+7 more)

### Community 19 - "main.dart"
Cohesion: 0.09
Nodes (11): UnsupportedError, android, DefaultFirebaseOptions, ios, web, windows, _firebaseMessagingBackgroundHandler, init (+3 more)

### Community 20 - "employees_screen.dart"
Cohesion: 0.09
Nodes (25): Center, ListTile, Padding, Scaffold, SizedBox, SnackBar, Employee, employeesRepositoryProvider (+17 more)

### Community 21 - ".eslintrc.json"
Cohesion: 0.12
Nodes (16): env, es2020, node, extends, ignorePatterns, parser, parserOptions, ecmaVersion (+8 more)

### Community 22 - "package:flutter_riverpod/flutter_riverpod.dart"
Cohesion: 0.20
Nodes (3): GoRouter, Scaffold, build

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
Nodes (30): Exception, extractBalance, balanceFor, balances, cashboxDebtToStaff, cashboxDebtToStaffFor, cashboxDebtToStaffForUid, CashboxRepository (+22 more)

### Community 27 - "../auth/auth_repository.dart"
Cohesion: 0.11
Nodes (14): now, null, tsToDate, _col, _db, delete, markAllAsRead, markAsRead (+6 more)

### Community 28 - "../../l10n/app_localizations.dart"
Cohesion: 0.12
Nodes (12): launchUrl, Padding, PopScope, SizedBox, Spacer, _Body, build, info (+4 more)

### Community 29 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 30 - "pdf_report_service.dart"
Cohesion: 0.04
Nodes (40): _bold, _buildCustomFooter, _buildCustomHeader, _buildEmptyBox, _buildFooter, _buildHeader, _buildInfoItem, _buildKpiCard (+32 more)

### Community 31 - "authRepositoryProvider"
Cohesion: 0.23
Nodes (9): authRepositoryProvider, _employeeSignIn, _googleSignIn, AdminShell, _AdminShellState, _buildDesktopShell, _buildMobileShell, _buildHeaderGreeting (+1 more)

### Community 32 - "auth_repository.dart"
Cohesion: 0.10
Nodes (19): AppUser, GoogleSignIn, StateError, addFcmToken, _auth, authStateChanges, currentAppUser, currentAppUserStream (+11 more)

### Community 33 - "profile_screen.dart"
Cohesion: 0.13
Nodes (13): ListView, Scaffold, SizedBox, profileRepositoryProvider, _busy, createState, dispose, _initialized (+5 more)

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
Nodes (17): Center, Column, Dismissible, Divider, DraggableScrollableSheet, Icon, showModalBottomSheet, SizedBox (+9 more)

### Community 38 - "cashbox_service.dart"
Cohesion: 0.12
Nodes (14): cashboxDocId, cashboxRef, CashboxService, debtKey, ensureExists, initialData, ledgerCol, registerDirectAdjustment (+6 more)

### Community 39 - "win32_window.cpp"
Cohesion: 0.05
Nodes (20): FlutterWindow, flutter_controller_, FlutterWindow::FlutterWindow(), project_, EnableFullDpiSupportIfAvailable(), Point, x, y (+12 more)

### Community 40 - "GeneratedPluginRegistrant.swift"
Cohesion: 0.05
Nodes (28): cloud_firestore, Cocoa, connectivity_plus, file_selector_macos, firebase_analytics, firebase_auth, firebase_core, firebase_crashlytics (+20 more)

### Community 41 - "app_update_repository.dart"
Cohesion: 0.11
Nodes (15): StateError, AppUpdateInfo, AppUpdateRepository, appUpdateRepositoryProvider, check, currentVersion, debugMessage, downloadUrl (+7 more)

### Community 42 - "suppliers_repository.dart"
Cohesion: 0.07
Nodes (29): StateError, add, addBalanceTransaction, addPackage, addPurchase, applyPaymentToPurchase, _balanceCol, _col (+21 more)

### Community 43 - "ConsumerState"
Cohesion: 0.17
Nodes (14): PermissionsSheet, _PermissionsSheetState, RecurringExpenseFormSheet, _RecurringExpenseFormSheetState, cashboxRepositoryProvider, _ClaimReimbursementRequestSheet, _ClaimReimbursementRequestSheetState, _DirectAdjustmentSheet (+6 more)

### Community 44 - "history_repository.dart"
Cohesion: 0.11
Nodes (17): StateError, _db, eventData, _expenseIdFromDeleteRequestEvent, historyLoggerProvider, HistoryRepository, isSubscriptionPaymentAction, _isUndoable (+9 more)

### Community 45 - "subscribersRepositoryProvider"
Cohesion: 0.12
Nodes (18): _syncDueDebts, _buildBody, subscribersRepositoryProvider, _confirmAndDeleteDebt, _confirmAndPayDebt, _confirmAndUnpayDebt, _exportStatement, _exportSubscriberStatement (+10 more)

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
Cohesion: 0.14
Nodes (16): _RefreshOnChange, authStateProvider, currentAppUserProvider, build, _ChatConversationScreenState, _markRead, _sendMessage, chatMessagesStreamProvider (+8 more)

### Community 50 - "_InboxScreenState"
Cohesion: 0.27
Nodes (10): employeesStreamProvider, cashboxLedgerStreamProvider, build, _buildAdminStaffDebtsTab, CashboxScreen, _CashboxScreenState, chatThreadsStreamProvider, chatThreadStreamProvider (+2 more)

### Community 51 - "StatelessWidget"
Cohesion: 0.13
Nodes (14): _SplashScreen, _UpdateCheckErrorScreen, _AuthLoadingScreen, _FeatureChip, _AdminBottomTabItem, _AvatarMini, _ChartLegend, _ModernKpiCard (+6 more)

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
Cohesion: 0.08
Nodes (19): StateError, dart:io, firebaseAuthProvider, firebaseMessagingProvider, FirebaseService, firebaseStorageProvider, firestoreProvider, init (+11 more)

### Community 58 - "cashboxStreamProvider"
Cohesion: 0.19
Nodes (13): expensesRepositoryProvider, _deleteExpense, ExpenseFormSheet, _ExpenseFormSheetState, _PayRecurringMonthDialog, _PayRecurringMonthDialogState, _RecurringExpenseMonthsDialog, _RecurringExpenseMonthsDialogState (+5 more)

### Community 59 - "advance_subscription_sheet.dart"
Cohesion: 0.11
Nodes (17): Subscriber, AdvanceSubscriptionSheet, _AdvanceSubscriptionSheetState, _amountController, _busy, by, createState, _cycles (+9 more)

### Community 60 - "suppliersRepositoryProvider"
Cohesion: 0.22
Nodes (9): suppliersRepositoryProvider, _save, SupplierBalanceTransactionSheet, _SupplierBalanceTransactionSheetState, _SupplierBalanceTransactionsTab, SupplierFormSheet, _SupplierFormSheetState, SupplierPaymentRequestSheet (+1 more)

### Community 61 - "formatters.dart"
Cohesion: 0.17
Nodes (9): addDays, calendarDaysBetween, CurrencyFormatter, date, DateFormatter, dateTime, format, monthLabel (+1 more)

### Community 62 - "auth_utils.dart"
Cohesion: 0.29
Nodes (5): buildEmployeeEmail, bytes, cleanAdmin, cleanUser, hash

### Community 63 - "../../core/models/models.dart"
Cohesion: 0.17
Nodes (6): _authRepo, init, _messaging, NotificationService, syncUserToken, _tokenRefreshSub

### Community 64 - "receipt_editor_dialog.dart"
Cohesion: 0.05
Nodes (37): _activeHandle, _applyAndSave, build, _buildCropCanvas, createState, _CropHandle, _CropOverlayPainter, _cropRect (+29 more)

### Community 65 - "MaterialPageRoute"
Cohesion: 0.33
Nodes (5): _buildEmployeeDashboardCard, _buildGeneralCashboxSummaryCard, _buildHeroLiquidityCard, _buildQuickActions, _openImagePreview

### Community 70 - "_ExpensesScreenState"
Cohesion: 0.40
Nodes (4): recurringExpensesStreamProvider, build, ExpensesScreen, _ExpensesScreenState

### Community 71 - "webNotificationsEnabledProvider"
Cohesion: 0.67
Nodes (3): build, initState, webNotificationsEnabledProvider

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
- **1293 isolated node(s):** `eslint:recommended`, `plugin:@typescript-eslint/recommended`, `@typescript-eslint/eslint-plugin`, `@typescript-eslint/parser`, `eslint` (+1288 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 1511 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **17 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Win32Window` connect `win32_window.cpp` to `string`?**
  _High betweenness centrality (0.035) - this node is a cross-community bridge._
- **What connects `eslint:recommended`, `plugin:@typescript-eslint/recommended`, `@typescript-eslint/eslint-plugin` to the rest of the system?**
  _1293 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `cashbox_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.02702702702702703 - nodes in this community are weakly interconnected._
- **Why does `AppCurrency` connect `preferences_providers.dart` to `cashbox_screen.dart`, `expenses_screen.dart`, `constants.dart`, `subscribers_screen.dart`, `suppliers_screen.dart`, `inbox_screen.dart`, `reports_screen.dart`, `models.dart`, `pdf_report_service.dart`?**
  _High betweenness centrality (0.030) - this node is a cross-community bridge._
- **Should `my_application.cc` be split into smaller, more focused modules?**
  _Cohesion score 0.05426356589147287 - nodes in this community are weakly interconnected._
- **Why does `AppUser` connect `record_payment_sheet.dart` to `cashbox_screen.dart`, `expenses_screen.dart`, `admin_shell.dart`, `subscribers_screen.dart`, `suppliers_screen.dart`, `models.dart`, `employees_screen.dart`, `advance_subscription_sheet.dart`?**
  _High betweenness centrality (0.014) - this node is a cross-community bridge._
- **Should `expenses_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.02857142857142857 - nodes in this community are weakly interconnected._