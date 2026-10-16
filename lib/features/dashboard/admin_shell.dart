import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/models/models.dart';
import '../../l10n/app_localizations.dart';
import '../auth/auth_repository.dart';
import '../employees/employees_screen.dart';
import '../expenses/expenses_screen.dart';
import '../finance/cashbox_screen.dart';
import '../history/history_screen.dart';
import '../inbox/inbox_screen.dart';
import '../reports/reports_screen.dart';
import '../notifications/notifications_repository.dart';
import '../notifications/notifications_sheet.dart';
import '../settings/settings_screen.dart';
import '../subscribers/subscribers_screen.dart';
import '../suppliers/suppliers_screen.dart';
import 'dashboard_screen.dart';

class _Tab {
  final String Function(AppLocalizations) label;
  final IconData icon;
  final WidgetBuilder builder;
  final Permission? permission;
  final bool Function(AppUser)? customCheck;
  final bool adminOnly;
  const _Tab({
    required this.label,
    required this.icon,
    required this.builder,
    this.permission,
    this.customCheck,
    this.adminOnly = false,
  });
}

class AdminShell extends ConsumerStatefulWidget {
  const AdminShell({super.key});

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  static const _pageSwitchDuration = Duration(milliseconds: 260);

  int _index = 0;

  static final _tabs = <_Tab>[
    _Tab(
      label: (l) => l.dashboard,
      icon: Icons.dashboard_outlined,
      builder: (_) => const DashboardScreen(),
    ),
    _Tab(
      label: (l) => l.subscribers,
      icon: Icons.people_outline,
      builder: (_) => const SubscribersScreen(),
      customCheck: (u) =>
          u.can(Permission.viewSubscribers) ||
          u.can(Permission.addSubscriber),
    ),
    _Tab(
      label: (l) => l.suppliers,
      icon: Icons.local_shipping_outlined,
      builder: (_) => const SuppliersScreen(),
      customCheck: (u) =>
          u.can(Permission.viewSuppliers) ||
          u.can(Permission.manageSuppliers) ||
          u.can(Permission.notifySupplierPayment) ||
          u.can(Permission.manageSupplierPurchases),
    ),
    _Tab(
      label: (l) => l.expenses,
      icon: Icons.receipt_long_outlined,
      builder: (_) => const ExpensesScreen(),
    ),
    _Tab(
      label: (l) => l.t('cashbox'),
      icon: Icons.savings_outlined,
      builder: (_) => const CashboxScreen(),
    ),
    _Tab(
      label: (l) => l.employees,
      icon: Icons.badge_outlined,
      builder: (_) => const EmployeesScreen(),
      adminOnly: true,
    ),
    _Tab(
      label: (l) => l.inbox,
      icon: Icons.message_outlined,
      builder: (_) => const InboxScreen(),
    ),
    _Tab(
      label: (l) => l.reports,
      icon: Icons.bar_chart_outlined,
      builder: (_) => const ReportsScreen(),
      permission: Permission.viewReports,
    ),
    _Tab(
      label: (l) => l.history,
      icon: Icons.history,
      builder: (_) => const HistoryScreen(),
      permission: Permission.viewHistory,
    ),
    _Tab(
      label: (l) => l.settings,
      icon: Icons.settings_outlined,
      builder: (_) => const SettingsScreen(),
    ),
  ];

  List<_Tab> _visibleTabs(AppUser user) {
    return _tabs.where((t) {
      if (t.adminOnly && !user.isAdmin) return false;
      if (t.permission != null && !user.can(t.permission!)) return false;
      if (t.customCheck != null && !t.customCheck!(user)) return false;
      return true;
    }).toList();
  }

  void _selectTab(int index) {
    if (index == _index) return;
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final userAsync = ref.watch(currentAppUserProvider);
    return userAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (user) {
        if (user == null) {
          return Scaffold(body: Center(child: Text(l.pleaseSignIn)));
        }
        final tabs = _visibleTabs(user);
        final idx = _index.clamp(0, tabs.length - 1);
        return Scaffold(
          appBar: AppBar(
            title: Text(tabs[idx].label(l)),
            actions: [
              Consumer(
                builder: (context, ref, _) {
                  final unread =
                      ref.watch(unreadNotificationsCountProvider).valueOrNull ??
                          0;
                  return IconButton(
                    onPressed: () => NotificationsSheet.show(context),
                    icon: Badge(
                      isLabelVisible: unread > 0,
                      label: Text('$unread'),
                      child: const Icon(Icons.notifications_outlined),
                    ),
                    tooltip: l.t('notifications'),
                  );
                },
              ),
              IconButton(
                onPressed: () => context.push('/profile'),
                icon: _AvatarMini(user: user),
                tooltip: l.profile,
              ),
              IconButton(
                onPressed: () async {
                  await ref.read(authRepositoryProvider).signOut();
                  if (context.mounted) context.go('/login');
                },
                icon: const Icon(Icons.logout),
                tooltip: l.logout,
              ),
            ],
          ),
          body: AnimatedSwitcher(
            duration: _pageSwitchDuration,
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              final offsetAnimation = Tween<Offset>(
                begin: const Offset(0.04, 0),
                end: Offset.zero,
              ).animate(animation);
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: offsetAnimation,
                  child: child,
                ),
              );
            },
            child: KeyedSubtree(
              key: ValueKey<_Tab>(tabs[idx]),
              child: tabs[idx].builder(context),
            ),
          ),
          bottomNavigationBar: _AdminBottomTabBar(
            tabs: tabs,
            selectedIndex: idx,
            localizations: l,
            onSelected: _selectTab,
          ),
        );
      },
    );
  }
}

class _AdminBottomTabBar extends StatefulWidget {
  const _AdminBottomTabBar({
    required this.tabs,
    required this.selectedIndex,
    required this.localizations,
    required this.onSelected,
  });

  final List<_Tab> tabs;
  final int selectedIndex;
  final AppLocalizations localizations;
  final ValueChanged<int> onSelected;

  @override
  State<_AdminBottomTabBar> createState() => _AdminBottomTabBarState();
}

class _AdminBottomTabBarState extends State<_AdminBottomTabBar> {
  static const _scrollDuration = Duration(milliseconds: 360);

  final _scrollController = ScrollController();
  var _itemKeys = <GlobalKey>[];

  @override
  void initState() {
    super.initState();
    _syncKeys();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showSelectedTab());
  }

  @override
  void didUpdateWidget(covariant _AdminBottomTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tabs.length != widget.tabs.length) {
      _syncKeys();
    }
    if (oldWidget.selectedIndex != widget.selectedIndex ||
        oldWidget.tabs.length != widget.tabs.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showSelectedTab());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _syncKeys() {
    _itemKeys = List.generate(widget.tabs.length, (_) => GlobalKey());
  }

  void _showSelectedTab() {
    if (!mounted || widget.tabs.isEmpty) return;
    final selectedIndex = widget.selectedIndex.clamp(0, widget.tabs.length - 1);
    final selectedContext = _itemKeys[selectedIndex].currentContext;
    if (selectedContext == null) return;

    Scrollable.ensureVisible(
      selectedContext,
      alignment: 0.5,
      alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
      duration: _scrollDuration,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surface,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Container(
          height: 74,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.45),
              ),
            ),
          ),
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              children: [
                for (var i = 0; i < widget.tabs.length; i++)
                  Padding(
                    key: _itemKeys[i],
                    padding: EdgeInsetsDirectional.only(
                      end: i == widget.tabs.length - 1 ? 0 : 8,
                    ),
                    child: _AdminBottomTabItem(
                      icon: widget.tabs[i].icon,
                      label: widget.tabs[i].label(widget.localizations),
                      selected: i == widget.selectedIndex,
                      onTap: () => widget.onSelected(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminBottomTabItem extends StatelessWidget {
  const _AdminBottomTabItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final labelStyle = theme.textTheme.labelMedium ??
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w600);
    final foreground = selected
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant;

    return Tooltip(
      message: label,
      preferBelow: false,
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: AnimatedScale(
          scale: selected ? 1 : 0.96,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(18),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                height: 52,
                constraints: BoxConstraints(
                  minWidth: selected ? 130 : 92,
                  maxWidth: selected ? 178 : 130,
                ),
                padding: EdgeInsetsDirectional.only(
                  start: selected ? 14 : 12,
                  end: selected ? 16 : 12,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? colorScheme.primaryContainer
                      : colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.45,
                        ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: selected
                        ? colorScheme.primary.withValues(alpha: 0.32)
                        : colorScheme.outlineVariant.withValues(alpha: 0.72),
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.18),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      color: foreground,
                      size: selected ? 24 : 22,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        style: labelStyle.copyWith(
                          color: foreground,
                          fontWeight:
                              selected ? FontWeight.w800 : FontWeight.w600,
                          height: 1,
                        ),
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AvatarMini extends StatelessWidget {
  const _AvatarMini({required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final initials = user.displayName.isNotEmpty
        ? user.displayName.trim().substring(0, 1).toUpperCase()
        : '?';
    if (user.photoUrl != null && user.photoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 16,
        backgroundImage: CachedNetworkImageProvider(user.photoUrl!),
      );
    }
    return CircleAvatar(radius: 16, child: Text(initials));
  }
}
