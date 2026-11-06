import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_theme.dart';
import '../../core/constants.dart';
import '../../core/services/web_notification_helper.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/providers/preferences_providers.dart';
import '../auth/auth_repository.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final webColorTheme = ref.watch(webColorThemeProvider);
    final webNotifsEnabled = ref.watch(webNotificationsEnabledProvider);
    final locale = ref.watch(localeProvider);
    final currency = ref.watch(currencyProvider);
    final defaultAutoRenewMode = ref.watch(defaultAutoRenewModeProvider);
    final defaultAutoRenewDays = ref.watch(defaultAutoRenewDaysProvider);
    final defaultAutoRenewDayOfMonth =
        ref.watch(defaultAutoRenewDayOfMonthProvider);
    final isArabic = locale.languageCode.startsWith('ar');
    final uiTheme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          decoration: AppTheme.cardDecoration(context),
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.brightness_6_outlined,
                    color: uiTheme.colorScheme.primary),
                title: Text(l.theme),
                trailing: DropdownButton<ThemeMode>(
                  value: themeMode,
                  onChanged: (v) {
                    if (v != null) {
                      ref.read(themeModeProvider.notifier).set(v);
                      final user = ref.read(currentAppUserProvider).valueOrNull;
                      if (user != null) {
                        ref
                            .read(authRepositoryProvider)
                            .saveUserThemePreference(
                              user: user,
                              themeMode: v.name,
                            );
                      }
                    }
                  },
                  items: [
                    DropdownMenuItem(
                        value: ThemeMode.system, child: Text(l.themeSystem)),
                    DropdownMenuItem(
                        value: ThemeMode.light, child: Text(l.themeLight)),
                    DropdownMenuItem(
                        value: ThemeMode.dark, child: Text(l.themeDark)),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading:
                    Icon(Icons.translate, color: uiTheme.colorScheme.primary),
                title: Text(l.language),
                trailing: DropdownButton<String>(
                  value: locale.languageCode,
                  underline: const SizedBox.shrink(),
                  onChanged: (v) {
                    if (v != null) {
                      ref.read(localeProvider.notifier).set(Locale(v));
                    }
                  },
                  items: const [
                    DropdownMenuItem(value: 'ar', child: Text('العربية')),
                    DropdownMenuItem(value: 'en', child: Text('English')),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.attach_money,
                    color: uiTheme.colorScheme.primary),
                title: Text(l.defaultCurrency),
                trailing: DropdownButton<AppCurrency>(
                  value: currency,
                  underline: const SizedBox.shrink(),
                  onChanged: (v) {
                    if (v != null) ref.read(currencyProvider.notifier).set(v);
                  },
                  items: AppCurrency.values
                      .map((c) =>
                          DropdownMenuItem(value: c, child: Text(c.code)))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.cardDecoration(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.autorenew_rounded,
                    color: uiTheme.colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isArabic
                              ? 'خيارات التجديد التلقائي الافتراضية'
                              : 'Default Auto-Renewal Options',
                          style: uiTheme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isArabic
                              ? 'اختر نظام التجديد التلقائي الافتراضي للمشتركين (بعد أيام محددة مثل 30 يوم، أو يوم ثابت من كل شهر)'
                              : 'Choose default auto-renewal mode (after fixed days like 30 days, or a fixed day of each month)',
                          style: uiTheme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SegmentedButton<AutoRenewMode>(
                segments: [
                  ButtonSegment(
                    value: AutoRenewMode.fixedIntervalDays,
                    icon: const Icon(Icons.timelapse_rounded, size: 18),
                    label: Text(
                      isArabic
                          ? 'بعد أيام محددة (مثل 30 يوم)'
                          : 'After Fixed Days (e.g. 30d)',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  ButtonSegment(
                    value: AutoRenewMode.fixedMonthlyDay,
                    icon: const Icon(Icons.calendar_month_rounded, size: 18),
                    label: Text(
                      isArabic
                          ? 'وقت ثابت (يوم ثابت من كل شهر)'
                          : 'Fixed Monthly Day',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
                selected: {defaultAutoRenewMode},
                onSelectionChanged: (set) {
                  ref
                      .read(defaultAutoRenewModeProvider.notifier)
                      .set(set.first);
                },
              ),
              const SizedBox(height: 12),
              if (defaultAutoRenewMode == AutoRenewMode.fixedIntervalDays)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      isArabic
                          ? 'عدد الأيام الافتراضي للدورة:'
                          : 'Default Cycle Days:',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    for (final d in [15, 28, 30, 31])
                      ChoiceChip(
                        label: Text(isArabic ? '$d يوم' : '$d days'),
                        selected: defaultAutoRenewDays == d,
                        onSelected: (_) {
                          ref.read(defaultAutoRenewDaysProvider.notifier).set(d);
                        },
                      ),
                  ],
                )
              else
                DropdownButtonFormField<int>(
                  value: defaultAutoRenewDayOfMonth.clamp(1, 31),
                  decoration: InputDecoration(
                    labelText: isArabic
                        ? 'اليوم الثابت للتجديد من كل شهر'
                        : 'Fixed Renewal Day of Each Month',
                    border: const OutlineInputBorder(),
                    isDense: true,
                    prefixIcon:
                        const Icon(Icons.event_repeat_rounded, size: 18),
                  ),
                  items: [
                    for (int d = 1; d <= 31; d++)
                      DropdownMenuItem(
                        value: d,
                        child: Text(
                          isArabic
                              ? 'يوم $d من كل شهر'
                              : 'Day $d of each month',
                        ),
                      ),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      ref
                          .read(defaultAutoRenewDayOfMonthProvider.notifier)
                          .set(v);
                    }
                  },
                ),
            ],
          ),
        ),
        if (kIsWeb) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AppTheme.cardDecoration(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.notifications_active_outlined,
                      color: uiTheme.colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isArabic
                                ? 'إشعارات صفحة الويب'
                                : 'Web Page Notifications',
                            style: uiTheme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isArabic
                                ? 'تلقي إشعارات فورية وتنبيهات المتصفح عند وصول أي إشعار جديد على الويب'
                                : 'Receive real-time alerts and browser notifications on Web',
                            style: uiTheme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: webNotifsEnabled,
                      onChanged: (v) async {
                        await ref
                            .read(webNotificationsEnabledProvider.notifier)
                            .set(v);
                        if (v) {
                          await WebNotificationHelper.requestPermission();
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () async {
                        final status =
                            await WebNotificationHelper.requestPermission();
                        if (!context.mounted) return;
                        final msg = status == 'granted'
                            ? (isArabic
                                ? 'تم تفعيل إشعارات المتصفح بنجاح ✓'
                                : 'Browser notifications enabled ✓')
                            : (isArabic
                                ? 'حالة إذن إشعارات المتصفح: $status'
                                : 'Browser notification permission: $status');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(msg)),
                        );
                      },
                      icon: const Icon(Icons.browser_updated_rounded, size: 18),
                      label: Text(
                        isArabic
                            ? 'تفعيل إشعارات المتصفح'
                            : 'Allow Browser Notifications',
                      ),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () async {
                        await WebNotificationHelper.requestPermission();
                        WebNotificationHelper.showNotification(
                          title: isArabic
                              ? 'إشعار تجريبي — ISP Manager'
                              : 'Test Notification — ISP Manager',
                          body: isArabic
                              ? 'ميزة تلقي الإشعارات على صفحة الويب تعمل بنجاح!'
                              : 'Web page notifications are working properly!',
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isArabic
                                  ? 'تم إرسال إشعار تجريبي على صفحة الويب ✓'
                                  : 'Test notification sent on Web ✓',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.notifications_none_rounded,
                          size: 18),
                      label: Text(
                        isArabic ? 'تجربة إشعار' : 'Test Notification',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AppTheme.cardDecoration(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.palette_outlined,
                        color: uiTheme.colorScheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isArabic
                                ? 'ثيمات الويب (ألوان الواجهة)'
                                : 'Web Interface Color Themes',
                            style: uiTheme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isArabic
                                ? 'اختر الثيم اللوني المفضل لنسخة الويب'
                                : 'Choose your preferred color palette for the Web version',
                            style: uiTheme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: AppColorTheme.values.map((palette) {
                    final selected = palette == webColorTheme;
                    return InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        ref.read(webColorThemeProvider.notifier).set(palette);
                        final user =
                            ref.read(currentAppUserProvider).valueOrNull;
                        if (user != null) {
                          ref
                              .read(authRepositoryProvider)
                              .saveUserThemePreference(
                                user: user,
                                webColorTheme: palette.name,
                              );
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: selected
                              ? palette.previewColor.withValues(alpha: 0.16)
                              : uiTheme.colorScheme.surface
                                  .withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selected
                                ? palette.previewColor
                                : AppTheme.cardBorderColor(context),
                            width: selected ? 2.0 : 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: palette.previewColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: palette.previewColor
                                        .withValues(alpha: 0.4),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: selected
                                  ? const Icon(Icons.check,
                                      size: 14, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              palette.label(locale.languageCode),
                              style: TextStyle(
                                fontWeight: selected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: selected
                                    ? palette.previewColor
                                    : uiTheme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: AppTheme.cardDecoration(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color:
                          uiTheme.colorScheme.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.info_outline_rounded,
                      color: uiTheme.colorScheme.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isArabic ? 'حول التطبيق' : 'About the Application',
                          style: uiTheme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isArabic
                              ? 'ISP Manager - نظام متكامل لإدارة شبكات ومشتركي الإنترنت والحسابات المالية'
                              : 'ISP Manager - Complete ISP Subscribers & Financial Management System',
                          style: uiTheme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Divider(height: 1),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: uiTheme.colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: uiTheme.colorScheme.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: uiTheme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified_user_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isArabic ? 'إعداد وتطوير' : 'Developed By',
                            style: uiTheme.textTheme.labelMedium?.copyWith(
                              color: uiTheme.colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isArabic
                                ? 'مهندس البرمجيات أحمد طه'
                                : 'Software Engineer Ahmed Taha (مهندس البرمجيات أحمد طه)',
                            style: uiTheme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isArabic
                                ? 'ماجستير في هندسة البرمجيات - اختصاص أمن وسرية المعلومات'
                                : 'M.Sc. in Software Engineering - Information Security & Privacy',
                            style: uiTheme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: uiTheme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
