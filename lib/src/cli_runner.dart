import 'package:args/command_runner.dart';
import 'commands/create_command.dart';
import 'commands/add_command.dart';

CommandRunner<int> makeRunner() {
  final runner = CommandRunner<int>('mvvm', 'MVVM Flutter scaffolding CLI')
    ..addCommand(CreateCommand())
    ..addCommand(AddCommand());
  return runner;
}