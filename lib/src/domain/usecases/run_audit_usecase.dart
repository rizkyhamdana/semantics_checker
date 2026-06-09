import '../entities/semantics_issue.dart';
import '../entities/fixed_semantics_item.dart';
import '../repositories/git_repository.dart';
import '../repositories/config_repository.dart';
import '../repositories/analyzer_repository.dart';
import '../repositories/report_repository.dart';

class RunAuditResult {
  final List<SemanticsIssue> issues;
  final List<FixedSemanticsItem> fixedList;

  RunAuditResult({required this.issues, required this.fixedList});
}

class RunAuditUseCase {
  final GitRepository gitRepository;
  final ConfigRepository configRepository;
  final AnalyzerRepository analyzerRepository;
  final ReportRepository reportRepository;

  RunAuditUseCase({
    required this.gitRepository,
    required this.configRepository,
    required this.analyzerRepository,
    required this.reportRepository,
  });

  Future<RunAuditResult> execute({
    required bool allFiles,
    required String configPath,
    required String baseBranch,
  }) async {
    // 1. Load config
    final config = await configRepository.loadConfig(configPath);

    // 2. Identify target files to scan
    List<String> targetFiles;
    if (allFiles) {
      targetFiles = await analyzerRepository.listAllDartFiles('lib', config);
    } else {
      final changed = await gitRepository.getChangedFiles();
      // Filter out files that don't match or are excluded in config
      targetFiles = changed.where((file) {
        if (!file.endsWith('.dart')) return false;
        for (final exclude in config.excludePaths) {
          if (file.contains(exclude)) return false;
        }
        return true;
      }).toList();
    }

    // 3. Scan files
    final issues = await analyzerRepository.analyzeFiles(targetFiles, config);

    // 4. Retrieve fixed semantics on current branch
    final rawFixedList = await gitRepository.getFixedSemantics(baseBranch);
    
    // Filter hanya memasukkan yang format ID-nya benar ke dalam Fixed Semantics list
    final fixedList = rawFixedList.where((item) {
      final cleanVal = item.identifier
          .replaceAll(RegExp(r'\\?\$[a-zA-Z0-9_]+'), '')
          .replaceAll(RegExp(r'\\?\$\{[a-zA-Z0-9_]+\}'), '');
      return RegExp(config.idPattern).hasMatch(cleanVal);
    }).toList();

    // 5. Generate PDF, HTML, Markdown reports
    await reportRepository.generateReports(issues, fixedList);

    return RunAuditResult(issues: issues, fixedList: fixedList);
  }
}
