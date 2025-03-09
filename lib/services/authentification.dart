import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class Authentication {
  static final GoogleSignIn googleSignIn = GoogleSignIn();


  static Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }


  static Future<String> signInWithGoogle() async {
    print("start signing with Google");
    final GoogleSignInAccount googleSignInAccount = (await googleSignIn.signIn())!;
    final GoogleSignInAuthentication googleSignInAuthentication = await googleSignInAccount.authentication;

    final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleSignInAuthentication.idToken,
        accessToken: googleSignInAuthentication.accessToken
    );

    final UserCredential user = await FirebaseAuth.instance.signInWithCredential(credential);

    assert(!user.user!.isAnonymous);
    assert(await user.user!.getIdToken() != null);

    final currentUser = FirebaseAuth.instance.currentUser;
    assert(user.user!.uid == currentUser!.uid);

    return 'signInWithGoogle succeeded: ${user.user}';
  }

  void signOutGoogle() async {
    await googleSignIn.signOut();
    print("User Sign Out");
  }

  static Future<void> signInWithApple() async {
    final appleIdCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ]);
    print(appleIdCredential.state);
    switch (appleIdCredential.state) {
      case null:
        print("successfull sign in");
        OAuthProvider oAuthProvider = new OAuthProvider('apple.com');

        final AuthCredential credential = oAuthProvider.credential(
          idToken: appleIdCredential.identityToken,
          accessToken: appleIdCredential.authorizationCode,
        );

        final UserCredential user = await FirebaseAuth.instance.signInWithCredential(credential);

        assert (!user.user!.isAnonymous);
        assert(await user.user!.getIdToken() != null);

        final currentUser = FirebaseAuth.instance.currentUser;
        assert(user.user!.uid == currentUser!.uid);

        break;
      default:
        break;
    }

  }
}


