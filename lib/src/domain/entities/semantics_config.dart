class SemanticsConfig {
  final List<String> targetWidgets;
  final List<String> excludePaths;
  final String idPattern;

  SemanticsConfig({
    required this.targetWidgets,
    required this.excludePaths,
    required this.idPattern,
  });
}
