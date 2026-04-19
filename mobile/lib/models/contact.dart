class Contact {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? venmo;
  final String? cashapp;
  final bool isTemporary;

  Contact({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.venmo,
    this.cashapp,
    this.isTemporary = false,
  });

  factory Contact.fromJson(Map<String, dynamic> json) => Contact(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String?,
        phone: json['phone'] as String?,
        venmo: json['venmo'] as String?,
        cashapp: json['cashapp'] as String?,
        isTemporary: (json['isTemporary'] as bool?) ?? false,
      );

  Map<String, dynamic> toCreateJson() => {
        'name': name,
        if (email != null && email!.isNotEmpty) 'email': email,
        if (phone != null && phone!.isNotEmpty) 'phone': phone,
        if (venmo != null && venmo!.isNotEmpty) 'venmo': venmo,
        if (cashapp != null && cashapp!.isNotEmpty) 'cashapp': cashapp,
        'isTemporary': isTemporary,
      };
}
