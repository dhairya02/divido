import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/bill.dart';
import '../services/local_repository.dart';
import '../state/profile_state.dart';
import '../widgets/money.dart';
import 'account_screen.dart';
import 'bill_detail_screen.dart';
import 'contacts_screen.dart';
import 'new_bill_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = const [
      _BillsTab(),
      ContactsScreen(),
      AccountScreen(),
    ];
    return Scaffold(
      body: SafeArea(child: pages[_index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Bills',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Contacts',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_circle_outlined),
            selectedIcon: Icon(Icons.account_circle),
            label: 'Account',
          ),
        ],
      ),
      floatingActionButton: _index == 0
          ? FloatingActionButton.extended(
              onPressed: () async {
                final created = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => const NewBillScreen()),
                );
                if (created == true && mounted) setState(() {});
              },
              icon: const Icon(Icons.add),
              label: const Text('New bill'),
            )
          : null,
    );
  }
}

class _BillsTab extends StatefulWidget {
  const _BillsTab();

  @override
  State<_BillsTab> createState() => _BillsTabState();
}

class _BillsTabState extends State<_BillsTab> {
  late Future<List<Bill>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Bill>> _load() => context.read<LocalRepository>().listBills();

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileState>();
    return RefreshIndicator(
      onRefresh: _refresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hi ${profile.displayName?.split(' ').first ?? 'there'} 👋',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your recent bills',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                  ),
                ],
              ),
            ),
          ),
          FutureBuilder<List<Bill>>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snap.hasError) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Could not load bills.\n${snap.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              }
              final bills = snap.data ?? [];
              if (bills.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyBills(),
                );
              }
              return SliverList.separated(
                itemCount: bills.length,
                separatorBuilder: (_, _) => const SizedBox(height: 4),
                itemBuilder: (context, i) {
                  final b = bills[i];
                  return ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.restaurant_outlined),
                    ),
                    title: Text(b.title,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: b.venue != null
                        ? Text(b.venue!,
                            maxLines: 1, overflow: TextOverflow.ellipsis)
                        : null,
                    trailing: Money(
                      cents: b.subtotalCents,
                      currency: b.currency,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => BillDetailScreen(billId: b.id),
                        ),
                      );
                      if (mounted) _refresh();
                    },
                  );
                },
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}

class _EmptyBills extends StatelessWidget {
  const _EmptyBills();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 64, color: Theme.of(context).hintColor),
          const SizedBox(height: 16),
          Text(
            'No bills yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap “New bill” to start splitting one.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
