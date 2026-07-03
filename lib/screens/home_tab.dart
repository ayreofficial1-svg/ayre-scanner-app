import 'package:flutter/material.dart';
import '../services/api_service.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  String _displayName = '';
  Map<String, dynamic>? _market;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final session = await ApiService.getSession();
    final market = await ApiService.getMarket();

    if (!mounted) return;
    setState(() {
      _displayName = session?['display_name'] ?? session?['username'] ?? '';
      _market = market;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            "Hi $_displayName, here's what we have for you today",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildMarketSnapshot(),
        ],
      ),
    );
  }

  Widget _buildMarketSnapshot() {
    if (_market == null) {
      return const Text('Market data unavailable');
    }

    // Adjust these keys once we confirm the exact shape of /api/market's response.
    final nifty = _market!['nifty'] ?? _market!['NIFTY'];
    final sensex = _market!['sensex'] ?? _market!['SENSEX'];

    return Row(
      children: [
        Expanded(child: _marketCard('NIFTY 50', nifty)),
        const SizedBox(width: 12),
        Expanded(child: _marketCard('SENSEX', sensex)),
      ],
    );
  }

  Widget _marketCard(String label, dynamic data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(data?.toString() ?? '--'),
          ],
        ),
      ),
    );
  }
}
