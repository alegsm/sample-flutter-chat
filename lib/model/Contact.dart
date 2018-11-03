import 'package:chat/model/UserContacts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Contact {
  String id;
  String email;
  String name;
  String avatarUrl;

  Contact({this.id, this.name, this.avatarUrl});

  Contact.parse(DocumentSnapshot document)
  {
    id = document.documentID;
    name = document.data['name'];
    email = document.data['email'];
    avatarUrl = document.data['avatarUrl'];
  }

  Contact.parseJson(Map<dynamic, dynamic> document)
  {
    id = document['id'];
    name = document['name'];
    email = document['email'];
    avatarUrl = document['avatarUrl'];
  }

  Map<String, dynamic> toJson()
  {
    return{
      'id': id,
      'email' : email,
      'name' : name,
      'avatarUrl' : avatarUrl,
    };
  }
  Widget getAvatar({fontSize = 20.0, color : Colors.blue})
  {
    String imgUrl = avatarUrl ?? '';

    Widget avatar = new Container();

    if(imgUrl.isEmpty)
      avatar = new CircleAvatar(
          radius: 100.0,
          minRadius: 100.0,
          maxRadius: 100.0,
          backgroundColor: color,
          child: new Align(
            alignment: Alignment.center,
            child: new Text(name.substring(0, 1),
                textAlign: TextAlign.center,
                // ignore: conflicting_dart_import
                style: new TextStyle(color: Colors.white, fontSize: fontSize)
            )
          )
      );
    else
      avatar = new CircleAvatar(
        backgroundColor: Colors.transparent,
        backgroundImage: new NetworkImage(imgUrl),
      );

    return avatar;
  }

  Widget createListItem(VoidCallback onTap)
  {
    return new ListTile(
      onTap: onTap,
      title: new Text(name),
      subtitle: new Text(email),
      leading: getAvatar(),
    );
  }
}

class Contacts{

  static addNewContact(String email)
  {
    Firestore.instance.collection('contacts').document(email.replaceAll('.', ',')).get().then(
      (snap)
      {
        if(snap.exists)
          {
            Contact c = new Contact.parse(snap);
            UserContactsHandler.addNewContact(c);
          }
      }
    );
  }

}