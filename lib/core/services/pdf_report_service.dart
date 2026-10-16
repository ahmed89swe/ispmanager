import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../constants.dart';
import '../models/models.dart';
import '../utils/formatters.dart';

class PdfReportData {
  PdfReportData({
    required this.title,
    required this.from,
    required this.to,
    required this.generatedBy,
    required this.currency,
    required this.locale,
    required this.kpis,
    required this.tableHeaders,
    required this.tableRows,
    this.subtitle,
    this.notes,
  });

  final String title;
  final String? subtitle;
  final DateTime from;
  final DateTime to;
  final String generatedBy;
  final AppCurrency currency;
  final String locale;
  final List<PdfKpi> kpis;
  final List<String> tableHeaders;
  final List<List<String>> tableRows;
  final String? notes;
}

class PdfKpi {
  PdfKpi(this.label, this.value, {this.highlight = false});
  final String label;
  final String value;
  final bool highlight;
}

class PdfReportService {
  pw.Font? _regular;
  pw.Font? _bold;
  List<pw.Font> _fallbacks = [];

  Future<void> _ensureFonts() async {
    if (_regular != null && _bold != null && _fallbacks.isNotEmpty) return;
    try {
      // Cairo has native matching Arabic and Latin character support (letters, digits, punctuation)
      final cairoReg = await PdfGoogleFonts.cairoRegular();
      final cairoBold = await PdfGoogleFonts.cairoBold();

      // Roboto provides complete ASCII and extended Latin glyph coverage
      final robotoReg = await PdfGoogleFonts.robotoRegular();
      final robotoBold = await PdfGoogleFonts.robotoBold();

      // Noto Sans Arabic provides additional Arabic contextual forms
      final notoSansReg = await PdfGoogleFonts.notoSansArabicRegular();
      final notoSansBold = await PdfGoogleFonts.notoSansArabicBold();

      _regular = cairoReg;
      _bold = cairoBold;
      _fallbacks = [
        robotoReg,
        robotoBold,
        notoSansReg,
        notoSansBold,
      ];
    } catch (e) {
      debugPrint('Fallback loading local fonts for PDF: $e');
      try {
        final fontData =
            await rootBundle.load('packages/pdf/fonts/Roboto-Regular.ttf');
        final roboto = pw.Font.ttf(fontData);
        _regular = roboto;
        _bold = roboto;
        _fallbacks = [roboto];
      } catch (_) {}
    }
  }

  Future<Uint8List> buildPdf(PdfReportData data) async {
    await _ensureFonts();
    final doc = pw.Document(
      title: data.title,
      author: data.generatedBy,
    );

    final isArabic = data.locale.startsWith('ar');
    final textDirection =
        isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr;

    final theme = pw.ThemeData.withFont(
      base: _regular!,
      bold: _bold!,
      fontFallback: _fallbacks,
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        margin: const pw.EdgeInsets.fromLTRB(28, 32, 28, 32),
        textDirection: textDirection,
        header: (ctx) => _buildHeader(data, isArabic),
        footer: (ctx) => _buildFooter(ctx, isArabic),
        build: (ctx) => [
          _buildMeta(data, isArabic),
          pw.SizedBox(height: 12),
          if (data.kpis.isNotEmpty) ...[
            _buildKpiGrid(data),
            pw.SizedBox(height: 16),
          ],
          if (data.tableRows.isNotEmpty) ...[
            pw.Text(
              isArabic ? 'تفاصيل العمليات' : 'Detailed Records',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey800,
              ),
            ),
            pw.SizedBox(height: 8),
            _buildTable(data),
          ] else ...[
            pw.Container(
              alignment: pw.Alignment.center,
              padding: const pw.EdgeInsets.all(24),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Text(
                isArabic
                    ? 'لا توجد عمليات ضمن الفترة المحددة'
                    : 'No records within the selected period',
                style: const pw.TextStyle(color: PdfColors.grey700),
              ),
            ),
          ],
          if (data.notes != null && data.notes!.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.amber50,
                border: pw.Border.all(color: PdfColors.amber200),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child:
                  pw.Text(data.notes!, style: const pw.TextStyle(fontSize: 10)),
            ),
          ],
        ],
      ),
    );

    return doc.save();
  }

  pw.Widget _buildHeader(PdfReportData data, bool isArabic) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.blueGrey300, width: 0.8),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                isArabic ? 'تقرير' : 'Report',
                style: const pw.TextStyle(
                    fontSize: 10, color: PdfColors.blueGrey500),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                data.title,
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blueGrey900,
                ),
              ),
              if (data.subtitle != null)
                pw.Text(data.subtitle!,
                    style: const pw.TextStyle(
                        fontSize: 10, color: PdfColors.blueGrey600)),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue700,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Text(
              'ISP Manager',
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(pw.Context ctx, bool isArabic) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300, width: 0.6),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            DateFormatter.dateTime(DateTime.now(),
                locale: isArabic ? 'ar' : 'en'),
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
          pw.Text(
            isArabic
                ? 'صفحة ${ctx.pageNumber} من ${ctx.pagesCount}'
                : 'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildMeta(PdfReportData data, bool isArabic) {
    final loc = isArabic ? 'ar' : 'en';
    final rows = [
      [
        isArabic ? 'الفترة' : 'Period',
        '${DateFormatter.date(data.from, locale: loc)}  →  ${DateFormatter.date(data.to, locale: loc)}',
      ],
      [isArabic ? 'العملة' : 'Currency', data.currency.code],
      [isArabic ? 'أعد بواسطة' : 'Generated by', data.generatedBy],
      [
        isArabic ? 'تاريخ الإصدار' : 'Generated at',
        DateFormatter.dateTime(DateTime.now(), locale: loc),
      ],
    ];
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.blueGrey50,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Wrap(
        spacing: 24,
        runSpacing: 6,
        children: rows
            .map((r) => pw.RichText(
                  text: pw.TextSpan(
                    children: [
                      pw.TextSpan(
                        text: '${r[0]}: ',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blueGrey700,
                        ),
                      ),
                      pw.TextSpan(
                        text: r[1],
                        style: const pw.TextStyle(
                            fontSize: 10, color: PdfColors.blueGrey900),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  pw.Widget _buildKpiGrid(PdfReportData data) {
    const cols = 3;
    final rows = <pw.Widget>[];
    for (var i = 0; i < data.kpis.length; i += cols) {
      final slice = data.kpis.skip(i).take(cols).toList();
      rows.add(pw.Row(
        children: [
          for (final k in slice) ...[
            pw.Expanded(child: _kpiBox(k)),
            pw.SizedBox(width: 6),
          ],
          for (var j = slice.length; j < cols; j++)
            pw.Expanded(child: pw.SizedBox()),
        ],
      ));
      rows.add(pw.SizedBox(height: 6));
    }
    return pw.Column(children: rows);
  }

  pw.Widget _kpiBox(PdfKpi k) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: pw.BoxDecoration(
        color: k.highlight ? PdfColors.blue50 : PdfColors.grey100,
        border: pw.Border.all(
          color: k.highlight ? PdfColors.blue300 : PdfColors.grey300,
          width: 0.5,
        ),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            k.label,
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            k.value,
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: k.highlight ? PdfColors.blue800 : PdfColors.blueGrey900,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTable(PdfReportData data) {
    return pw.TableHelper.fromTextArray(
      headers: data.tableHeaders,
      data: data.tableRows,
      headerStyle: pw.TextStyle(
        fontSize: 10,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700),
      cellStyle: const pw.TextStyle(fontSize: 9),
      cellHeight: 22,
      cellAlignment: pw.Alignment.centerLeft,
      oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.4),
    );
  }

  Future<void> share(PdfReportData data) async {
    final bytes = await buildPdf(data);
    await Printing.sharePdf(
      bytes: bytes,
      filename: '${data.title.replaceAll(' ', '_')}.pdf',
    );
  }

  Future<void> preview(PdfReportData data) async {
    await Printing.layoutPdf(
      onLayout: (_) async => buildPdf(data),
      name: data.title,
    );
  }

  Future<Uint8List> buildSubscriberStatementPdf({
    required Subscriber subscriber,
    required List<SubscriberDebt> debts,
    required List<Payment> payments,
    required String generatedBy,
    required String locale,
  }) async {
    await _ensureFonts();
    final doc = pw.Document(
      title: 'كشف حساب مشترك - ${subscriber.name}',
      author: generatedBy,
    );

    final isArabic = locale.startsWith('ar');
    final textDirection =
        isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr;
    final theme = pw.ThemeData.withFont(
      base: _regular!,
      bold: _bold!,
      fontFallback: _fallbacks,
    );

    final totalDebtsAmount = debts.fold<num>(0, (sum, d) => sum + d.amount);
    final totalPaidAmount = payments.fold<num>(0, (sum, p) => sum + p.amount);
    final remainingBalance = subscriber.balance;

    final sortedDebts = List<SubscriberDebt>.from(debts)
      ..sort((a, b) => b.periodStart.compareTo(a.periodStart));
    final sortedPayments = List<Payment>.from(payments)
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        margin: const pw.EdgeInsets.fromLTRB(28, 28, 28, 28),
        textDirection: textDirection,
        header: (ctx) => _buildCustomHeader(
          title: 'كشف حساب مشترك - سجل التفعيلات والتسديدات',
          subtitle: 'ISP Manager - نظام إدارة شبكات الإنترنت',
        ),
        footer: (ctx) => _buildCustomFooter(ctx, isArabic, generatedBy),
        build: (ctx) => [
          pw.SizedBox(height: 10),
          _buildSubscriberInfoCard(subscriber, locale),
          pw.SizedBox(height: 14),
          pw.Row(
            children: [
              _buildKpiCard(
                'إجمالي مبالغ التفعيلات',
                CurrencyFormatter.format(
                    totalDebtsAmount, subscriber.currency,
                    locale: locale),
                PdfColors.blueGrey800,
                PdfColors.blueGrey50,
              ),
              pw.SizedBox(width: 8),
              _buildKpiCard(
                'إجمالي المبالغ المسددة',
                CurrencyFormatter.format(totalPaidAmount, subscriber.currency,
                    locale: locale),
                PdfColors.green800,
                PdfColors.green50,
              ),
              pw.SizedBox(width: 8),
              _buildKpiCard(
                'صافي المتبقي بذمة المشترك',
                CurrencyFormatter.format(
                    remainingBalance, subscriber.currency,
                    locale: locale),
                remainingBalance > 0 ? PdfColors.red800 : PdfColors.blueGrey800,
                remainingBalance > 0 ? PdfColors.red50 : PdfColors.blueGrey50,
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            'سجل الاشتراكات والتفعيلات (${debts.length})',
            style: pw.TextStyle(
              fontSize: 12.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blueGrey800,
            ),
          ),
          pw.SizedBox(height: 6),
          if (sortedDebts.isEmpty)
            _buildEmptyBox('لا توجد اشتراكات أو تفعيلات مسجلة')
          else
            pw.TableHelper.fromTextArray(
              headers: [
                'الباقة',
                'بداية الاشتراك',
                'نهاية الاشتراك',
                'المبلغ',
                'المدفوع',
                'المتبقي',
                'الحالة'
              ],
              data: sortedDebts.map((d) {
                final statusStr = d.status == SubscriptionDebtStatus.paid
                    ? 'مدفوع بالكامل'
                    : d.status == SubscriptionDebtStatus.partiallyPaid
                        ? 'مدفوع جزئياً'
                        : 'غير مدفوع';
                return [
                  (d.packageName != null && d.packageName!.isNotEmpty)
                      ? d.packageName!
                      : 'باقة المشترك',
                  DateFormatter.date(d.periodStart, locale: locale),
                  DateFormatter.date(d.periodEnd, locale: locale),
                  CurrencyFormatter.format(d.amount, d.currency,
                      locale: locale),
                  CurrencyFormatter.format(d.paidAmount, d.currency,
                      locale: locale),
                  CurrencyFormatter.format(d.remaining, d.currency,
                      locale: locale),
                  statusStr,
                ];
              }).toList(),
              headerStyle: pw.TextStyle(
                  fontSize: 8.5,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.blue700),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellHeight: 20,
              oddRowDecoration:
                  const pw.BoxDecoration(color: PdfColors.grey100),
              border:
                  pw.TableBorder.all(color: PdfColors.grey300, width: 0.4),
            ),
          pw.SizedBox(height: 16),
          pw.Text(
            'سجل الدفعات والتسديدات (${payments.length})',
            style: pw.TextStyle(
              fontSize: 12.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blueGrey800,
            ),
          ),
          pw.SizedBox(height: 6),
          if (sortedPayments.isEmpty)
            _buildEmptyBox('لا توجد دفعات أو تسديدات مسجلة')
          else
            pw.TableHelper.fromTextArray(
              headers: [
                '#',
                'تاريخ التسديد',
                'المبلغ المسدد',
                'العملة',
                'طريقة الدفع',
                'ملاحظات'
              ],
              data: sortedPayments.asMap().entries.map((entry) {
                final idx = entry.key + 1;
                final p = entry.value;
                final destStr = p.receivedIn == MoneyStorage.personal
                    ? 'جيب الموظف'
                    : 'الصندوق العام';
                return [
                  '$idx',
                  DateFormatter.dateTime(p.recordedAt, locale: locale),
                  CurrencyFormatter.format(p.amount, p.currency,
                      locale: locale),
                  p.currency.code,
                  destStr,
                  p.note != null && p.note!.isNotEmpty ? p.note! : '-',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(
                  fontSize: 8.5,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.teal700),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellHeight: 20,
              oddRowDecoration:
                  const pw.BoxDecoration(color: PdfColors.grey100),
              border:
                  pw.TableBorder.all(color: PdfColors.grey300, width: 0.4),
            ),
        ],
      ),
    );

    return doc.save();
  }

  Future<void> previewSubscriberStatement({
    required Subscriber subscriber,
    required List<SubscriberDebt> debts,
    required List<Payment> payments,
    required String generatedBy,
    required String locale,
  }) async {
    await Printing.layoutPdf(
      onLayout: (_) async => buildSubscriberStatementPdf(
        subscriber: subscriber,
        debts: debts,
        payments: payments,
        generatedBy: generatedBy,
        locale: locale,
      ),
      name: 'كشف_حساب_${subscriber.name}',
    );
  }

  Future<Uint8List> buildSubscribersDebtReportPdf({
    required List<Subscriber> subscribers,
    List<SubscriberDebt>? allDebts,
    required String generatedBy,
    required String locale,
  }) async {
    await _ensureFonts();
    final doc = pw.Document(
      title: 'تقرير ديون المشتركين الشامل',
      author: generatedBy,
    );

    final isArabic = locale.startsWith('ar');
    final textDirection =
        isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr;
    final theme = pw.ThemeData.withFont(
      base: _regular!,
      bold: _bold!,
      fontFallback: _fallbacks,
    );

    final indebtedSubs = subscribers.where((s) => s.balance > 0).toList()
      ..sort((a, b) => b.balance.compareTo(a.balance));

    num totalDebtIqd = 0;
    num totalDebtUsd = 0;
    for (final s in indebtedSubs) {
      if (s.currency == AppCurrency.iqd) {
        totalDebtIqd += s.balance;
      } else {
        totalDebtUsd += s.balance;
      }
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        margin: const pw.EdgeInsets.fromLTRB(28, 28, 28, 28),
        textDirection: textDirection,
        header: (ctx) => _buildCustomHeader(
          title: 'تقرير ديون المشتركين الشامل',
          subtitle: 'ISP Manager - كشف بالذمم المالية ومستحقات المشتركين',
        ),
        footer: (ctx) => _buildCustomFooter(ctx, isArabic, generatedBy),
        build: (ctx) => [
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              _buildKpiCard(
                'إجمالي الديون (بالدينار)',
                CurrencyFormatter.format(totalDebtIqd, AppCurrency.iqd,
                    locale: locale),
                PdfColors.red800,
                PdfColors.red50,
              ),
              pw.SizedBox(width: 8),
              _buildKpiCard(
                'إجمالي الديون (بالدولار)',
                CurrencyFormatter.format(totalDebtUsd, AppCurrency.usd,
                    locale: locale),
                PdfColors.red800,
                PdfColors.red50,
              ),
              pw.SizedBox(width: 8),
              _buildKpiCard(
                'عدد المشتركين المدينين',
                '${indebtedSubs.length} مشترك',
                PdfColors.blueGrey800,
                PdfColors.blueGrey50,
              ),
              pw.SizedBox(width: 8),
              _buildKpiCard(
                'إجمالي كافة المشتركين',
                '${subscribers.length} مشترك',
                PdfColors.blueGrey800,
                PdfColors.blueGrey50,
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            'تفاصيل المشتركين المطلوبين للديون (${indebtedSubs.length})',
            style: pw.TextStyle(
              fontSize: 12.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blueGrey800,
            ),
          ),
          pw.SizedBox(height: 8),
          if (indebtedSubs.isEmpty)
            _buildEmptyBox('لا توجد أي ديون على المشتركين، جميع الحسابات مسددة!')
          else
            pw.TableHelper.fromTextArray(
              headers: [
                '#',
                'اسم المشترك',
                'رقم الهاتف',
                'المجهز',
                'الباقة',
                'مبلغ الدين',
                'العملة',
                'تاريخ الانتهاء',
                'الحالة'
              ],
              data: indebtedSubs.asMap().entries.map((entry) {
                final idx = entry.key + 1;
                final s = entry.value;
                final expiryStr =
                    DateFormatter.date(s.subscriptionEndsAt, locale: locale);
                final phoneStr =
                    (s.phone != null && s.phone!.isNotEmpty) ? s.phone! : '-';
                final supplierStr = (s.supplierName != null &&
                        s.supplierName!.isNotEmpty)
                    ? s.supplierName!
                    : '-';
                final packageStr = (s.packageName != null &&
                        s.packageName!.isNotEmpty)
                    ? s.packageName!
                    : (s.planName != null && s.planName!.isNotEmpty
                        ? s.planName!
                        : '-');
                return [
                  '$idx',
                  s.name,
                  phoneStr,
                  supplierStr,
                  packageStr,
                  CurrencyFormatter.format(s.balance, s.currency,
                      locale: locale),
                  s.currency.code,
                  expiryStr,
                  s.status == SubscriberStatus.active ? 'نشط' : 'منتهي / معلق',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.red700),
              cellStyle: const pw.TextStyle(fontSize: 7.5),
              cellHeight: 20,
              oddRowDecoration:
                  const pw.BoxDecoration(color: PdfColors.grey100),
              border:
                  pw.TableBorder.all(color: PdfColors.grey300, width: 0.4),
            ),
        ],
      ),
    );

    return doc.save();
  }

  Future<void> previewSubscribersDebtReport({
    required List<Subscriber> subscribers,
    List<SubscriberDebt>? allDebts,
    required String generatedBy,
    required String locale,
  }) async {
    await Printing.layoutPdf(
      onLayout: (_) async => buildSubscribersDebtReportPdf(
        subscribers: subscribers,
        allDebts: allDebts,
        generatedBy: generatedBy,
        locale: locale,
      ),
      name: 'تقرير_ديون_المشتركين',
    );
  }

  pw.Widget _buildCustomHeader(
      {required String title, required String subtitle}) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.blueGrey300, width: 0.8),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 15,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blueGrey900,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                subtitle,
                style: const pw.TextStyle(
                    fontSize: 9, color: PdfColors.blueGrey600),
              ),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue700,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Text(
              'ISP Manager',
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCustomFooter(
      pw.Context ctx, bool isArabic, String generatedBy) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300, width: 0.6),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            isArabic
                ? 'تم استخراج التقرير بواسطة: $generatedBy - ${DateFormatter.dateTime(DateTime.now(), locale: "ar")}'
                : 'Generated by: $generatedBy - ${DateTime.now()}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
          pw.Text(
            isArabic
                ? 'صفحة ${ctx.pageNumber} من ${ctx.pagesCount}'
                : 'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSubscriberInfoCard(Subscriber subscriber, String locale) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
      ),
      child: pw.Column(
        children: [
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildInfoItem('اسم المشترك:', subscriber.name,
                    isBold: true),
              ),
              pw.Expanded(
                child: _buildInfoItem(
                    'رقم الهاتف:',
                    (subscriber.phone != null && subscriber.phone!.isNotEmpty)
                        ? subscriber.phone!
                        : 'غير متوفر'),
              ),
              pw.Expanded(
                child: _buildInfoItem(
                    'المجهز:',
                    (subscriber.supplierName != null &&
                            subscriber.supplierName!.isNotEmpty)
                        ? subscriber.supplierName!
                        : 'غير محدد'),
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildInfoItem(
                    'حالة المشترك:',
                    subscriber.status == SubscriberStatus.active
                        ? 'نشط'
                        : 'منتهي / معلق'),
              ),
              pw.Expanded(
                child: _buildInfoItem(
                    'الباقة الحالية:',
                    (subscriber.packageName != null &&
                            subscriber.packageName!.isNotEmpty)
                        ? subscriber.packageName!
                        : (subscriber.planName ?? 'باقة افتراضية')),
              ),
              pw.Expanded(
                child: _buildInfoItem(
                  'تاريخ الانتهاء:',
                  DateFormatter.date(subscriber.subscriptionEndsAt,
                      locale: locale),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildInfoItem(String label, String value,
      {bool isBold = false}) {
    return pw.Row(
      children: [
        pw.Text(label,
            style: const pw.TextStyle(
                fontSize: 8.5, color: PdfColors.grey700)),
        pw.SizedBox(width: 4),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 8.5,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: PdfColors.blueGrey900,
            ),
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildKpiCard(
      String label, String value, PdfColor textColor, PdfColor bgColor) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: pw.BoxDecoration(
          color: bgColor,
          borderRadius: pw.BorderRadius.circular(6),
          border: pw.Border.all(color: textColor.shade(0.3), width: 0.5),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              label,
              style: const pw.TextStyle(
                  fontSize: 7.5, color: PdfColors.grey700),
              maxLines: 1,
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: textColor,
              ),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildEmptyBox(String message) {
    return pw.Container(
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: PdfColors.grey200),
      ),
      child: pw.Text(
        message,
        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
      ),
    );
  }
}
