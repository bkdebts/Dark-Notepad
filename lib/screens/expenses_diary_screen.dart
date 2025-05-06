import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ExpenseEntry {
  final String item;
  final double amount;
  final DateTime timestamp;
  ExpenseEntry({required this.item, required this.amount, required this.timestamp});

  Map<String, dynamic> toJson() => {
    'item': item,
    'amount': amount,
    'timestamp': timestamp.toIso8601String(),
  };
  factory ExpenseEntry.fromJson(Map<String, dynamic> json) => ExpenseEntry(
    item: json['item'],
    amount: (json['amount'] as num).toDouble(),
    timestamp: DateTime.parse(json['timestamp']),
  );
}

class ExpensesDiaryScreen extends StatefulWidget {
  const ExpensesDiaryScreen({Key? key}) : super(key: key);
  @override
  State<ExpensesDiaryScreen> createState() => _ExpensesDiaryScreenState();
}

class _ExpensesDiaryScreenState extends State<ExpensesDiaryScreen> {
  List<ExpenseEntry> _entries = [];
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  DateTime _periodStart = DateTime.now().subtract(const Duration(days: 30));
  DateTime _periodEnd = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('expenses_entries');
    if (data != null) {
      final List<dynamic> jsonList = jsonDecode(data);
      setState(() {
        _entries = jsonList.map((e) => ExpenseEntry.fromJson(e)).toList();
      });
    }
  }

  Future<void> _saveExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(_entries.map((e) => e.toJson()).toList());
    await prefs.setString('expenses_entries', data);
  }

  void _addEntry() {
    final item = _itemController.text.trim();
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (item.isEmpty || amount <= 0) return;
    setState(() {
      _entries.add(ExpenseEntry(item: item, amount: amount, timestamp: DateTime.now()));
      _itemController.clear();
      _amountController.clear();
    });
    _saveExpenses();
  }

  double get _totalForPeriod {
    return _entries.where((e) => e.timestamp.isAfter(_periodStart) && e.timestamp.isBefore(_periodEnd.add(const Duration(days: 1)))).fold(0.0, (sum, e) => sum + e.amount);
  }

  @override
  Widget build(BuildContext context) {
    final periodEntries = _entries.where((e) => e.timestamp.isAfter(_periodStart) && e.timestamp.isBefore(_periodEnd.add(const Duration(days: 1)))).toList();
    periodEntries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses Diary'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            tooltip: 'Change Period',
            onPressed: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2000),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                initialDateRange: DateTimeRange(start: _periodStart, end: _periodEnd),
              );
              if (picked != null) {
                setState(() {
                  _periodStart = picked.start;
                  _periodEnd = picked.end;
                });
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _itemController,
                    decoration: const InputDecoration(
                      labelText: 'Item',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addEntry,
                  child: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('₹${_totalForPeriod.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: periodEntries.isEmpty
                  ? const Center(child: Text('No expenses yet.'))
                  : SingleChildScrollView(
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Item')),
                          DataColumn(label: Text('Amount')),
                          DataColumn(label: Text('Timestamp')),
                        ],
                        rows: periodEntries.map((e) {
                          final index = _entries.indexOf(e);
                          return DataRow(cells: [
                            DataCell(Text(e.item)),
                            DataCell(Text('₹${e.amount.toStringAsFixed(2)}')),
                            DataCell(Row(
                              children: [
                                Text(DateFormat('yyyy-MM-dd HH:mm').format(e.timestamp)),
                                IconButton(
                                  icon: Icon(Icons.edit, size: 18, color: Colors.purple),
                                  tooltip: 'Edit',
                                  onPressed: () async {
                                    final result = await showDialog<Map<String, dynamic>>(
                                      context: context,
                                      builder: (context) {
                                        final itemController = TextEditingController(text: e.item);
                                        final amountController = TextEditingController(text: e.amount.toString());
                                        return AlertDialog(
                                          title: const Text('Edit Expense'),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              TextField(
                                                controller: itemController,
                                                decoration: const InputDecoration(labelText: 'Item'),
                                              ),
                                              TextField(
                                                controller: amountController,
                                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                                decoration: const InputDecoration(labelText: 'Amount'),
                                              ),
                                            ],
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context, {'delete': true}),
                                              child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text('Cancel'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () {
                                                final newItem = itemController.text.trim();
                                                final newAmount = double.tryParse(amountController.text.trim()) ?? 0.0;
                                                if (newItem.isEmpty || newAmount <= 0) return;
                                                Navigator.pop(context, {
                                                  'item': newItem,
                                                  'amount': newAmount,
                                                });
                                              },
                                              child: const Text('Save'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                    if (result != null) {
                                      if (result['delete'] == true) {
                                        setState(() {
                                          _entries.removeAt(index);
                                        });
                                        _saveExpenses();
                                      } else if (result['item'] != null && result['amount'] != null) {
                                        setState(() {
                                          _entries[index] = ExpenseEntry(
                                            item: result['item'],
                                            amount: result['amount'],
                                            timestamp: e.timestamp,
                                          );
                                        });
                                        _saveExpenses();
                                      }
                                    }
                                  },
                                ),
                              ],
                            )),
                          ]);
                        }).toList(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
} 