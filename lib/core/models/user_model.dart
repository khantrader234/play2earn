import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoURL;
  final DateTime createdAt;
  final String? referralCode;
  final int coins;
  final int gamesPlayed;
  final List<String> powerUps;
  final DateTime? lastLoginDate;
  final DateTime? lastWatchTime;
  final DateTime? lastSpinTime;
  final DateTime? lastDayReset;
  final int spinsRemaining;
  final int adSpinsUsed;
  final int loginStreak;
  final int highScore;
  final int totalEarned;
  final int totalSpent;
  final Map<String, dynamic> achievements;
  final Map<String, dynamic> missions;

  UserModel({
    required this.uid,
    this.email,
    this.displayName,
    this.photoURL,
    required this.createdAt,
    this.referralCode,
    required this.coins,
    required this.gamesPlayed,
    required this.powerUps,
    this.lastLoginDate,
    this.lastWatchTime,
    this.lastSpinTime,
    this.lastDayReset,
    this.spinsRemaining = 3,
    this.adSpinsUsed = 0,
    required this.loginStreak,
    required this.highScore,
    required this.totalEarned,
    required this.totalSpent,
    required this.achievements,
    required this.missions,
  });

  String get id => uid;

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] as String?,
      displayName: data['displayName'] as String?,
      photoURL: data['photoURL'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      referralCode: data['referralCode'] as String?,
      coins: data['coins'] as int? ?? 0,
      gamesPlayed: data['gamesPlayed'] as int? ?? 0,
      powerUps: List<String>.from(data['powerUps'] as List<dynamic>? ?? []),
      lastLoginDate: data['lastLoginDate'] != null
          ? (data['lastLoginDate'] as Timestamp).toDate()
          : null,
      lastWatchTime: data['lastWatchTime'] != null
          ? (data['lastWatchTime'] as Timestamp).toDate()
          : null,
      lastSpinTime: data['lastSpinTime'] != null
          ? (data['lastSpinTime'] as Timestamp).toDate()
          : null,
      lastDayReset: data['lastDayReset'] != null
          ? (data['lastDayReset'] as Timestamp).toDate()
          : null,
      spinsRemaining: data['spinsRemaining'] as int? ?? 3,
      adSpinsUsed: data['adSpinsUsed'] as int? ?? 0,
      loginStreak: data['loginStreak'] as int? ?? 0,
      highScore: data['highScore'] as int? ?? 0,
      totalEarned: data['totalEarned'] as int? ?? 0,
      totalSpent: data['totalSpent'] as int? ?? 0,
      achievements: Map<String, dynamic>.from(
          data['achievements'] as Map<dynamic, dynamic>? ?? {}),
      missions: Map<String, dynamic>.from(
          data['missions'] as Map<dynamic, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'createdAt': Timestamp.fromDate(createdAt),
      'referralCode': referralCode,
      'coins': coins,
      'gamesPlayed': gamesPlayed,
      'powerUps': powerUps,
      'lastLoginDate':
          lastLoginDate != null ? Timestamp.fromDate(lastLoginDate!) : null,
      'lastWatchTime':
          lastWatchTime != null ? Timestamp.fromDate(lastWatchTime!) : null,
      'lastSpinTime':
          lastSpinTime != null ? Timestamp.fromDate(lastSpinTime!) : null,
      'lastDayReset':
          lastDayReset != null ? Timestamp.fromDate(lastDayReset!) : null,
      'spinsRemaining': spinsRemaining,
      'adSpinsUsed': adSpinsUsed,
      'loginStreak': loginStreak,
      'highScore': highScore,
      'totalEarned': totalEarned,
      'totalSpent': totalSpent,
      'achievements': achievements,
      'missions': missions,
    };
  }

  Map<String, dynamic> toFirestore() {
    return toMap();
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    DateTime? createdAt,
    String? referralCode,
    int? coins,
    int? gamesPlayed,
    List<String>? powerUps,
    DateTime? lastLoginDate,
    DateTime? lastWatchTime,
    DateTime? lastSpinTime,
    DateTime? lastDayReset,
    int? spinsRemaining,
    int? adSpinsUsed,
    int? loginStreak,
    int? highScore,
    int? totalEarned,
    int? totalSpent,
    Map<String, dynamic>? achievements,
    Map<String, dynamic>? missions,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      createdAt: createdAt ?? this.createdAt,
      referralCode: referralCode ?? this.referralCode,
      coins: coins ?? this.coins,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      powerUps: powerUps ?? this.powerUps,
      lastLoginDate: lastLoginDate ?? this.lastLoginDate,
      lastWatchTime: lastWatchTime ?? this.lastWatchTime,
      lastSpinTime: lastSpinTime ?? this.lastSpinTime,
      lastDayReset: lastDayReset ?? this.lastDayReset,
      spinsRemaining: spinsRemaining ?? this.spinsRemaining,
      adSpinsUsed: adSpinsUsed ?? this.adSpinsUsed,
      loginStreak: loginStreak ?? this.loginStreak,
      highScore: highScore ?? this.highScore,
      totalEarned: totalEarned ?? this.totalEarned,
      totalSpent: totalSpent ?? this.totalSpent,
      achievements: achievements ?? this.achievements,
      missions: missions ?? this.missions,
    );
  }
}
