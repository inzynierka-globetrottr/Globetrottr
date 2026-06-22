import 'package:globetrottr_front/core/exceptions/app_exception.dart';

enum InviteStatus {
  pending,
  accepted,
  blocked;

  static InviteStatus? fromString(String? value) {
    if (value == null) return null;
    return InviteStatus.values.firstWhere(
      (e) => e.name.toUpperCase() == value.toUpperCase(),
      orElse: () => throw DataParsingException('Unknown InviteStatus: $value'),
    );
  }
}
