import 'package:meta/meta.dart';

/// Represents a granular permission to perform an action on a resource.
@immutable
final class Capability {
  /// The resource this capability applies to (e.g., 'user', 'order', 'system').
  final String resource;

  /// The action allowed on the resource (e.g., 'read', 'write', 'delete').
  final String action;

  /// Creates a [Capability].
  const Capability({required this.resource, required this.action});

  /// Creates a [Capability] from a JSON map.
  factory Capability.fromJson(Map<String, dynamic> json) => Capability(
    resource: json['resource'] as String,
    action: json['action'] as String,
  );

  /// Converts this [Capability] to a JSON map.
  Map<String, dynamic> toJson() => {'resource': resource, 'action': action};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Capability &&
          runtimeType == other.runtimeType &&
          resource == other.resource &&
          action == other.action;

  @override
  int get hashCode => Object.hash(resource, action);

  @override
  String toString() => 'Capability($resource:$action)';
}
