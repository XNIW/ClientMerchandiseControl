import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

const _releaseAttestationLibrary =
    'package:client_merchandise_control/core/config/release_config_attestation.dart';
const _appEnvironmentLibrary =
    'package:client_merchandise_control/core/config/app_environment.dart';
const _compiledBindings = <String, String>{
  '_compiledAppEnvironment': 'APP_ENV',
  '_compiledSupabaseUrl': 'SUPABASE_URL',
  '_compiledSupabasePublishableKey': 'SUPABASE_PUBLISHABLE_KEY',
  '_compiledAuthRedirectUri': 'AUTH_REDIRECT_URI',
  '_compiledGoogleAuthEnabled': 'GOOGLE_AUTH_ENABLED',
  '_compiledStorefrontShopSlug': 'STOREFRONT_SHOP_SLUG',
  '_compiledDeliveryMapsEnabled': 'DELIVERY_MAPS_ENABLED',
  '_compiledDeliveryMapsNativeConfigured': 'DELIVERY_MAPS_NATIVE_CONFIGURED',
  '_compiledReleaseConfigSha256': 'RELEASE_CONFIG_SHA256',
};
const _configArguments = <String, String>{
  'appEnvironment': '_compiledAppEnvironment',
  'supabaseUrl': '_compiledSupabaseUrl',
  'supabasePublishableKey': '_compiledSupabasePublishableKey',
  'authRedirectUri': '_compiledAuthRedirectUri',
  'googleAuthEnabled': '_compiledGoogleAuthEnabled',
  'storefrontShopSlug': '_compiledStorefrontShopSlug',
  'releaseConfigSha256': '_compiledReleaseConfigSha256',
};
const _attestationEntries = <String, String>{
  'APP_ENV': '_compiledAppEnvironment',
  'SUPABASE_URL': '_compiledSupabaseUrl',
  'SUPABASE_PUBLISHABLE_KEY': '_compiledSupabasePublishableKey',
  'AUTH_REDIRECT_URI': '_compiledAuthRedirectUri',
  'GOOGLE_AUTH_ENABLED': '_compiledGoogleAuthEnabled',
  'STOREFRONT_SHOP_SLUG': '_compiledStorefrontShopSlug',
  'DELIVERY_MAPS_ENABLED': '_compiledDeliveryMapsEnabled',
  'DELIVERY_MAPS_NATIVE_CONFIGURED': '_compiledDeliveryMapsNativeConfigured',
};

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
    if (resolved == null || resolved.diagnostics.isNotEmpty) {
      _fail('SOURCE_SEMANTICALLY_UNRESOLVED');
    }

    final visitor = _AppConfigBindingVisitor();
    resolved.unit.accept(visitor);
    if (!visitor.hasCanonicalStructure) {
      _fail('COMPILED_BINDING_STRUCTURE_INVALID');
    }
    if (!_hasCanonicalFactory(
      visitor.fromEnvironmentFactory!,
      visitor.bindingElements,
      visitor.releaseMarkerElement!,
    )) {
      _fail('COMPILED_BINDING_CONSUMER_INVALID');
    }
    stdout.writeln('APP_CONFIG_BINDING_VALID');
  } on FileSystemException catch (_) {
    _fail('SOURCE_UNREADABLE');
  } on StateError catch (_) {
    _fail('SOURCE_SEMANTICALLY_UNRESOLVED');
  }
}

final class _AppConfigBindingVisitor extends RecursiveAstVisitor<void> {
  var appConfigClasses = 0;
  var fromEnvironmentFactories = 0;
  final declarationCounts = <String, int>{};
  final bindingElements = <String, VariableElement>{};
  ConstructorDeclaration? fromEnvironmentFactory;
  VariableElement? releaseMarkerElement;

  bool get hasCanonicalStructure =>
      appConfigClasses == 1 &&
      fromEnvironmentFactories == 1 &&
      fromEnvironmentFactory != null &&
      bindingElements.length == _compiledBindings.length &&
      _compiledBindings.keys.every((name) => declarationCounts[name] == 1) &&
      declarationCounts['_compiledReleaseAttestationMarker'] == 1 &&
      releaseMarkerElement != null;

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
    final name = node.name.lexeme;
    if (!_compiledBindings.containsKey(name) &&
        name != '_compiledReleaseAttestationMarker') {
      super.visitVariableDeclaration(node);
      return;
    }
    declarationCounts[name] = (declarationCounts[name] ?? 0) + 1;
    final field = node.parent?.parent;
    final enclosingClass = field?.parent?.parent;
    if (field is! FieldDeclaration ||
        enclosingClass is! ClassDeclaration ||
        enclosingClass.namePart.typeName.lexeme != 'AppConfig' ||
        !field.isStatic ||
        !node.isConst) {
      return;
    }
    final element = node.declaredFragment?.element;
    if (element == null) {
      return;
    }
    if (name == '_compiledReleaseAttestationMarker') {
      if (_isCanonicalReleaseMarker(node.initializer)) {
        releaseMarkerElement = element;
      }
      return;
    }
    if (_isCanonicalEnvironmentBinding(
      node.initializer,
      key: _compiledBindings[name]!,
      requiresDevelopmentDefault: name == '_compiledAppEnvironment',
    )) {
      bindingElements[name] = element;
    }
  }
}

bool _isCanonicalEnvironmentBinding(
  Expression? initializer, {
  required String key,
  required bool requiresDevelopmentDefault,
}) {
  if (initializer is! InstanceCreationExpression) {
    return false;
  }
  final constructor = initializer.constructorName.element;
  if (constructor == null ||
      !constructor.isConst ||
      constructor.enclosingElement.name != 'String' ||
      constructor.name != 'fromEnvironment' ||
      constructor.library.uri.toString() != 'dart:core') {
    return false;
  }
  final arguments = initializer.argumentList.arguments;
  if (arguments.isEmpty ||
      arguments.first is! SimpleStringLiteral ||
      (arguments.first as SimpleStringLiteral).value != key) {
    return false;
  }
  if (!requiresDevelopmentDefault) {
    return arguments.length == 1;
  }
  if (arguments.length != 2 || arguments[1] is! NamedArgument) {
    return false;
  }
  final defaultValue = arguments[1] as NamedArgument;
  return defaultValue.name.lexeme == 'defaultValue' &&
      defaultValue.argumentExpression is SimpleStringLiteral &&
      (defaultValue.argumentExpression as SimpleStringLiteral).value ==
          'development';
}

bool _isCanonicalReleaseMarker(Expression? initializer) {
  if (initializer is! StringInterpolation) {
    return false;
  }
  final expressions = initializer.elements
      .whereType<InterpolationExpression>()
      .map((element) => element.expression)
      .toList(growable: false);
  if (expressions.length != 2) {
    return false;
  }
  final markerPrefix = expressions[0];
  final releaseSha = expressions[1];
  return markerPrefix.toSource() == 'ReleaseConfigAttestation.markerPrefix' &&
      _elementLibrary(markerPrefix) == _releaseAttestationLibrary &&
      releaseSha is SimpleIdentifier &&
      releaseSha.name == '_compiledReleaseConfigSha256';
}

bool _hasCanonicalFactory(
  ConstructorDeclaration factory,
  Map<String, VariableElement> bindings,
  VariableElement releaseMarker,
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
  final configElement = configDeclaration?.declaredFragment?.element;
  final configCreation = configDeclaration?.initializer;
  if (configElement == null ||
      configCreation is! InstanceCreationExpression ||
      !_isConstructor(
        configCreation.constructorName.element,
        className: 'AppConfig',
        constructorName: 'fromValues',
        library: bindings.values.first.library,
      ) ||
      !_matchesNamedBindings(
        configCreation.argumentList.arguments,
        _configArguments,
        bindings,
      )) {
    return false;
  }

  if (!_isProductionGuard(statements[1], configElement)) {
    return false;
  }
  final tryStatement = statements[2];
  if (tryStatement is! TryStatement ||
      tryStatement.body.statements.length != 2 ||
      tryStatement.catchClauses.length != 1 ||
      tryStatement.finallyBlock != null) {
    return false;
  }
  final attestationDeclaration = _singleVariable(
    tryStatement.body.statements[0],
    'attestation',
  );
  final attestationElement = attestationDeclaration?.declaredFragment?.element;
  final attestationCall = attestationDeclaration?.initializer;
  if (attestationElement == null ||
      attestationCall is! MethodInvocation ||
      !_isCanonicalAttestationCall(attestationCall, bindings)) {
    return false;
  }
  if (!_isAttestationGuard(
    tryStatement.body.statements[1],
    configElement,
    attestationElement,
    releaseMarker,
  )) {
    return false;
  }
  if (!_isCanonicalAttestationCatch(tryStatement.catchClauses.single)) {
    return false;
  }
  if (!_isReturnOf(statements[3], configElement)) {
    return false;
  }

  final returns = _ReturnCollector();
  body.accept(returns);
  if (returns.statements.length != 2 ||
      !returns.statements.every(
        (statement) => _isReturnOf(statement, configElement),
      )) {
    return false;
  }
  final bindingReferences = _BindingReferenceCollector(bindings.values.toSet());
  body.accept(bindingReferences);
  final expectedReferenceCounts = <String, int>{
    for (final name in _compiledBindings.keys)
      name:
          _configArguments.containsValue(name) &&
              _attestationEntries.containsValue(name)
          ? 2
          : 1,
  };
  for (final entry in bindings.entries) {
    if (bindingReferences.counts[entry.value] !=
        expectedReferenceCounts[entry.key]) {
      return false;
    }
  }
  return true;
}

bool _matchesNamedBindings(
  NodeList<Argument> arguments,
  Map<String, String> expected,
  Map<String, VariableElement> bindings,
) {
  if (arguments.length != expected.length) {
    return false;
  }
  final actual = <String, Expression>{};
  for (final argument in arguments) {
    if (argument is! NamedArgument ||
        actual.containsKey(argument.name.lexeme)) {
      return false;
    }
    actual[argument.name.lexeme] = argument.argumentExpression;
  }
  if (actual.keys.toSet().difference(expected.keys.toSet()).isNotEmpty ||
      expected.keys.toSet().difference(actual.keys.toSet()).isNotEmpty) {
    return false;
  }
  return expected.entries.every(
    (entry) => _isReference(actual[entry.key], bindings[entry.value]),
  );
}

bool _isProductionGuard(Statement statement, VariableElement config) {
  if (statement is! IfStatement ||
      statement.elseStatement != null ||
      statement.expression.toSource() !=
          'config.environment != AppEnvironment.production' ||
      statement.expression is! BinaryExpression) {
    return false;
  }
  final condition = statement.expression as BinaryExpression;
  return condition.operator.lexeme == '!=' &&
      _targetElement(condition.leftOperand) == config &&
      _elementLibrary(condition.rightOperand) == _appEnvironmentLibrary &&
      statement.thenStatement is Block &&
      (statement.thenStatement as Block).statements.length == 1 &&
      _isReturnOf((statement.thenStatement as Block).statements.single, config);
}

bool _isCanonicalAttestationCall(
  MethodInvocation call,
  Map<String, VariableElement> bindings,
) {
  final method = call.methodName.element;
  if (call.target?.toSource() != 'ReleaseConfigAttestation' ||
      method is! MethodElement ||
      !method.isStatic ||
      method.name != 'fromValues' ||
      method.enclosingElement?.name != 'ReleaseConfigAttestation' ||
      method.library.uri.toString() != _releaseAttestationLibrary) {
    return false;
  }
  final arguments = call.argumentList.arguments;
  if (arguments.length != 1 || arguments.single is! SetOrMapLiteral) {
    return false;
  }
  final literal = arguments.single as SetOrMapLiteral;
  if (literal.elements.length != _attestationEntries.length) {
    return false;
  }
  final actual = <String, Expression>{};
  for (final element in literal.elements) {
    if (element is! MapLiteralEntry || element.key is! SimpleStringLiteral) {
      return false;
    }
    final key = (element.key as SimpleStringLiteral).value;
    if (actual.containsKey(key)) {
      return false;
    }
    actual[key] = element.value;
  }
  return _attestationEntries.entries.every(
    (entry) => _isReference(actual[entry.key], bindings[entry.value]),
  );
}

bool _isAttestationGuard(
  Statement statement,
  VariableElement config,
  VariableElement attestation,
  VariableElement releaseMarker,
) {
  if (statement is! IfStatement ||
      statement.elseStatement != null ||
      statement.expression.toSource() !=
          'config.releaseConfigSha256 != attestation.sha256 || '
              '_compiledReleaseAttestationMarker != attestation.marker' ||
      statement.thenStatement is! Block ||
      (statement.thenStatement as Block).statements.length != 1 ||
      !_isThrowStatement(
        (statement.thenStatement as Block).statements.single,
      )) {
    return false;
  }
  final identifiers = _IdentifierCollector();
  statement.expression.accept(identifiers);
  return identifiers.elements.where((element) => element == config).length ==
          1 &&
      identifiers.elements.where((element) => element == attestation).length ==
          2 &&
      identifiers.elements
              .where((element) => element == releaseMarker)
              .length ==
          1;
}

bool _isCanonicalAttestationCatch(CatchClause clause) {
  final type = clause.exceptionType;
  return type is NamedType &&
      type.name.lexeme == 'ReleaseConfigValidationException' &&
      type.element?.library?.uri.toString() == _releaseAttestationLibrary &&
      clause.exceptionParameter == null &&
      clause.stackTraceParameter == null &&
      clause.body.statements.length == 1 &&
      _isThrowStatement(clause.body.statements.single);
}

bool _isThrowStatement(Statement statement) =>
    statement is ExpressionStatement && statement.expression is ThrowExpression;

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

bool _isReference(Expression? expression, VariableElement? expected) =>
    expression is SimpleIdentifier &&
    expected != null &&
    _originVariable(expression.element) == expected;

bool _isReturnOf(Statement statement, VariableElement expected) =>
    statement is ReturnStatement &&
    _isReference(statement.expression, expected);

VariableElement? _originVariable(Element? element) {
  if (element is VariableElement) {
    return element;
  }
  if (element is PropertyAccessorElement && element.isOriginVariable) {
    return element.variable;
  }
  return null;
}

Element? _targetElement(Expression expression) {
  if (expression is PrefixedIdentifier) {
    return _originVariable(expression.prefix.element);
  }
  if (expression is PropertyAccess && expression.target is SimpleIdentifier) {
    return _originVariable((expression.target as SimpleIdentifier).element);
  }
  return null;
}

String? _elementLibrary(Expression expression) {
  Element? element;
  if (expression is PrefixedIdentifier) {
    element = expression.identifier.element;
  } else if (expression is PropertyAccess) {
    element = expression.propertyName.element;
  } else if (expression is SimpleIdentifier) {
    element = expression.element;
  }
  return element?.library?.uri.toString();
}

final class _BindingReferenceCollector extends RecursiveAstVisitor<void> {
  _BindingReferenceCollector(this.bindings);

  final Set<VariableElement> bindings;
  final counts = <VariableElement, int>{};

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    final variable = _originVariable(node.element);
    if (variable != null && bindings.contains(variable)) {
      counts[variable] = (counts[variable] ?? 0) + 1;
    }
    super.visitSimpleIdentifier(node);
  }
}

final class _ReturnCollector extends RecursiveAstVisitor<void> {
  final statements = <ReturnStatement>[];

  @override
  void visitReturnStatement(ReturnStatement node) {
    statements.add(node);
    super.visitReturnStatement(node);
  }
}

final class _IdentifierCollector extends RecursiveAstVisitor<void> {
  final elements = <Element?>[];

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    elements.add(_originVariable(node.element) ?? node.element);
    super.visitSimpleIdentifier(node);
  }
}
