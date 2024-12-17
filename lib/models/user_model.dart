import 'package:cloud_firestore/cloud_firestore.dart';

class UserAddress {
  final String id;
  final String addressLine;
  final String city;
  final String state;
  final String pincode;
  final double latitude;
  final double longitude;
  final bool isDefault;

  UserAddress({
    required this.id,
    required this.addressLine,
    required this.city,
    required this.state,
    required this.pincode,
    required this.latitude,
    required this.longitude,
    this.isDefault = false,
  });

  factory UserAddress.fromMap(Map<String, dynamic> map, String id) {
    return UserAddress(
      id: id,
      addressLine: map['addressLine'] ?? '',
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      pincode: map['pincode'] ?? '',
      latitude: map['latitude'] ?? 0.0,
      longitude: map['longitude'] ?? 0.0,
      isDefault: map['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'addressLine': addressLine,
      'city': city,
      'state': state,
      'pincode': pincode,
      'latitude': latitude,
      'longitude': longitude,
      'isDefault': isDefault,
    };
  }

  UserAddress copyWith({
    String? id,
    String? addressLine,
    String? city,
    String? state,
    String? pincode,
    double? latitude,
    double? longitude,
    bool? isDefault,
  }) {
    return UserAddress(
      id: id ?? this.id,
      addressLine: addressLine ?? this.addressLine,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final List<UserAddress> addresses;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime lastLogin;
  final String role; // CUSTOMER or ADMIN

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.addresses = const [],
    this.isVerified = false,
    required this.createdAt,
    required this.lastLogin,
    this.role = 'CUSTOMER',
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    List<UserAddress> addressList = [];
    if (map['addresses'] != null) {
      addressList = List<UserAddress>.from(
        (map['addresses'] as List).map(
          (address) => UserAddress.fromMap(
            address as Map<String, dynamic>,
            address['id'] ?? '',
          ),
        ),
      );
    }

    return UserModel(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      addresses: addressList,
      isVerified: map['isVerified'] ?? false,
      createdAt:
          map['createdAt'] != null
              ? (map['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
      lastLogin:
          map['lastLogin'] != null
              ? (map['lastLogin'] as Timestamp).toDate()
              : DateTime.now(),
      role: map['role'] ?? 'CUSTOMER',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'addresses': addresses.map((address) => address.toMap()).toList(),
      'isVerified': isVerified,
      'createdAt': createdAt,
      'lastLogin': lastLogin,
      'role': role,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    List<UserAddress>? addresses,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? lastLogin,
    String? role,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      addresses: addresses ?? this.addresses,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      role: role ?? this.role,
    );
  }
}
