import 'package:yaml/yaml.dart';
import '../datasources/file_local_datasource.dart';
import '../../domain/entities/semantics_config.dart';
import '../../domain/repositories/config_repository.dart';

class ConfigRepositoryImpl implements ConfigRepository {
  final FileLocalDatasource fileDatasource;

  ConfigRepositoryImpl(this.fileDatasource);

  @override
  Future<SemanticsConfig> loadConfig(String configPath) async {
    final targets = <String>[];
    final excludes = <String>[];
    final semanticsProps = <String>[];
    final defaultWgts = <String>[];
    final defaultIds = <String>[];
    String idPattern = '^[a-z0-9_]+\$'; // Default snake_case regex

    if (fileDatasource.fileExists(configPath)) {
      try {
        final content = await fileDatasource.readFileAsString(configPath);
        final doc = loadYaml(content);
        if (doc != null && doc is YamlMap) {
          if (doc['target_widgets'] != null && doc['target_widgets'] is YamlList) {
            targets.addAll(List<String>.from(doc['target_widgets']));
          }
          if (doc['exclude_paths'] != null && doc['exclude_paths'] is YamlList) {
            excludes.addAll(List<String>.from(doc['exclude_paths']));
          }
          if (doc['semantics_properties'] != null && doc['semantics_properties'] is YamlList) {
            semanticsProps.addAll(List<String>.from(doc['semantics_properties']));
          }
          if (doc['id_pattern'] != null && doc['id_pattern'] is String) {
            idPattern = doc['id_pattern'] as String;
          }
          if (doc['default_widgets'] != null && doc['default_widgets'] is YamlList) {
            defaultWgts.addAll(List<String>.from(doc['default_widgets']));
          }
          if (doc['default_identifiers'] != null && doc['default_identifiers'] is YamlList) {
            defaultIds.addAll(List<String>.from(doc['default_identifiers']));
          }
        }
      } catch (_) {}
    }

    // Fallback defaults if configuration is empty
    if (targets.isEmpty) {
      targets.addAll([
        'CustomButton',
        'CustomButtonAnimationLoading',
        'CustomTextField',
        'LabeledTextField',
        'ElevatedButton',
        'TextButton',
        'OutlinedButton',
        'IconButton',
        'GestureDetector',
        'InkWell',
        'ListTile',
        'TextField',
        'TextFormField',
        'Radio',
        'FloatingActionButton',
      ]);
    }

    if (semanticsProps.isEmpty) {
      semanticsProps.addAll([
        'semanticsIdentifier',
        'identifier',
        'identifierId',
        'semanticsId',
        'id',
      ]);
    }

    return SemanticsConfig(
      targetWidgets: targets,
      excludePaths: excludes,
      idPattern: idPattern,
      semanticsProperties: semanticsProps,
      defaultWidgets: defaultWgts,
      defaultIdentifiers: defaultIds,
    );
  }
}
