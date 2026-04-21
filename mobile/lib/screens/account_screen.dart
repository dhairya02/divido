import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/local_repository.dart';
import '../services/receipt_scanner.dart';
import '../state/profile_state.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  ({int bills, int contacts})? _stats;
  bool _loading = true;
  String? _geminiKey;

  @override
  void initState() {
    super.initState();
    _loadStats();
    _loadGeminiKey();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    try {
      final s = await context.read<LocalRepository>().getStats();
      if (!mounted) return;
      setState(() {
        _stats = s;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _loadGeminiKey() async {
    final key = await context
        .read<LocalRepository>()
        .getSetting(kGeminiApiKeySettingName);
    if (!mounted) return;
    setState(() => _geminiKey = key);
  }

  Future<void> _editGeminiKey() async {
    final repo = context.read<LocalRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final ctl = TextEditingController(text: _geminiKey ?? '');
    final next = await showDialog<String?>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Gemini API key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Used to scan receipts with Google Gemini. Get a free key at '
              'aistudio.google.com/apikey. Stored only on this device.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctl,
              autofocus: true,
              autocorrect: false,
              enableSuggestions: false,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'API key',
                hintText: 'AIza...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          if ((_geminiKey ?? '').isNotEmpty)
            TextButton(
              onPressed: () => Navigator.pop(context, ''),
              child: const Text('Remove'),
            ),
          FilledButton(
            onPressed: () => Navigator.pop(context, ctl.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (next == null) return;
    if (next.isEmpty) {
      await repo.setSetting(kGeminiApiKeySettingName, null);
    } else {
      await repo.setSetting(kGeminiApiKeySettingName, next);
    }
    if (!mounted) return;
    setState(() => _geminiKey = next.isEmpty ? null : next);
    messenger.showSnackBar(
      SnackBar(
        content: Text(next.isEmpty
            ? 'Removed Gemini key — scans will use on-device OCR.'
            : 'Saved. Receipt scans now use Gemini.'),
      ),
    );
  }

  Future<void> _editName() async {
    final profile = context.read<ProfileState>();
    final ctl = TextEditingController(text: profile.displayName ?? '');
    final next = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Your name'),
        content: TextField(
          controller: ctl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Display name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, ctl.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (next == null || next.isEmpty) return;
    await profile.setDisplayName(next);
  }

  Future<void> _resetData() async {
    final profile = context.read<ProfileState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset all data?'),
        content: const Text(
            'Deletes every bill, contact, and setting on this device. '
            'This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Erase'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await profile.reset();
    if (!mounted) return;
    await _loadStats();
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      child: Text(
                        (profile.displayName ?? '?')
                            .characters
                            .first
                            .toUpperCase(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(profile.displayName ?? '—',
                              style:
                                  Theme.of(context).textTheme.titleMedium),
                          const Text('On-device account',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _editName,
                      icon: const Icon(Icons.edit_outlined),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_stats != null)
              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      label: 'Bills',
                      value: '${_stats!.bills}',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatTile(
                      label: 'Contacts',
                      value: '${_stats!.contacts}',
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 24),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.auto_awesome_outlined),
              title: const Text('Receipt scanning (Gemini)'),
              subtitle: Text(
                _geminiKey == null || _geminiKey!.isEmpty
                    ? 'No key — using on-device OCR fallback. Tap to add a Google Gemini API key for sharper scans.'
                    : 'Using Gemini ${_maskKey(_geminiKey!)} for receipt scans.',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _editGeminiKey,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About Divido'),
              subtitle: const Text(
                  'Your data lives on this device. Receipt photos are only sent to Google Gemini if you provide a key above.'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever_outlined,
                  color: Colors.red),
              title: const Text('Reset all data',
                  style: TextStyle(color: Colors.red)),
              onTap: _resetData,
            ),
          ],
        ),
      ),
    );
  }
}

/// Returns "AIza••••••••f3h2" so the key is recognisable but mostly hidden.
String _maskKey(String key) {
  if (key.length <= 8) return '••••';
  return '${key.substring(0, 4)}••••${key.substring(key.length - 4)}';
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        child: Column(
          children: [
            Text(value, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).hintColor,
                    )),
          ],
        ),
      ),
    );
  }
}
