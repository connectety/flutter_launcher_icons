import 'dart:io';

import 'package:flutter_launcher_icons/constants.dart' as constants;
import 'package:flutter_launcher_icons/custom_exceptions.dart';
import 'package:flutter_launcher_icons/svg2png.dart';
import 'package:flutter_launcher_icons/utils.dart';
import 'package:flutter_launcher_icons/xml_templates.dart' as xml_template;
import 'package:image/image.dart';
import 'package:path/path.dart' as p;

class AndroidIconTemplate {
  AndroidIconTemplate({this.size, this.directoryName});
  final String directoryName;
  final int size;
}

final List<AndroidIconTemplate> adaptiveForegroundIcons = <AndroidIconTemplate>[
  AndroidIconTemplate(directoryName: 'drawable-mdpi', size: 108),
  AndroidIconTemplate(directoryName: 'drawable-hdpi', size: 162),
  AndroidIconTemplate(directoryName: 'drawable-xhdpi', size: 216),
  AndroidIconTemplate(directoryName: 'drawable-xxhdpi', size: 324),
  AndroidIconTemplate(directoryName: 'drawable-xxxhdpi', size: 432),
];

List<AndroidIconTemplate> androidIcons = <AndroidIconTemplate>[
  AndroidIconTemplate(directoryName: 'mipmap-mdpi', size: 48),
  AndroidIconTemplate(directoryName: 'mipmap-hdpi', size: 72),
  AndroidIconTemplate(directoryName: 'mipmap-xhdpi', size: 96),
  AndroidIconTemplate(directoryName: 'mipmap-xxhdpi', size: 144),
  AndroidIconTemplate(directoryName: 'mipmap-xxxhdpi', size: 192),
];

void createDefaultIcons(Map<String, dynamic> yamlConfig) {
  print('Creating default icons Android');
  final String filePath = getAndroidIconPath(yamlConfig);
  if (isCustomAndroidFile(yamlConfig)) {
    addNewIcon(yamlConfig, filePath);
  } else {
    replaceDefaultFlutterProjectIcon(filePath);
  }
}

// Adding new icon to the project not replacing the default Flutter project icon
void addNewIcon(
    Map<String, dynamic> flutterLauncherIconsConfig,
    String filePath) {
  print('Adding a new Android launcher icon');

  // get the file name entered by the user
  final String iconName = getNewIconName(flutterLauncherIconsConfig);

  // ensure the new icon name is in the correct format
  // otherwise throw exception
  isAndroidIconNameCorrectFormat(iconName);

  final String iconPath = '$iconName.png';
  for (AndroidIconTemplate template in androidIcons) {
    saveNewImages(template, filePath, iconPath);
  }

  overwriteAndroidManifestWithNewLauncherIcon(iconName);
}

// replaces ic_launcher.png launcher icon
void replaceDefaultFlutterProjectIcon(String filePath) {
  print('Overwriting the default Android launcher icon with a new icon');
  for (AndroidIconTemplate template in androidIcons) {
    overwriteExistingIcons(template, filePath, constants.androidFileName);
  }
  overwriteAndroidManifestWithNewLauncherIcon(
      constants.androidDefaultIconName);
}

/// Ensures that the Android icon name is in the correct format
bool isAndroidIconNameCorrectFormat(String iconName) {
  // assure the icon only consists of lowercase letters, numbers and underscore
  if (!RegExp(r'^[a-z0-9_]+$').hasMatch(iconName)) {
    throw const InvalidAndroidIconNameException(
        constants.errorIncorrectIconName);
  }
  return true;
}

void createAdaptiveIcons(Map<String, dynamic> flutterLauncherIconsConfig) {
  print('Creating adaptive icons Android');

  // Retrieve the necessary Flutter Launcher Icons configuration from the pubspec.yaml file
  final String backgroundConfig =
      flutterLauncherIconsConfig['adaptive_icon_background'];
  final String foregroundImagePath =
      flutterLauncherIconsConfig['adaptive_icon_foreground'];

  // Create adaptive icon foreground images
  for (AndroidIconTemplate androidIcon in adaptiveForegroundIcons) {
    overwriteExistingIcons(
      androidIcon,
      foregroundImagePath,
      constants.androidAdaptiveForegroundFileName,
    );
  }

  // Create adaptive icon background
  if (isPngJpgImage(backgroundConfig) || isSvgImage(backgroundConfig)) {
    createAdaptiveBackgrounds(flutterLauncherIconsConfig, backgroundConfig);
  } else {
    createAdaptiveIconMipmapXmlFile(flutterLauncherIconsConfig);
    updateColorsXmlFile(backgroundConfig);
  }
}

/// Retrieves the colors.xml file for the project.
///
/// If the colors.xml file is found, it is updated with a new color item for the
/// adaptive icon background.
///
/// If not, the colors.xml file is created and a color item for the adaptive icon
/// background is included in the new colors.xml file.
void updateColorsXmlFile(String backgroundConfig) {
  final File colorsXml = File(constants.androidColorsFile);
  if (colorsXml.existsSync()) {
    print('Updating colors.xml with color for adaptive icon background');
    updateColorsFile(colorsXml, backgroundConfig);
  } else {
    print('No colors.xml file found in your Android project');
    print('Creating colors.xml file and adding it to your Android project');
    createNewColorsFile(backgroundConfig);
  }
}

/// Creates the xml file required for the adaptive launcher icon
/// FILE LOCATED HERE: res/mipmap-anydpi/{icon-name-from-yaml-config}.xml
void createAdaptiveIconMipmapXmlFile(
    Map<String, dynamic> flutterLauncherIconsConfig) {
  final String adaptiveName =
    isCustomAndroidFile(flutterLauncherIconsConfig)
      ? getNewIconName(flutterLauncherIconsConfig)
      : constants.androidDefaultIconName;
  final String adaptivePath =
    p.join(constants.androidAdaptiveXmlFolder, adaptiveName + '.xml');
  final File adaptiveIcon = File(adaptivePath)..createSync(recursive: true);
  adaptiveIcon.writeAsString(xml_template.icLauncherXml);
}

/// creates adaptive background using png image
void createAdaptiveBackgrounds(Map<String, dynamic> yamlConfig, String filePath) {

  // creates a png image (ic_adaptive_background.png) for the adaptive icon background in each of the locations
  // it is required
  for (AndroidIconTemplate androidIcon in adaptiveForegroundIcons) {
    saveNewImages(
      androidIcon,
      filePath,
      constants.androidAdaptiveBackgroundFileName,
    );
  }

  // Creates the xml file required for the adaptive launcher icon
  // FILE LOCATED HERE:  res/mipmap-anydpi/{icon-name-from-yaml-config}.xml
  final String adaptiveName =
    isCustomAndroidFile(yamlConfig)
      ? getNewIconName(yamlConfig)
      : constants.androidDefaultIconName;
  final String adaptivePath = p.join(
      constants.androidAdaptiveXmlFolder, adaptiveName + '.xml');
  final File adaptiveIcon = File(adaptivePath)..createSync(recursive: true);
  adaptiveIcon.writeAsString(xml_template.icLauncherDrawableBackgroundXml);
}

/// Creates a colors.xml file if it was missing from android/app/src/main/res/values/colors.xml
void createNewColorsFile(String backgroundColor) {
  final File colorsFile =
    File(constants.androidColorsFile)..createSync(recursive: true);
  colorsFile.writeAsString(xml_template.colorsXml);
  updateColorsFile(colorsFile, backgroundColor);
}

/// Updates the colors.xml with the new adaptive launcher icon color
void updateColorsFile(File colorsFile, String backgroundColor) {
  // Write foreground color
  final List<String> lines = colorsFile.readAsLinesSync();
  bool foundExisting = false;
  for (int x = 0; x < lines.length; x++) {
    String line = lines[x];
    if (line.contains('name="ic_launcher_background"')) {
      foundExisting = true;
      // replace anything between tags which does not contain another tag
      line = line.replaceAll(RegExp(r'>([^><]*)<'), '>$backgroundColor<');
      lines[x] = line;
      break;
    }
  }

  // Add new line if we didn't find an existing value
  if (!foundExisting) {
    lines.insert(lines.length - 1,
        '\t<color name="ic_launcher_background">$backgroundColor</color>');
  }

  colorsFile.writeAsStringSync(lines.join('\n'));
}

/// Check to see if specified Android config is a string or bool
/// String - Generate new launcher icon with the string specified
/// bool - override the default flutter project icon
bool isCustomAndroidFile(Map<String, dynamic> config) {
  final dynamic androidConfig = config['android'];
  return androidConfig is String;
}

/// return the new launcher icon file name
String getNewIconName(Map<String, dynamic> config) {
  return config['android'];
}

/// Overrides the existing launcher icons in the project
/// Note: Do not change interpolation unless you end up with better results (see issue for result when using cubic
/// interpolation)
/// https://github.com/fluttercommunity/flutter_launcher_icons/issues/101#issuecomment-495528733
void overwriteExistingIcons(AndroidIconTemplate template, String path, String filename) {
  final String newFilePath = p.join(
      constants.androidResFolder, template.directoryName, filename);

  if (isPngJpgImage(path)) {
    final Image foregroundImage = decodeImage(File(path).readAsBytesSync());

    final Image newImage = createResizedImage(template.size, foregroundImage);
    final File newFile = File(newFilePath)..createSync(recursive: true);
    newFile.writeAsBytesSync(encodePng(newImage));
  } else if (isSvgImage(path)) {
    convertSvgToPng(path, newFilePath, template.size, template.size);
  } else {
    throw const InvalidImageFormatException();
  }
}

/// Saves new launcher icons to the project, keeping the old launcher icons.
/// Note: Do not change interpolation unless you end up with better results
/// https://github.com/fluttercommunity/flutter_launcher_icons/issues/101#issuecomment-495528733
void saveNewImages(AndroidIconTemplate template, String path, String iconFilePath) {
  final String newFilePath = p.join(
      constants.androidResFolder, template.directoryName, iconFilePath);

  if (isPngJpgImage(path)) {
    final Image image = decodeImage(File(path).readAsBytesSync());

    final Image newImage = createResizedImage(template.size, image);
    final File newFile = File(newFilePath)..createSync(recursive: true);
    newFile.writeAsBytesSync(encodePng(newImage));
  } else if (isSvgImage(path)) {
    convertSvgToPng(path, newFilePath, template.size, template.size);
  } else {
    throw const InvalidImageFormatException();
  }
}

/// Updates the line which specifies the launcher icon within the AndroidManifest.xml
/// with the new icon name (only if it has changed)
///
/// Note: default iconName = "ic_launcher"
Future<void> overwriteAndroidManifestWithNewLauncherIcon(
    String iconName) async {
  final File androidManifestFile = File(constants.androidManifestFile);
  final List<String> oldManifestLines = await androidManifestFile.readAsLines();
  final List<String> transformedLines = transformAndroidManifestWithNewLauncherIcon(oldManifestLines, iconName);
  await androidManifestFile.writeAsString(transformedLines.join('\n'));
}

/// Updates only the line containing android:icon with the specified iconName
List<String> transformAndroidManifestWithNewLauncherIcon(List<String> oldManifestLines, String iconName) {
  return oldManifestLines.map((String line) {
    if (line.contains('android:icon')) {
      // Using RegExp replace the value of android:icon to point to the new icon
      // anything but a quote of any length: [^"]*
      // an escaped quote: \\" (escape slash, because it exists regex)
      // quote, no quote / quote with things behind : \"[^"]*
      // repeat as often as wanted with no quote at start: [^"]*(\"[^"]*)*
      // escaping the slash to place in string: [^"]*(\\"[^"]*)*"
      // result: any string which does only include escaped quotes
      return line.replaceAll(RegExp(r'android:icon="[^"]*(\\"[^"]*)*"'),
          'android:icon="@mipmap/$iconName"');
    } else {
      return line;
    }
  }).toList();
}

/// Retrieves the minSdk value from the Android build.gradle file
int minSdk() {
  final File androidGradleFile = File(constants.androidGradleFile);
  final List<String> lines = androidGradleFile.readAsLinesSync();
  for (String line in lines) {
    if (line.contains('minSdkVersion')) {
      // remove anything from the line that is not a digit
      final String minSdk = line.replaceAll(RegExp(r'[^\d]'), '');
      print('Android minSdkVersion = $minSdk');
      return int.parse(minSdk);
    }
  }
  return 0; // Didn't find minSdk, assume the worst
}

/// Method for the retrieval of the Android icon path
/// If image_path_android is found, this will be prioritised over the image_path
/// value.
String getAndroidIconPath(Map<String, dynamic> config) {
  return config['image_path_android'] ?? config['image_path'];
}

/// (NOTE THIS IS JUST USED FOR UNIT TEST)
/// Ensures the correct path is used for generating adaptive icons
/// "Next you must create alternative drawable resources in your app for use with
/// Android 8.0 (API level 26) in res/mipmap-anydpi/ic_launcher.xml"
/// Source: https://developer.android.com/guide/practices/ui_guidelines/icon_design_adaptive
bool isCorrectMipmapDirectoryForAdaptiveIcon(String path) {
  return path == 'android/app/src/main/res/mipmap-anydpi-v26/';
}
