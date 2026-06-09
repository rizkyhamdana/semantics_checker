import 'dart:io';
import '../../domain/entities/semantics_issue.dart';
import '../../domain/entities/fixed_semantics_item.dart';
import 'brand_identity.dart';

class MarkdownReporter {
  static Future<void> generate(
    List<SemanticsIssue> issues,
    List<FixedSemanticsItem> fixedList,
    String dirPath,
  ) async {
    await BrandIdentity.writeReportLogo(dirPath);

    final buffer = StringBuffer();
    buffer.writeln(
        '![${BrandIdentity.appName}](${BrandIdentity.reportLogoFileName})');
    buffer.writeln('\n# ${BrandIdentity.reportTitle}\n');
    buffer.writeln('**${BrandIdentity.tagline}**\n');

    // 1. Alert Status Banner
    if (issues.isNotEmpty) {
      buffer.writeln('> [!WARNING]');
      buffer.writeln(
          '> **AUDIT FAILED**: Found ${issues.length} interactive elements lacking semantics identifiers.');
    } else {
      buffer.writeln('> [!NOTE]');
      buffer.writeln(
          '> **AUDIT PASSED**: All scanned widgets comply with semantics testing requirements.');
    }
    buffer.writeln('\n');

    // 2. Metrics Summary Table
    buffer.writeln('### 📊 Audit Metrics');
    buffer.writeln('| Metric | Value | Status |');
    buffer.writeln('| --- | --- | --- |');
    buffer.writeln(
        '| **Remaining Issues** | `${issues.length}` | ${issues.isEmpty ? "🟢 Passed" : "🔴 Action Required"} |');
    buffer.writeln(
        '| **Affected Files** | `${_groupIssuesByFile(issues).length}` | ${issues.isEmpty ? "🟢 None" : "⚠️ Review"} |');
    buffer.writeln(
        '| **Fixed Semantics in Branch** | `${fixedList.length}` | 🟢 Verified |');
    buffer.writeln('\n');

    // 2.1 Fixed Semantics list
    if (fixedList.isNotEmpty) {
      buffer.writeln('<details>');
      buffer.writeln(
          '<summary><b>✅ View Fixed Semantics in this Branch</b> (${fixedList.length} item${fixedList.length > 1 ? "s" : ""})</summary>\n');
      buffer.writeln('<br/>\n');
      buffer.writeln('| Line | Widget | Verified Semantics ID | File Path |');
      buffer.writeln('| :---: | :--- | :--- | :--- |');
      for (final item in fixedList) {
        buffer.writeln(
            '| **${item.line}** | `${item.widget}` | **`${item.identifier}`** | `${item.file}` |');
      }
      buffer.writeln('</details>\n');
    }

    // 3. Grouped Issues List
    if (issues.isNotEmpty) {
      buffer.writeln('### ⚠️ Remaining Issues by File\n');
      buffer.writeln(
          'Select a file below to view line details, suggestions, and source snippets:\n');

      final grouped = _groupIssuesByFile(issues);
      for (final group in grouped) {
        final totalIssues = group.issues.length;
        buffer.writeln('<details>');
        buffer.writeln(
            '<summary><b>📄 ${group.filePath}</b> ($totalIssues issue${totalIssues > 1 ? "s" : ""})</summary>\n');
        buffer.writeln('<br/>\n');

        buffer.writeln(
            '| Line | Widget | Suggested Semantics ID | Code Snippet |');
        buffer.writeln('| :---: | :--- | :--- | :--- |');

        for (final issue in group.issues) {
          final singleLineCode = issue.codeSnippet
              .replaceAll('\n', ' ')
              .replaceAll('\r', '')
              .trim();
          final formattedCodeSnippet = singleLineCode.length > 50
              ? '${singleLineCode.substring(0, 47)}...'
              : singleLineCode;

          final displaySuggestion = issue.isFormatIssue 
              ? '❌ _Format Salah_' 
              : '**`${issue.suggestion}`**';

          buffer.writeln(
              '| **${issue.line}** | `${issue.widgetName}` | $displaySuggestion | `${formattedCodeSnippet}` |');
        }

        buffer.writeln('\n');
        buffer.writeln('#### Detailed Code View\n');
        for (final issue in group.issues) {
          if (issue.isFormatIssue) {
            buffer.writeln(
                '**Line ${issue.line}** - `${issue.widgetName}` (⚠️ ${issue.errorMessage}):');
          } else {
            buffer.writeln(
                '**Line ${issue.line}** - `${issue.widgetName}` (Suggested: `${issue.suggestion}`):');
          }
          buffer.writeln('```dart');
          buffer.writeln(issue.codeSnippet.trim());
          buffer.writeln('```\n');
        }

        buffer.writeln('</details>\n');
      }
    } else {
      buffer.writeln('### 🎉 Excellent Quality Standards');
      buffer.writeln(
          'No remaining missing semantics issues found. Ready for automated testing execution.');
    }

    await File('$dirPath/report.md').writeAsString(buffer.toString());
    print('\x1B[1;32m✓ Markdown report created: $dirPath/report.md\x1B[0m');
  }

  static List<_IssueGroup> _groupIssuesByFile(List<SemanticsIssue> issues) {
    final Map<String, List<SemanticsIssue>> map = {};
    for (final issue in issues) {
      map.putIfAbsent(issue.filePath, () => []).add(issue);
    }
    return map.entries
        .map((e) => _IssueGroup(filePath: e.key, issues: e.value))
        .toList();
  }
}

class _IssueGroup {
  final String filePath;
  final List<SemanticsIssue> issues;

  _IssueGroup({required this.filePath, required this.issues});
}
