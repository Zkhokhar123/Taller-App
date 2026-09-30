class Karigar {
  final String id;
  final String name;
  final String? phone;
  final String? specialty;
  final String? notes;
  final DateTime createdAt;

  const Karigar({
    required this.id,
    required this.name,
    this.phone,
    this.specialty,
    this.notes,
    required this.createdAt,
  });

  Karigar copyWith({
    String? id,
    String? name,
    String? phone,
    String? specialty,
    String? notes,
    DateTime? createdAt,
  }) {
    return Karigar(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      specialty: specialty ?? this.specialty,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'phone': phone,
        'specialty': specialty,
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
      };

  factory Karigar.fromMap(Map<String, Object?> map) => Karigar(
        id: map['id'] as String,
        name: map['name'] as String,
        phone: map['phone'] as String?,
        specialty: map['specialty'] as String?,
        notes: map['notes'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}
