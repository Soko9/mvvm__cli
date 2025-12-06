// Lightweight entrypoint. Run: dart pub global activate --source path .

import 'dart:io';
import '../lib/mvvm__cli.dart';

Future<void> main(List<String> args) async {
  // forward to library CLI runner
  await runCli(args, stdin: stdin, stdout: stdout, stderr: stderr);
}
