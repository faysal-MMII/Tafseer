class IslamicFact {
  final String category;
  final String title;
  final String description;

  IslamicFact({
    required this.category,
    required this.title,
    required this.description,
  });

  factory IslamicFact.fromMap(Map<String, String> map) {
    return IslamicFact(
      category: map['category'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
    );
  }
}

