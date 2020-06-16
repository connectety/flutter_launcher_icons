import 'package:flutter_launcher_icons/utils.dart';
import 'package:test/test.dart';

void main() {
  const String pngFile = 'assets/images/icon-710x599-android.png';
  const String jpgFile = 'assets/images/icon-710x599-android.jpg';
  const String jpg2File = 'assets/images/icon-710x599-android.jpeg';
  const String svgFile = 'assets/images/icon-710x599-android.svg';
  const String pdfFile = 'assets/images/icon-710x599-android.pdf';

  test('Is PNG file', () {
    expect(isPngJpgImage(pngFile), true);
    expect(isPngJpgImage(jpgFile), true);
    expect(isPngJpgImage(jpg2File), true);
    expect(isPngJpgImage(svgFile), false);
    expect(isPngJpgImage(pdfFile), false);
  });

  test('Is SVG file', () {
    expect(isSvgImage(svgFile), true);
    expect(isSvgImage(pngFile), false);
    expect(isSvgImage(jpgFile), false);
    expect(isSvgImage(jpg2File), false);
    expect(isSvgImage(pdfFile), false);
  });
}
