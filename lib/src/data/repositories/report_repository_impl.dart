import 'dart:io';
import '../reporters/pdf_reporter.dart';
import '../reporters/html_reporter.dart';
import '../reporters/markdown_reporter.dart';
import '../../domain/entities/semantics_issue.dart';
import '../../domain/entities/fixed_semantics_item.dart';
import '../../domain/repositories/report_repository.dart';

class ReportRepositoryImpl implements ReportRepository {
  final String reportDirectory;

  ReportRepositoryImpl({this.reportDirectory = 'semantics_report'});

  @override
  Future<void> generateReports(List<SemanticsIssue> issues, List<FixedSemanticsItem> fixedList) async {
    final reportDir = Directory(reportDirectory);
    if (!reportDir.existsSync()) {
      reportDir.createSync(recursive: true);
    }

    // 1. Generate PDF
    await PdfReporter.generate(issues, fixedList, reportDir.path);

    // 2. Generate HTML
    await HtmlReporter.generate(issues, fixedList, reportDir.path);

    // 3. Generate Markdown
    await MarkdownReporter.generate(issues, fixedList, reportDir.path);
  }
}
