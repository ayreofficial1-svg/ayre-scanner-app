import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SignalsTab extends StatefulWidget {
  const SignalsTab({super.key});

  @override
  State<SignalsTab> createState() => _SignalsTabState();
}

class _SignalsTabState extends State<SignalsTab> {
  List<Map<String, dynamic>> _signals = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final signals = await ApiService.getSignals();
    if (!mounted) return;
    setState(() {
      _signals = signals;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_signals.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: const [
            SizedBox(height: 120),
            Center(child: Text('No signals yet', style: TextStyle(color: Colors.grey))),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _signals.length,
        itemBuilder: (context, i) => _signalCard(_signals[i]),
      ),
    );
  }

  Widget _signalCard(Map<String, dynamic> s) {
    final symbol = s['symbol']?.toString() ?? '';
    final rationale = s['rationale']?.toString() ?? '';
    final dateAdded = s['date_added']?.toString() ?? '';
    final lastPrice = s['last_price'];
    final changePct = s['change_pct'];

    final isUp = (changePct is num) ? changePct >= 0 : null;
    final changeColor = isUp == null
        ? Colors.grey
        : (isUp ? Colors.green : Colors.red);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(symbol, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      lastPrice is num ? lastPrice.toStringAsFixed(2) : '--',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      changePct is num
                          ? '${isUp! ? '+' : ''}${changePct.toStringAsFixed(2)}%'
                          : '--',
                      style: TextStyle(color: changeColor, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
            if (rationale.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(rationale, style: const TextStyle(color: Colors.black87)),
            ],
            if (dateAdded.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Added $dateAdded', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ],
        ),
      ),
    );
  }
}