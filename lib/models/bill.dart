import 'item.dart';

class Bill {
  final String id;
  final String activityId;
  final String title;
  final String createdById;
  final DateTime date;
  final List<Item> items;
  final List<String> participantIds;
  final String? notes;

  Bill({
    required this.id,
    required this.activityId,
    required this.title,
    required this.createdById,
    required this.date,
    required this.items,
    required this.participantIds,
    this.notes,
  });

  double get totalAmount {
    return items.fold(0.0, (sum, item) => sum + item.amount);
  }

  Map<String, double> calculateShares() {
    final Map<String, double> shareMap = {};

    for (final participantId in participantIds) {
      shareMap[participantId] = 0.0;
    }

    for (final item in items) {
      final double itemShare = item.sharePerPerson;
      for (final participantId in item.participantIds) {
        shareMap[participantId] = (shareMap[participantId] ?? 0.0) + itemShare;
      }
    }

    return shareMap;
  }
}
