import 'dart:io';
import 'package:path/path.dart' as p;
import '../templates/templates.dart';

class ProjectGenerator {
  final String projectName;
  final bool force;
  ProjectGenerator({required this.projectName, this.force = false});

  Future<void> generate() async {
    print('Creating flutter project "\$projectName"...');

    final flutterCmd = Platform.isWindows ? 'flutter.bat' : 'flutter';
    final result = await Process.run(
        flutterCmd, ['create', projectName, '--empty'],
        runInShell: true);
    stdout.write(result.stdout);
    stderr.write(result.stderr);
    if (result.exitCode != 0) {
      print('flutter create failed with exit code \${result.exitCode}');
      return;
    }

    await _createStructure();
    await _createTemplates();
    await _patchPubspec();

    print(
        'Project "\$projectName" created. Run `cd \$projectName` then `flutter pub get`.');
  }

  Future<void> _createStructure() async {
    final lib = p.join(projectName, 'lib');
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
      final d = Directory(f);
      if (!await d.exists()) {
        await d.create(recursive: true);
        print('Created directory: \$f');
      }
    }
  }

  Future<void> _createTemplates() async {
    final lib = p.join(projectName, 'lib');
    await _createFile(
        p.join(lib, 'core', 'either', 'either.dart'), eitherTemplate);
    await _createFile(
        p.join(lib, 'core', 'service_locator', 'service_locator.dart'),
        serviceLocatorTemplate);
    await _createFile(
        p.join(lib, 'core', 'routes', 'app_routes.dart'), routesTemplate);
    await _createFile(
        p.join(lib, 'core', 'theme', 'app_theme.dart'), appThemeTemplate);

    // main with proper package name
    final mainContent = mainTemplateWithSl.replaceAll(r"$project", projectName);
    await _createFile(p.join(lib, 'main.dart'), mainContent);
    await _createFile(
        p.join(projectName, 'MVVM_README.md'), mvvmReadmeTemplate);
    await _createFile(
        p.join(projectName, 'analysis_options.yaml'), mvvmAnalysisTemplate);
  }

  Future<void> _createFile(String path, String content,
      {bool overwrite = false}) async {
    final f = File(path);

    if (await f.exists()) {
      if (!overwrite) {
        print('Skipped (exists): $path');
        return;
      }
      await f.delete(); // remove old file before creating new
      print('Overwriting file: $path');
    }

    await f.create(recursive: true);
    await f.writeAsString(content);
    print('Created file: $path');
  }

  Future<void> _patchPubspec() async {
    final pubspec = File(p.join(projectName, 'pubspec.yaml'));
    if (!await pubspec.exists()) {
      print('Warning: pubspec.yaml not found, skipping dependency patch.');
      return;
    }

    var content = await pubspec.readAsString();

    final depsToAdd = {
      'get_it:': '  get_it: ^8.1.1',
      'json_annotation:': '  json_annotation: ^4.8.0',
    };

    final devDepsToAdd = {
      'build_runner:': '  build_runner: ^2.4.6',
      'json_serializable:': '  json_serializable: ^6.6.0',
      'very_good_analysis:': '  very_good_analysis: ^10.0.0',
    };

    if (!content.contains('dependencies:')) {
      content += '\ndependencies:\n';
    }
    for (final key in depsToAdd.keys) {
      if (!content.contains(key)) {
        content = content.replaceFirst(RegExp(r'dependencies:\s*\n'),
            'dependencies:\n${depsToAdd[key]}\n');
        print('Inserted dependency \$key');
      }
    }

    if (!content.contains('dev_dependencies:')) {
      content += '\n\ndev_dependencies:\n';
    }
    for (final key in devDepsToAdd.keys) {
      if (!content.contains(key)) {
        content = content.replaceFirst(RegExp(r'dev_dependencies:\s*\n'),
            'dev_dependencies:\n${devDepsToAdd[key]}\n');
        print('Inserted dev_dependency \$key');
      }
    }

    await pubspec.writeAsString(content);
    print('Pubspec patch complete.');
  }
}
