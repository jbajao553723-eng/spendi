import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.createdAt,
  });

  final String uid;
  final String email;
  final DateTime createdAt;

  factory AppUser.fromFirebaseUser(firebase_auth.User user) {
    return AppUser(
      uid: user.uid,
      email: user.email ?? '',
      createdAt: user.metadata.creationTime ?? DateTime.now(),
    );
  }

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    final createdAt = map['createdAt'];
    return AppUser(
      uid: uid,
      email: map['email'] as String? ?? '',
      createdAt: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
