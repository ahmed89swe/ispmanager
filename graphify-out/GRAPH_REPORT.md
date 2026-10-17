# Graph Report - isp_user_manager  (2026-10-17)

## Corpus Check
- 99 files · ~84,470 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 58 file(s) not represented in the graph (top: (none) 9, .xcconfig 8, .xml 7)

## Summary
- 1887 nodes · 2705 edges · 79 communities (66 shown, 13 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 17 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `3c7f472a`
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
- ../../l10n/app_localizations.dart
- manifest.json
- pdf_report_service.dart
- authRepositoryProvider
- auth_repository.dart
- profile_screen.dart
- app_localizations.dart
- constants.dart
- advance_subscription_sheet.dart
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
- app.dart
- app_theme.dart
- app_avatar.dart
- auth_utils.dart
- StatelessWidget
- package:flutter/material.dart
- notifications_repository.dart
- utils.cpp
- main.dart
- MainActivity.kt
- expensesRepositoryProvider
- NotificationsSheet
- ConsumerWidget
- formatters.dart
- profile_repository.dart
- ../../core/models/models.dart
- _AdminBottomTabBar
- payments_repository.dart
- AppLocalizations
- isp_user_manager
- LaunchImage.imageset/README.md
- package:flutter/foundation.dart
- _ChatConversationScreenState
- RecurringExpenseFormSheet
- Map
- _InboxScreenState

## God Nodes (most connected - your core abstractions)
1. `currentAppUserProvider` - 41 edges
2. `Win32Window` - 21 edges
3. `subscribersRepositoryProvider` - 18 edges
4. `compilerOptions` - 13 edges
5. `cashboxStreamProvider` - 13 edges
6. `currencyProvider` - 13 edges
7. `expensesRepositoryProvider` - 12 edges
8. `_InboxScreenState` - 12 edges
9. `AppCurrency` - 11 edges
10. `_DashboardScreenState` - 11 edges

## Surprising Connections (you probably didn't know these)
- `build` --references--> `currentAppUserProvider`  [EXTRACTED]
  lib/features/dashboard/admin_shell.dart → lib/features/auth/auth_repository.dart
- `build` --references--> `currentAppUserProvider`  [EXTRACTED]
  lib/features/inbox/inbox_screen.dart → lib/features/auth/auth_repository.dart
- `_submit` --references--> `currentAppUserProvider`  [EXTRACTED]
  lib/features/payments/advance_subscription_sheet.dart → lib/features/auth/auth_repository.dart
- `_save` --references--> `currentAppUserProvider`  [EXTRACTED]
  lib/features/payments/record_payment_sheet.dart → lib/features/auth/auth_repository.dart
- `build` --references--> `currentAppUserProvider`  [EXTRACTED]
  lib/features/profile/profile_screen.dart → lib/features/auth/auth_repository.dart

## Import Cycles
- None detected.

## Communities (79 total, 13 thin omitted)

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
Cohesion: 0.08
Nodes (32): ListView, Locale, UnimplementedError, build, IspUserManagerApp, _MainAppRouter, routerProvider, AppColorTheme (+24 more)

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

### Community 12 - "currentAppUserProvider"
Cohesion: 0.20
Nodes (24): currentAppUserProvider, build, _DashboardScreenState, expensesStreamProvider, build, cashboxLedgerStreamProvider, cashboxStreamProvider, build (+16 more)

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
Cohesion: 0.09
Nodes (27): Center, ListTile, Padding, Scaffold, SizedBox, SnackBar, Employee, employeesRepositoryProvider (+19 more)

### Community 21 - ".eslintrc.json"
Cohesion: 0.12
Nodes (16): env, es2020, node, extends, ignorePatterns, parser, parserOptions, ecmaVersion (+8 more)

### Community 22 - "package:flutter_riverpod/flutter_riverpod.dart"
Cohesion: 0.15
Nodes (5): GoRouter, Scaffold, build, _RefreshOnChange, authStateProvider

### Community 23 - "expenses_repository.dart"
Cohesion: 0.08
Nodes (23): StateError, add, authUser, _col, createDeleteRequest, _db, decideDeleteRequest, delete (+15 more)

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
Cohesion: 0.33
Nodes (6): cashboxRepositoryProvider, _ClaimReimbursementRequestSheet, _ClaimReimbursementRequestSheetState, _DirectAdjustmentSheet, _DirectAdjustmentSheetState, _submit

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
Cohesion: 0.27
Nodes (7): authRepositoryProvider, _employeeSignIn, _googleSignIn, _buildDesktopShell, _buildMobileShell, _buildHeaderGreeting, unreadNotificationsCountProvider

### Community 32 - "auth_repository.dart"
Cohesion: 0.11
Nodes (17): AppUser, GoogleSignIn, StateError, addFcmToken, _auth, authStateChanges, currentAppUser, currentAppUserStream (+9 more)

### Community 33 - "profile_screen.dart"
Cohesion: 0.12
Nodes (15): ListView, Scaffold, SizedBox, profileRepositoryProvider, build, _busy, createState, dispose (+7 more)

### Community 34 - "app_localizations.dart"
Cohesion: 0.01
Nodes (131): addExpense, addNew, addSubscriber, admin, adminEmail, all, amount, approve (+123 more)

### Community 35 - "constants.dart"
Cohesion: 0.09
Nodes (19): all, code, ExpenseCategory, ExpenseEntryType, fromCode, fromName, manageSupplierPurchases, MoneyStorage (+11 more)

### Community 36 - "advance_subscription_sheet.dart"
Cohesion: 0.06
Nodes (29): Padding, SizedBox, Subscriber, AdvanceSubscriptionSheet, _AdvanceSubscriptionSheetState, _amountController, build, _busy (+21 more)

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
Cohesion: 0.11
Nodes (15): StateError, AppUpdateInfo, AppUpdateRepository, appUpdateRepositoryProvider, check, currentVersion, debugMessage, downloadUrl (+7 more)

### Community 42 - "suppliers_repository.dart"
Cohesion: 0.06
Nodes (30): StateError, add, addBalanceTransaction, addPackage, addPurchase, applyPaymentToPurchase, authUser, _balanceCol (+22 more)

### Community 43 - "ConsumerState"
Cohesion: 0.12
Nodes (19): AdminShell, _AdminShellState, DashboardScreen, ExpenseFormSheet, _ExpenseFormSheetState, _PayRecurringMonthDialog, _PayRecurringMonthDialogState, _SettleStaffDebtSheet (+11 more)

### Community 44 - "history_repository.dart"
Cohesion: 0.09
Nodes (19): StateError, now, null, tsToDate, authUser, _db, eventData, _expenseIdFromDeleteRequestEvent (+11 more)

### Community 45 - "subscribersRepositoryProvider"
Cohesion: 0.18
Nodes (11): _syncDueDebts, _buildBody, subscribersRepositoryProvider, AddSubscriberDebtSheet, _AddSubscriberDebtSheetState, _confirmAndDeleteDebt, _confirmAndPayDebt, _exportStatement (+3 more)

### Community 46 - "employees_repository.dart"
Cohesion: 0.11
Nodes (17): authUser, _col, create, _db, delete, EmployeesRepository, _imageContentType, _logger (+9 more)

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
Cohesion: 0.29
Nodes (5): buildEmployeeEmail, bytes, cleanAdmin, cleanUser, hash

### Community 51 - "StatelessWidget"
Cohesion: 0.14
Nodes (13): _SplashScreen, _AuthLoadingScreen, _FeatureChip, _AdminBottomTabItem, _AvatarMini, _ChartLegend, _ModernKpiCard, _QuickActionButton (+5 more)

### Community 53 - "notifications_repository.dart"
Cohesion: 0.15
Nodes (11): _col, _db, delete, markAllAsRead, markAsRead, NotificationsRepository, ref, sendNotification (+3 more)

### Community 54 - "utils.cpp"
Cohesion: 0.19
Nodes (4): wWinMain(), CreateAndAttachConsole(), GetCommandLineArguments(), Utf8FromUtf16()

### Community 55 - "main.dart"
Cohesion: 0.15
Nodes (5): _firebaseMessagingBackgroundHandler, init, main, prefs, setPreferredOrientations

### Community 58 - "expensesRepositoryProvider"
Cohesion: 0.25
Nodes (8): expensesRepositoryProvider, _deleteExpense, _RecurringExpenseMonthsDialog, _RecurringExpenseMonthsDialogState, _save, _submit, _undoExistingPayment, _unpayMonth

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
Cohesion: 0.13
Nodes (11): StateError, dart:io, _auth, _db, _imageContentType, ProfileRepository, removeAvatar, _storage (+3 more)

### Community 63 - "../../core/models/models.dart"
Cohesion: 0.15
Nodes (8): AppUser, _authRepo, init, _messaging, NotificationService, syncUserToken, _tokenRefreshSub, AuthRepository

### Community 64 - "_AdminBottomTabBar"
Cohesion: 0.40
Nodes (4): _AdminBottomTabBar, _AdminBottomTabBarState, _EmployeeAccountStatementSheet, _EmployeeAccountStatementSheetState

### Community 65 - "payments_repository.dart"
Cohesion: 0.17
Nodes (8): HistoryLogger, _db, _logger, _notificationsRepo, PaymentsRepository, record, watchAll, watchForSubscriber

### Community 70 - "package:flutter/foundation.dart"
Cohesion: 0.20
Nodes (6): UnsupportedError, android, DefaultFirebaseOptions, ios, web, windows

### Community 71 - "_ChatConversationScreenState"
Cohesion: 0.29
Nodes (7): build, ChatConversationScreen, _ChatConversationScreenState, _markRead, _sendMessage, chatMessagesStreamProvider, chatRepositoryProvider

### Community 80 - "_InboxScreenState"
Cohesion: 0.20
Nodes (11): employeesStreamProvider, recurringExpensesStreamProvider, ExpensesScreen, _ExpensesScreenState, reimbursementRequestsStreamProvider, chatThreadsStreamProvider, chatThreadStreamProvider, _buildChatsTab (+3 more)

## Knowledge Gaps
- **1191 isolated node(s):** `eslint:recommended`, `plugin:@typescript-eslint/recommended`, `@typescript-eslint/eslint-plugin`, `@typescript-eslint/parser`, `eslint` (+1186 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 1399 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **13 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Win32Window` connect `win32_window.cpp` to `flutter_window.h`?**
  _High betweenness centrality (0.030) - this node is a cross-community bridge._
- **What connects `eslint:recommended`, `plugin:@typescript-eslint/recommended`, `@typescript-eslint/eslint-plugin` to the rest of the system?**
  _1191 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `cashbox_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.02666666666666667 - nodes in this community are weakly interconnected._
- **Why does `AppCurrency` connect `preferences_providers.dart` to `cashbox_screen.dart`, `expenses_screen.dart`, `constants.dart`, `subscribers_screen.dart`, `suppliers_screen.dart`, `inbox_screen.dart`, `reports_screen.dart`, `models.dart`, `pdf_report_service.dart`?**
  _High betweenness centrality (0.029) - this node is a cross-community bridge._
- **Should `my_application.cc` be split into smaller, more focused modules?**
  _Cohesion score 0.05426356589147287 - nodes in this community are weakly interconnected._
- **Why does `AppUser` connect `../../core/models/models.dart` to `cashbox_screen.dart`, `expenses_screen.dart`, `admin_shell.dart`, `subscribers_screen.dart`, `suppliers_screen.dart`, `models.dart`, `employees_screen.dart`?**
  _High betweenness centrality (0.014) - this node is a cross-community bridge._
- **Should `expenses_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.02857142857142857 - nodes in this community are weakly interconnected._