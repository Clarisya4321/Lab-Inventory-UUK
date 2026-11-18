import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Mengurus Firebase Authentication dan profil pengguna.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  /// Register: semua akun baru otomatis menjadi User.
  Future<void> register({
    required String name,
    required String kelas,
    required String email,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final uid = cred.user!.uid;

    await _db.collection('users').doc(uid).set({
      'user_id': uid,
      'name': name.trim(),
      'email': email.trim(),
      'kelas': kelas.trim(),
      'role': 'user',
      'created_at': FieldValue.serverTimestamp(),
      'foto':
          'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name.trim())}&background=3157D5&color=fff&size=256',
    });
  }

  /// Login menggunakan Firebase Authentication.
  Future<void> login(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Mengambil role pengguna dari Firestore.
  Future<String> getUserRole(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();

    if (!doc.exists) {
      throw Exception('Profil pengguna tidak ditemukan.');
    }

    final data = doc.data();

    // Akun lama yang belum memiliki role dianggap sebagai User.
    final role = data?['role'] ?? 'user';

    if (role != 'user' && role != 'owner') {
      throw Exception('Role akun tidak valid.');
    }

    return role.toString();
  }

  /// Logout.
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// Data profil pengguna secara real-time.
  Stream<DocumentSnapshot<Map<String, dynamic>>> userStream(String uid) {
    return _db.collection('users').doc(uid).snapshots();
  }

  /// Mengambil data profil pengguna.
  Future<Map<String, dynamic>?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data();
  }

  /// Mengubah kode error Firebase menjadi pesan bahasa Indonesia.
  static String pesanError(String code) {
    switch (code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Email atau password salah.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'email-already-in-use':
        return 'Email sudah terdaftar. Silakan login.';
      case 'weak-password':
        return 'Password terlalu lemah (minimal 6 karakter).';
      case 'network-request-failed':
        return 'Tidak ada koneksi internet.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba lagi nanti.';
      default:
        return 'Terjadi kesalahan ($code).';
    }
  }
}
