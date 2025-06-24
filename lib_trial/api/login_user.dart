class LoginUser {
  String? identifier; // username or email
  String? password;

  LoginUser({this.identifier, this.password});

  LoginUser.fromJson(Map<String, dynamic> json) {
    identifier = json['identifier'];
    password = json['password'];
  }

  Map<String, dynamic> toJson() {
    return {
      'identifier': identifier,
      'password': password,
    };
  }
}
