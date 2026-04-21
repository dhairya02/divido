import 'package:flutter/material.dart';

import '../services/receipt_scanner.dart';
import '../utils/money.dart';

/// Bottom sheet shown after a receipt scan. Lets the user verify, rename,
/// re-price, add or remove items before they're committed to the bill.
///
/// Returns `null` if the user dismisses the sheet, otherwise an updated
/// [ScanResult] with whatever edits they made.
class ScanReviewSheet extends StatefulWidget {
  const ScanReviewSheet({super.key, required this.initial});

  final ScanResult initial;

  static Future<ScanResult?> show(
    BuildContext context, {
    required ScanResult initial,
  }) {
    return showModalBottomSheet<ScanResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ScanReviewSheet(initial: initial),
    );
  }

  @override
  State<ScanReviewSheet> createState() => _ScanReviewSheetState();
}

class _ScanReviewSheetState extends State<ScanReviewSheet> {
  late final List<_EditableItem> _items;
  late ScannedTotals _totals;

  @override
  void initState() {
    super.initState();
    _items = widget.initial.items.map(_EditableItem.from).toList();
    _totals = widget.initial.totals;
  }

  @override
  void dispose() {
    for (final it in _items) {
      it.dispose();
    }
    super.dispose();
  }

  int get _itemsTotalCents => _items.fold<int>(
        0,
        (acc, it) =>
            acc + (it.priceCents ?? 0) * it.quantity,
      );

  void _addBlank() {
    setState(() {
      _items.add(_EditableItem(name: '', priceCents: null, quantity: 1));
    });
  }

  void _remove(int index) {
    setState(() {
      _items.removeAt(index).dispose();
    });
  }

  void _confirm() {
    final cleaned = <ScannedItem>[];
    for (final it in _items) {
      final name = it.nameCtl.text.trim();
      final cents = parseCents(it.priceCtl.text);
      if (name.isEmpty || cents == null || cents <= 0) continue;
      cleaned.add(ScannedItem(
        name: name,
        priceCents: cents,
        quantity: it.quantity.clamp(1, 99),
      ));
    }
    Navigator.of(context).pop(
      ScanResult(
        items: cleaned,
        totals: ScannedTotals(
          subtotalCents: cleaned.isEmpty
              ? _totals.subtotalCents
              : cleaned.fold<int>(
                  0, (acc, it) => acc + it.priceCents * it.quantity),
          taxCents: _totals.taxCents,
          tipCents: _totals.tipCents,
          totalCents: _totals.totalCents,
        ),
        merchant: widget.initial.merchant,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.initial.merchant ?? 'Scanned receipt',
                            style: Theme.of(context).textTheme.titleLarge,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Review items before adding them to the bill',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                    color: Theme.of(context).hintColor),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Add row',
                      icon: const Icon(Icons.add),
                      onPressed: _addBlank,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _items.isEmpty
                    ? _EmptyState(onAdd: _addBlank)
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: _items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final it = _items[i];
                          return _ItemRow(
                            item: it,
                            onChanged: () => setState(() {}),
                            onRemove: () => _remove(i),
                          );
                        },
                      ),
              ),
              _SummaryFooter(
                itemCount: _items.length,
                subtotalCents: _itemsTotalCents,
                totals: _totals,
                onConfirm: _items.isEmpty ? null : _confirm,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EditableItem {
  _EditableItem({
    required String name,
    required int? priceCents,
    required this.quantity,
  })  : nameCtl = TextEditingController(text: name),
        priceCtl = TextEditingController(
            text: priceCents == null ? '' : (priceCents / 100).toStringAsFixed(2));

  factory _EditableItem.from(ScannedItem s) => _EditableItem(
        name: s.name,
        priceCents: s.priceCents,
        quantity: s.quantity,
      );

  final TextEditingController nameCtl;
  final TextEditingController priceCtl;
  int quantity;

  int? get priceCents => parseCents(priceCtl.text);

  void dispose() {
    nameCtl.dispose();
    priceCtl.dispose();
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.item,
    required this.onChanged,
    required this.onRemove,
  });

  final _EditableItem item;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 5,
              child: TextField(
                controller: item.nameCtl,
                onChanged: (_) => onChanged(),
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  isDense: true,
                  labelText: 'Item',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 56,
              child: _QtyStepper(
                value: item.quantity,
                onChanged: (v) {
                  item.quantity = v;
                  onChanged();
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: TextField(
                controller: item.priceCtl,
                onChanged: (_) => onChanged(),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  isDense: true,
                  prefixText: '\$ ',
                  labelText: 'Price',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Remove',
              icon: const Icon(Icons.close, size: 20),
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}

class _QtyStepper extends StatelessWidget {
  const _QtyStepper({required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(value >= 99 ? 1 : value + 1),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          border: Border.all(
              color: Theme.of(context).dividerColor, width: 1),
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.center,
        child: Text('×$value',
            style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _SummaryFooter extends StatelessWidget {
  const _SummaryFooter({
    required this.itemCount,
    required this.subtotalCents,
    required this.totals,
    required this.onConfirm,
  });

  final int itemCount;
  final int subtotalCents;
  final ScannedTotals totals;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      itemCount == 0
                          ? 'No items yet'
                          : '$itemCount item${itemCount == 1 ? '' : 's'} • subtotal ${formatCents(subtotalCents)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  if (totals.taxCents != null)
                    _Pill(
                      label: 'Tax',
                      value: formatCents(totals.taxCents!),
                    ),
                  if (totals.tipCents != null) ...[
                    const SizedBox(width: 6),
                    _Pill(
                      label: 'Tip',
                      value: formatCents(totals.tipCents!),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: onConfirm,
                icon: const Icon(Icons.check),
                label: Text(itemCount == 0
                    ? 'Add at least one item'
                    : 'Use these items'),
              ),
            ],
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text('$label $value',
          style: Theme.of(context).textTheme.labelSmall),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 48, color: Theme.of(context).hintColor),
            const SizedBox(height: 12),
            const Text(
              "Hmm, we couldn't pick out any line items.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Try a clearer photo, or add items manually below.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).hintColor),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add item'),
            ),
          ],
        ),
      ),
    );
  }
}
