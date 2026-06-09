import '../entities/semantics_config.dart';

abstract class ConfigRepository {
  Future<SemanticsConfig> loadConfig(String configPath);
}
