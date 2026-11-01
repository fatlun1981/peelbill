class Item {
  final String id;
  final String name;
  final double amount;
  final String payerId;
  final List<String> participantIds;
  final String? notes;

  Item({
    required this.id,
    required this.name,
    required this.amount,
    required this.payerId,
    required this.participantIds,
    this.notes,
  });

  double get sharePerPerson {
    if (participantIds.isEmpty) {
      return 0.0;
    }
    return amount / participantIds.length;
  }
}
