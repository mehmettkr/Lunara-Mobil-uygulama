  import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_service.dart';
import '../models/user_model.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirestoreService();

  User? get currentUser => _auth.currentUser;

  Future<void> register({
    required String email,
    required String username,
    required String password,
  }) async {
    // 1. Check if username exists
    if (await _firestore.isUsernameTaken(username.trim().toLowerCase())) {
      throw Exception('Bu kullanıcı adı zaten alınmış.');
    }

    // 2. Create Auth user
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    
    // 3. Create Firestore user document
    if (cred.user != null) {
      await _firestore.createUser(UserModel(
        id: cred.user!.uid,
        email: email.trim(),
        username: username.trim().toLowerCase(),
      ));
    }
  }

  Future<void> loginWithUsername({
    required String username,
    required String password,
  }) async {
    // 1. Find email by username
    final userModel = await _firestore.getUserByUsername(username.trim().toLowerCase());
    if (userModel == null) {
      throw Exception('Kullanıcı bulunamadı.');
    }

    // 2. Login with email
    await _auth.signInWithEmailAndPassword(
      email: userModel.email,
      password: password,
    );
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
