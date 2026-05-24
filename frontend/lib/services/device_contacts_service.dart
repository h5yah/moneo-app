import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';

class DeviceContactPick {
  const DeviceContactPick({
    required this.displayName,
    required this.phone,
  });

  final String displayName;
  final String phone;
}

class DeviceContactsService {
  DeviceContactsService._();

  static final FlutterNativeContactPicker _picker = FlutterNativeContactPicker();

  /// Opens the device contact picker (no full address-book permission needed).
  static Future<DeviceContactPick?> pickFromPhone() async {
    final contact = await _picker.selectPhoneNumber();
    if (contact == null) {
      return null;
    }

    final rawPhone = contact.selectedPhoneNumber ??
        (contact.phoneNumbers != null && contact.phoneNumbers!.isNotEmpty
            ? contact.phoneNumbers!.first
            : null);

    if (rawPhone == null || rawPhone.trim().isEmpty) {
      throw StateError('no_phone');
    }

    final normalized = normalizeMauritiusMobile(rawPhone);
    if (normalized == null) {
      throw StateError('invalid_phone');
    }

    final name = contact.fullName?.trim() ?? '';
    return DeviceContactPick(
      displayName: name.isNotEmpty ? name : 'Contact',
      phone: normalized,
    );
  }

  /// Extracts 8-digit Mauritius mobile (5xxxxxxx) from any phone string.
  static String? normalizeMauritiusMobile(String raw) {
    var digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('230') && digits.length >= 11) {
      digits = digits.substring(3);
    }
    if (digits.length == 8 && digits.startsWith('5')) {
      return digits;
    }
    return null;
  }
}
