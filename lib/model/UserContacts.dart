import 'dart:async';

import 'package:chat/model/Contact.dart';
import 'package:chat/model/LoginHandler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

class UserContacts
{
  String userEmail;
  List<Contact> contacts;

  UserContacts({this.userEmail, this.contacts});
  UserContacts.parse(DocumentSnapshot doc)
  {
    List<Contact> list = [];
    userEmail = doc.data['userEmail'];
    if(doc.data != null && doc.data['contacts'] is List) {
      var raw = doc.data['contacts'] as List;
      raw.forEach(
        (c)
        {
          list.add(new Contact.parseJson(c));
        }
      );
      contacts = list;
    }
  }

  Map<String, dynamic> toJson()
  {
    List<Map<String,dynamic>> jsonList = [];
    contacts.forEach(
      (Contact c)
      {
        jsonList.add(c.toJson());
      }
    );
    return {
      'userEmail' : userEmail,
      'contacts' : jsonList,
    };
  }
}

class UserContactsHandler
{
  static UserContacts users;

  static Future<UserContacts> getContacts()
  {
    final Completer<UserContacts> completer = new Completer<UserContacts>();
    Firestore.instance.collection('usercontacts').
      document(LoginHandler.currentUser.name.replaceAll('.', ','))
      .get().then(
      (snap)
      {
        if(snap.exists && snap.data != null)
          users = new UserContacts.parse(snap);
        completer.complete(users);
      });

    return completer.future;
  }

  static addNewContact(Contact c)
  {
    getContacts().then((uc){

      UserContacts contacts;
      if(uc != null) {
        uc.contacts.add(c);
        contacts = uc;
      }
      else
      {
        contacts = new UserContacts(userEmail: LoginHandler.currentUser.email, contacts: [c]);
      }

      Firestore.instance.collection('usercontacts').
        document(LoginHandler.currentUser.email.replaceAll('.', ',')).setData(contacts.toJson());
    });
  }
}