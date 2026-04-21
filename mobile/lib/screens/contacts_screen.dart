import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/contact.dart';
import '../services/local_repository.dart';
import '../state/profile_state.dart';
import 'import_contacts_screen.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  late Future<List<Contact>> _future;

  /// IDs of contacts the user has multi-selected. When non-empty, the screen
  /// switches into "selection mode": the app bar shows a count + bulk delete,
  /// taps toggle selection instead of opening the editor, and a long-press
  /// is no longer required to add more.
  final Set<String> _selected = <String>{};

  bool get _selectionMode => _selected.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Contact>> _load() => context.read<LocalRepository>().listContacts();

  Future<void> _refresh() async {
    final next = _load();
    setState(() {
      _future = next;
    });
    await next;
  }

  void _toggleSelected(Contact c) {
    final selfId = context.read<ProfileState>().selfContactId;
    if (c.id == selfId) return; // can't bulk-delete the "self" contact
    setState(() {
      if (!_selected.add(c.id)) _selected.remove(c.id);
    });
  }

  void _clearSelection() {
    if (_selected.isEmpty) return;
    setState(_selected.clear);
  }

  Future<void> _selectAll(List<Contact> contacts) async {
    final selfId = context.read<ProfileState>().selfContactId;
    setState(() {
      _selected
        ..clear()
        ..addAll(contacts.where((c) => c.id != selfId).map((c) => c.id));
    });
  }

  Future<void> _add() async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _ContactForm(),
    );
    if (saved == true) await _refresh();
  }

  Future<void> _importFromPhone() async {
    final imported = await Navigator.of(context).push<int>(
      MaterialPageRoute(builder: (_) => const ImportContactsScreen()),
    );
    if ((imported ?? 0) > 0 && mounted) await _refresh();
  }

  Future<void> _edit(Contact c) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ContactForm(existing: c),
    );
    if (saved == true) await _refresh();
  }

  Future<void> _delete(Contact c) async {
    final messenger = ScaffoldMessenger.of(context);
    final selfId = context.read<ProfileState>().selfContactId;
    if (selfId == c.id) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Cannot delete the contact for you.')),
      );
      return;
    }
    final repo = context.read<LocalRepository>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete ${c.name}?'),
        content: const Text(
          'They will be removed from Divido and any future splits. '
          'Your phone contacts are not affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await repo.deleteContact(c.id);
      if (!mounted) return;
      await _refresh();
      messenger.showSnackBar(
        SnackBar(content: Text('Deleted ${c.name} from Divido')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Could not delete: $e')),
      );
    }
  }

  Future<void> _deleteSelected() async {
    if (_selected.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    final repo = context.read<LocalRepository>();
    final ids = _selected.toList();
    final count = ids.length;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          count == 1 ? 'Delete 1 contact?' : 'Delete $count contacts?',
        ),
        content: const Text(
          'They will be removed from Divido and any future splits. '
          'Your phone contacts are not affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    int deleted = 0;
    int failed = 0;
    for (final id in ids) {
      try {
        await repo.deleteContact(id);
        deleted++;
      } catch (_) {
        failed++;
      }
    }
    if (!mounted) return;
    setState(_selected.clear);
    await _refresh();
    final parts = <String>[
      if (deleted > 0)
        'Deleted $deleted contact${deleted == 1 ? '' : 's'} from Divido',
      if (failed > 0) 'could not delete $failed',
    ];
    if (parts.isNotEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(parts.join(' • '))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final selfId = context.watch<ProfileState>().selfContactId;
    return PopScope(
      canPop: !_selectionMode,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _selectionMode) _clearSelection();
      },
      child: Scaffold(
        appBar: _selectionMode
            ? _buildSelectionAppBar()
            : _buildDefaultAppBar(),
        body: RefreshIndicator(
          onRefresh: _refresh,
          child: FutureBuilder<List<Contact>>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Center(child: Text('Error: ${snap.error}'));
              }
              final contacts = snap.data ?? [];
              if (contacts.isEmpty) {
                return ListView(
                  children: const [
                    SizedBox(height: 120),
                    Icon(Icons.people_outline, size: 64),
                    SizedBox(height: 12),
                    Center(child: Text('No contacts yet')),
                  ],
                );
              }
              return ListView.separated(
                itemCount: contacts.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final c = contacts[i];
                  final isSelf = c.id == selfId;
                  final isSelected = _selected.contains(c.id);
                  return ListTile(
                    selected: isSelected,
                    selectedTileColor: Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withValues(alpha: 0.4),
                    leading: GestureDetector(
                      onTap: isSelf ? null : () => _toggleSelected(c),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 150),
                        transitionBuilder: (child, anim) =>
                            ScaleTransition(scale: anim, child: child),
                        child: isSelected
                            ? CircleAvatar(
                                key: const ValueKey('selected'),
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                child: const Icon(Icons.check,
                                    color: Colors.white, size: 20),
                              )
                            : CircleAvatar(
                                key: ValueKey('avatar-${c.id}'),
                                child: Text(_initials(c.name)),
                              ),
                      ),
                    ),
                    title: Row(
                      children: [
                        Flexible(child: Text(c.name)),
                        if (isSelf) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('You',
                                style: Theme.of(context).textTheme.labelSmall),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text([
                      if (c.email != null && c.email!.isNotEmpty) c.email,
                      if (c.phone != null && c.phone!.isNotEmpty) c.phone,
                    ].whereType<String>().join(' • ')),
                    trailing: _selectionMode
                        ? null
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () => _edit(c)),
                              if (!isSelf)
                                IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () => _delete(c)),
                            ],
                          ),
                    onTap: _selectionMode
                        ? () => _toggleSelected(c)
                        : () => _edit(c),
                    onLongPress:
                        isSelf ? null : () => _toggleSelected(c),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  AppBar _buildDefaultAppBar() {
    return AppBar(
      title: const Text('Contacts'),
      actions: [
        IconButton(
          tooltip: 'Select',
          icon: const Icon(Icons.checklist_outlined),
          onPressed: () async {
            final contacts = await _future;
            if (!mounted || contacts.isEmpty) return;
            final selfId = context.read<ProfileState>().selfContactId;
            final first = contacts.firstWhere(
              (c) => c.id != selfId,
              orElse: () => contacts.first,
            );
            if (first.id != selfId) _toggleSelected(first);
          },
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.person_add_alt_1_outlined),
          tooltip: 'Add contact',
          onSelected: (v) {
            if (v == 'manual') _add();
            if (v == 'phone') _importFromPhone();
          },
          itemBuilder: (_) => const [
            PopupMenuItem<String>(
              value: 'phone',
              child: ListTile(
                leading: Icon(Icons.contacts_outlined),
                title: Text('From phone contacts'),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
            PopupMenuItem<String>(
              value: 'manual',
              child: ListTile(
                leading: Icon(Icons.edit_outlined),
                title: Text('Enter manually'),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  AppBar _buildSelectionAppBar() {
    return AppBar(
      leading: IconButton(
        tooltip: 'Cancel',
        icon: const Icon(Icons.close),
        onPressed: _clearSelection,
      ),
      title: Text('${_selected.length} selected'),
      actions: [
        FutureBuilder<List<Contact>>(
          future: _future,
          builder: (context, snap) {
            final contacts = snap.data ?? const <Contact>[];
            final selfId = context.read<ProfileState>().selfContactId;
            final selectable =
                contacts.where((c) => c.id != selfId).toList();
            final allSelected = selectable.isNotEmpty &&
                selectable.every((c) => _selected.contains(c.id));
            return IconButton(
              tooltip: allSelected ? 'Select none' : 'Select all',
              icon: Icon(allSelected
                  ? Icons.deselect_outlined
                  : Icons.select_all_outlined),
              onPressed: contacts.isEmpty
                  ? null
                  : () {
                      if (allSelected) {
                        _clearSelection();
                      } else {
                        _selectAll(contacts);
                      }
                    },
            );
          },
        ),
        IconButton(
          tooltip: 'Delete selected',
          icon: const Icon(Icons.delete_outline),
          onPressed: _deleteSelected,
        ),
      ],
    );
  }
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.characters.first.toUpperCase();
  return (parts.first.characters.first + parts.last.characters.first)
      .toUpperCase();
}

class _ContactForm extends StatefulWidget {
  const _ContactForm({this.existing});
  final Contact? existing;

  @override
  State<_ContactForm> createState() => _ContactFormState();
}

class _ContactFormState extends State<_ContactForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _venmo;
  late final TextEditingController _cashapp;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _email = TextEditingController(text: e?.email ?? '');
    _phone = TextEditingController(text: e?.phone ?? '');
    _venmo = TextEditingController(text: e?.venmo ?? '');
    _cashapp = TextEditingController(text: e?.cashapp ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _venmo.dispose();
    _cashapp.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final repo = context.read<LocalRepository>();
    try {
      if (widget.existing == null) {
        await repo.createContact(
          name: _name.text.trim(),
          email: _email.text.trim(),
          phone: _phone.text.trim(),
          venmo: _venmo.text.trim(),
          cashapp: _cashapp.text.trim(),
        );
      } else {
        await repo.updateContact(widget.existing!.id, {
          'name': _name.text.trim(),
          'email': _email.text.trim(),
          'phone': _phone.text.trim(),
          'venmo': _venmo.text.trim(),
          'cashapp': _cashapp.text.trim(),
        });
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: 16 + viewInsets,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.existing == null ? 'New contact' : 'Edit contact',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _venmo,
                decoration: const InputDecoration(labelText: 'Venmo'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _cashapp,
                decoration: const InputDecoration(labelText: 'Cash App'),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(widget.existing == null ? 'Create' : 'Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
