import 'dart:io';
import 'package:args/args.dart';
import '../../domain/usecases/run_audit_usecase.dart';
import '../../data/datasources/git_local_datasource.dart';
import '../../data/datasources/file_local_datasource.dart';
import '../../data/repositories/git_repository_impl.dart';
import '../../data/repositories/config_repository_impl.dart';
import '../../data/repositories/analyzer_repository_impl.dart';
import '../../data/repositories/report_repository_impl.dart';

class CliRunner {
  Future<void> run(List<String> arguments) async {
    final parser = ArgParser()
      ..addFlag('all', abbr: 'a', negatable: false, help: 'Scan all Dart files in the lib/ directory.');

    final argResults = parser.parse(arguments);
    final scanAll = argResults['all'] as bool;

    // Enforce running from the Flutter project root
    if (!File('pubspec.yaml').existsSync()) {
      print('❌ Error: pubspec.yaml not found in the current working directory.');
      print('Please run "dart run semantics_checker" from the root of your Flutter project.');
      exit(1);
    }

    print('=== Running Semantics Checker CLI ===');

    // 1. Dependency Injection setup
    final gitDatasource = GitLocalDatasource();
    final fileDatasource = FileLocalDatasource();

    final gitRepository = GitRepositoryImpl(
      gitDatasource: gitDatasource,
      fileDatasource: fileDatasource,
    );
    final configRepository = ConfigRepositoryImpl(fileDatasource);
    final analyzerRepository = AnalyzerRepositoryImpl(fileDatasource);
    final reportRepository = ReportRepositoryImpl();

    final runAuditUseCase = RunAuditUseCase(
      gitRepository: gitRepository,
      configRepository: configRepository,
      analyzerRepository: analyzerRepository,
      reportRepository: reportRepository,
    );

    try {
      // 2. Execute audit usecase
      final result = await runAuditUseCase.execute(
        allFiles: scanAll,
        configPath: 'semantics_checker.yaml',
        baseBranch: 'master',
      );

      // 3. Print issues in console
      final errors = result.issues.where((i) => !i.isWarning).toList();
      final warnings = result.issues.where((i) => i.isWarning).toList();

      if (result.issues.isNotEmpty) {
        for (final issue in result.issues) {
          print('\n📄 File: ${issue.filePath}');
          if (issue.isWarning) {
            print('  [Baris ${issue.line}] ⚠️ [WARNING] Widget "${issue.widgetName}": ${issue.errorMessage ?? "Missing semantics identifier (uses default widget value)."}');
            if (issue.suggestion.isNotEmpty) {
              print('    👉 Suggested unique ID: "${issue.suggestion}"');
            }
          } else if (issue.isFormatIssue) {
            print('  [Baris ${issue.line}] ❌ [ERROR] ${issue.errorMessage}');
          } else {
            print('  [Baris ${issue.line}] ❌ [ERROR] Widget "${issue.widgetName}" lacks semantics identifier.');
            print('    👉 Suggested placeholder ID: "${issue.suggestion}"');
          }
        }
      }

      print('\n=======================================');
      if (errors.isNotEmpty) {
        print('❌ Audit failed: Found ${errors.length} error(s) and ${warnings.length} warning(s).');
        exit(1);
      } else {
        if (warnings.isNotEmpty) {
          print('⚠️ Audit passed with warnings: Found ${warnings.length} warning(s). No blocking errors.');
        } else {
          if (scanAll) {
            print('🎉 Audit passed: All interactive widgets in the project have semantics identifiers!');
          } else {
            print('🎉 Audit passed: All changed interactive widgets have semantics identifiers!');
          }
        }
        exit(0);
      }
    } catch (e) {
      print('❌ Unexpected audit execution error: $e');
      exit(255);
    }
  }
}
