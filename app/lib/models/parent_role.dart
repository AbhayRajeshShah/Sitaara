/// Matches the backend's `ParentRole` enum (`mom | dad | guardian`).
enum ParentRole {
  dad,
  mom,
  guardian;

  /// The exact string the API expects/returns.
  String get apiValue => name;

  /// Display label shown in the UI ("Father"/"Mother"/"Guardian").
  String get label {
    switch (this) {
      case ParentRole.dad:
        return 'Father';
      case ParentRole.mom:
        return 'Mother';
      case ParentRole.guardian:
        return 'Guardian';
    }
  }

  static ParentRole fromApiValue(String value) {
    return ParentRole.values.firstWhere(
      (role) => role.apiValue == value,
      orElse: () => throw ArgumentError('Unknown role: $value'),
    );
  }
}
