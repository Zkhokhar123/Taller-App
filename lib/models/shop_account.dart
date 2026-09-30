class ShopAccount {
  final String id;
  final String shopName;
  final String phone;
  final String address;
  final String passwordHash;
  final DateTime createdAt;

  const ShopAccount({
    required this.id,
    required this.shopName,
    required this.phone,
    required this.address,
    required this.passwordHash,
    required this.createdAt,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'shop_name': shopName,
        'phone': phone,
        'address': address,
        'password_hash': passwordHash,
        'created_at': createdAt.toIso8601String(),
      };

  factory ShopAccount.fromMap(Map<String, Object?> map) => ShopAccount(
        id: map['id'] as String,
        shopName: map['shop_name'] as String,
        phone: map['phone'] as String,
        address: map['address'] as String,
        passwordHash: map['password_hash'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}
