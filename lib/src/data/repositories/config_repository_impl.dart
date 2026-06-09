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

    return SemanticsConfig(
      targetWidgets: targets,
      excludePaths: excludes,
    );
  }
}
