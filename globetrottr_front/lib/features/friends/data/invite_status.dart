enum InviteStatus {
  pending,
  accepted,
  blocked;

  static InviteStatus? fromString(String? value) {
    if (value == null) return null;
    return InviteStatus.values.firstWhere(
      (e) => e.name.toUpperCase() == value.toUpperCase(),
      orElse: () => throw ArgumentError('Unknown InviteStatus: $value'),
    );
  }
}