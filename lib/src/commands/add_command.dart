import 'package:args/command_runner.dart';
import '../generators/feature_generator.dart';
import '../generators/service_generator.dart';
import '../generators/model_generator.dart';
import '../generators/repo_generator.dart';

class AddCommand extends Command<int> {
  @override
  final name = 'add';
  @override
  final description = 'Add feature/service/model/repo to an existing project';

  AddCommand() {
    argParser.addFlag('force', abbr: 'f', negatable: false);
  }

  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.length < 2) {
      print('Usage: mvvm add <type> <name>');
      return 64;
    }
    final type = rest[0];
    final name = rest[1];
    final force = argResults!['force'] as bool;

    switch (type) {
      case 'feature':
        await FeatureGenerator(featureName: name, force: force).generate();
        break;
      case 'service':
        await ServiceGenerator(serviceName: name, force: force).generate();
        break;
      case 'model':
        await ModelGenerator(modelName: name, force: force).generate();
        break;
      case 'repo':
      case 'repository':
        await RepoGenerator(repoName: name, force: force).generate();
        break;
      default:
        print('Unknown type: \$type');
        return 64;
    }
    return 0;
  }
}