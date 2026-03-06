import 'user_model.dart';

class AuthResponseModel {
  final String message;
  final UserModel user;
  final String token;
  final String tokenType;

  AuthResponseModel({
    required this.message,
    required this.user,
    required this.token,
    required this.tokenType,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      message: json['message'],
      user: UserModel.fromJson(json['user']['data'] ?? json['user']),
      token: json['token'],
      tokenType: json['token_type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'user': user.toJson(),
      'token': token,
      'token_type': tokenType,
    };
  }
}
