import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/contact.dart';
import '../services/device_contacts.dart';
import '../services/local_repository.dart';

/// Lets the user pick one or more contacts from their phone's address book
/// and import them into the local Divido contacts list. Skips entries that
/// already exist in the local DB (matched by name + phone/email).
class ImportContactsScreen extends StatefulWidget {
  const ImportContactsScreen({super.key});

  @override
  State<ImportContactsScreen> createState() => _ImportContactsScreenState();
}

class _ImportContactsScreenState extends State<ImportContactsScreen> {
  Future<_LoadResult>? _loadFuture;
  final _selected = <String>{}; // device contact ids
  final _searchCtrl = TextEditingController();
  String _query = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadFuture = _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<_LoadResult> _load() async {
    final svc = context.read<DeviceContactsService>();
    final repo = context.read<LocalRepository>();

    final status = await svc.requestPermission();
    if (status != DeviceContactsPermission.granted) {
      return _LoadResult(
        permission: status,
        device: const [],
        existingKeys: const {},
      );
    }
    final device = await svc.fetchAll();
    final existing = await repo.listContacts();
    final keys = existing.map(_localKey).toSet();

    // Default to selecting every device contact that isn't already a Divido
    // contact, so the common case ("sync everything") is one tap on Import.
    _selected
      ..clear()
      ..addAll(
        device.where((c) => !keys.contains(_deviceKey(c))).map((c) => c.id),
      );

    return _LoadResult(
      permission: status,
      device: device,
      existingKeys: keys,
    );
  }

  Iterable<DeviceContact> _selectableContacts(_LoadResult data) =>
      data.device.where((c) => !data.existingKeys.contains(_deviceKey(c)));

  void _toggleSelectAll(_LoadResult data) {
    final selectable = _selectableContacts(data).toList();
    final allSelected = selectable.every((c) => _selected.contains(c.id));
    setState(() {
      _selected.clear();
      if (!allSelected) {
        _selected.addAll(selectable.map((c) => c.id));
      }
    });
  }

  static String _localKey(Contact c) => _key(c.name, c.phone, c.email);
  static String _deviceKey(DeviceContact c) =>
      _key(c.displayName, c.phone, c.email);

  static String _key(String name, String? phone, String? email) {
    final normalizedName = name.trim().toLowerCase();
    final normalizedPhone = (phone ?? '').replaceAll(RegExp(r'[^0-9+]'), '');
    final normalizedEmail = (email ?? '').trim().toLowerCase();
    return '$normalizedName|$normalizedPhone|$normalizedEmail';
  }

  Future<void> _import(_LoadResult data) async {
    if (_selected.isEmpty) return;
    setState(() => _saving = true);

    // Capture the messenger + navigator before any await so we can still post
    // the confirmation toast after popping this route.
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final repo = context.read<LocalRepository>();

    final picked =
        data.device.where((c) => _selected.contains(c.id)).toList();
    int created = 0;
    int skipped = 0;
    for (final c in picked) {
      if (data.existingKeys.contains(_deviceKey(c))) {
        skipped++;
        continue;
      }
      try {
        await repo.createContact(
          name: c.displayName,
          email: c.email,
          phone: c.phone,
        );
        created++;
      } catch (_) {
        skipped++;
      }
    }

    final parts = <String>[
      if (created > 0) 'Imported $created contact${created == 1 ? '' : 's'}',
      if (skipped > 0) 'skipped $skipped duplicate${skipped == 1 ? '' : 's'}',
    ];
    if (parts.isNotEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(parts.join(' • '))));
    }
    navigator.pop(created);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('From phone contacts'),
        actions: [
          FutureBuilder<_LoadResult>(
            future: _loadFuture,
            builder: (context, snap) {
              final data = snap.data;
              final ready = data != null &&
                  data.permission == DeviceContactsPermission.granted;
              if (!ready) return const SizedBox.shrink();
              final selectable = _selectableContacts(data).toList();
              if (selectable.isEmpty) return const SizedBox.shrink();
              final allSelected =
                  selectable.every((c) => _selected.contains(c.id));
              return TextButton(
                onPressed: _saving ? null : () => _toggleSelectAll(data),
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                child: Text(allSelected ? 'Select none' : 'Select all'),
              );
            },
          ),
          FutureBuilder<_LoadResult>(
            future: _loadFuture,
            builder: (context, snap) {
              final data = snap.data;
              final canImport = data != null &&
                  data.permission == DeviceContactsPermission.granted &&
                  _selected.isNotEmpty &&
                  !_saving;
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: TextButton(
                  onPressed: canImport ? () => _import(data) : null,
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  child: _saving
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          _selected.isEmpty
                              ? 'Import'
                              : 'Import (${_selected.length})',
                        ),
                ),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<_LoadResult>(
        future: _loadFuture,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not read contacts.\n${snap.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final data = snap.data!;
          if (data.permission != DeviceContactsPermission.granted) {
            return _PermissionDenied(
              status: data.permission,
              onRetry: () {
                final next = _load();
                setState(() {
                  _loadFuture = next;
                });
              },
              onOpenSettings: () =>
                  context.read<DeviceContactsService>().openSystemSettings(),
            );
          }
          if (data.device.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No contacts found on this device.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final q = _query.trim().toLowerCase();
          final filtered = q.isEmpty
              ? data.device
              : data.device.where((c) {
                  return c.displayName.toLowerCase().contains(q) ||
                      (c.email?.toLowerCase().contains(q) ?? false) ||
                      (c.phone?.toLowerCase().contains(q) ?? false);
                }).toList();

          final selectableCount = _selectableContacts(data).length;
          final selectedCount = _selected.length;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  selectableCount == 0
                      ? 'All ${data.device.length} of your contacts are already in Divido.'
                      : '$selectedCount of $selectableCount selected — tap Import to add them all to Divido.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search contacts',
                    isDense: true,
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _query = '');
                            },
                          ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final c = filtered[i];
                    final alreadyImported =
                        data.existingKeys.contains(_deviceKey(c));
                    final selected = _selected.contains(c.id);
                    return CheckboxListTile(
                      value: selected,
                      onChanged: alreadyImported
                          ? null
                          : (v) {
                              setState(() {
                                if (v == true) {
                                  _selected.add(c.id);
                                } else {
                                  _selected.remove(c.id);
                                }
                              });
                            },
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(c.displayName),
                      subtitle: Text(
                        [
                          if (c.phone != null && c.phone!.isNotEmpty) c.phone,
                          if (c.email != null && c.email!.isNotEmpty) c.email,
                          if (alreadyImported) 'Already added',
                        ].whereType<String>().join(' • '),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LoadResult {
  const _LoadResult({
    required this.permission,
    required this.device,
    required this.existingKeys,
  });

  final DeviceContactsPermission permission;
  final List<DeviceContact> device;
  final Set<String> existingKeys;
}

class _PermissionDenied extends StatelessWidget {
  const _PermissionDenied({
    required this.status,
    required this.onRetry,
    required this.onOpenSettings,
  });

  final DeviceContactsPermission status;
  final VoidCallback onRetry;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final mustOpenSettings =
        status == DeviceContactsPermission.permanentlyDenied ||
            status == DeviceContactsPermission.restricted;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.contacts_outlined,
              size: 64,
              color: Theme.of(context).hintColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Contacts access is off',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              status == DeviceContactsPermission.restricted
                  ? 'Contacts access is restricted on this device (e.g. by parental controls or device management).'
                  : 'Allow Divido to read your phone contacts so you can add the people you split bills with in one tap. Your contacts stay on your device — Divido never uploads them.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (mustOpenSettings)
              FilledButton.icon(
                icon: const Icon(Icons.settings_outlined),
                label: const Text('Open Settings'),
                onPressed: onOpenSettings,
              )
            else
              FilledButton.icon(
                icon: const Icon(Icons.lock_open),
                label: const Text('Allow contacts access'),
                onPressed: onRetry,
              ),
          ],
        ),
      ),
    );
  }
}
