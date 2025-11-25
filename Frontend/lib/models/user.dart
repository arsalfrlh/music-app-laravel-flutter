class User {
  final int id;
  final String name;
  final String email;
  final String? bio;
  final String? profile;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({required this.id, required this.name, required this.email, this.bio, this.profile, this.createdAt, this.updatedAt});
  factory User.fromJson(Map<String, dynamic> json){
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      bio: json['bio'],
      profile: json['profile'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at'])
    );
  }
}