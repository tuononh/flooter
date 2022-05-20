Future<BuildConfig?> run() async {
  stdout.write('🚚 Getting dependencies... ');
  ProcessResult pubgetRes = await Process.run('flutter', ['pub', 'get']);
  if (pubgetRes.exitCode != 0) {
    stdout.write('❌ Error!\n');
    return Future.value(null);
  } else {
    stdout.write('👍🏻 Done!\n');
  }
  var doc = loadYaml(File('pubspec.yaml').readAsStringSync());
  List<String> vers = doc['version'].toString().split('+');
  String? buildType = doc['build_type'];
  String? env = doc['env'];
  String? fbai = doc['firebase_android_id'];
  String? fbii = doc['firebase_ios_id'];
  if (!{'DEV', 'PRO_DEBUG', 'PRO_RELEASE'}.contains(buildType)) {
    stdout.write('\n❌ Build type $buildType is invalid! Aborted.');
    return Future.value(null);
  }
  if (!{'Dev', 'Pro'}.contains(env)) {
    stdout.write('\n❌ Environment $env is invalid! Aborted.');
    return Future.value(null);
  }
  stdout.write(
    '\nℹ️  VPBank NeoBiz version ${vers[0]} build ${vers[1]} $buildType ($env)',
  );

  Directory current = Directory.current;
  File configFile = File('${current.path}/lib/config.dart');
  await configFile.writeAsString('''
// Generated file. Do not edit!
enum BuildType { DEV, PRO_DEBUG, PRO_RELEASE }

enum AppEnvironment {
  Dev,
  Pro,
}

class AppConfig {
  static BuildType buildType = BuildType.$buildType;
  static AppEnvironment env = AppEnvironment.$env;
  static String versionName = '${vers[0]}';
  static String buildNumber = '${vers[1]}';
  static String firebaseAndroidId = '$fbai';
  static String firebaseiOSId = '$fbii';
}
''');

  try {
    updateVersionInfo(vers[0], vers[1]);
  } catch (e) {
    return Future.value(null);
  }

  return Future.value(BuildConfig(
    buildType: buildType,
    env: env,
    versionName: vers[0],
    buildNumber: vers[1],
    firebaseAndroidId: fbai,
    firebaseiOSId: fbii,
  ));
}

void main() {
  run();
}