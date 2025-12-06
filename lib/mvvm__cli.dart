library mvvm__cli;

export 'src/cli_runner.dart';
export 'src/commands/create_command.dart';
export 'src/commands/add_command.dart';
export 'src/generators/project_generator.dart';
export 'src/generators/feature_generator.dart';
export 'src/generators/service_generator.dart';
export 'src/templates/templates.dart';

// convenience runner used by bin/mvvm.dart
import 'dart:io' as io;
import 'src/cli_runner.dart';

Future<void> runCli(
  List<String> args, {
  io.Stdin? stdin,
  io.Stdout? stdout,
  io.IOSink? stderr,
}) async {
  final runner = makeRunner();
  try {
    await runner.run(args);
  } catch (e) {
    (stderr ?? io.stderr).writeln('Error: \$e');
  }
}
