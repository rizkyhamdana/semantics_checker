class SemanticsIssue {
  final String filePath;
  final int line;
  final String widgetName;
  final String suggestion;
  final String codeSnippet;
  final bool isFormatIssue;
  final String? errorMessage;
  final bool isWarning;

  SemanticsIssue({
    required this.filePath,
    required this.line,
    required this.widgetName,
    required this.suggestion,
    required this.codeSnippet,
    this.isFormatIssue = false,
    this.errorMessage,
    this.isWarning = false,
  });
}
