import '../entities/fixed_semantics_item.dart';

abstract class GitRepository {
  Future<List<String>> getChangedFiles();
  Future<List<FixedSemanticsItem>> getFixedSemantics(String baseBranch, List<String> semanticsProperties);
}
