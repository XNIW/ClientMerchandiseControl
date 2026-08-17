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
    if (!_hasCanonicalFactoryConsumers(factory, bindingElement)) {
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
    final constructor = initializer is InstanceCreationExpression
        ? initializer.constructorName.element
        : null;
    if (field is! FieldDeclaration ||
        enclosingClass is! ClassDeclaration ||
        enclosingClass.namePart.typeName.lexeme != 'AppConfig' ||
        !field.isStatic ||
        !node.isConst ||
        initializer is! InstanceCreationExpression ||
        constructor == null ||
        !constructor.isConst ||
        constructor.enclosingElement.name != 'String' ||
        constructor.name != 'fromEnvironment' ||
        constructor.library.uri.toString() != 'dart:core') {
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

bool _hasCanonicalFactoryConsumers(
  ConstructorDeclaration factory,
  VariableElement bindingElement,
) {
  final body = factory.body;
  if (body is! BlockFunctionBody) {
    return false;
  }
  final statements = body.block.statements;
  if (statements.length != 4) {
    return false;
  }

  final configDeclaration = _singleVariable(statements[0], 'config');
  final configCreation = configDeclaration?.initializer;
  if (configCreation is! InstanceCreationExpression ||
      !_isConstructor(
        configCreation.constructorName.element,
        className: 'AppConfig',
        constructorName: 'fromValues',
        library: bindingElement.library,
      )) {
    return false;
  }
  final configArguments = configCreation.argumentList.arguments;
  const expectedConfigArguments = {
    'appEnvironment',
    'supabaseUrl',
    'supabasePublishableKey',
    'authRedirectUri',
    'googleAuthEnabled',
    'storefrontShopSlug',
    'releaseConfigSha256',
  };
  final namedConfigArguments = <String, NamedArgument>{};
  for (final argument in configArguments) {
    if (argument is! NamedArgument ||
        namedConfigArguments.putIfAbsent(
              argument.name.lexeme,
              () => argument,
            ) !=
            argument) {
      return false;
    }
  }
  if (namedConfigArguments.keys
          .toSet()
          .difference(expectedConfigArguments)
          .isNotEmpty ||
      expectedConfigArguments
          .difference(namedConfigArguments.keys.toSet())
          .isNotEmpty) {
    return false;
  }
  final storefrontArgument =
      namedConfigArguments['storefrontShopSlug']?.argumentExpression;
  if (storefrontArgument is! SimpleIdentifier ||
      !_referencesBinding(storefrontArgument, bindingElement)) {
    return false;
  }

  if (statements[1] is! IfStatement || statements[2] is! TryStatement) {
    return false;
  }
  final tryStatement = statements[2] as TryStatement;
  if (tryStatement.body.statements.length != 2) {
    return false;
  }
  final attestationDeclaration = _singleVariable(
    tryStatement.body.statements[0],
    'attestation',
  );
  final attestationCall = attestationDeclaration?.initializer;
  if (attestationCall is! MethodInvocation ||
      attestationCall.target is! SimpleIdentifier ||
      (attestationCall.target as SimpleIdentifier).name !=
          'ReleaseConfigAttestation') {
    return false;
  }
  final method = attestationCall.methodName.element;
  if (method is! MethodElement ||
      !method.isStatic ||
      method.name != 'fromValues' ||
      method.enclosingElement?.name != 'ReleaseConfigAttestation' ||
      !method.library.uri.toString().endsWith(
        '/core/config/release_config_attestation.dart',
      )) {
    return false;
  }
  final attestationArguments = attestationCall.argumentList.arguments;
  if (attestationArguments.length != 1 ||
      attestationArguments.single is! SetOrMapLiteral) {
    return false;
  }
  final values = attestationArguments.single as SetOrMapLiteral;
  const expectedAttestationKeys = {
    'APP_ENV',
    'SUPABASE_URL',
    'SUPABASE_PUBLISHABLE_KEY',
    'AUTH_REDIRECT_URI',
    'GOOGLE_AUTH_ENABLED',
    'STOREFRONT_SHOP_SLUG',
    'DELIVERY_MAPS_ENABLED',
    'DELIVERY_MAPS_NATIVE_CONFIGURED',
  };
  final entries = <String, MapLiteralEntry>{};
  for (final element in values.elements) {
    if (element is! MapLiteralEntry || element.key is! SimpleStringLiteral) {
      return false;
    }
    final key = (element.key as SimpleStringLiteral).value;
    if (entries.putIfAbsent(key, () => element) != element) {
      return false;
    }
  }
  if (entries.keys.toSet().difference(expectedAttestationKeys).isNotEmpty ||
      expectedAttestationKeys.difference(entries.keys.toSet()).isNotEmpty) {
    return false;
  }
  final storefrontEntry = entries['STOREFRONT_SHOP_SLUG']?.value;
  if (storefrontEntry is! SimpleIdentifier ||
      !_referencesBinding(storefrontEntry, bindingElement)) {
    return false;
  }

  final returned = statements[3];
  if (returned is! ReturnStatement ||
      returned.expression is! SimpleIdentifier ||
      (returned.expression as SimpleIdentifier).element !=
          configDeclaration?.declaredFragment?.element) {
    return false;
  }

  final references = _BindingReferenceCollector(bindingElement);
  body.accept(references);
  return references.identifiers.length == 2 &&
      references.identifiers.contains(storefrontArgument) &&
      references.identifiers.contains(storefrontEntry);
}

VariableDeclaration? _singleVariable(Statement statement, String name) {
  if (statement is! VariableDeclarationStatement ||
      statement.variables.variables.length != 1) {
    return null;
  }
  final variable = statement.variables.variables.single;
  return variable.name.lexeme == name ? variable : null;
}

bool _isConstructor(
  ConstructorElement? constructor, {
  required String className,
  required String constructorName,
  required LibraryElement? library,
}) =>
    constructor != null &&
    library != null &&
    constructor.enclosingElement.name == className &&
    constructor.name == constructorName &&
    constructor.library == library;

bool _referencesBinding(
  SimpleIdentifier identifier,
  VariableElement bindingElement,
) {
  final element = identifier.element;
  return element == bindingElement ||
      (element is PropertyAccessorElement &&
          element.isOriginVariable &&
          element.variable == bindingElement);
}

final class _BindingReferenceCollector extends RecursiveAstVisitor<void> {
  _BindingReferenceCollector(this.bindingElement);

  final VariableElement bindingElement;
  final identifiers = <SimpleIdentifier>[];

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (_referencesBinding(node, bindingElement)) {
      identifiers.add(node);
    }
    super.visitSimpleIdentifier(node);
  }
}
