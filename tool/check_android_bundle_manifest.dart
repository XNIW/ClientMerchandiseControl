import 'dart:io';
import 'dart:typed_data';

const _androidNamespace = 'http://schemas.android.com/apk/res/android';
const _expectedPackage = 'com.xniw.clientmerchandisecontrol';
const _maximumManifestBytes = 1024 * 1024;
const _dynamicReceiverPermission =
    '$_expectedPackage.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION';
const _expectedUsesPermissions = <String>{
  'android.permission.INTERNET',
  'android.permission.ACCESS_NETWORK_STATE',
  _dynamicReceiverPermission,
};
const _profileInstallReceiver =
    'androidx.profileinstaller.ProfileInstallReceiver';

void main(List<String> arguments) {
  try {
    if (arguments.length != 2 || arguments.first != '--manifest') {
      _fail('ARGUMENTS_INVALID');
    }
    final file = File(arguments[1]);
    if (!file.existsSync()) {
      _fail('MANIFEST_UNAVAILABLE');
    }
    final bytes = file.readAsBytesSync();
    if (bytes.isEmpty || bytes.length > _maximumManifestBytes) {
      _fail('MANIFEST_SIZE_INVALID');
    }

    final node = _XmlNode.fromProto(_ProtoMessage.parse(bytes));
    final manifest = node.element;
    if (manifest == null || manifest.name != 'manifest') {
      _fail('ROOT_INVALID');
    }
    _requireAttribute(manifest, '', 'package', _expectedPackage);
    _requireAttribute(manifest, _androidNamespace, 'versionName', '0.1.0');
    _requireAttribute(manifest, _androidNamespace, 'versionCode', '1');

    final usesSdk = _singleChild(manifest, 'uses-sdk');
    _requireAttribute(usesSdk, _androidNamespace, 'minSdkVersion', '24');
    _requireAttribute(usesSdk, _androidNamespace, 'targetSdkVersion', '36');

    final permissionElements = manifest.children
        .where((element) => element.name.startsWith('uses-permission'))
        .toList(growable: false);
    if (permissionElements.any(
      (element) => element.name != 'uses-permission',
    )) {
      _fail('USES_PERMISSION_ELEMENT_INVALID');
    }
    final usesPermissions = permissionElements
        .map((element) => element.attribute(_androidNamespace, 'name'))
        .toList(growable: false);
    if (usesPermissions.length != _expectedUsesPermissions.length ||
        usesPermissions.toSet().length != _expectedUsesPermissions.length ||
        !_expectedUsesPermissions.every(usesPermissions.contains)) {
      _fail('USES_PERMISSION_ALLOWLIST_INVALID');
    }
    final declaredPermissions = manifest.children.where(
      (element) => element.name == 'permission',
    );
    if (declaredPermissions.length != 1) {
      _fail('DECLARED_PERMISSION_ALLOWLIST_INVALID');
    }
    _requireAttribute(
      declaredPermissions.single,
      _androidNamespace,
      'name',
      _dynamicReceiverPermission,
    );
    _requireAttribute(
      declaredPermissions.single,
      _androidNamespace,
      'protectionLevel',
      'signature',
    );

    final application = _singleChild(manifest, 'application');
    _requireAttribute(application, _androidNamespace, 'allowBackup', 'false');
    _requireAttribute(
      application,
      _androidNamespace,
      'usesCleartextTraffic',
      'false',
    );
    _requireAttribute(
      application,
      _androidNamespace,
      'networkSecurityConfig',
      '@xml/network_security_config',
    );
    final debuggable = application.attribute(_androidNamespace, 'debuggable');
    if (debuggable != null && debuggable != 'false') {
      _fail('DEBUGGABLE_ENABLED');
    }

    final mapsMetadata = application.children.where(
      (element) =>
          element.name == 'meta-data' &&
          element.attribute(_androidNamespace, 'name') ==
              'com.google.android.geo.API_KEY',
    );
    if (mapsMetadata.length != 1 ||
        mapsMetadata.single.attribute(_androidNamespace, 'value') !=
            'NOT_CONFIGURED') {
      _fail('MAPS_SENTINEL_INVALID');
    }

    final mainActivities = application.children.where(
      (element) =>
          element.name == 'activity' &&
          element.attribute(_androidNamespace, 'name') ==
              '$_expectedPackage.MainActivity',
    );
    if (mainActivities.length != 1) {
      _fail('MAIN_ACTIVITY_INVALID');
    }
    final mainActivity = mainActivities.single;
    _requireAttribute(mainActivity, _androidNamespace, 'exported', 'true');
    final schemes = mainActivity
        .descendantsNamed('data')
        .map((element) => element.attribute(_androidNamespace, 'scheme'));
    if (!schemes.contains(_expectedPackage)) {
      _fail('DEEPLINK_SCHEME_MISSING');
    }

    const componentNames = <String>{
      'activity',
      'activity-alias',
      'provider',
      'receiver',
      'service',
    };
    final exportedComponents = <_XmlElement>[];
    for (final component in application.children.where(
      (element) => componentNames.contains(element.name),
    )) {
      final exported = component.attribute(_androidNamespace, 'exported');
      if (exported == null) {
        _fail('EXPORTED_VALUE_MISSING');
      }
      if (exported != 'true' && exported != 'false') {
        _fail('EXPORTED_VALUE_INVALID');
      }
      if (exported == 'true') {
        exportedComponents.add(component);
      }
    }
    if (exportedComponents.length != 2) {
      _fail('EXPORTED_COMPONENT_ALLOWLIST_INVALID');
    }
    final approvedMainActivity = exportedComponents.where(
      (element) =>
          element.name == 'activity' &&
          element.attribute(_androidNamespace, 'name') ==
              '$_expectedPackage.MainActivity' &&
          element.attribute(_androidNamespace, 'permission') == null,
    );
    final approvedProfileReceiver = exportedComponents.where(
      (element) =>
          element.name == 'receiver' &&
          element.attribute(_androidNamespace, 'name') ==
              _profileInstallReceiver &&
          element.attribute(_androidNamespace, 'permission') ==
              'android.permission.DUMP',
    );
    if (approvedMainActivity.length != 1 ||
        approvedProfileReceiver.length != 1) {
      _fail('EXPORTED_COMPONENT_ALLOWLIST_INVALID');
    }

    stdout.writeln('ANDROID_BUNDLE_MANIFEST_VALID');
  } on _ValidationException catch (error) {
    stderr.writeln('ANDROID_BUNDLE_MANIFEST_BLOCKED: ${error.code}');
    exitCode = 1;
  } on Object {
    stderr.writeln('ANDROID_BUNDLE_MANIFEST_BLOCKED: INVALID_PROTOBUF');
    exitCode = 1;
  }
}

Never _fail(String code) => throw _ValidationException(code);

void _requireAttribute(
  _XmlElement element,
  String namespace,
  String name,
  String expected,
) {
  if (element.attribute(namespace, name) != expected) {
    _fail('ATTRIBUTE_MISMATCH');
  }
}

_XmlElement _singleChild(_XmlElement parent, String name) {
  final matches = parent.children.where((element) => element.name == name);
  if (matches.length != 1) {
    _fail('ELEMENT_CARDINALITY_INVALID');
  }
  return matches.single;
}

final class _ValidationException implements Exception {
  const _ValidationException(this.code);

  final String code;
}

final class _XmlNode {
  const _XmlNode(this.element);

  factory _XmlNode.fromProto(_ProtoMessage message) {
    final elements = message.lengthDelimited(1);
    if (elements.length > 1) {
      _fail('NODE_INVALID');
    }
    return _XmlNode(
      elements.isEmpty
          ? null
          : _XmlElement.fromProto(_ProtoMessage.parse(elements.single)),
    );
  }

  final _XmlElement? element;
}

final class _XmlElement {
  const _XmlElement({
    required this.name,
    required this.attributes,
    required this.children,
  });

  factory _XmlElement.fromProto(_ProtoMessage message) {
    final name = message.singleUtf8(3);
    if (name == null || name.isEmpty) {
      _fail('ELEMENT_NAME_INVALID');
    }
    return _XmlElement(
      name: name,
      attributes: message
          .lengthDelimited(4)
          .map((bytes) => _XmlAttribute.fromProto(_ProtoMessage.parse(bytes)))
          .toList(growable: false),
      children: message
          .lengthDelimited(5)
          .map(
            (bytes) => _XmlNode.fromProto(_ProtoMessage.parse(bytes)).element,
          )
          .whereType<_XmlElement>()
          .toList(growable: false),
    );
  }

  final String name;
  final List<_XmlAttribute> attributes;
  final List<_XmlElement> children;

  String? attribute(String namespace, String name) {
    final matches = attributes.where(
      (attribute) => attribute.namespace == namespace && attribute.name == name,
    );
    if (matches.length > 1) {
      _fail('ATTRIBUTE_DUPLICATE');
    }
    return matches.isEmpty ? null : matches.single.value;
  }

  Iterable<_XmlElement> descendantsNamed(String expectedName) sync* {
    for (final child in children) {
      if (child.name == expectedName) {
        yield child;
      }
      yield* child.descendantsNamed(expectedName);
    }
  }
}

final class _XmlAttribute {
  const _XmlAttribute({
    required this.namespace,
    required this.name,
    required this.value,
  });

  factory _XmlAttribute.fromProto(_ProtoMessage message) {
    final namespace = message.singleUtf8(1) ?? '';
    final name = message.singleUtf8(2);
    final value = message.singleUtf8(3);
    if (name == null || name.isEmpty) {
      _fail('ATTRIBUTE_INVALID');
    }
    return _XmlAttribute(namespace: namespace, name: name, value: value);
  }

  final String namespace;
  final String name;
  final String? value;
}

final class _ProtoMessage {
  const _ProtoMessage(this.fields);

  factory _ProtoMessage.parse(Uint8List bytes) {
    final reader = _ProtoReader(bytes);
    final fields = <int, List<Uint8List>>{};
    while (!reader.isDone) {
      final key = reader.readVarint();
      final fieldNumber = key >> 3;
      final wireType = key & 7;
      if (fieldNumber <= 0) {
        _fail('PROTO_FIELD_INVALID');
      }
      switch (wireType) {
        case 0:
          reader.readVarint();
        case 1:
          reader.skip(8);
        case 2:
          final length = reader.readVarint();
          final value = reader.readBytes(length);
          fields.putIfAbsent(fieldNumber, () => <Uint8List>[]).add(value);
        case 5:
          reader.skip(4);
        default:
          _fail('PROTO_WIRE_TYPE_INVALID');
      }
    }
    return _ProtoMessage(fields);
  }

  final Map<int, List<Uint8List>> fields;

  List<Uint8List> lengthDelimited(int fieldNumber) =>
      fields[fieldNumber] ?? const <Uint8List>[];

  String? singleUtf8(int fieldNumber) {
    final values = lengthDelimited(fieldNumber);
    if (values.length > 1) {
      _fail('PROTO_CARDINALITY_INVALID');
    }
    if (values.isEmpty) {
      return null;
    }
    return String.fromCharCodes(values.single);
  }
}

final class _ProtoReader {
  _ProtoReader(this.bytes);

  final Uint8List bytes;
  int offset = 0;

  bool get isDone => offset == bytes.length;

  int readVarint() {
    var value = 0;
    for (var shift = 0; shift < 64; shift += 7) {
      if (offset >= bytes.length) {
        _fail('PROTO_TRUNCATED');
      }
      final byte = bytes[offset++];
      value |= (byte & 0x7f) << shift;
      if ((byte & 0x80) == 0) {
        return value;
      }
    }
    _fail('PROTO_VARINT_INVALID');
  }

  Uint8List readBytes(int length) {
    if (length < 0 || offset + length > bytes.length) {
      _fail('PROTO_LENGTH_INVALID');
    }
    final result = Uint8List.sublistView(bytes, offset, offset + length);
    offset += length;
    return result;
  }

  void skip(int length) {
    readBytes(length);
  }
}
