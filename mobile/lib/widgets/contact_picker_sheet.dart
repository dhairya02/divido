import 'package:flutter/material.dart';

import '../models/contact.dart';

/// A bottom-sheet contact picker with live search across name, phone, and
/// email. Supports two modes:
///
/// * **Multi-pick** — `pickMulti(...)` returns the final `Set<String>` of
///   selected contact ids (or `null` if the user cancelled).
/// * **Single-pick** — `pickOne(...)` returns the single selected `Contact`
///   (or `null`).
class ContactPickerSheet extends StatefulWidget {
  const ContactPickerSheet._({
    required this.allContacts,
    required this.initiallySelected,
    required this.selfId,
    required this.title,
    required this.multi,
  });

  /// Show the multi-pick variant. Returns the new selection on Done.
  static Future<Set<String>?> pickMulti({
    required BuildContext context,
    required List<Contact> allContacts,
    required Set<String> initiallySelected,
    String? selfId,
    String title = 'Add participants',
  }) {
    return showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ContactPickerSheet._(
        allContacts: allContacts,
        initiallySelected: initiallySelected,
        selfId: selfId,
        title: title,
        multi: true,
      ),
    );
  }

  /// Show the single-pick variant. Returns the picked contact (or null).
  static Future<Contact?> pickOne({
    required BuildContext context,
    required List<Contact> allContacts,
    String? selfId,
    String title = 'Pick a contact',
  }) async {
    final id = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ContactPickerSheet._(
        allContacts: allContacts,
        initiallySelected: const {},
        selfId: selfId,
        title: title,
        multi: false,
      ),
    );
    if (id == null) return null;
    return allContacts.firstWhere(
      (c) => c.id == id,
      orElse: () => throw StateError('Picked id $id not in allContacts'),
    );
  }

  final List<Contact> allContacts;
  final Set<String> initiallySelected;
  final String? selfId;
  final String title;
  final bool multi;

  @override
  State<ContactPickerSheet> createState() => _ContactPickerSheetState();
}

class _ContactPickerSheetState extends State<ContactPickerSheet> {
  late final Set<String> _selected;
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selected = {...widget.initiallySelected};
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Contact> _sorted() {
    final list = [...widget.allContacts];
    list.sort((a, b) {
      if (a.id == widget.selfId) return -1;
      if (b.id == widget.selfId) return 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final all = _sorted();
    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? all
        : all.where((c) {
            return c.name.toLowerCase().contains(q) ||
                (c.email?.toLowerCase().contains(q) ?? false) ||
                (c.phone?.toLowerCase().contains(q) ?? false);
          }).toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    if (widget.multi)
                      Padding(
                        padding: const EdgeInsets.only(left: 4, right: 4),
                        child: FilledButton(
                          onPressed: () =>
                              Navigator.pop(context, _selected),
                          child: Text('Done (${_selected.length})'),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: TextField(
                  controller: _searchCtrl,
                  autofocus: true,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search by name, phone, or email',
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
                child: filtered.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            all.isEmpty
                                ? 'No contacts to choose from yet.'
                                : 'No contacts match "$_query".',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) =>
                            const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final c = filtered[i];
                          final isSelf = c.id == widget.selfId;
                          final selected = _selected.contains(c.id);
                          final subtitle = _subtitle(c);
                          if (widget.multi) {
                            return CheckboxListTile(
                              value: selected,
                              controlAffinity:
                                  ListTileControlAffinity.leading,
                              secondary: CircleAvatar(
                                child: Text(_initial(c.name)),
                              ),
                              title: Text(
                                isSelf ? '${c.name} (you)' : c.name,
                              ),
                              subtitle:
                                  subtitle == null ? null : Text(subtitle),
                              onChanged: (v) {
                                setState(() {
                                  if (v == true) {
                                    _selected.add(c.id);
                                  } else {
                                    _selected.remove(c.id);
                                  }
                                });
                              },
                            );
                          }
                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(_initial(c.name)),
                            ),
                            title:
                                Text(isSelf ? '${c.name} (you)' : c.name),
                            subtitle:
                                subtitle == null ? null : Text(subtitle),
                            onTap: () => Navigator.pop(context, c.id),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _initial(String name) {
    final t = name.trim();
    if (t.isEmpty) return '?';
    return t.characters.first.toUpperCase();
  }

  static String? _subtitle(Contact c) {
    final bits = <String>[
      if (c.phone != null && c.phone!.isNotEmpty) c.phone!,
      if (c.email != null && c.email!.isNotEmpty) c.email!,
    ];
    return bits.isEmpty ? null : bits.join(' • ');
  }
}
