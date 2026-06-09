import 'dart:io';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/analysis/results.dart';

class FileLocalDatasource {
  bool fileExists(String path) => File(path).existsSync();
  bool dirExists(String path) => Directory(path).existsSync();

  Future<String> readFileAsString(String path) async {
    return File(path).readAsString();
  }

  Future<void> writeStringToFile(String path, String contents) async {
    final file = File(path);
    final parent = file.parent;
    if (!parent.existsSync()) {
      await parent.create(recursive: true);
    }
    await file.writeAsString(contents);
  }

  Future<List<String>> listFiles(String path) async {
    final dir = Directory(path);
    if (!dir.existsSync()) return [];
    return dir
        .list(recursive: true)
        .where((entity) => entity is File)
        .map((entity) => entity.path)
        .toList();
  }

  ParseStringResult parseDartString(String content) {
    return parseString(content: content);
  }
}
