/// App user / profile. Fields mirror `/api/user/fetch_profile`.
class UserModel {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String referCode;
  final String accountStatus; // active | banned
  final int totalMatchesPlayed;
  final int totalMatchesWon;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.referCode = '',
    this.accountStatus = 'active',
    this.totalMatchesPlayed = 0,
    this.totalMatchesWon = 0,
  });

  String get uid => '#$id';
  bool get isBanned => accountStatus == 'banned';

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
        id: j['id'] ?? 0,
        name: j['name'] ?? '',
        email: j['email'] ?? '',
        phone: j['phone'] ?? '',
        referCode: j['refer_code'] ?? '',
        accountStatus: j['account_status'] ?? 'active',
        totalMatchesPlayed: j['total_matches_played'] ?? 0,
        totalMatchesWon: j['total_matches_won'] ?? 0,
      );

  UserModel copyWith({String? name, String? email, String? phone}) => UserModel(
        id: id,
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        referCode: referCode,
        accountStatus: accountStatus,
        totalMatchesPlayed: totalMatchesPlayed,
        totalMatchesWon: totalMatchesWon,
      );
}
