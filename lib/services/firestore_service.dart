  import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/dream.dart';
import '../models/user_model.dart';

import 'package:firebase_auth/firebase_auth.dart'; // import

class FirestoreService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance; // _auth tanımlandı

  CollectionReference<Map<String, dynamic>> get _dreams =>
      _db.collection('dreams');

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  // --- User Methods ---

  Future<void> createUser(UserModel user) async {
    await _users.doc(user.id).set(user.toMap());
  }

  Future<UserModel?> getUserByUsername(String username) async {
    final snap = await _users
        .where('username', isEqualTo: username)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return UserModel.fromMap(snap.docs.first.id, snap.docs.first.data());
  }

  Future<bool> isUsernameTaken(String username) async {
    final user = await getUserByUsername(username);
    return user != null;
  }

  // --- Friend Methods ---

  Future<void> addFriend(String currentUserId, String friendUsername) async {
    // 1. Arkadaşı bul
    final friend = await getUserByUsername(friendUsername);
    if (friend == null) throw Exception('Kullanıcı bulunamadı.');
    if (friend.id == currentUserId) throw Exception('Kendini ekleyemezsin.');

    // 2. Kendini bul (Karşı tarafın listesine eklemek için)
    final currentUserDoc = await _users.doc(currentUserId).get();
    if (!currentUserDoc.exists) throw Exception('Kullanıcı oturumu hatası.');
    final currentUser =
        UserModel.fromMap(currentUserDoc.id, currentUserDoc.data()!);

    // 3. Current User -> Friend (Kendi listene ekle)
    await _users.doc(currentUserId).collection('friends').doc(friend.id).set({
      'username': friend.username,
      'email': friend.email,
      'addedAt': DateTime.now().toUtc().millisecondsSinceEpoch,
    });

    // 4. Friend -> Current User (Arkadaşının listesine seni ekle - Karşılıklı)
    await _users.doc(friend.id).collection('friends').doc(currentUserId).set({
      'username': currentUser.username,
      'email': currentUser.email,
      'addedAt': DateTime.now().toUtc().millisecondsSinceEpoch,
    });
  }

  Future<void> removeFriend(String currentUserId, String friendId) async {
    await _users.doc(currentUserId).collection('friends').doc(friendId).delete();
  }

  Stream<List<Map<String, dynamic>>> streamFriends(String userId) {
    return _users
        .doc(userId)
        .collection('friends')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => {'id': d.id, ...d.data()})
            .toList());
  }

  // --- Dream Methods ---

  Stream<List<Dream>> streamDreamsForUser(String userId) {
    return _dreams
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Dream.fromMap(d.id, d.data()))
            .toList());
  }

  Future<String> addDream({
    required String userId,
    required String title,
    required String text,
    bool isShared = false,
    String? mood,
  }) async {
    final doc = await _dreams.add(Dream(
      id: '',
      userId: userId,
      title: title,
      text: text,
      isShared: isShared,
      createdAt: DateTime.now(),
      mood: mood,
    ).toMap());
    return doc.id;
  }

  Future<void> updateInterpretation({
    required String dreamId,
    required String interpretation,
  }) async {
    await _dreams.doc(dreamId).update({'aiInterpretation': interpretation});
  }

  // Rüya Silme
  Future<void> deleteDream(String dreamId) async {
    await _dreams.doc(dreamId).delete();
  }

  Future<void> updateImage({
    required String dreamId,
    required String imageUrl,
  }) async {
    await _dreams.doc(dreamId).update({'imageUrl': imageUrl});
  }

  Future<void> updateShareStatus({
    required String dreamId,
    required bool isShared,
  }) async {
    await _dreams.doc(dreamId).update({'isShared': isShared});
  }

  Stream<List<Dream>> streamSharedDreamsOfFriend(String friendId) {
    return _dreams
        .where('userId', isEqualTo: friendId)
        .where('isShared', isEqualTo: true)
        // .orderBy('createdAt', descending: true) 
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Dream.fromMap(d.id, d.data()))
            .toList());
  }

  Future<Dream> getDream(String id) async {
    final doc = await _dreams.doc(id).get();
    return Dream.fromMap(doc.id, doc.data()!);
  }

 
  Stream<List<Dream>> streamAllSharedDreams() {
    return _dreams
        .where('isShared', isEqualTo: true)
        // .orderBy('createdAt', descending: true) 
        .limit(10) // Performans için limit
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Dream.fromMap(d.id, d.data()))
            .toList());
  }

  //  Yorum Sistemi 

  Future<void> addComment(String dreamId, String text) async {
    final user = _auth.currentUser;
    if (user == null) return;

    String username = 'Anonim';
    final userDoc = await _users.doc(user.uid).get();
    if (userDoc.exists) {
      username = userDoc['username'] ?? username;
    }

    await _dreams.doc(dreamId).collection('comments').add({
      'userId': user.uid,
      'username': username,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

 
  Stream<List<Map<String, dynamic>>> streamComments(String dreamId) {
    return _dreams
        .doc(dreamId)
        .collection('comments')
        .orderBy('createdAt', descending: false) // Eskiden yeniye
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }
}

