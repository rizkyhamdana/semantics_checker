import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import '../datasources/file_local_datasource.dart';
import '../../domain/entities/semantics_issue.dart';
import '../../domain/entities/semantics_config.dart';
import '../../domain/repositories/analyzer_repository.dart';

class AnalyzerRepositoryImpl implements AnalyzerRepository {
  final FileLocalDatasource fileDatasource;

  AnalyzerRepositoryImpl(this.fileDatasource);

  @override
  Future<List<String>> listAllDartFiles(String directory, SemanticsConfig config) async {
    final allFiles = await fileDatasource.listFiles(directory);
    return allFiles.where((file) {
      if (!file.endsWith('.dart')) return false;
      for (final exclude in config.excludePaths) {
        if (file.contains(exclude)) return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<List<SemanticsIssue>> analyzeFiles(List<String> filePaths, SemanticsConfig config) async {
    final allIssues = <SemanticsIssue>[];
    final widgetsWithDefaults = <String, bool>{};

    try {
      // 1. Pre-scan all local Dart files to find class definitions and build defaults map
      final allFiles = await listAllDartFiles('lib', config);
      for (final file in allFiles) {
        if (!fileDatasource.fileExists(file)) continue;
        try {
          final content = await fileDatasource.readFileAsString(file);
          final parseResult = fileDatasource.parseDartString(content);
          
          final classVisitor = _ClassDefinitionVisitor(config.targetWidgets, config.semanticsProperties);
          parseResult.unit.accept(classVisitor);
          widgetsWithDefaults.addAll(classVisitor.widgetsWithDefaults);
        } catch (_) {}
      }
    } catch (_) {}

    // 2. Perform main call site analysis
    for (final file in filePaths) {
      if (!fileDatasource.fileExists(file)) continue;
      try {
        final content = await fileDatasource.readFileAsString(file);
        final parseResult = fileDatasource.parseDartString(content);
        
        final visitor = _SemanticsVisitor(
          file,
          content,
          config.targetWidgets,
          config.idPattern,
          config.semanticsProperties,
          config.defaultWidgets,
          config.defaultIdentifiers,
          widgetsWithDefaults,
        );
        parseResult.unit.accept(visitor);
        allIssues.addAll(visitor.issues);
      } catch (_) {}
    }
    return allIssues;
  }
}

class _SemanticsVisitor extends RecursiveAstVisitor<void> {
  final String filePath;
  final String fileContent;
  final List<String> targetWidgets;
  final String idPattern;
  final List<String> semanticsProperties;
  final List<String> defaultWidgets;
  final List<String> defaultIdentifiers;
  final Map<String, bool> dynamicallyDetectedDefaults;
  final List<SemanticsIssue> issues = [];

  _SemanticsVisitor(
    this.filePath,
    this.fileContent,
    this.targetWidgets,
    this.idPattern,
    this.semanticsProperties,
    this.defaultWidgets,
    this.defaultIdentifiers,
    this.dynamicallyDetectedDefaults,
  );

  void _checkWidget(String name, ArgumentList argumentList, AstNode node) {
    if (targetWidgets.contains(name)) {
      final lineInfo = node.root as CompilationUnit;
      final line = lineInfo.lineInfo.getLocation(node.offset).lineNumber;

      bool hasIgnoreComment = false;
      try {
        final fileLines = fileContent.split('\n');
        for (int i = line - 2; i <= line - 1; i++) {
          if (i >= 0 && i < fileLines.length) {
            final lineContent = fileLines[i];
            if (lineContent.contains('ignore: missing_semantics') ||
                lineContent.contains('semantics-ignore')) {
              hasIgnoreComment = true;
              break;
            }
          }
        }
      } catch (_) {}

      if (hasIgnoreComment) {
        return;
      }

      bool hasSemantics = false;
      String? semanticsValue;
      bool isLiteral = false;
      
      // Mengubah ke lowercase untuk membandingkan secara case-insensitive
      final lowerCaseProps = semanticsProperties.map((p) => p.toLowerCase()).toList();

      for (final arg in argumentList.arguments) {
        if (arg is NamedExpression) {
          final paramName = arg.name.label.name.toLowerCase();
          if (lowerCaseProps.contains(paramName)) {
            hasSemantics = true;
            // Dapatkan nilai string literal jika memungkinkan
            final valueExpr = arg.expression;
            if (valueExpr is SimpleStringLiteral) {
              semanticsValue = valueExpr.value;
              isLiteral = true;
            } else if (valueExpr is StringLiteral || valueExpr is AdjacentStrings) {
              semanticsValue = valueExpr.toSource().replaceAll(RegExp(r"['" + '"' + "]"), '');
              isLiteral = true;
            } else {
              semanticsValue = valueExpr.toSource().replaceAll(RegExp(r"['" + '"' + "]"), '');
              isLiteral = false;
            }
            break;
          }
        }
      }

      if (!hasSemantics) {
        AstNode? parent = node.parent;
        while (parent != null) {
          if (parent is InstanceCreationExpression) {
            final parentName = parent.constructorName.toSource().split('.').first;
            if (parentName == 'Semantics') {
              hasSemantics = true;
              // Cari parameter identifier pada widget Semantics
              for (final arg in parent.argumentList.arguments) {
                if (arg is NamedExpression) {
                  final paramName = arg.name.label.name;
                  if (paramName == 'identifier') {
                    final valueExpr = arg.expression;
                    if (valueExpr is SimpleStringLiteral) {
                      semanticsValue = valueExpr.value;
                      isLiteral = true;
                    } else if (valueExpr is StringLiteral || valueExpr is AdjacentStrings) {
                      semanticsValue = valueExpr.toSource().replaceAll(RegExp(r"['" + '"' + "]"), '');
                      isLiteral = true;
                    } else {
                      semanticsValue = valueExpr.toSource().replaceAll(RegExp(r"['" + '"' + "]"), '');
                      isLiteral = false;
                    }
                    break;
                  }
                }
              }
              break;
            }
          } else if (parent is MethodInvocation) {
            final parentName = parent.methodName.toSource();
            if (parentName == 'Semantics') {
              hasSemantics = true;
              for (final arg in parent.argumentList.arguments) {
                if (arg is NamedExpression) {
                  final paramName = arg.name.label.name;
                  if (paramName == 'identifier') {
                    final valueExpr = arg.expression;
                    if (valueExpr is SimpleStringLiteral) {
                      semanticsValue = valueExpr.value;
                      isLiteral = true;
                    } else if (valueExpr is StringLiteral || valueExpr is AdjacentStrings) {
                      semanticsValue = valueExpr.toSource().replaceAll(RegExp(r"['" + '"' + "]"), '');
                      isLiteral = true;
                    } else {
                      semanticsValue = valueExpr.toSource().replaceAll(RegExp(r"['" + '"' + "]"), '');
                      isLiteral = false;
                    }
                    break;
                  }
                }
              }
              break;
            }
          }
          if (parent is ClassDeclaration || parent is MethodDeclaration) {
            break;
          }
          parent = parent.parent;
        }
      }

      String snippet = '';
      try {
        final fileLines = fileContent.split('\n');
        final endLineIdx = (line + 3 < fileLines.length) ? line + 3 : fileLines.length;
        final startLineIdx = (line - 1 >= 0) ? line - 1 : 0;
        snippet = fileLines.sublist(startLineIdx, endLineIdx).map((l) => l.trim()).join('\n');
      } catch (_) {}

      final isDefaultWidget = defaultWidgets.contains(name) || (dynamicallyDetectedDefaults[name] ?? false);
      final isDefaultId = semanticsValue != null && defaultIdentifiers.contains(semanticsValue);

      // Kasus 1: Sama sekali tidak ada Semantics ID
      if (!hasSemantics) {
        String suggestionSnippet = '';
        try {
          final endOffset = (node.offset + 1500 < fileContent.length) ? node.offset + 1500 : fileContent.length;
          suggestionSnippet = fileContent.substring(node.offset, endOffset);
        } catch (_) {}

        final suggestion = _suggestIdentifier(name, suggestionSnippet);
        
        issues.add(SemanticsIssue(
          filePath: filePath,
          line: line,
          widgetName: name,
          suggestion: suggestion,
          codeSnippet: snippet,
          isFormatIssue: false,
          isWarning: isDefaultWidget,
          errorMessage: isDefaultWidget 
              ? 'Widget "$name" tidak memiliki semantics identifier unik (menggunakan nilai default widget).'
              : null,
        ));
      } 
      // Kasus 2: Ada Semantics ID tetapi menggunakan default identifier
      else if (isDefaultId) {
        String suggestionSnippet = '';
        try {
          final endOffset = (node.offset + 1500 < fileContent.length) ? node.offset + 1500 : fileContent.length;
          suggestionSnippet = fileContent.substring(node.offset, endOffset);
        } catch (_) {}

        final suggestion = _suggestIdentifier(name, suggestionSnippet);

        issues.add(SemanticsIssue(
          filePath: filePath,
          line: line,
          widgetName: name,
          suggestion: suggestion,
          codeSnippet: snippet,
          isFormatIssue: false,
          isWarning: true,
          errorMessage: 'Widget "$name" menggunakan default identifier "$semanticsValue". Harap ganti dengan identifier unik.',
        ));
      }
      // Kasus 3: Ada Semantics ID tetapi salah format berdasarkan RegExp config (hanya jika berupa literal string)
      else if (semanticsValue != null && isLiteral) {
        // Bersihkan interpolasi string dinamis (seperti $index, ${index + 1}) agar tidak merusak validasi regex standar
        final cleanValue = semanticsValue
            .replaceAll(RegExp(r'\$[a-zA-Z0-9_]+'), '')
            .replaceAll(RegExp(r'\$\{[^}]+\}'), '');

        final regExp = RegExp(idPattern);
        if (!regExp.hasMatch(cleanValue)) {
          issues.add(SemanticsIssue(
            filePath: filePath,
            line: line,
            widgetName: name,
            suggestion: '', // manual fix
            codeSnippet: snippet,
            isFormatIssue: true,
            errorMessage: 'Format identifier "$semanticsValue" tidak valid (harus sesuai pattern: $idPattern)',
            isWarning: false,
          ));
        }
      }
    }
  }

  String _suggestIdentifier(String widgetName, String snippet) {
    String prefix = 'btn';
    
    // Kelompokkan input fields
    if (['CustomTextField', 'LabeledTextField', 'TextField', 'TextFormField'].contains(widgetName)) {
      prefix = 'input';
    }

    String? label;

    final stringsMatch = RegExp(r'\b(?:text|hint|title|label|semanticsIdentifier)\s*:\s*Strings\.(\w+)').firstMatch(snippet);
    if (stringsMatch != null) {
      label = stringsMatch.group(1);
    }

    if (label == null) {
      final locMatch = RegExp('(?:AppLocalization\\.of\\(context\\)\\.getValue|Utility\\.getKeyTranslator|Utility\\.getValueTranslator)\\s*\\(\\s*([a-zA-Z0-9_\\.\\!\\?\\x27\\x22\\s|]+)\\)').firstMatch(snippet);
      if (locMatch != null) {
        final expr = locMatch.group(1)!.trim();
        final litMatch = RegExp('^[\\x27\\x22]([^\\x27\\x22]+)[\\x27\\x22]\$').firstMatch(expr);
        label = litMatch != null ? litMatch.group(1) : expr;
      }
    }

    if (label == null) {
      final literalMatch = RegExp('\\b(?:text|hint|title|label)\\s*:\\s*[\\x27\\x22]([^\\x27\\x22]+)[\\x27\\x22]').firstMatch(snippet);
      if (literalMatch != null) {
        label = literalMatch.group(1);
        if (label!.contains('|')) {
          label = label.split('|').first;
        }
      }
    }

    if (label == null) {
      final textMatch = RegExp('\\bText\\s*\\(\\s*([a-zA-Z0-9_\\.\\!\\?\\x27\\x22\\s()|]+)').firstMatch(snippet);
      if (textMatch != null) {
        final expr = textMatch.group(1)!.trim();
        final litMatch = RegExp('[\\x27\\x22]([^\\x27\\x22]+)[\\x27\\x22]').firstMatch(expr);
        if (litMatch != null) {
          label = litMatch.group(1);
        } else {
          final nestedLoc = RegExp('getValue\\(\\s*([a-zA-Z0-9_]+)\\s*\\)').firstMatch(expr);
          if (nestedLoc != null) {
            label = nestedLoc.group(1);
          } else {
            label = expr;
          }
        }
      }
    }

    if (label == null && snippet.contains('Icon')) {
      final iconMatch = RegExp(r'Icons\.(\w+)').firstMatch(snippet);
      if (iconMatch != null) {
        label = iconMatch.group(1);
      }
    }

    if (label != null) {
      label = label
          .replaceAll(RegExp(r'AppLocalization\.of\(context\)\.getValue\('), '')
          .replaceAll(RegExp(r'Utility\.getKeyTranslator\('), '')
          .replaceAll(RegExp(r'Utility\.getValueTranslator\('), '')
          .replaceAll(')', '')
          .trim();

      if (label.contains('.')) {
        final parts = label.split('.')
            .map((p) => p.replaceAll('!', '').replaceAll('?', '').replaceAll(RegExp(r'[\x27\x22]'), '').trim())
            .where((p) => !['widget', 'context', 'item', 'Strings'].contains(p))
            .toList();
        if (parts.isNotEmpty) {
          label = parts.join('_');
        }
      }

      label = label.replaceAll("'", "").replaceAll('"', '');

      String normalized = label.replaceAllMapped(RegExp(r'(.)([A-Z][a-z]+)'), (m) => '${m.group(1)}_${m.group(2)}');
      normalized = normalized.replaceAllMapped(RegExp(r'([a-z0-9])([A-Z])'), (m) => '${m.group(1)}_${m.group(2)}');
      normalized = normalized.toLowerCase();
      normalized = normalized.replaceAll(RegExp(r'[^a-z0-9_]'), '').replaceAll(' ', '_');
      normalized = normalized.replaceAll(RegExp(r'_+'), '_').trim();

      if (normalized.isNotEmpty) {
        if (!['null', 'true', 'false', 'const'].contains(normalized)) {
          return '${prefix}_$normalized';
        }
      }
    }

    return '${prefix}_[deskripsi]';
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final name = node.methodName.toSource();
    _checkWidget(name, node.argumentList, node);
    super.visitMethodInvocation(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final name = node.constructorName.toSource().split('.').first;
    _checkWidget(name, node.argumentList, node);
    super.visitInstanceCreationExpression(node);
  }
}

class _ClassDefinitionVisitor extends RecursiveAstVisitor<void> {
  final List<String> targetWidgets;
  final List<String> semanticsProperties;
  final Map<String, bool> widgetsWithDefaults = {};

  _ClassDefinitionVisitor(this.targetWidgets, this.semanticsProperties);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final className = node.name.lexeme;
    if (!targetWidgets.contains(className)) {
      super.visitClassDeclaration(node);
      return;
    }

    bool hasDefault = false;

    // 1. Check constructor parameters for defaults
    for (final member in node.members) {
      if (member is ConstructorDeclaration) {
        for (final param in member.parameters.parameters) {
          if (param is DefaultFormalParameter) {
            final paramName = param.name?.lexeme ?? '';
            if (semanticsProperties.contains(paramName)) {
              if (param.defaultValue != null) {
                hasDefault = true;
                break;
              }
            }
          }
        }
      }
      if (hasDefault) break;
    }

    // 2. Check build method body for Semantics wrapping with defaults
    if (!hasDefault) {
      for (final member in node.members) {
        if (member is MethodDeclaration && member.name.lexeme == 'build') {
          final buildVisitor = _SemanticsCheckInBuildVisitor(semanticsProperties);
          member.accept(buildVisitor);
          if (buildVisitor.hasDefaultSemanticsValue) {
            hasDefault = true;
            break;
          }
        }
      }
    }

    widgetsWithDefaults[className] = hasDefault;
    super.visitClassDeclaration(node);
  }
}

class _SemanticsCheckInBuildVisitor extends RecursiveAstVisitor<void> {
  final List<String> semanticsProperties;
  bool hasDefaultSemanticsValue = false;

  _SemanticsCheckInBuildVisitor(this.semanticsProperties);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final name = node.constructorName.toSource().split('.').first;
    if (name == 'Semantics') {
      _checkSemanticsArguments(node.argumentList);
    }
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final name = node.methodName.toSource();
    if (name == 'Semantics') {
      _checkSemanticsArguments(node.argumentList);
    }
    super.visitMethodInvocation(node);
  }

  void _checkSemanticsArguments(ArgumentList argumentList) {
    for (final arg in argumentList.arguments) {
      if (arg is NamedExpression) {
        final paramName = arg.name.label.name;
        if (paramName == 'identifier') {
          final expr = arg.expression;
          if (expr is BinaryExpression && expr.operator.lexeme == '??') {
            final right = expr.rightOperand;
            if (right is SimpleStringLiteral) {
              hasDefaultSemanticsValue = true;
            } else {
              final rightSrc = right.toSource().toLowerCase();
              if (rightSrc.contains('text') || rightSrc.contains('label') || rightSrc.contains('title') || rightSrc.contains('hint')) {
                hasDefaultSemanticsValue = true;
              }
            }
          } else if (expr is SimpleStringLiteral) {
            hasDefaultSemanticsValue = true;
          } else {
            final exprSrc = expr.toSource().toLowerCase();
            if (exprSrc.contains('text') || exprSrc.contains('label') || exprSrc.contains('title') || exprSrc.contains('hint')) {
              hasDefaultSemanticsValue = true;
            }
          }
        }
      }
    }
  }
}
