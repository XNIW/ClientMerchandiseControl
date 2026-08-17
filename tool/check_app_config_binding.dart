import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

Never _fail(String code) {
  stderr.writeln('APP_CONFIG_BINDING_BLOCKED: $code');
  exit(1);
}

Future<void> main(List<String> arguments) async {
  if (arguments.length != 1) {
    _fail('USAGE');
  }

  try {
    final sourceFile = File(arguments.single).absolute;
    final sourcePath = sourceFile.path;
    final parsed = parseString(
      content: sourceFile.readAsStringSync(),
      path: sourcePath,
      throwIfDiagnostics: false,
    );
    if (parsed.errors.isNotEmpty) {
      _fail('SOURCE_SYNTACTICALLY_INVALID');
    }

    final collection = AnalysisContextCollection(includedPaths: [sourcePath]);
    ResolvedUnitResult? resolved;
    try {
      final result = await collection
          .contextFor(sourcePath)
          .currentSession
          .getResolvedUnit(sourcePath);
      if (result is ResolvedUnitResult) {
        resolved = result;
      }
    } finally {
      await collection.dispose();
    }
    if (resolved == null) {
      _fail('SOURCE_SEMANTICALLY_UNRESOLVED');
    }

    final visitor = _StorefrontBindingVisitor();
    resolved.unit.accept(visitor);
    final bindingElement = visitor.validBindingElement;
    final factory = visitor.fromEnvironmentFactory;
    if (visitor.appConfigClasses != 1 ||
        visitor.declarations != 1 ||
        visitor.validBindings != 1 ||
        visitor.fromEnvironmentFactories != 1 ||
        bindingElement == null ||
        factory == null) {
      _fail('STOREFRONT_BINDING_STRUCTURE_INVALID');
    }
    final consumer = _FromEnvironmentConsumerVisitor(bindingElement);
    factory.body.accept(consumer);
    if (!consumer.isValid) {
      _fail('STOREFRONT_BINDING_CONSUMER_INVALID');
    }
    stdout.writeln('APP_CONFIG_BINDING_VALID');
  } on FileSystemException catch (_) {
    _fail('SOURCE_UNREADABLE');
  } on StateError catch (_) {
    _fail('SOURCE_SEMANTICALLY_UNRESOLVED');
  }
}

final class _StorefrontBindingVisitor extends RecursiveAstVisitor<void> {
  var appConfigClasses = 0;
  var declarations = 0;
  var validBindings = 0;
  var fromEnvironmentFactories = 0;
  VariableElement? validBindingElement;
  ConstructorDeclaration? fromEnvironmentFactory;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    if (node.namePart.typeName.lexeme == 'AppConfig') {
      appConfigClasses += 1;
      for (final member in node.body.members) {
        if (member is ConstructorDeclaration &&
            member.name?.lexeme == 'fromEnvironment') {
          fromEnvironmentFactories += 1;
          if (member.factoryKeyword != null) {
            fromEnvironmentFactory = member;
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
        initializer is! InstanceCreationExpression ||
        initializer.constructorName.type.name.lexeme != 'String' ||
        initializer.constructorName.name?.name != 'fromEnvironment') {
      return;
    }
    final arguments = initializer.argumentList.arguments;
    if (arguments.length != 1 || arguments.single is! SimpleStringLiteral) {
      return;
    }
    final key = arguments.single as SimpleStringLiteral;
    if (key.value == 'STOREFRONT_SHOP_SLUG') {
      validBindings += 1;
      validBindingElement = node.declaredFragment?.element;
    }
  }
}

final class _FromEnvironmentConsumerVisitor extends RecursiveAstVisitor<void> {
  _FromEnvironmentConsumerVisitor(this.bindingElement);

  final VariableElement bindingElement;
  var storefrontArguments = 0;
  var validStorefrontArguments = 0;
  var attestationEntries = 0;
  var validAttestationEntries = 0;

  bool get isValid =>
      storefrontArguments == 1 &&
      validStorefrontArguments == 1 &&
      attestationEntries == 1 &&
      validAttestationEntries == 1;

  bool _referencesBinding(SimpleIdentifier identifier) {
    final element = identifier.element;
    return element == bindingElement ||
        (element is PropertyAccessorElement &&
            element.isOriginVariable &&
            element.variable == bindingElement);
  }

  @override
  void visitNamedArgument(NamedArgument node) {
    if (node.name.lexeme == 'storefrontShopSlug') {
      storefrontArguments += 1;
      final expression = node.argumentExpression;
      if (expression is SimpleIdentifier &&
          expression.name == '_compiledStorefrontShopSlug' &&
          _referencesBinding(expression)) {
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
          value.name == '_compiledStorefrontShopSlug' &&
          _referencesBinding(value)) {
        validAttestationEntries += 1;
      }
    }
    super.visitMapLiteralEntry(node);
  }
}
