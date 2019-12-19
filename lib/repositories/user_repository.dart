import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mamma/model/user.dart';

class UserRepository {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final userCollection = Firestore.instance.collection('user');
  FirebaseUser _firebaseUser;

  UserRepository({FirebaseAuth firebaseAuth, GoogleSignIn googleSignin})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignin ?? GoogleSignIn();

  Future<User> signInWithGoogle() async {
    // NOTE: SHA1 fingerprint registration required in firebase.
    final GoogleSignInAccount googleUser = await _googleSignIn.signIn();
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.getCredential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    await _firebaseAuth.signInWithCredential(credential);
    return getUser();
  }

  Future<void> signInWithCredentials(String email, String password) {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signUp({String email, String password}) async {
    return await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    return Future.wait([
      _firebaseAuth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  Future<bool> isSignedIn() async {
    final currentUser = await _firebaseAuth.currentUser();
    return currentUser != null;
  }

  Future<FirebaseUser> getFirebaseUser() async {
    if (_firebaseUser == null) {
      _firebaseUser = await _firebaseAuth.currentUser();
    }
    return _firebaseUser;
  }

  Future<User> getUser() async {
    final firebaseUser = await getFirebaseUser();
    assert(firebaseUser != null);
    final userSnapshot = await userCollection.document(firebaseUser.uid).get();
    if (userSnapshot != null && userSnapshot.data != null) {
      return User.fromSnapshot(userSnapshot);
    }

    return null;
  }

  Future<void> createUser(User user) {
    return userCollection.document(user.id).setData(user.toDocument());
  }

  Future<void> deleteUser(User user) {
    return userCollection.document(user.id).delete();
  }

  Future<void> updateUser(User update) {
    return userCollection
        .document(update.id)
        .updateData(update.toDocument());
  }
}
