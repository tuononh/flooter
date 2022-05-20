import 'dart:io';

import 'dart:isolate';

Isolate? countdownIsolate;

Future<void> main() async {
  stdout.write('\n🙌 Welcome to Flooter 🙌 Please select:');
  stdout.write('\n1. Get dependencies');
  stdout.write('\n2. Build iOS application');
  stdout.write('\n3. Build Android application');
  String? res = prompt(['1', '2', '3']);
  if (res == '1') await getDependencies();
}

Future<void> getDependencies() async {
  stdout.write('🚚 Getting dependencies... ');
  spawnCountdown();
  ProcessResult pubGetRes = await Process.run('flutter', ['pub', 'get']);
  exitCountdown();
  if (pubGetRes.exitCode != 0) {
    prErrorHelper(pubGetRes);
    return Future.value(null);
  } else {
    stdout.write('\n👍🏻 Done!');
  }
}

void prErrorHelper(ProcessResult res) {
  if (res.exitCode != 0) {
    stdout.write('\nError occurred. Wanna see it? (y/n):');
    String? p = prompt(['y', 'n']);
    if (p == 'y') stdout.write(res.stdout);
  }
}

String? prompt(List<String> expected) {
  stdout.write('\nYour choice: ');
  String? ans = stdin.readLineSync();
  while (!expected.contains(ans)) {
    stdout.write('Invalid choice. Again: ');
    ans = stdin.readLineSync();
  }

  return ans;
}

void spawnCountdown() async {
  countdownIsolate = await Isolate.spawn(startCountdown, 1);
}

Future<void> exitCountdown() async {
  countdownIsolate?.kill();
}

void startCountdown(int x) async {
  int start = 0;
  while (true) {
    stdout.write('\r${start}s elapsed');
    await Future.delayed(const Duration(seconds: 1));
    start += 1;
  }
}
