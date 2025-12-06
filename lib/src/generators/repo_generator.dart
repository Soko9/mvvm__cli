import 'dart:io';
import 'package:path/path.dart' as p;
import '../templates/templates.dart';

class RepoGenerator {
  final String repoName;
  final bool force;
  RepoGenerator({required this.repoName, this.force = false});

  Future<void> generate() async {
    final n = repoName.toLowerCase();
    final className = _toPascal(repoName);
    final repoPath = p.join('lib', 'data', 'repos', '\${n}_repo.dart');
    await _createFile(repoPath, repoTemplate(n, className));
    print('Repository created: \$repoPath');
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