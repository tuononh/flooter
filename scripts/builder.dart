import 'dart:io';

import 'package:flooter/common/app_config.dart';

import 'start.dart';

void main() async {
  DateTime startTime = DateTime.now();
  AppConfig? buildConfig = await applyConfig();
  if (buildConfig == null) return;

  bool isBuildingProduction = buildConfig.buildType != 'DEV';
  stdout.write('\n');

  try {
    await buildiOS(isBuildingProduction);
  } catch (e) {
    return;
  }

  try {
    await buildAndroid(isBuildingProduction);
  } catch (e) {
    return;
  }

  stdout.write('Total build time: ${DateTime.now().difference(startTime).inSeconds} seconds!\n');

  uploadToFirebase(isBuildingProduction);
}

Future<void> buildiOS(bool isProduction) async {
  DateTime startTime = DateTime.now();
  stdout.write('\n⏳ Building iOS ${isProduction ? 'production' : 'development'} archive... ');

  ProcessResult updatePods = await Process.run(
      'pod',
      [
        'install',
      ],
      workingDirectory: 'ios');

  if (updatePods.exitCode != 0) {
    stdout.write('❌ Error!\n');
    throw (updatePods.stdout);
  }

  ProcessResult buildiOS = await Process.run('xcodebuild', [
    '-workspace',
    'ios/Runner.xcworkspace',
    '-scheme',
    isProduction ? 'Production' : 'Development',
    '-configuration',
    isProduction ? 'ReleaseProduction' : 'ReleaseDevelopment',
    '-sdk',
    'iphoneos',
    '-archivePath',
    'build/iosArchive.xcarchive',
    'archive',
  ]);

  if (buildiOS.exitCode != 0) {
    stdout.write('❌ Error!\n');
    throw (buildiOS.stdout);
  }

  stdout.write('👍🏻 Done in ${DateTime.now().difference(startTime).inSeconds}s!\n');

  await exportiOS(isProduction);
}

Future<void> exportiOS(bool isProduction) async {
  DateTime startTime = DateTime.now();
  stdout.write('\n⏳ Exporting iOS ${isProduction ? 'production' : 'development'} IPA... ');
  ProcessResult buildiOS = await Process.run('xcodebuild', [
    '-exportArchive',
    '-archivePath',
    'build/iosArchive.xcarchive/',
    '-exportPath',
    'build/ios/',
    '-exportOptionsPlist',
    'ios/exportOptions.plist',
  ]);
  await Process.run('open', ['build/ios/']);

  if (buildiOS.exitCode != 0) {
    stdout.write('❌ Error!\n');
    throw (buildiOS.stdout);
  }

  stdout.write('👍🏻 Done in ${DateTime.now().difference(startTime).inSeconds}s!\n');
}

Future<void> buildAndroid(bool isProduction) async {
  DateTime startTime = DateTime.now();
  stdout.write('\n⏳ Building Android ${isProduction ? 'production' : 'development'} APK... ');
  ProcessResult buildAndroid = await Process.run(
    './gradlew',
    [
      isProduction ? 'assembleRelease' : 'assembleRelease',
    ],
    workingDirectory: 'android',
  );
  await Process.run('open', ['build/app/outputs/flutter-apk']);

  if (buildAndroid.exitCode != 0) {
    stdout.write('❌ Error!\n');
    throw (buildAndroid.stdout);
  }

  stdout.write('👍🏻 Done in ${DateTime.now().difference(startTime).inSeconds}s!\n');
}

Future<void> uploadToFirebase(bool isProduction) async {
  stdout.write('\n🧐 Do you want to upload to Firebase? (y/n): ');
  String? ans = stdin.readLineSync();
  if (ans == 'y') {
    stdout.write('\n🧐 What news in this version?: ');
    String? releaseNote = stdin.readLineSync();
    DateTime startTime = DateTime.now();
    stdout.write('\n⏳ Uploading Android APK to Firebase... ');
    ProcessResult uploadAndroid = await Process.run('firebase', [
      'appdistribution:distribute',
      'build/app/outputs/flutter-apk/app-release.apk',
      '--app',
      AppConfig.firebaseAndroidId,
      '--groups',
      'internal-android',
      '--release-notes',
      '$releaseNote',
    ]);

    if (uploadAndroid.exitCode != 0) {
      stdout.write('❌ Error!\n');
      stdout.writeln(uploadAndroid.stdout);
    } else {
      stdout.write('👍🏻 Done!\n');
    }

    stdout.write('\n⏳ Uploading iOS IPA to Firebase... ');
    ProcessResult uploadiOS = await Process.run('firebase', [
      'appdistribution:distribute',
      'build/ios/b2b.ipa',
      '--app',
      AppConfig.firebaseiOSId,
      '--groups',
      'internal-ios',
      '--release-notes',
      '$releaseNote',
    ]);

    if (uploadiOS.exitCode != 0) {
      stdout.write('❌ Error!\n');
      stdout.writeln(uploadiOS.stdout);
    } else {
      stdout.write('👍🏻 Done!\n');
    }
    stdout.write('👍🏻 Done in ${DateTime.now().difference(startTime).inSeconds}s!\n');
  } else {
    stdout.write('👌🏻 Bye!\n');
  }
}
