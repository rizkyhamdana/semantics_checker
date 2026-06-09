import '../entities/semantics_issue.dart';
import '../entities/semantics_config.dart';

abstract class AnalyzerRepository {
  Future<List<SemanticsIssue>> analyzeFiles(List<String> filePaths, SemanticsConfig config);
  Future<List<String>> listAllDartFiles(String directory, SemanticsConfig config);
}
