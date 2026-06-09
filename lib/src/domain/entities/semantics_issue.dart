class SemanticsIssue {
  final String filePath;
  final int line;
  final String widgetName;
  final String suggestion;
  final String codeSnippet;

  SemanticsIssue({
    required this.filePath,
    required this.line,
    required this.widgetName,
    required this.suggestion,
    required this.codeSnippet,
  });
}
