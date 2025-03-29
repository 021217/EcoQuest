import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ecoquest/model/user.dart';
import 'package:ecoquest/services/sharedpreferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ✅ Convert Firebase User + Firestore Data into Custom MyUser Model
  MyUser? _userFromFirebaseUser(User? user, Map<String, dynamic>? userData) {
    if (user == null || userData == null) return null;

    return MyUser(
      uid: user.uid,
      name: userData['name'] ?? '',
      email: userData['email'] ?? '',
      password: null, // Don't store password
      googleLogin: userData['googleLogin'] ?? false,
      profilePic: userData['profilePic'] ?? '',
      qrCode: userData['qrCode'] ?? '',
      referralCode: userData['referralCode'] ?? '',
      status: (userData['status'] as num?)?.toInt() ?? 0,
      createdDate:
          (userData['createdDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastUpdateDate:
          (userData['lastUpdateDate'] as Timestamp?)?.toDate() ??
          DateTime.now(),
    );
  }

  /// ✅ Get User Stream (Real-time Auth Changes)
  Stream<MyUser?> get user {
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;

      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(firebaseUser.uid).get();

      return _userFromFirebaseUser(
        firebaseUser,
        userDoc.data() as Map<String, dynamic>?,
      );
    });
  }

  /// ✅ Register a New User
  Future<MyUser?> registerWithEmailAndPassword(
    String email,
    String password,
    String name,
  ) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? firebaseUser = result.user;
      if (firebaseUser != null) {
        MyUser newUser = MyUser(
          uid: firebaseUser.uid,
          name: name,
          email: email,
          password: null, // Never store password
          googleLogin: false,
          profilePic: '',
          qrCode: '',
          referralCode: '',
          status: 1, // 1 = Active
          createdDate: DateTime.now(),
          lastUpdateDate: DateTime.now(),
        );

        await _firestore.collection('users').doc(firebaseUser.uid).set({
          ...newUser.toMap(),
          'createdDate': Timestamp.fromDate(newUser.createdDate),
          'lastUpdateDate': Timestamp.fromDate(newUser.lastUpdateDate),
        });

        await PreferencesHelper.setUserSignedIn(true); // ✅ Save login state

        return newUser;
      }
      return null;
    } catch (e) {
      print("Register Error: ${e.toString()}");
      return null;
    }
  }

  /// ✅ Sign In User
  Future<MyUser?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? firebaseUser = result.user;
      if (firebaseUser != null) {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(firebaseUser.uid).get();

        MyUser? user = _userFromFirebaseUser(
          firebaseUser,
          userDoc.data() as Map<String, dynamic>?,
        );

        await PreferencesHelper.setUserSignedIn(true); // ✅ Save login state

        return user;
      }
      return null;
    } catch (e) {
      print("Sign In Error: ${e.toString()}");
      return null;
    }
  }

  /// ✅ Fetch User Data (Manually Retrieve User Info)
  Future<MyUser?> getUserData() async {
    try {
      User? firebaseUser = _auth.currentUser;
      if (firebaseUser != null) {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(firebaseUser.uid).get();

        if (userDoc.exists) {
          return _userFromFirebaseUser(
            firebaseUser,
            userDoc.data() as Map<String, dynamic>?,
          );
        }
      }
      return null;
    } catch (e) {
      print("Fetch User Data Error: ${e.toString()}");
      return null;
    }
  }

  /// ✅ Sign Out User
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await PreferencesHelper.setUserSignedIn(false); // ✅ Clear login state
    } catch (e) {
      print("Sign Out Error: ${e.toString()}");
    }
  }

  /// ✅ Check if User is Signed In
  Future<bool> isUserSignedIn() async {
    return await PreferencesHelper.getUserSignedIn();
  }
}
