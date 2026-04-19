import 'package:flutter/foundation.dart';

import '../services/local_repository.dart';

/// Tracks the device owner's display name. Stored in the `settings` table so
/// it survives reinstalls of the SQLite file. Doubles as the name used when
/// auto-creating the "self" contact for splits.
class ProfileState extends ChangeNotifier {
  ProfileState(this.repo);
  final LocalRepository repo;

  String? displayName;
  String? selfContactId;
  bool ready = false;

  Future<void> bootstrap() async {
    displayName = await repo.getSetting('display_name');
    selfContactId = await repo.getSetting('self_contact_id');
    ready = true;
    notifyListeners();
  }

  Future<void> setDisplayName(String name) async {
    final trimmed = name.trim();
    displayName = trimmed.isEmpty ? null : trimmed;
    await repo.setSetting('display_name', displayName);

    // Keep the self-contact in sync so splits include the device owner.
    if (displayName != null) {
      if (selfContactId == null) {
        final c = await repo.createContact(name: displayName!);
        selfContactId = c.id;
        await repo.setSetting('self_contact_id', c.id);
      } else {
        await repo.updateContact(selfContactId!, {'name': displayName});
      }
    }
    notifyListeners();
  }

  Future<void> reset() async {
    await repo.resetEverything();
    displayName = null;
    selfContactId = null;
    notifyListeners();
  }
}
