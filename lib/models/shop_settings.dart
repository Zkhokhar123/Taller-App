class ShopSettings {
  final String shopName;
  final String phone;
  final String address;
  final String currencySymbol;

  const ShopSettings({
    this.shopName = '',
    this.phone = '',
    this.address = '',
    this.currencySymbol = 'Rs',
  });

  ShopSettings copyWith({
    String? shopName,
    String? phone,
    String? address,
    String? currencySymbol,
  }) {
    return ShopSettings(
      shopName: shopName ?? this.shopName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      currencySymbol: currencySymbol ?? this.currencySymbol,
    );
  }
}
