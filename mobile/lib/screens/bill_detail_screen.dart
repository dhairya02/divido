import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/bill.dart';
import '../services/local_repository.dart';
import '../services/receipt_scanner.dart';
import '../state/profile_state.dart';
import '../utils/money.dart';
import '../widgets/contact_picker_sheet.dart';
import '../widgets/money.dart';
import '../widgets/scan_review_sheet.dart';

class BillDetailScreen extends StatefulWidget {
  const BillDetailScreen({super.key, required this.billId});
  final String billId;

  @override
  State<BillDetailScreen> createState() => _BillDetailScreenState();
}

class _BillDetailScreenState extends State<BillDetailScreen> {
  late Future<BillDetails> _future;
  CalcResult? _calc;
  String? _calcError;
  bool _calculating = false;
  bool _scanning = false;

  // Lazily created so the ML Kit recognizer isn't initialized until the
  // user actually taps the scan button.
  ReceiptScannerService? _scanner;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _scanner?.dispose();
    super.dispose();
  }

  Future<BillDetails> _load() =>
      context.read<LocalRepository>().getBill(widget.billId);

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
      _calc = null;
      _calcError = null;
    });
    await _future;
  }

  LocalRepository get _repo => context.read<LocalRepository>();

  Future<void> _addItem() async {
    final result = await showModalBottomSheet<_NewItem>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _AddItemSheet(),
    );
    if (result == null) return;
    try {
      await _repo.addItem(
        widget.billId,
        name: result.name,
        priceCents: result.priceCents,
        quantity: result.quantity,
        taxable: result.taxable,
      );
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not add item: $e')),
      );
    }
  }

  Future<void> _scanItems() async {
    final messenger = ScaffoldMessenger.of(context);
    final source = await showModalBottomSheet<ReceiptSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(ctx, ReceiptSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Pick from photos'),
              onTap: () => Navigator.pop(ctx, ReceiptSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    setState(() => _scanning = true);
    ScanOutcome? outcome;
    try {
      final repo = _repo;
      _scanner ??= ReceiptScannerService(
        geminiApiKey: kGeminiApiKeyDartDefine.isEmpty
            ? null
            : kGeminiApiKeyDartDefine,
        geminiKeyResolver: () => repo.getSetting(kGeminiApiKeySettingName),
      );
      outcome = await _scanner!.scan(source);
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text("Couldn't read that receipt: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _scanning = false);
    }

    if (!mounted || outcome == null) return;
    final result = outcome.result;
    if (result.items.isEmpty && !result.totals.hasAny) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(outcome.fallbackReason != null
              ? "Couldn't read this one — try a clearer photo."
              : "No items detected — try a clearer or straighter photo of the receipt."),
        ),
      );
      return;
    }
    final fallbackMessage = _scanFallbackMessage(outcome.engine);
    if (outcome.fallbackReason != null && fallbackMessage != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(fallbackMessage)),
      );
    }

    final reviewed = await ScanReviewSheet.show(context, initial: result);
    if (!mounted || reviewed == null || reviewed.items.isEmpty) return;

    int added = 0;
    for (final item in reviewed.items) {
      try {
        await _repo.addItem(
          widget.billId,
          name: item.name,
          priceCents: item.priceCents,
          quantity: item.quantity,
        );
        added++;
      } catch (_) {
        // Skip the bad row; the others still come through.
      }
    }
    if (!mounted) return;
    await _refresh();
    messenger.showSnackBar(
      SnackBar(
        content: Text(added == 0
            ? "Couldn't add scanned items"
            : 'Added $added scanned item${added == 1 ? '' : 's'}'),
      ),
    );
  }

  /// Snackbar copy explaining why we ended up on a non-preferred engine.
  /// Returns `null` when nothing fell back, so the caller skips the toast.
  String? _scanFallbackMessage(ScanEngine engine) {
    switch (engine) {
      case ScanEngine.appleIntelligence:
        return null;
      case ScanEngine.gemini:
        return 'On-device AI was unavailable, used Gemini instead.';
      case ScanEngine.onDevice:
        return 'AI scanners were unavailable, used basic on-device OCR.';
    }
  }

  Future<void> _addParticipant(BillDetails details) async {
    final repo = _repo;
    final selfId = context.read<ProfileState>().selfContactId;
    final all = await repo.listContacts();
    final usedContactIds =
        details.participants.map((p) => p.contactId).toSet();
    final available =
        all.where((c) => !usedContactIds.contains(c.id)).toList();
    if (!mounted) return;
    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'No more contacts to add. Create one in the Contacts tab first.')),
      );
      return;
    }
    final picked = await ContactPickerSheet.pickOne(
      context: context,
      allContacts: available,
      selfId: selfId,
      title: 'Add participant',
    );
    if (picked == null) return;
    try {
      await repo.addParticipant(widget.billId, picked.id);
      if (!mounted) return;
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not add participant: $e')),
      );
    }
  }

  Future<void> _toggleShare(
      BillDetails details, Item item, BillParticipant p) async {
    final existing = details.shares.firstWhere(
      (s) => s.itemId == item.id && s.participantId == p.id,
      orElse: () =>
          ItemShare(id: '', itemId: item.id, participantId: p.id, weight: 0),
    );
    final newWeight = existing.weight > 0 ? 0.0 : 1.0;
    try {
      await _repo.upsertShare(
        widget.billId,
        itemId: item.id,
        participantId: p.id,
        weight: newWeight,
      );
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update share: $e')),
      );
    }
  }

  Future<void> _calculate() async {
    setState(() {
      _calculating = true;
      _calcError = null;
    });
    try {
      final res = await _repo.calculate(widget.billId);
      if (!mounted) return;
      setState(() {
        _calc = res;
        _calculating = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _calcError = e is StateError ? e.message : e.toString();
        _calculating = false;
      });
    }
  }

  Future<void> _deleteItem(Item item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete ${item.name}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _repo.deleteItem(widget.billId, item.id);
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete item: $e')),
      );
    }
  }

  Future<void> _deleteBill() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete bill?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _repo.deleteBill(widget.billId);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bill'),
        actions: [
          IconButton(
            tooltip: 'Delete bill',
            onPressed: _deleteBill,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: FutureBuilder<BillDetails>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final d = snap.data!;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              children: [
                _Header(bill: d.bill),
                const SizedBox(height: 16),
                _Section(
                  title: 'Items',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton.icon(
                        onPressed: _scanning ? null : _scanItems,
                        icon: _scanning
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.document_scanner_outlined),
                        label: Text(_scanning ? 'Scanning…' : 'Scan'),
                      ),
                      TextButton.icon(
                        onPressed: _addItem,
                        icon: const Icon(Icons.add),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                  child: d.items.isEmpty
                      ? const _EmptyHint(
                          'No items yet. Add one to start splitting.')
                      : Column(
                          children: [
                            for (final item in d.items)
                              _ItemRow(
                                item: item,
                                currency: d.bill.currency,
                                onDelete: () => _deleteItem(item),
                              ),
                          ],
                        ),
                ),
                const SizedBox(height: 16),
                _Section(
                  title: 'Participants',
                  trailing: TextButton.icon(
                    onPressed: () => _addParticipant(d),
                    icon: const Icon(Icons.person_add_alt_1_outlined),
                    label: const Text('Add'),
                  ),
                  child: d.participants.isEmpty
                      ? const _EmptyHint(
                          'No participants yet. Add the people splitting the bill.')
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: d.participants
                              .map((p) => Chip(
                                    avatar: CircleAvatar(
                                      child: Text(p.name.isNotEmpty
                                          ? p.name.characters.first
                                              .toUpperCase()
                                          : '?'),
                                    ),
                                    label: Text(p.name),
                                  ))
                              .toList(),
                        ),
                ),
                const SizedBox(height: 16),
                if (d.items.isNotEmpty && d.participants.isNotEmpty)
                  _Section(
                    title: 'Who had what?',
                    child: _ShareMatrix(
                      details: d,
                      onToggle: (item, p) => _toggleShare(d, item, p),
                    ),
                  ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _calculating ? null : _calculate,
                  icon: const Icon(Icons.calculate_outlined),
                  label: Text(_calculating ? 'Calculating…' : 'Calculate split'),
                ),
                if (_calcError != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .errorContainer
                          .withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_calcError!),
                  ),
                ],
                if (_calc != null) ...[
                  const SizedBox(height: 16),
                  _CalcResultCard(calc: _calc!, currency: d.bill.currency),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.bill});
  final Bill bill;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(bill.title, style: Theme.of(context).textTheme.titleLarge),
            if (bill.venue != null) ...[
              const SizedBox(height: 4),
              Text(bill.venue!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).hintColor,
                      )),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _Pill(
                    label: 'Subtotal',
                    value: formatCents(bill.subtotalCents, bill.currency)),
                _Pill(label: 'Tax', value: '${bill.taxRatePct}%'),
                _Pill(label: 'Tip', value: '${bill.tipRatePct}%'),
                if (bill.convenienceFeeRatePct > 0)
                  _Pill(
                      label: 'Convenience fee',
                      value: '${bill.convenienceFeeRatePct}%'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text('$label: $value',
          style: Theme.of(context).textTheme.labelMedium),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(
      {required this.title, required this.child, this.trailing});
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                    child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 4),
                  child: Text(title,
                      style: Theme.of(context).textTheme.titleMedium),
                )),
                ?trailing,
              ],
            ),
            const SizedBox(height: 4),
            child,
          ],
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Text(
        text,
        style: TextStyle(color: Theme.of(context).hintColor),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.item,
    required this.currency,
    required this.onDelete,
  });
  final Item item;
  final String currency;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(item.name),
      subtitle: item.quantity > 1 ? Text('Qty ${item.quantity}') : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Money(
              cents: item.priceCents,
              currency: currency,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _ShareMatrix extends StatelessWidget {
  const _ShareMatrix({required this.details, required this.onToggle});
  final BillDetails details;
  final void Function(Item, BillParticipant) onToggle;

  bool _has(String itemId, String participantId) => details.shares.any(
        (s) =>
            s.itemId == itemId &&
            s.participantId == participantId &&
            s.weight > 0,
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final item in details.items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        )),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final p in details.participants)
                      FilterChip(
                        label: Text(p.name),
                        selected: _has(item.id, p.id),
                        onSelected: (_) => onToggle(item, p),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                const Divider(height: 1),
              ],
            ),
          ),
      ],
    );
  }
}

class _CalcResultCard extends StatelessWidget {
  const _CalcResultCard({required this.calc, required this.currency});
  final CalcResult calc;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Final split',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _row('Subtotal', calc.billTotals.subtotalCents),
            _row('Tax', calc.billTotals.taxCents),
            _row('Tip', calc.billTotals.tipCents),
            if (calc.billTotals.convenienceFeeCents > 0)
              _row('Convenience fee', calc.billTotals.convenienceFeeCents),
            const Divider(),
            _row('Grand total', calc.billTotals.grandTotalCents, bold: true),
            const SizedBox(height: 16),
            Text('Per person',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final p in calc.participants)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(p.name,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    Text(formatCents(p.totalOwedCents, currency),
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, int cents, {bool bold = false}) {
    final style = TextStyle(fontWeight: bold ? FontWeight.w700 : null);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(formatCents(cents, currency), style: style),
        ],
      ),
    );
  }
}

class _NewItem {
  final String name;
  final int priceCents;
  final int quantity;
  final bool taxable;
  _NewItem({
    required this.name,
    required this.priceCents,
    required this.quantity,
    required this.taxable,
  });
}

class _AddItemSheet extends StatefulWidget {
  const _AddItemSheet();
  @override
  State<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<_AddItemSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _qty = TextEditingController(text: '1');
  bool _taxable = true;

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _qty.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + viewInsets),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
            Text('Add item', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _price,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Price',
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
                    controller: _qty,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Qty'),
                  ),
                ),
                const SizedBox(width: 12),
                Row(
                  children: [
                    Switch(
                      value: _taxable,
                      onChanged: (v) => setState(() => _taxable = v),
                    ),
                    const Text('Taxable'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                if (!(_formKey.currentState?.validate() ?? false)) return;
                Navigator.of(context).pop(_NewItem(
                  name: _name.text.trim(),
                  priceCents: parseCents(_price.text)!,
                  quantity: int.tryParse(_qty.text.trim()) ?? 1,
                  taxable: _taxable,
                ));
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
