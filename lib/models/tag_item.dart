import 'package:flutter/material.dart';

class TagItem {
  final String id;
  final String name;
  final int colorValue;
  final DateTime createdAt;

  const TagItem({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.createdAt,
  });

  Color get color => Color(colorValue);

  TagItem copyWith({
    String? id,
    String? name,
    int? colorValue,
    DateTime? createdAt,
  }) {
    return TagItem(
      id: id ?? this.id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'color': colorValue,
        'created_at': createdAt.toIso8601String(),
      };

  factory TagItem.fromMap(Map<String, Object?> map) => TagItem(
        id: map['id'] as String,
        name: map['name'] as String,
        colorValue: map['color'] as int,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}
