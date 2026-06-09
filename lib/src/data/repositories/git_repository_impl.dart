import '../datasources/git_local_datasource.dart';
import '../datasources/file_local_datasource.dart';
import '../../domain/entities/fixed_semantics_item.dart';
import '../../domain/repositories/git_repository.dart';

class GitRepositoryImpl implements GitRepository {
  final GitLocalDatasource gitDatasource;
  final FileLocalDatasource fileDatasource;

  GitRepositoryImpl({
    required this.gitDatasource,
    required this.fileDatasource,
  });

  @override
  Future<List<String>> getChangedFiles() async {
    try {
      List<String> diffResult = [];
      
      // Deteksi branch utama untuk dibandingkan (main, development, master)
      for (final baseBranch in ['main', 'development', 'master']) {
        try {
          // git diff --name-only baseBranch...HEAD mendeteksi semua file yang dimodifikasi di branch aktif
          // sejak bercabang dari baseBranch (termasuk commit lokal)
          diffResult = await gitDatasource.runCommand(['diff', '--name-only', '$baseBranch...HEAD']);
          if (diffResult.isNotEmpty) break;
        } catch (_) {}
      }

      // Jika tidak ada branch perbandingan atau kita berada di branch utama, fallback ke perubahan lokal
      if (diffResult.isEmpty) {
        diffResult = await gitDatasource.runCommand(['diff', '--name-only', 'HEAD']);
      }

      final untrackedResult = await gitDatasource.runCommand(['ls-files', '--others', '--exclude-standard']);
      return {...diffResult, ...untrackedResult}.toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<FixedSemanticsItem>> getFixedSemantics(String baseBranch) async {
    final fixedList = <FixedSemanticsItem>[];
    try {
      List<String> diffOutput = [];

      // Try the requested baseBranch first if it is not HEAD
      if (baseBranch.isNotEmpty && baseBranch != 'HEAD') {
        try {
          diffOutput = await gitDatasource.runCommand(['diff', '-U0', baseBranch]);
        } catch (_) {}
      }

      // Fallback to main
      if (diffOutput.isEmpty) {
        try {
          diffOutput = await gitDatasource.runCommand(['diff', '-U0', 'main']);
        } catch (_) {}
      }

      // Fallback to development
      if (diffOutput.isEmpty) {
        try {
          diffOutput = await gitDatasource.runCommand(['diff', '-U0', 'development']);
        } catch (_) {}
      }

      // Fallback to HEAD
      if (diffOutput.isEmpty) {
        try {
          diffOutput = await gitDatasource.runCommand(['diff', '-U0', 'HEAD']);
        } catch (_) {}
      }

      String? currentFile;
      for (final line in diffOutput) {
        if (line.startsWith('+++ b/')) {
          currentFile = line.substring(6);
          continue;
        }

        if (currentFile == null || !currentFile.endsWith('.dart')) continue;
        if (!fileDatasource.fileExists(currentFile)) continue;

        final chunkHeader = RegExp(r'^@@\s+-\d+(?:,\d+)?\s+\+(\d+)(?:,(\d+))?\s+@@').firstMatch(line);
        if (chunkHeader != null) {
          final startLine = int.parse(chunkHeader.group(1)!);
          final lineCount = chunkHeader.group(2) != null ? int.parse(chunkHeader.group(2)!) : 1;

          final content = await fileDatasource.readFileAsString(currentFile);
          final fileLines = content.split('\n');

          for (int i = 0; i < lineCount; i++) {
            final fileLineIdx = startLine + i - 1;
            if (fileLineIdx < 0 || fileLineIdx >= fileLines.length) continue;

            final fileLineContent = fileLines[fileLineIdx];
            final semanticsMatch = RegExp(
              r'\b(?:[a-zA-Z0-9_]*semanticsIdentifier|[a-zA-Z0-9_]*identifier|[a-zA-Z0-9_]*id)\s*:\s*[\x27\x22]([^\x27\x22]+)[\x27\x22]',
              caseSensitive: false,
            ).firstMatch(fileLineContent);
            
            if (semanticsMatch != null) {
              final identifier = semanticsMatch.group(1)!;

              String widgetName = 'Semantics';
              for (int backtrack = fileLineIdx; backtrack >= 0; backtrack--) {
                final backtrackLine = fileLines[backtrack].trim();
                final classMatch = RegExp(r'\b([A-Z][a-zA-Z0-9_]*)\s*\(').firstMatch(backtrackLine);
                if (classMatch != null) {
                  widgetName = classMatch.group(1)!;
                  break;
                }
              }

              fixedList.add(FixedSemanticsItem(
                file: currentFile,
                line: fileLineIdx + 1,
                widget: widgetName,
                identifier: identifier,
              ));
            }
          }
        }
      }
    } catch (_) {}
    return fixedList;
  }
}
