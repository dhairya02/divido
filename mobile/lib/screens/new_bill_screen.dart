import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/contact.dart';
import '../services/local_repository.dart';
import '../state/profile_state.dart';
import '../utils/money.dart';
import 'bill_detail_screen.dart';

class NewBillScreen extends StatefulWidget {
  const NewBillScreen({super.key});

  @override
  State<NewBillScreen> createState() => _NewBillScreenState();
}

class _NewBillScreenState extends State<NewBillScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _venue = TextEditingController();
  final _subtotal = TextEditingController();
  final _tax = TextEditingController(text: '0');
  final _tip = TextEditingController(text: '0');
  final _fee = TextEditingController(text: '0');
  bool _saving = false;

  List<Contact> _contacts = [];
  final Set<String> _selected = {};
  bool _loadingContacts = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final selfId = context.read<ProfileState>().selfContactId;
    try {
      final cs = await context.read<LocalRepository>().listContacts();
      if (!mounted) return;
      setState(() {
        _contacts = cs;
        _loadingContacts = false;
        if (selfId != null && cs.any((c) => c.id == selfId)) {
          _selected.add(selfId);
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingContacts = false);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _venue.dispose();
    _subtotal.dispose();
    _tax.dispose();
    _tip.dispose();
    _fee.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final cents = parseCents(_subtotal.text);
    if (cents == null || cents <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid subtotal')),
      );
      return;
    }
    setState(() => _saving = true);
    final repo = context.read<LocalRepository>();
    try {
      final id = await repo.createBill(
        title: _title.text.trim(),
        venue: _venue.text.trim().isEmpty ? null : _venue.text.trim(),
        subtotalCents: cents,
        taxRatePct: double.tryParse(_tax.text.trim()) ?? 0,
        tipRatePct: double.tryParse(_tip.text.trim()) ?? 0,
        convenienceFeeRatePct: double.tryParse(_fee.text.trim()) ?? 0,
        participantContactIds: _selected.toList(),
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => BillDetailScreen(billId: id)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not create bill: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final selfId = context.watch<ProfileState>().selfContactId;
    return Scaffold(
      appBar: AppBar(title: const Text('New bill')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _venue,
                decoration: const InputDecoration(labelText: 'Venue (optional)'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _subtotal,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Subtotal',
                  prefixText: '\$ ',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (parseCents(v) == null) return 'Invalid amount';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _tax,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Tax %',
                        suffixText: '%',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _tip,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Tip %',
                        suffixText: '%',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _fee,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Fee %',
                        suffixText: '%',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Participants',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (_loadingContacts)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_contacts.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                        'Add contacts first from the Contacts tab to assign participants.'),
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _contacts.map((c) {
                    final selected = _selected.contains(c.id);
                    final isSelf = c.id == selfId;
                    return FilterChip(
                      label: Text(isSelf ? '${c.name} (you)' : c.name),
                      selected: selected,
                      onSelected: (v) => setState(() {
                        if (v) {
                          _selected.add(c.id);
                        } else {
                          _selected.remove(c.id);
                        }
                      }),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _saving ? null : _create,
                icon: const Icon(Icons.check),
                label: Text(_saving ? 'Creating…' : 'Create bill'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
