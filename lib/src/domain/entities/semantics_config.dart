class SemanticsConfig {
  final List<String> targetWidgets;
  final List<String> excludePaths;
  final String idPattern;
  final List<String> semanticsProperties;
  final List<String> defaultWidgets;
  final List<String> defaultIdentifiers;

  SemanticsConfig({
    required this.targetWidgets,
    required this.excludePaths,
    required this.idPattern,
    required this.semanticsProperties,
    required this.defaultWidgets,
    required this.defaultIdentifiers,
  });
}
