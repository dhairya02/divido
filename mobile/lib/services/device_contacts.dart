import 'package:flutter_contacts/flutter_contacts.dart' as fc;

/// A lightweight, presentation-friendly view of a phone contact. We expose
/// only the fields Divido actually cares about so the UI doesn't depend on
/// the underlying plugin types.
class DeviceContact {
  const DeviceContact({
    required this.id,
    required this.displayName,
    this.phone,
    this.email,
  });

  final String id;
  final String displayName;
  final String? phone;
  final String? email;
}

/// Outcome of a permission request, mapped to a small enum so the UI doesn't
/// import the plugin's types.
enum DeviceContactsPermission {
  granted, // includes iOS 18+ "limited" access
  denied, // can ask again
  permanentlyDenied, // user must enable in system settings
  restricted, // blocked by parental controls / MDM
}

/// Wraps `flutter_contacts` so the rest of the app deals with simple Dart
/// data and a single point of permission handling.
class DeviceContactsService {
  /// Asks the OS for read-only contacts permission. The first call surfaces
  /// the system prompt; subsequent calls return the cached status.
  Future<DeviceContactsPermission> requestPermission() async {
    final status =
        await fc.FlutterContacts.permissions.request(fc.PermissionType.read);
    return _mapStatus(status);
  }

  DeviceContactsPermission _mapStatus(fc.PermissionStatus status) {
    switch (status) {
      case fc.PermissionStatus.granted:
      case fc.PermissionStatus.limited:
        return DeviceContactsPermission.granted;
      case fc.PermissionStatus.denied:
      case fc.PermissionStatus.notDetermined:
        return DeviceContactsPermission.denied;
      case fc.PermissionStatus.permanentlyDenied:
        return DeviceContactsPermission.permanentlyDenied;
      case fc.PermissionStatus.restricted:
        return DeviceContactsPermission.restricted;
    }
  }

  /// Opens the system Settings page for the app so the user can flip the
  /// Contacts toggle on after a permanent denial.
  Future<void> openSystemSettings() =>
      fc.FlutterContacts.permissions.openSettings();

  /// Fetches all contacts on the device with their primary email and phone,
  /// already sorted by display name. Caller must have a granted permission
  /// first; otherwise returns an empty list.
  Future<List<DeviceContact>> fetchAll() async {
    final raw = await fc.FlutterContacts.getAll(
      properties: const {
        fc.ContactProperty.name,
        fc.ContactProperty.phone,
        fc.ContactProperty.email,
      },
    );

    final out = <DeviceContact>[];
    for (final c in raw) {
      final name = (c.displayName ?? '').trim();
      if (name.isEmpty) continue;
      final id = c.id ?? name; // displayName is unique enough as a fallback
      out.add(
        DeviceContact(
          id: id,
          displayName: name,
          phone: c.phones.isNotEmpty ? c.phones.first.number.trim() : null,
          email: c.emails.isNotEmpty ? c.emails.first.address.trim() : null,
        ),
      );
    }
    out.sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
    return out;
  }
}
