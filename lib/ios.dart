import 'dart:convert';
import 'dart:io';
import 'package:flutter_launcher_icons/utils.dart';
import 'package:image/image.dart';
import 'package:flutter_launcher_icons/constants.dart';
import 'package:path/path.dart' as p;

import 'custom_exceptions.dart';
import 'svg2png.dart';

/// File to handle the creation of icons for iOS platform
class IosIconTemplate {
  IosIconTemplate({this.size, this.name});

  final String name;
  final int size;
}

List<IosIconTemplate> iosIcons = <IosIconTemplate>[
  IosIconTemplate(name: '-20x20@1x', size: 20),
  IosIconTemplate(name: '-20x20@2x', size: 40),
  IosIconTemplate(name: '-20x20@3x', size: 60),
  IosIconTemplate(name: '-29x29@1x', size: 29),
  IosIconTemplate(name: '-29x29@2x', size: 58),
  IosIconTemplate(name: '-29x29@3x', size: 87),
  IosIconTemplate(name: '-40x40@1x', size: 40),
  IosIconTemplate(name: '-40x40@2x', size: 80),
  IosIconTemplate(name: '-40x40@3x', size: 120),
  IosIconTemplate(name: '-50x50@1x', size: 50),
  IosIconTemplate(name: '-50x50@2x', size: 100),
  IosIconTemplate(name: '-57x57@1x', size: 57),
  IosIconTemplate(name: '-57x57@2x', size: 114),
  IosIconTemplate(name: '-60x60@2x', size: 120),
  IosIconTemplate(name: '-60x60@3x', size: 180),
  IosIconTemplate(name: '-72x72@1x', size: 72),
  IosIconTemplate(name: '-72x72@2x', size: 144),
  IosIconTemplate(name: '-76x76@1x', size: 76),
  IosIconTemplate(name: '-76x76@2x', size: 152),
  IosIconTemplate(name: '-83.5x83.5@2x', size: 167),
  IosIconTemplate(name: '-1024x1024@1x', size: 1024),
];

void createIcons(Map<String, dynamic> config) {
  final String filePath = config['image_path_ios'] ?? config['image_path'];
  String iconName;
  final dynamic iosConfig = config['ios'];
  // If the IOS configuration is a string then the user has specified a new icon to be created
  // and for the old icon file to be kept
  if (iosConfig is String) {
    final String newIconName = iosConfig;
    print('Adding new iOS launcher icon');
    for (IosIconTemplate template in iosIcons) {
      saveNewIcons(template, filePath, newIconName);
    }
    iconName = newIconName;
    changeIosLauncherIcon(iconName);
    modifyContentsFile(iconName);
  }
  // Otherwise the user wants the new icon to use the default icons name and
  // update config file to use it
  else {
    print('Overwriting default iOS launcher icon with new icon');
    for (IosIconTemplate template in iosIcons) {
      overwriteDefaultIcons(template, filePath);
    }
    iconName = iosDefaultIconName;
    changeIosLauncherIcon('AppIcon');
  }
}

/// Note: Do not change interpolation unless you end up with better results (see issue for result when using cubic
/// interpolation)
/// https://github.com/fluttercommunity/flutter_launcher_icons/issues/101#issuecomment-495528733
void overwriteDefaultIcons(IosIconTemplate template, String imagePath) {
  final String newIconPath = p.join(iosDefaultIconFolder, iosDefaultIconName + template.name + '.png');
  if (isPngImage(imagePath)) {
    final Image image = decodeImage(File(imagePath).readAsBytesSync());

    final Image newFile = createResizedImage(template.size, image);
    File(newIconPath)..writeAsBytesSync(encodePng(newFile));
  } else if (isSvgImage(imagePath)) {
    convertSvgToPng(imagePath, newIconPath, template.size, template.size);
  } else {
    throw const InvalidImageFormatException();
  }
}

/// Note: Do not change interpolation unless you end up with better results (see issue for result when using cubic
/// interpolation)
/// https://github.com/fluttercommunity/flutter_launcher_icons/issues/101#issuecomment-495528733
void saveNewIcons(IosIconTemplate template, String filePath, String newIconName) {
  final String newIconPath = p.join(
    iosAssetFolder,
    newIconName + '.appiconset/',
    newIconName + template.name + '.png',
  );

  if (isPngImage(filePath)) {
    final Image image = decodeImage(File(filePath).readAsBytesSync());
    final Image newImage = createResizedImage(template.size, image);

    final File file = File(newIconPath)..createSync(recursive: true);
    file.writeAsBytesSync(encodePng(newImage));
  } else if (isSvgImage(filePath)) {
    convertSvgToPng(filePath, newIconPath, template.size, template.size);
  } else {
    throw const InvalidImageFormatException();
  }
}

Future<void> changeIosLauncherIcon(String iconName) async {
  final File iOSConfigFile = File(iosConfigFile);
  final List<String> lines = await iOSConfigFile.readAsLines();
  for (int x = 0; x < lines.length; x++) {
    String line = lines[x];
    if (line.contains('ASSETCATALOG')) {
      line = line.replaceAll(RegExp(r'=.*;'), '= $iconName;');
      lines[x] = line;
      lines[lines.length - 1] = '}\n';
    }
  }
  final String entireFile = lines.join('\n');
  await iOSConfigFile.writeAsString(entireFile);
}

/// Create the Contents.json file
void modifyContentsFile(String newIconName) {
  final String newIconFolder = p.join(iosAssetFolder, newIconName + '.appiconset', 'Contents.json');
  File(newIconFolder).create(recursive: true).then((File contentsJsonFile) {
    final String contentsFileContent = generateContentsFileAsString(newIconName);
    contentsJsonFile.writeAsString(contentsFileContent);
  });
}

String generateContentsFileAsString(String newIconName) {
  return json.encode(<String, dynamic>{
    'images': createImageList(newIconName),
    'info': ContentsInfoObject(version: 1, author: 'xcode').toJson()
  });
}

class ContentsImageObject {
  ContentsImageObject({this.size, this.idiom, this.scale});

  final String size;
  final String idiom;
  final String scale;

  Map<String, String> toJsonWithPrefix(String fileNamePrefix) {
    final String filename = '$fileNamePrefix-$size@$scale.png';

    return <String, String>{'size': size, 'idiom': idiom, 'filename': filename, 'scale': scale};
  }
}

class ContentsInfoObject {
  ContentsInfoObject({this.version, this.author});

  final int version;
  final String author;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'version': version,
      'author': author,
    };
  }
}

List<Map<String, String>> createImageList(String fileNamePrefix) {
  return <Map<String, String>>[
    ContentsImageObject(size: '20x20', idiom: 'iphone', scale: '2x')
        .toJsonWithPrefix(fileNamePrefix),
    ContentsImageObject(size: '20x20', idiom: 'iphone', scale: '3x')
        .toJsonWithPrefix(fileNamePrefix),
    ContentsImageObject(size: '29x29', idiom: 'iphone', scale: '1x')
        .toJsonWithPrefix(fileNamePrefix),
    ContentsImageObject(size: '29x29', idiom: 'iphone', scale: '2x')
        .toJsonWithPrefix(fileNamePrefix),
    ContentsImageObject(size: '29x29', idiom: 'iphone', scale: '3x')
        .toJsonWithPrefix(fileNamePrefix),
    ContentsImageObject(size: '40x40', idiom: 'iphone', scale: '2x')
        .toJsonWithPrefix(fileNamePrefix),
    ContentsImageObject(size: '40x40', idiom: 'iphone', scale: '3x')
        .toJsonWithPrefix(fileNamePrefix),
    ContentsImageObject(size: '60x60', idiom: 'iphone', scale: '2x')
        .toJsonWithPrefix(fileNamePrefix),
    ContentsImageObject(size: '60x60', idiom: 'iphone', scale: '3x')
        .toJsonWithPrefix(fileNamePrefix),
    ContentsImageObject(size: '20x20', idiom: 'ipad', scale: '1x')
        .toJsonWithPrefix(fileNamePrefix),
    ContentsImageObject(size: '20x20', idiom: 'ipad', scale: '2x')
        .toJsonWithPrefix(fileNamePrefix),
    ContentsImageObject(size: '29x29', idiom: 'ipad', scale: '1x')
        .toJsonWithPrefix(fileNamePrefix),
    ContentsImageObject(size: '29x29', idiom: 'ipad', scale: '2x')
        .toJsonWithPrefix(fileNamePrefix),
    ContentsImageObject(size: '40x40', idiom: 'ipad', scale: '1x')
        .toJsonWithPrefix(fileNamePrefix),
    ContentsImageObject(size: '40x40', idiom: 'ipad', scale: '2x')
        .toJsonWithPrefix(fileNamePrefix),
    ContentsImageObject(size: '76x76', idiom: 'ipad', scale: '1x')
        .toJsonWithPrefix(fileNamePrefix),
    ContentsImageObject(size: '76x76', idiom: 'ipad', scale: '2x')
        .toJsonWithPrefix(fileNamePrefix),
    ContentsImageObject(size: '83.5x83.5', idiom: 'ipad', scale: '2x')
        .toJsonWithPrefix(fileNamePrefix),
    ContentsImageObject(size: '1024x1024', idiom: 'ios-marketing', scale: '1x')
        .toJsonWithPrefix(fileNamePrefix),
  ];
}
