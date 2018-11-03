import 'package:firebase_messaging/firebase_messaging.dart';

class FirebaseHandler
{
  static final FirebaseMessaging _firebaseMessaging = new FirebaseMessaging();

  static init()
  {
    _firebaseMessaging.requestNotificationPermissions();

    _firebaseMessaging.getToken().then(
       (token)
      {
        print('T O K E N: $token');
      }
    );
    _firebaseMessaging.configure(
      onMessage:
        (Map<String, dynamic> message)
        {
          print(message.toString());
        }
    );
  }

}
