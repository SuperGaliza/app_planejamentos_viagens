//in here first we create the users json model
// To parse this JSON data, do
class Users {
  final int? usrId;
  final String usrName;
  final String usrPassword;
  final String? profileImagePath; // NOVO CAMPO

  Users({
    this.usrId,
    required this.usrName,
    required this.usrPassword,
    this.profileImagePath, // NOVO
  });

  factory Users.fromMap(Map<String, dynamic> json) => Users(
        usrId: json["usrId"],
        usrName: json["usrName"],
        usrPassword: json["usrPassword"],
        profileImagePath: json["profileImagePath"], // NOVO
      );

  Map<String, dynamic> toMap() => {
        "usrId": usrId,
        "usrName": usrName,
        "usrPassword": usrPassword,
        "profileImagePath": profileImagePath, // NOVO
      };
}