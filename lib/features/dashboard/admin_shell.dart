import '../../core/widgets/app_avatar.dart';
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
      error: (e, _) =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      data: (user) {
        if (user == null) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        final tabs = _visibleTabs(user);
        final idx = _index.clamp(0, tabs.length - 1);

        return LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 900;
            if (isDesktop) {
              return _buildDesktopShell(context, l, user, tabs, idx);
            }
            return _buildMobileShell(context, l, user, tabs, idx);
          },
        );
      },
    );
  }

  Widget _buildMobileShell(
    BuildContext context,
    AppLocalizations l,
    AppUser user,
    List<_Tab> tabs,
    int idx,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tabs[idx].label(l)),
        actions: [
          Consumer(
            builder: (context, ref, _) {
              final unread =
                  ref.watch(unreadNotificationsCountProvider).valueOrNull ?? 0;
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
              if (context.mounted) context.go('/login');
              await ref.read(authRepositoryProvider).signOut();
            },
            icon: const Icon(Icons.logout),
            tooltip: l.logout,
          ),
        ],
      ),
      body: _buildAnimatedTabBody(tabs, idx),
      bottomNavigationBar: _AdminBottomTabBar(
        tabs: tabs,
        selectedIndex: idx,
        localizations: l,
        onSelected: _selectTab,
      ),
    );
  }

  Widget _buildDesktopShell(
    BuildContext context,
    AppLocalizations l,
    AppUser user,
    List<_Tab> tabs,
    int idx,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0B1120)
          : const Color(0xFFF1F5F9),
      body: Row(
        children: [
          // Side Navigation Drawer (RTL-aware: placed on right in Arabic, left in English)
          Container(
            width: 268,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              border: BorderDirectional(
                end: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.45),
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Brand Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colorScheme.primary,
                              colorScheme.tertiary,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.router_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.appTitle,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'ISP Management Web',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.outline,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                ),
                const SizedBox(height: 12),
                // Navigation Links
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                    itemCount: tabs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (context, i) {
                      final tab = tabs[i];
                      final selected = i == idx;
                      final label = tab.label(l);
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _selectTab(i),
                          borderRadius: BorderRadius.circular(14),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 13,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? colorScheme.primaryContainer
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                              border: selected
                                  ? Border.all(
                                      color: colorScheme.primary
                                          .withValues(alpha: 0.25),
                                    )
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  tab.icon,
                                  size: 22,
                                  color: selected
                                      ? colorScheme.primary
                                      : colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    label,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: selected
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      color: selected
                                          ? colorScheme.onPrimaryContainer
                                          : colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                if (selected)
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Divider(
                  height: 1,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                ),
                // User Profile & Logout Footer in Sidebar
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () => context.push('/profile'),
                          borderRadius: BorderRadius.circular(20),
                          child: _AvatarMini(user: user),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () => context.push('/profile'),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.displayName.isEmpty
                                      ? l.employee
                                      : user.displayName,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  user.isAdmin ? l.admin : l.employee,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.outline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () async {
                            if (context.mounted) context.go('/login');
                            await ref.read(authRepositoryProvider).signOut();
                          },
                          icon: const Icon(Icons.logout_rounded, size: 20),
                          tooltip: l.logout,
                          color: colorScheme.error,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main Web Content Area
          Expanded(
            child: Column(
              children: [
                // Top Web Navbar
                Container(
                  height: 68,
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                    border: Border(
                      bottom: BorderSide(
                        color:
                            colorScheme.outlineVariant.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        tabs[idx].icon,
                        color: colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        tabs[idx].label(l),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      Consumer(
                        builder: (context, ref, _) {
                          final unread = ref
                                  .watch(unreadNotificationsCountProvider)
                                  .valueOrNull ??
                              0;
                          return FilledButton.tonalIcon(
                            onPressed: () => NotificationsSheet.show(context),
                            icon: Badge(
                              isLabelVisible: unread > 0,
                              label: Text('$unread'),
                              child: const Icon(
                                Icons.notifications_outlined,
                                size: 20,
                              ),
                            ),
                            label: Text(l.t('notifications')),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        onPressed: () => context.push('/profile'),
                        icon: _AvatarMini(user: user),
                        label: Text(
                          user.displayName.isEmpty
                              ? l.profile
                              : user.displayName,
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Centered Content Body with MaxWidth
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1320),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: _buildAnimatedTabBody(tabs, idx),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedTabBody(List<_Tab> tabs, int idx) {
    return AnimatedSwitcher(
      duration: _pageSwitchDuration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final offsetAnimation = Tween<Offset>(
          begin: const Offset(0.02, 0),
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
    return AppAvatar(
      photoUrl: user.photoUrl,
      name: user.displayName,
      radius: 16,
    );
  }
}
