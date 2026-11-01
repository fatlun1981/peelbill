import 'package:flutter/material.dart';

import '../models/models.dart';

class _ItemDraft {
  _ItemDraft(this.id);

  final String id;
  final TextEditingController name = TextEditingController();
  final TextEditingController amount = TextEditingController();
  String? payerId;
  final Set<String> participantIds = {};

  void dispose() {
    name.dispose();
    amount.dispose();
  }
}

class BillFormScreen extends StatefulWidget {
  const BillFormScreen({super.key});

  @override
  State<BillFormScreen> createState() => _BillFormScreenState();
}

class _BillFormScreenState extends State<BillFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  final _personController = TextEditingController();

  DateTime _date = DateTime.now();
  final List<Person> _people = [];
  final List<_ItemDraft> _items = [];
  int _idCounter = 0;

  String _nextId(String prefix) => '$prefix-${_idCounter++}';

  @override
  void initState() {
    super.initState();
    _items.add(_ItemDraft(_nextId('item')));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _personController.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _nameOf(String id) => _people
      .firstWhere((p) => p.id == id, orElse: () => Person(id: id, name: id))
      .name;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _addPerson() {
    final name = _personController.text.trim();
    if (name.isEmpty) return;
    setState(() {
      final person = Person(id: _nextId('person'), name: name);
      _people.add(person);
      // New participants join every existing item by default.
      for (final item in _items) {
        item.participantIds.add(person.id);
      }
      _personController.clear();
    });
  }

  void _removePerson(Person person) {
    setState(() {
      _people.removeWhere((p) => p.id == person.id);
      for (final item in _items) {
        item.participantIds.remove(person.id);
        if (item.payerId == person.id) item.payerId = null;
      }
    });
  }

  void _addItem() {
    setState(() {
      final item = _ItemDraft(_nextId('item'));
      item.participantIds.addAll(_people.map((p) => p.id));
      _items.add(item);
    });
  }

  void _removeItem(_ItemDraft item) {
    setState(() => _items.remove(item));
    item.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_people.isEmpty) {
      _showError('Add at least one participant.');
      return;
    }
    if (_items.isEmpty) {
      _showError('Add at least one item.');
      return;
    }
    for (final item in _items) {
      if (item.payerId == null) {
        _showError('Choose who paid for "${item.name.text.trim()}".');
        return;
      }
      if (item.participantIds.isEmpty) {
        _showError('Select who shares "${item.name.text.trim()}".');
        return;
      }
    }

    final notes = _notesController.text.trim();
    final bill = Bill(
      id: _nextId('bill'),
      activityId: '',
      title: _titleController.text.trim(),
      createdById: _people.first.id,
      date: _date,
      participantIds: _people.map((p) => p.id).toList(),
      notes: notes.isEmpty ? null : notes,
      items: _items
          .map((i) => Item(
                id: i.id,
                name: i.name.text.trim(),
                amount: double.parse(i.amount.text.trim()),
                payerId: i.payerId!,
                participantIds: i.participantIds.toList(),
              ))
          .toList(),
    );

    _showSummary(bill);
  }

  void _showSummary(Bill bill) {
    final shares = bill.calculateShares();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(bill.title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Date: ${_formatDate(bill.date)}'),
              Text('Total: ${bill.totalAmount.toStringAsFixed(2)}'),
              const Divider(),
              for (final entry in shares.entries)
                Text(
                    '${_nameOf(entry.key)} owes ${entry.value.toStringAsFixed(2)}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('New Bill'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter a title' : null,
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(_formatDate(_date)),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            Text('Participants',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _personController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addPerson(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _addPerson,
                  icon: const Icon(Icons.person_add),
                  tooltip: 'Add participant',
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              children: [
                for (final p in _people)
                  Chip(
                    label: Text(p.name),
                    onDeleted: () => _removePerson(p),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Items', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final item in _items) _buildItemCard(item),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _addItem,
                icon: const Icon(Icons.add),
                label: const Text('Add item'),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _submit,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Save bill'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(_ItemDraft item) {
    return Card(
      key: ValueKey(item.id),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: item.name,
                    decoration: const InputDecoration(labelText: 'Item name'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: item.amount,
                    decoration: const InputDecoration(labelText: 'Amount'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      final value = double.tryParse((v ?? '').trim());
                      if (value == null || value <= 0) return 'Invalid';
                      return null;
                    },
                  ),
                ),
                IconButton(
                  onPressed: () => _removeItem(item),
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Remove item',
                ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              key: ValueKey('${item.id}-${item.payerId}-${_people.length}'),
              initialValue: item.payerId,
              decoration: const InputDecoration(labelText: 'Paid by'),
              items: [
                for (final p in _people)
                  DropdownMenuItem(value: p.id, child: Text(p.name)),
              ],
              onChanged: (v) => setState(() => item.payerId = v),
            ),
            const SizedBox(height: 12),
            const Text('Shared by'),
            Wrap(
              spacing: 8,
              children: [
                for (final p in _people)
                  FilterChip(
                    label: Text(p.name),
                    selected: item.participantIds.contains(p.id),
                    onSelected: (selected) => setState(() {
                      if (selected) {
                        item.participantIds.add(p.id);
                      } else {
                        item.participantIds.remove(p.id);
                      }
                    }),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
