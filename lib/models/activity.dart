class Activity {
  final String id;
  final String title;
  final String? description;
  final DateTime date;
  final List<String> participantIds;
  final List<String> billIds;

  Activity({
    required this.id,
    required this.title,
    required this.date,
    required this.participantIds,
    required this.billIds,
    this.description,
  });
}
