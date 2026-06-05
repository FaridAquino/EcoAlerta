class User {
  final String email;
  final String routeId;
  final String address;

  const User({
    required this.email,
    required this.routeId,
    required this.address,
  });

  factory User.fromMap(String email, Map<String, dynamic> map) {
    return User(
      email: email,
      routeId: map['routeId'] as String,
      address: map['address'] as String,
    );
  }
}
