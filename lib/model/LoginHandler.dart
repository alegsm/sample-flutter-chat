import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
class LoginHandler{
  static CurrentUser currentUser = new CurrentUser();
  static final _googleSignIn = new GoogleSignIn();

  static Future<Null> login() async {
    GoogleSignInAccount user = _googleSignIn.currentUser;
    if (user == null)
      user = await _googleSignIn.signInSilently();
    if (user == null) {
      await _googleSignIn.signIn();
    }
    currentUser.avatarUrl = user.photoUrl;
    currentUser.name = user.displayName;
    currentUser.email = user.email;
    addNewUser(currentUser);
    final Completer<Null> completer = new Completer<Null>();
    completer.complete();
    return completer.future;
  }

  static addNewUser(CurrentUser current){
    Firestore.instance.collection('contacts').document(current.email.replaceAll('.', ',')).get().then(
      (DocumentSnapshot snapshot)
      {
        if(!snapshot.exists)
          Firestore.instance.collection('contacts').document(current.email.replaceAll('.', ','))
              .setData(current.toJson());
      }
    );
  }
}

class CurrentUser{
  String name;
  String email;
  String avatarUrl;
  CurrentUser({this.name, this.avatarUrl});

  Map<String, dynamic> toJson()
  {
    return {
      'name' : name,
      'email' : email,
      'avatarUrl' : avatarUrl
    };
  }
}
