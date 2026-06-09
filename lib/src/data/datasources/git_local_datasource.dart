import 'dart:io';

class GitLocalDatasource {
  Future<List<String>> runCommand(List<String> arguments) async {
    final result = await Process.run('git', arguments);
    if (result.exitCode != 0) {
      throw ProcessException('git', arguments, result.stderr.toString(), result.exitCode);
    }
    return result.stdout.toString().split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
  }
}
