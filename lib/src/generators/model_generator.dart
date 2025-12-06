import 'dart:io';
import 'package:path/path.dart' as p;
import '../templates/templates.dart';

class ModelGenerator {
  final String modelName;
  final bool force;
  ModelGenerator({required this.modelName, this.force = false});

  Future<void> generate() async {
    final n = modelName.toLowerCase();
    final className = _toPascal(modelName);
    final modelPath = p.join('lib', 'data', 'models', '\${n}_model.dart');
    await _createFile(modelPath, modelJsonTemplate(n, className));
    print('Model created: \$modelPath');
  }

  Future<void> _createFile(String path, String content) async {
    final f = File(path);
    if (await f.exists()) {
      if (!force) { print('Skipped (exists): \$path'); return; }
      await f.delete();
    }
    await f.create(recursive: true);
    await f.writeAsString(content);
    print('Created file: \$path');
  }

  String _toPascal(String s) => s.split(RegExp('[_\\- ]+')).map((p) => p.isEmpty ? '' : p[0].toUpperCase() + p.substring(1)).join();
}