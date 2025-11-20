// dart pub global activate --source path .

import 'dart:io';
import 'package:args/args.dart';
import 'package:path/path.dart' as p;

const toolVersion = '1.0.0';

void printToolVersion() {
  print('mvvm CLI Tool');
  print('mvvm CLI version $toolVersion');
}

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addFlag('version',
        abbr: 'v', negatable: false, help: 'Show the tool version')
    ..addCommand('create')
    ..addCommand('add')
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show help');

  try {
    final results = parser.parse(arguments);
    if (results['version'] == true) {
      printToolVersion();
      return;
    }

    if (results['help'] == true || results.command == null) {
      printHelp();
      return;
    }

    final command = results.command!;
    switch (command.name) {
      case 'create':
        await handleCreate(command.arguments);
        break;
      case 'add':
        await handleAdd(command.arguments);
        break;
      default:
        printHelp();
    }
  } catch (e) {
    print('Error: $e');
    printHelp();
  }
}

void printHelp() {
  print('''
mvvm — Flutter MVVM project generator (global)

Usage:
  mvvm create <project_name>               Create a new Flutter project with MVVM structure
  mvvm add feature <name>                  Add a feature (view + viewmodel using ValueNotifier)
  mvvm add service <name>                  Add a service + repo and register them into GetIt service locator
  mvvm add model <name>                    Add a json_serializable model (creates model + part file)
  mvvm add repo <name>                     Add a repository file

Examples:
  mvvm create tasty_plan
  mvvm add feature login
  mvvm add service auth
  mvvm add model user
''');
}

/// ---------------------- CREATE --------------------------
Future<void> handleCreate(List<String> args) async {
  if (args.isEmpty) {
    print('Error: project name required.');
    return;
  }

  final projectName = args.first;
  print('Creating flutter project "$projectName"...');

  final flutterPath = r"C:\src\flutter\bin\flutter.bat";
  print('Using flutter at: $flutterPath');

  // Use runInShell: true so Windows can find flutter.bat
  final result = await Process.run(
    flutterPath,
    ['create', projectName, '--empty'],
    runInShell: true,
  );

  // Print stdout and stderr
  stdout.write(result.stdout);
  stderr.write(result.stderr);

  if (result.exitCode != 0) {
    print('flutter create failed with exit code ${result.exitCode}');
    return;
  }

  print('Project created — setting up MVVM structure...');

  // Your existing MVVM setup functions
  await createMvvmStructure(projectName);
  await patchPubspec(projectName);

  print(
      'Done. Run `cd $projectName` then `flutter pub get` and follow the README instructions.');
}

/// Create folder structure and files
Future<void> createMvvmStructure(String project) async {
  final lib = p.join(project, 'lib');

  final folders = [
    p.join(lib, 'core', 'errors'),
    p.join(lib, 'core', 'either'),
    p.join(lib, 'core', 'routes'),
    p.join(lib, 'core', 'theme'),
    p.join(lib, 'core', 'shared', 'widgets'),
    p.join(lib, 'core', 'shared', 'helpers'),
    p.join(lib, 'core', 'shared', 'extensions'),
    p.join(lib, 'core', 'service_locator'),
    p.join(lib, 'data', 'models'),
    p.join(lib, 'data', 'repos'),
    p.join(lib, 'data', 'services'),
    p.join(lib, 'features'),
  ];

  for (final f in folders) {
    await _createDirectory(f);
  }

  // create templates
  await _createFile(
      p.join(lib, 'core', 'either', 'either.dart'), eitherTemplate);
  await _createFile(
      p.join(lib, 'core', 'service_locator', 'service_locator.dart'),
      serviceLocatorTemplate);
  await _createFile(
      p.join(lib, 'core', 'routes', 'app_routes.dart'), routesTemplate);
  await _createFile(
      p.join(lib, 'core', 'theme', 'app_theme.dart'), appThemeTemplate);

  final mainFile = File('testing_app/lib/main.dart');

  if (await mainFile.exists()) {
    await mainFile.delete();
  }
  await _createFile(p.join(lib, 'main.dart'), mainTemplateWithSl);

  // add README-extra
  await _createFile(p.join(project, 'MVVM_README.md'), mvvmReadmeTemplate);

  final analysisFile = File('testing_app/analysis_options.yaml');

  if (await analysisFile.exists()) {
    await analysisFile.delete();
  }
  await _createFile(
      p.join(project, 'analysis_options.yaml'), mvvmAnalysisTemplate);
}

/// ---------------------- PATCH PUBSPEC --------------------------
Future<void> patchPubspec(String project) async {
  final pubspec = File(p.join(project, 'pubspec.yaml'));
  if (!await pubspec.exists()) {
    print('Warning: pubspec.yaml not found, skipping dependency patch.');
    return;
  }
  var content = await pubspec.readAsString();

  // dependencies & dev_dependencies to ensure
  final deps = '''
  get_it: ^8.1.1
  json_annotation: ^4.8.0
  ''';

  final devDeps = '''
  build_runner: ^2.4.6
  json_serializable: ^6.6.0
  very_good_analysis: ^10.0.0
  ''';

  // Insert (naive) — if dependencies key exists, append after it
  if (content.contains('dependencies:')) {
    content = content.replaceFirst(
        RegExp(r'dependencies:\s*\n'), 'dependencies:\n$deps\n');
  } else {
    content += 'dependencies:\n$deps\n';
  }

  if (content.contains('dev_dependencies:')) {
    content = content.replaceFirst(
        RegExp(r'dev_dependencies:\s*\n'), 'dev_dependencies:\n$devDeps\n');
  } else {
    content += '\n\ndev_dependencies:\n$devDeps\n';
  }

  await pubspec.writeAsString(content);

  print(
      'Patched pubspec.yaml with get_it and json_serializable (please run `flutter pub get`).');
}

/// ---------------------- ADD COMMANDS --------------------------
Future<void> handleAdd(List<String> args) async {
  if (args.length < 2) {
    print('Error: add <type> <name>');
    return;
  }
  final type = args[0];
  final name = args[1];

  switch (type) {
    case 'feature':
      await addFeature(name);
      break;
    case 'service':
      await addServiceAndRepo(name);
      break;
    case 'model':
      await addModel(name);
      break;
    case 'repo':
    case 'repository':
      await addRepo(name);
      break;
    default:
      print('Unknown add type: $type');
  }
}

/// Add feature -> view + viewmodel (ValueNotifier)
Future<void> addFeature(String name) async {
  final feature = name.toLowerCase();
  final featureDir = p.join('lib', 'features', feature);
  await _createDirectory(featureDir);
  final viewFile = p.join(featureDir, '${feature}_view.dart');
  final vmFile = p.join(featureDir, '${feature}_viewmodel.dart');

  await _createFile(
      viewFile, viewUsingValueNotifierTemplate(feature, toPascal(name)));
  await _createFile(
      vmFile, viewModelValueNotifierTemplate(feature, toPascal(name)));
  print('Feature created:\n - $viewFile\n - $vmFile');
}

/// Add service + repo and register into service_locator
Future<void> addServiceAndRepo(String name) async {
  final n = name.toLowerCase();
  final className = toPascal(name);
  final repoPath = p.join('lib', 'data', 'repos', '${n}_repo.dart');
  final servicePath = p.join('lib', 'data', 'services', '${n}_service.dart');
  final slPath =
      p.join('lib', 'core', 'service_locator', 'service_locator.dart');

  await _createFile(repoPath, repoTemplate(n, className));
  await _createFile(servicePath, serviceTemplate(n, className));
  print('Created repo and service:\n - $repoPath\n - $servicePath');

  // Register in service locator (append registration lines)
  if (await File(slPath).exists()) {
    final registration = '''
void _register${n[0].toUpperCase()}${n.substring(1)}() {
  final service = ${className}Service();
  getIt.registerLazySingleton<${className}Service>(() => service);
}
_register${n[0].toUpperCase()}${n.substring(1)}();
''';
    final file = File(slPath);
    var content = await file.readAsString();
    content += '''import '../../data/services/${n}_service.dart';'''
    content = content + '\n' + registration;
    await file.writeAsString(content);
    print('Registered $className service into service_locator.');
  } else {
    print(
        'service_locator not found at $slPath — created service but could not auto-register.');
  }
}

/// Add model (json_serializable) — creates model and part file reference
Future<void> addModel(String name) async {
  final n = name.toLowerCase();
  final className = toPascal(name);
  final modelPath = p.join('lib', 'data', 'models', '${n}_model.dart');

  await _createFile(modelPath, modelJsonTemplate(n, className));
  print('Model created: $modelPath');
  print(
      'Run: flutter pub run build_runner build --delete-conflicting-outputs to generate *.g.dart');
}

/// Add repo only
Future<void> addRepo(String name) async {
  final n = name.toLowerCase();
  final className = toPascal(name);
  final repoPath = p.join('lib', 'data', 'repos', '${n}_repo.dart');
  await _createFile(repoPath, repoTemplate(n, className));
  print('Repository created: $repoPath');
}

/// ---------------------- UTIL --------------------------
String toPascal(String s) {
  return s
      .split(RegExp('[_\\- ]+'))
      .map((p) => p.isEmpty ? '' : p[0].toUpperCase() + p.substring(1))
      .join();
}

Future<void> _createDirectory(String dir) async {
  final d = Directory(dir);
  if (!(await d.exists())) {
    await d.create(recursive: true);
    print('Created directory: $dir');
  }
}

Future<void> _createFile(String path, String content) async {
  final f = File(path);
  if (await f.exists()) {
    print('Skipped (exists): $path');
    return;
  }
  await f.create(recursive: true);
  await f.writeAsString(content);
  print('Created file: $path');
}

/// ---------------------- TEMPLATES --------------------------

const eitherTemplate = r'''
/// Simple Either implementation
abstract class Either<L, R> {
  const Either();
  B fold<B>(B Function(L l) leftF, B Function(R r) rightF);
}

class Left<L, R> extends Either<L, R> {
  const Left(this.value);
  final L value;
  @override
  B fold<B>(B Function(L l) leftF, B Function(R r) rightF) => leftF(value);
}

class Right<L, R> extends Either<L, R> {
  const Right(this.value);
  final R value;
  @override
  B fold<B>(B Function(L l) leftF, B Function(R r) rightF) => rightF(value);
}
''';

const serviceLocatorTemplate = r'''
import 'package:get_it/get_it.dart';

final GetIt getIt = GetIt.instance;

Future<void> initServiceLocator() async {
  // Register core services here
}
''';

const routesTemplate = r'''
import 'package:flutter/material.dart';

class AppRoutes {
  static const home = '/';
  // add more routes as static strings
}

Route<dynamic>? generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case AppRoutes.home:
      return MaterialPageRoute(builder: (_) => const HomeScreen());
    default:
      return MaterialPageRoute(builder: (_) => const _ErrorScreen());
  }
}

class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Error: Route not found',
          style: TextStyle(color: Colors.red, fontSize: 18),
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Welcome to the Home Screen',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}
''';

const appThemeTemplate = r'''
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData light() {
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
    );
  }

  static ThemeData dark() {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
    );
  }
}
''';

const mainTemplateWithSl = r'''
import 'package:flutter/material.dart';
import 'package:testing_app/core/routes/app_routes.dart';
import 'package:testing_app/core/service_locator/service_locator.dart';
import 'package:testing_app/core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initServiceLocator();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MVVM App',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      onGenerateRoute: generateRoute,
      initialRoute: AppRoutes.home,
    );
  }
}
''';

const mvvmReadmeTemplate = '''
# MVVM scaffolding

This project was prepared by mvvm CLI tool.
- Features go inside lib/features/<feature>/
- Models: lib/data/models/
- Repos: lib/data/repos/
- Services: lib/data/services/
- Service locator: lib/core/service_locator/service_locator.dart

Run:
  flutter pub get
  flutter pub run build_runner build --delete-conflicting-outputs
''';

const mvvmAnalysisTemplate = '''
include: package:very_good_analysis/analysis_options.yaml
linter:
  rules:
    public_member_api_docs: false
analyzer:
  errors:
    one_member_abstracts: ignore
''';

String viewUsingValueNotifierTemplate(String feature, String className) => '''
import 'package:flutter/material.dart';
import './${feature}_viewmodel.dart';

class ${className}View extends StatelessWidget {
  ${className}View({super.key});

  final ${className}ViewModel viewModel = ${className}ViewModel();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('${className}')),
      body: Center(
        child: ValueListenableBuilder<bool>(
          valueListenable: viewModel.isLoading,
          builder: (context, isLoading, child) => isLoading 
            ? const CircularProgressIndicator() 
            : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: viewModel.load,
                  child: const Text('Hello from ${className}View!'),
                ),
              ],
            ),
        ),
      ),
    );
  }
}
''';

String viewModelValueNotifierTemplate(String feature, String className) => '''
import 'package:flutter/foundation.dart';

class ${className}ViewModel {
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);

  Future<void> load() async {
    isLoading.value = true;
    await Future.delayed(const Duration(seconds: 1));
    isLoading.value = false;
  }
}
''';

String repoTemplate(String name, String className) => '''
abstract interface class ${className}Repo {
  ${className}Repo();

  Future<List<dynamic>> fetchAll();
}
''';

String serviceTemplate(String name, String className) => '''
import '../repos/${name}_repo.dart';

class ${className}Service implements ${className}Repo {
  ${className}Service();

  @override
  Future<List<dynamic>> fetchAll() async {
    // implement your service logic here
    return [];
  }
}
''';

String modelJsonTemplate(String name, String className) => '''
import 'package:json_annotation/json_annotation.dart';

part '${name}_model.g.dart';

@JsonSerializable()
class ${className}Model {
  const ${className}Model({
    required this.id,
    required this.name,
  });

  factory ${className}Model.fromJson(Map<String, dynamic> json) 
          => _\$${className}ModelFromJson(json);

  final String id;
  final String name;

  Map<String, dynamic> toJson() => _\$${className}ModelToJson(this);
}
''';
