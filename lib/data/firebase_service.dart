import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:btl_nhom_15/model/lunar_event.dart';

class FirebaseService {
  static final FirebaseService instance = FirebaseService._init();
  FirebaseService._init();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // ── Auth ──────────────────────────────────────────────────────────────────

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // người dùng hủy

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential result =
          await _auth.signInWithCredential(credential);
      return result.user;
    } catch (e) {
      print('Google Sign-In error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // ── Firestore path ────────────────────────────────────────────────────────
  // Mỗi user có collection riêng: users/{uid}/events/{eventId}
  CollectionReference<Map<String, dynamic>> get _eventsCollection {
    final uid = _auth.currentUser!.uid;
    return _db.collection('users').doc(uid).collection('events');
  }

  // ── CRUD Firestore ────────────────────────────────────────────────────────

  // Đẩy 1 sự kiện lên cloud (dùng id SQLite làm document id để đồng bộ dễ)
  Future<void> uploadEvent(LunarEvent event) async {
    if (!isLoggedIn || event.id == null) return;
    try {
      await _eventsCollection.doc(event.id.toString()).set({
        ...event.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Upload event error: $e');
    }
  }

  // Xóa sự kiện trên cloud
  Future<void> deleteEvent(int id) async {
    if (!isLoggedIn) return;
    try {
      await _eventsCollection.doc(id.toString()).delete();
    } catch (e) {
      print('Delete event error: $e');
    }
  }

  // Lấy toàn bộ sự kiện từ cloud về
  Future<List<LunarEvent>> fetchAllEvents() async {
    if (!isLoggedIn) return [];
    try {
      final snapshot = await _eventsCollection
          .orderBy('date', descending: false)
          .get();
      return snapshot.docs
          .map((doc) => LunarEvent.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Fetch events error: $e');
      return [];
    }
  }

  // Đẩy toàn bộ sự kiện local lên cloud (dùng khi login lần đầu)
  Future<void> uploadAllEvents(List<LunarEvent> events) async {
    if (!isLoggedIn) return;
    final batch = _db.batch();
    for (final event in events) {
      if (event.id == null) continue;
      final docRef = _eventsCollection.doc(event.id.toString());
      batch.set(docRef, {
        ...event.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  // Lắng nghe thay đổi realtime từ Firestore
  Stream<List<LunarEvent>> streamEvents() {
    if (!isLoggedIn) return const Stream.empty();
    return _eventsCollection
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LunarEvent.fromMap(doc.data()))
            .toList());
  }
}