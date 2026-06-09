class SemanticsIssue {
  final String filePath;
  final int line;
  final String widgetName;
  final String suggestion;
  final String codeSnippet;
  final bool isFormatIssue;
  final String? errorMessage;

  SemanticsIssue({
    required this.filePath,
    required this.line,
    required this.widgetName,
    required this.suggestion,
    required this.codeSnippet,
    this.isFormatIssue = false,
    this.errorMessage,
  });
}
