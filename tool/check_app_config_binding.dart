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
    if (visitor.appConfigClasses != 1 ||
        visitor.declarations != 1 ||
        visitor.validBindings != 1 ||
        visitor.fromEnvironmentFactories != 1 ||
        visitor.validFactoryConsumers != 1) {
      _fail('STOREFRONT_BINDING_INVALID');
    }
    stdout.writeln('APP_CONFIG_BINDING_VALID');
  } on FileSystemException {
    _fail('SOURCE_UNREADABLE');
  }
}

final class _StorefrontBindingVisitor extends RecursiveAstVisitor<void> {
  var appConfigClasses = 0;
  var declarations = 0;
  var validBindings = 0;
  var fromEnvironmentFactories = 0;
  var validFactoryConsumers = 0;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    if (node.namePart.typeName.lexeme == 'AppConfig') {
      appConfigClasses += 1;
      for (final member in node.body.members) {
        if (member is ConstructorDeclaration &&
            member.name?.lexeme == 'fromEnvironment') {
          fromEnvironmentFactories += 1;
          if (member.factoryKeyword != null) {
            final consumer = _FromEnvironmentConsumerVisitor();
            member.body.accept(consumer);
            if (consumer.isValid) {
              validFactoryConsumers += 1;
            }
          }
        }
      }
    }
    super.visitClassDeclaration(node);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    if (node.name.lexeme != '_compiledStorefrontShopSlug') {
      return;
    }
    declarations += 1;
    final field = node.parent?.parent;
    final enclosingClass = field?.parent?.parent;
    final initializer = node.initializer;
    if (field is! FieldDeclaration ||
        enclosingClass is! ClassDeclaration ||
        enclosingClass.namePart.typeName.lexeme != 'AppConfig' ||
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

final class _FromEnvironmentConsumerVisitor extends RecursiveAstVisitor<void> {
  var storefrontArguments = 0;
  var validStorefrontArguments = 0;
  var attestationEntries = 0;
  var validAttestationEntries = 0;

  bool get isValid =>
      storefrontArguments == 1 &&
      validStorefrontArguments == 1 &&
      attestationEntries == 1 &&
      validAttestationEntries == 1;

  @override
  void visitNamedArgument(NamedArgument node) {
    if (node.name.lexeme == 'storefrontShopSlug') {
      storefrontArguments += 1;
      final expression = node.argumentExpression;
      if (expression is SimpleIdentifier &&
          expression.name == '_compiledStorefrontShopSlug') {
        validStorefrontArguments += 1;
      }
    }
    super.visitNamedArgument(node);
  }

  @override
  void visitMapLiteralEntry(MapLiteralEntry node) {
    final key = node.key;
    if (key is SimpleStringLiteral && key.value == 'STOREFRONT_SHOP_SLUG') {
      attestationEntries += 1;
      final value = node.value;
      if (value is SimpleIdentifier &&
          value.name == '_compiledStorefrontShopSlug') {
        validAttestationEntries += 1;
      }
    }
    super.visitMapLiteralEntry(node);
  }
}
