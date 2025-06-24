class RegistrationUser {
  String? email;
  String? password;
  String? username;

  RegistrationUser({
    this.email,
    this.password,
    this.username,
  });
  
  RegistrationUser.fromJson(Map<String, dynamic> json) {
    email = json['email'];
    password = json['password'];
    username = json['username'];
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'password': password,
    };
  }
}