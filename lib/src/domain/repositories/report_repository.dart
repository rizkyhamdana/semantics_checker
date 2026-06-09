import '../entities/semantics_issue.dart';
import '../entities/fixed_semantics_item.dart';

abstract class ReportRepository {
  Future<void> generateReports(List<SemanticsIssue> issues, List<FixedSemanticsItem> fixedList);
}
