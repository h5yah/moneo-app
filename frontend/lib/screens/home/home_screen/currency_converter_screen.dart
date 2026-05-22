import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CurrencyConverterScreen extends StatefulWidget {
  const CurrencyConverterScreen({super.key});
  @override
  State<CurrencyConverterScreen> createState() => _CurrencyConverterScreenState();
}

class _CurrencyConverterScreenState extends State<CurrencyConverterScreen> {
  final _amountController = TextEditingController(text: '1');
  String _from = 'USD';
  String _to = 'MUR';
  double _result = 0;
  double _rate = 0;
  bool _loading = false;
  String? _error;
  String _rateDate = '';

  // Currencies to show in the dropdown
  final List<String> _currencies = [
    'USD', 'MUR', 'EUR', 'GBP', 'INR', 'ZAR', 'AUD', 'JPY', 'CAD', 'CHF',
  ];

  @override
  void initState() {
    super.initState();
    _fetchAndConvert();
  }

  Future<void> _fetchAndConvert() async {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount == 0) {
      setState(() => _result = 0);
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      final rate = await _fetchRate(_from, _to);
      setState(() {
        _rate = rate;
        _result = amount * rate;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to fetch rates. Check your connection.';
        _loading = false;
      });
    }
  }

  /// Fetches the exchange rate from [from] to [to].
  /// Primary: fawazahmed0 CDN API (no key, 200+ currencies incl. MUR)
  /// Fallback: currency-api.pages.dev mirror
  Future<double> _fetchRate(String from, String to) async {
    final fromLower = from.toLowerCase();
    final toLower = to.toLowerCase();

    final urls = [
      'https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies/$fromLower.json',
      'https://latest.currency-api.pages.dev/v1/currencies/$fromLower.json',
    ];

    for (final url in urls) {
      try {
        final response = await http.get(Uri.parse(url))
            .timeout(const Duration(seconds: 8));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final rates = data[fromLower] as Map<String, dynamic>;
          final rate = (rates[toLower] as num?)?.toDouble();
          if (rate != null) {
            _rateDate = data['date'] ?? '';
            return rate;
          }
        }
      } catch (_) {
        // try next URL
      }
    }
    throw Exception('Could not fetch rate');
  }

  void _swap() {
    setState(() {
      final tmp = _from; _from = _to; _to = tmp;
    });
    _fetchAndConvert();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F1020) : const Color(0xFFF5F7FB);
    final card = isDark ? const Color(0xFF1B1D33) : Colors.white;
    final border = isDark ? const Color(0xFF2A2D4A) : const Color(0xFFE9ECF4);
    final text = isDark ? Colors.white : const Color(0xFF111827);
    final muted = isDark ? const Color(0xFFAAB0C6) : const Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Currency converter',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: text)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF007AFF)),
            onPressed: _fetchAndConvert,
            tooltip: 'Refresh rates',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCurrencyRow('From', _from, (v) {
                    setState(() => _from = v!);
                    _fetchAndConvert();
                  }),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: '0',
                      hintStyle: TextStyle(color: muted),
                    ),
                    onChanged: (_) => _fetchAndConvert(),
                  ),
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildCurrencyRow('To', _to, (v) {
                        setState(() => _to = v!);
                        _fetchAndConvert();
                      }),
                      GestureDetector(
                        onTap: _swap,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF2FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.swap_vert_rounded, color: Color(0xFF007AFF)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _error != null
                          ? const Color(0xFFFFF0F0)
                          : const Color(0xFFEAF7EE),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: _loading
                        ? const Center(
                            child: SizedBox(
                              height: 36,
                              width: 36,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: Color(0xFF27500A),
                              ),
                            ),
                          )
                        : _error != null
                            ? Text(_error!,
                                style: const TextStyle(
                                    fontSize: 15, color: Colors.red))
                            : Text(
                                _result.toStringAsFixed(2),
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF27500A),
                                ),
                              ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: border),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: muted, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error != null
                          ? 'Could not load live rates.'
                          : _rate == 0
                              ? 'Fetching live rates...'
                              : '1 $_from = ${_rate.toStringAsFixed(4)} $_to'
                                '${_rateDate.isNotEmpty ? ' · $_rateDate' : ''}',
                      style: TextStyle(fontSize: 12, color: muted),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyRow(String label, String selected, ValueChanged<String?> onChanged) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? const Color(0xFFAAB0C6) : const Color(0xFF6B7280);
    final text = isDark ? Colors.white : const Color(0xFF111827);
    return Row(
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: muted)),
        const SizedBox(width: 12),
        DropdownButton<String>(
          value: selected,
          underline: const SizedBox(),
          dropdownColor: isDark ? const Color(0xFF1B1D33) : Colors.white,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: text),
          items: _currencies
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}