import 'package:args/command_runner.dart';
import '../generators/project_generator.dart';

class CreateCommand extends Command<int> {
  @override
  final name = 'create';
  @override
  final description = 'Create a new Flutter project with MVVM structure';

  CreateCommand() {
    argParser
      ..addFlag('force', abbr: 'f', negatable: false, help: 'Overwrite files if exist')
      ..addFlag('verbose', abbr: 'v', negatable: false, help: 'Verbose output');
  }

  @override
  Future<int> run() async {
    if (argResults!.rest.isEmpty) {
      print('Usage: mvvm create <project_name>');
      return 64;
    }
    final project = argResults!.rest.first;
    final force = argResults!['force'] as bool;
    final generator = ProjectGenerator(projectName: project, force: force);
    await generator.generate();
    return 0;
  }
}