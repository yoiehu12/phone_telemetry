// File: metadata_extractor.dart
// This version is updated to be compatible with recent versions of the
// Dart 'analyzer' package.
import 'dart:convert';
import 'dart:io';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

// --- Main Execution ---
void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln('Error: Please provide the path to a Dart file.');
    exit(1);
  }

  final filePath = args.first;
  final file = File(filePath);

  if (!file.existsSync()) {
    stderr.writeln('Error: File not found at "$filePath"');
    exit(1);
  }

  try {
    final content = file.readAsStringSync();
    // This parse configuration ensures we fail on any syntax errors.
    // The featureSet parameter is removed for better compatibility.
    final result = parseString(
      content: content,
      throwIfDiagnostics: true,
    );

    final visitor = MetadataVisitor(filePath);
    result.unit.visitChildren(visitor);

    // Output the collected metadata as a JSON string.
    stdout.writeln(jsonEncode(visitor.fileMetadata));
  } catch (e) {
    stderr.writeln('Failed to parse "$filePath":\n$e');
    exit(1);
  }
}

// --- AST Visitor ---
class MetadataVisitor extends GeneralizingAstVisitor<void> {
  final String filePath;
  final Map<String, dynamic> fileMetadata = {
    'path': '',
    'imports': <String>[],
    'classes': <Map<String, dynamic>>[],
    'functions': <Map<String, dynamic>>[],
    'variables': <Map<String, dynamic>>[],
  };

  MetadataVisitor(this.filePath) {
    // Store the relative path in the metadata.
    fileMetadata['path'] = filePath;
  }

  @override
  void visitImportDirective(ImportDirective node) {
    if (node.uri.stringValue != null) {
        fileMetadata['imports'].add(node.uri.stringValue!);
    }
    super.visitImportDirective(node);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final classVisitor = ClassVisitor();
    node.visitChildren(classVisitor);
    fileMetadata['classes'].add({
      'name': node.name.lexeme, // FIXED: Use .lexeme to get the name string
      'fields': classVisitor.fields,
      'methods': classVisitor.methods,
    });
    // We don't call super.visitClassDeclaration because the ClassVisitor handles it.
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    fileMetadata['functions'].add({
      'name': node.name.lexeme, // FIXED: Use .lexeme to get the name string
      'returnType': node.returnType?.toSource() ?? 'void',
    });
    super.visitFunctionDeclaration(node);
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    for (var variable in node.variables.variables) {
      fileMetadata['variables'].add({
        'name': variable.name.lexeme, // FIXED: Use .lexeme to get the name string
        'type': node.variables.type?.toSource() ?? 'dynamic',
        'isConst': variable.isConst,
        'isFinal': variable.isFinal,
      });
    }
    super.visitTopLevelVariableDeclaration(node);
  }
}

// --- Sub-Visitor for Class Members ---
class ClassVisitor extends GeneralizingAstVisitor<void> {
  final List<Map<String, dynamic>> fields = [];
  final List<Map<String, dynamic>> methods = [];

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    for (var variable in node.fields.variables) {
      fields.add({
        'name': variable.name.lexeme, // FIXED: Use .lexeme to get the name string
        'type': node.fields.type?.toSource() ?? 'dynamic',
        'isStatic': node.isStatic,
      });
    }
    super.visitFieldDeclaration(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    methods.add({
      'name': node.name.lexeme, // FIXED: Use .lexeme to get the name string
      'returnType': node.returnType?.toSource() ?? 'void',
      'isStatic': node.isStatic,
      'isGetter': node.isGetter,
      'isSetter': node.isSetter,
    });
    super.visitMethodDeclaration(node);
  }
}
