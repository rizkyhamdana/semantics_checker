class SemanticsConfig {
  final List<String> targetWidgets;
  final List<String> excludePaths;
  final String idPattern;
  final List<String> semanticsProperties;

  SemanticsConfig({
    required this.targetWidgets,
    required this.excludePaths,
    required this.idPattern,
    required this.semanticsProperties,
  });
}
