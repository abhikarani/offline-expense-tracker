/// Model representing a spending category/tag
class Tag {
  final String name;
  final bool isActive;

  Tag({
    required this.name,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'isActive': isActive ? 1 : 0,
    };
  }

  factory Tag.fromMap(Map<String, dynamic> map) {
    return Tag(
      name: map['name'] as String,
      isActive: (map['isActive'] as int) == 1,
    );
  }

  Tag copyWith({
    String? name,
    bool? isActive,
  }) {
    return Tag(
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
    );
  }
}
