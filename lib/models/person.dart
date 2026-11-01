class Person {
  final String id;
  final String name;
  final String? email;
  final String? avatarUrl;

  Person({
    required this.id,
    required this.name,
    this.email,
    this.avatarUrl,
  });
}
