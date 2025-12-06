import 'dart:io';
import 'package:path/path.dart' as p;
import '../templates/templates.dart';

class ServiceGenerator {
  final String serviceName;
  final bool force;
  ServiceGenerator({required this.serviceName, this.force = false});

  Future<void> generate() async {
    final n = serviceName.toLowerCase();
    final className = _toPascal(serviceName);
    final repoPath = p.join('lib', 'data', 'repos', '\${n}_repo.dart');
    final servicePath = p.join('lib', 'data', 'services', '\${n}_service.dart');
    final slPath =
        p.join('lib', 'core', 'service_locator', 'service_locator.dart');

    await _createFile(repoPath, repoTemplate(n, className));
    await _createFile(servicePath, serviceTemplate(n, className));
    print('Created repo and service: \$repoPath, \$servicePath');

    final slFile = File(slPath);
    if (!await slFile.exists()) {
      await _createFile(slPath, serviceLocatorTemplate);
      print('Created service locator template at \$slPath');
    }

    var content = await slFile.readAsString();

    final importLine = "import '../../data/services/\${n}_service.dart';";
    if (!content.contains(importLine)) {
      final lines = content.split('\n');
      int lastImportIndex = -1;
      for (int i = 0; i < lines.length; i++) {
        if (lines[i].trim().startsWith('import ')) lastImportIndex = i;
      }
      if (lastImportIndex >= 0)
        lines.insert(lastImportIndex + 1, importLine);
      else
        lines.insert(0, importLine);
      content = lines.join('\n');
      print('Inserted import for \${n}_service');
    }

    final registerCall = '_register\${className}Service();';
    final initPattern = 'Future<void> initServiceLocator() async {';
    if (content.contains(initPattern)) {
      if (!content.contains(registerCall)) {
        content = content.replaceFirst(
            initPattern,
            initPattern +
                '\n  // auto-registered by mvvm CLI\n  \$registerCall');
        print('Inserted registration call into initServiceLocator()');
      }
    } else {
      content +=
          '\n\nFuture<void> initServiceLocator() async {\n  // auto-registered by mvvm CLI\n  \$registerCall\n}\n';
      print('Appended initServiceLocator()');
    }

    // final registerFuncName = '_register\${className}Service';
    // if (!content.contains('void \$registerFuncName()')) {
    //   final registration = '\n\nvoid \$registerFuncName() {\n  final service = \${className}Service();\n  getIt.registerLazySingleton<\${className}Service>(() => service);\n}\n';
    //   content += registration;
    //   print('Appended private registration function \$registerFuncName');
    // }

    await slFile.writeAsString(content);
    print('Service locator updated');
  }

  Future<void> _createFile(String path, String content) async {
    final f = File(path);
    if (await f.exists()) {
      if (!force) {
        print('Skipped (exists): \$path');
        return;
      }
      await f.delete();
    }
    await f.create(recursive: true);
    await f.writeAsString(content);
    print('Created file: \$path');
  }

  String _toPascal(String s) => s
      .split(RegExp('[_\\- ]+'))
      .map((p) => p.isEmpty ? '' : p[0].toUpperCase() + p.substring(1))
      .join();
}
