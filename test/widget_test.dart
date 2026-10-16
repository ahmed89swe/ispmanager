import 'package:flutter_test/flutter_test.dart';

import 'package:printing/printing.dart';

void main() {
  test('test PdfGoogleFonts available fonts', () {
    expect(PdfGoogleFonts.cairoRegular, isNotNull);
    expect(PdfGoogleFonts.cairoBold, isNotNull);
    expect(PdfGoogleFonts.robotoRegular, isNotNull);
    expect(PdfGoogleFonts.robotoBold, isNotNull);
    expect(PdfGoogleFonts.notoSansArabicRegular, isNotNull);
    expect(PdfGoogleFonts.notoSansArabicBold, isNotNull);
  });
}

