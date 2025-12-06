import 'dart:io';
import 'package:path/path.dart' as p;
import '../templates/templates.dart';

class FeatureGenerator {
  final String featureName;
  final bool force;
  FeatureGenerator({required this.featureName, this.force = false});

  Future<void> generate() async {
    final feature = featureName.toLowerCase();
    final dir = p.join('lib', 'features', feature);
    await Directory(dir).create(recursive: true);
    await _createFile(p.join(dir, '\${feature}_view.dart'), viewUsingValueNotifierTemplate(feature, _toPascal(feature)));
    await _createFile(p.join(dir, '\${feature}_viewmodel.dart'), viewModelValueNotifierTemplate(feature, _toPascal(feature)));
    print('Feature created: \$feature');
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