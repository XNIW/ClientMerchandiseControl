import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

Never _fail(String code) {
  stderr.writeln('APP_CONFIG_BINDING_BLOCKED: $code');
  exit(1);
}

void main(List<String> arguments) {
  if (arguments.length != 1) {
    _fail('USAGE');
  }

  try {
    final parsed = parseString(
      content: File(arguments.single).readAsStringSync(),
      throwIfDiagnostics: false,
    );
    if (parsed.errors.isNotEmpty) {
      _fail('SOURCE_SYNTACTICALLY_INVALID');
    }
    final visitor = _StorefrontBindingVisitor();
    parsed.unit.accept(visitor);
    if (visitor.declarations != 1 || visitor.validBindings != 1) {
      _fail('STOREFRONT_BINDING_INVALID');
    }
    stdout.writeln('APP_CONFIG_BINDING_VALID');
  } on FileSystemException {
    _fail('SOURCE_UNREADABLE');
  }
}

final class _StorefrontBindingVisitor extends RecursiveAstVisitor<void> {
  var declarations = 0;
  var validBindings = 0;

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    if (node.name.lexeme != '_compiledStorefrontShopSlug') {
      return;
    }
    declarations += 1;
    final field = node.parent?.parent;
    final initializer = node.initializer;
    if (field is! FieldDeclaration ||
        !field.isStatic ||
        !node.isConst ||
        initializer is! MethodInvocation ||
        initializer.target is! SimpleIdentifier ||
        (initializer.target! as SimpleIdentifier).name != 'String' ||
        initializer.methodName.name != 'fromEnvironment') {
      return;
    }
    final arguments = initializer.argumentList.arguments;
    if (arguments.length != 1 || arguments.single is! SimpleStringLiteral) {
      return;
    }
    final key = arguments.single as SimpleStringLiteral;
    if (key.value == 'STOREFRONT_SHOP_SLUG') {
      validBindings += 1;
    }
  }
}
