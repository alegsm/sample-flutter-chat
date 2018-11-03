import 'dart:async';

import 'package:chat/chat/ChatScreen.dart';
import 'package:chat/model/Contact.dart';
import 'package:chat/model/LoginHandler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UserConversations
{
  List<Conversation> conversations;

  UserConversations(this.conversations);

  UserConversations.parse(DocumentSnapshot document)
  {
    conversations = [];
    if(document.data['conversations'] is List)
    {
      var raw = document.data['conversations'] as List;
      raw.forEach((obj)
      {
        conversations.add(new Conversation.parse(obj));
      });
    }
  }

  Map<String, dynamic> toJson(){

    List<Map<String, dynamic>> jsonList = [];

    conversations.forEach(
      (conversation)
      {
        jsonList.add(conversation.toJson());
      }
    );
    return{
      'conversations': jsonList,
    };
  }

}

class Member
{
  String name;
  String email;
  String avatar;

  Member({this.name, this.email, this.avatar});

  Member.parse(Map<dynamic, dynamic> document)
  {
    name = document['name'];
    email = document['email'];
    avatar = document['avatar'];
  }

  Map<String, dynamic> toJson()
  {
    return {
      'name' : name,
      'email' : email,
      'avatar' : avatar,
    };
  }

}

class Conversation{

  String id;
  String mirrorId;
  String ownerEmail;
  List<Member> members;
  String lastMessage;
  int timestamp;

  Conversation({this.id, this.members, this.lastMessage, this.timestamp, this.ownerEmail, this.mirrorId});

  Conversation.parse(DocumentSnapshot document)
  {
    id = document.documentID;
    ownerEmail = document.data['ownerEmail'];
    lastMessage = document.data['lastMessage'];
    timestamp = document.data['timestamp'];
    mirrorId = document.data['mirrorId'];
    members = [];
    if(document['members'] is List)
    {
      var list = document['members'] as List;
      list.forEach((raw){
        members.add(new Member.parse(raw));
      });
    }
  }

  String get name{
    return members.length == 1 ? members[0].name : 'Grupo';
  }

  String get imgUrl{
    return members.length == 1 ? members[0].avatar : '';
  }

  String get lastMessageDate
  {
    return new DateTime.fromMillisecondsSinceEpoch(timestamp).toIso8601String();
  }

  Widget getAvatar({fontSize = 20.0, color : Colors.blue})
  {
    Widget avatar = new Container();

    if(imgUrl != null && imgUrl.isEmpty)
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

  Widget createListItem(context)
  {
    return new InkWell(
      onTap: (){
        Navigator.of(context).push(new MaterialPageRoute(builder: (context) => new ChatScreen(conversation: this)));
      },
      child: new Container(
        padding: new EdgeInsets.symmetric(vertical: 10.0, horizontal: 5.0),
        child: new Row(
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            new Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                new Container(
                  width: 50.0,
                  height: 50.0,
                  margin: new EdgeInsets.symmetric(horizontal: 15.0, vertical: 5.0),
                  child:  getAvatar(),
                ),
              ],
            ),
            new Expanded(child: new Container(
              margin: new EdgeInsets.only(right: 10.0),
              padding: new EdgeInsets.fromLTRB(15.0, 5.0, 2.0, 10.0),
              decoration: new BoxDecoration(
                color: Colors.white,
                border: new Border.all(color: Colors.grey[300]),
                borderRadius: new BorderRadius.circular(10.0)
              ),
              child: new Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                new Text(name, style: new TextStyle(fontSize: 18.0, color: Colors.teal)),
                lastMessage == 'GIF' ? new Container(
                  margin: new EdgeInsets.symmetric(vertical:5.0),
                  height: 30.0,
                  decoration: new BoxDecoration(color: Colors.grey, borderRadius: new BorderRadius.circular(5.0)),
                  child: new Icon(Icons.gif, color: Colors.white, size: 30.0))
                  : new Text(lastMessage, maxLines: 1, style: new TextStyle(fontSize: 18.0, color: Colors.grey[800])),
                new Text(date, style: new TextStyle(color: Colors.grey[800], fontSize: 10.0)),
              ],
            ),),)
          ],
        ),
      ));
  }

  Map<String,dynamic> toJson()
  {
    List jsonList = [];
    members.forEach((member){
      jsonList.add(member.toJson());
    });
    return {
      'id' : id,
      'mirrorId' : mirrorId,
      'members' : jsonList,
      'ownerEmail' : ownerEmail,
      'timestamp' : timestamp,
      'lastMessage' : lastMessage,
    };
  }

  String get date{
    var formatter = new DateFormat.jm('en_US');
    return formatter.format(new DateTime.fromMillisecondsSinceEpoch(timestamp));
  }

}

class Conversations
{
  static Future<Conversation> addNewConversation(Contact contact, String message){
    CurrentUser user = LoginHandler.currentUser;
    int timestamp = new DateTime.now().millisecondsSinceEpoch;

    Conversation mine = new Conversation(
      ownerEmail: user.email,
      members: [new Member(name: contact.name, email: contact.email, avatar: contact.avatarUrl)],
      timestamp: timestamp,
      lastMessage: message,
    );

    Conversation mirror = new Conversation(
      ownerEmail: contact.email,
      members: [new Member(name: user.name, email: user.email, avatar: user.avatarUrl)],
      timestamp: timestamp,
      lastMessage: message,
    );

    String id = Firestore.instance.collection('conversations').document().documentID;
    mine.id = id;
    mirror.mirrorId = id;
    Firestore.instance.collection('conversations').document(mine.id).setData(mine.toJson());

    String mirrorId = Firestore.instance.collection('conversations').document().documentID;
    mirror.id = mirrorId;
    mine.mirrorId = mirrorId;

    Firestore.instance.collection('conversations').document(mirror.id).setData(mirror.toJson());

    //Overriding
    Firestore.instance.collection('conversations').document(mine.id).setData(mine.toJson());

    final Completer<Conversation> completer = new Completer<Conversation>();
    completer.complete(mine);
    return completer.future;
  }

  static Future<List<Conversation>> getConversations() async{
    List<Conversation> conversations = [];
    QuerySnapshot query = await Firestore.instance.collection('conversations').where('ownerEmail', isEqualTo: LoginHandler.currentUser.email).getDocuments();

    query.documents.forEach((c){
      conversations.add(new Conversation.parse(c));
    });

    final Completer<List<Conversation>> completer = new Completer<List<Conversation>>();
    completer.complete(conversations);
    return completer.future;
  }
}