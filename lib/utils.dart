import 'package:image/image.dart';

/// Returns true if the file ends in .png to indicate PNG image
bool isPngJpgImage(String backgroundFile) {
  return backgroundFile.endsWith('.png') || backgroundFile.endsWith('.jpg') || backgroundFile.endsWith('.jpeg');
}

/// Returns true if the file ends in .svg to indicate SVG image
bool isSvgImage(String backgroundFile) {
  return backgroundFile.endsWith('.svg');
}

Image createResizedImage(int iconSize, Image image) {
  if (image.width >= iconSize) {
    return copyResize(
      image,
      width: iconSize,
      height: iconSize,
      interpolation: Interpolation.average,
    );
  } else {
    return copyResize(
      image,
      width: iconSize,
      height: iconSize,
      interpolation: Interpolation.linear,
    );
  }
}
