import 'dart:async';

import 'package:chat/model/Contact.dart';
import 'package:chat/model/Conversation.dart';
import 'package:chat/model/LoginHandler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
class ChatMessage{

  static const String TYPE_TEXT = 'TEXT';
  static const String TYPE_GIF = 'GIF';

  String id;
  String type;
  int timestamp;
  String message;
  String senderEmail;
  String conversationId;

  ChatMessage({this.id, this.type, this.message, this.senderEmail, this.conversationId, this.timestamp});

  ChatMessage.parse(DocumentSnapshot document)
  {
    id = document.documentID;
    type = document['type'];
    message = document['message'];
    timestamp = document['timestamp'];
    senderEmail = document['senderEmail'];
    conversationId = document['conversationId'];
  }

  bool get sending {
    return senderEmail == LoginHandler.currentUser.email;
  }

  String get creationDate{
    var formatter = new DateFormat.jm('en_US');
    return formatter.format(new DateTime.fromMillisecondsSinceEpoch(timestamp));
  }

  Widget get body
  {
    Widget messageBody = new Container();
    if(type == TYPE_GIF)
      messageBody = new Container(
        margin: new EdgeInsets.only(top: 10.0, bottom: 0.0, left: 15.0, right: 15.0),
        child:new ClipRRect(
          borderRadius: new BorderRadius.circular(10.0),
          child: new Container(
            width: 200.0,
            child: new Image.network('$message', fit: BoxFit.fitWidth),
        ),
        )
      );

    else
      messageBody =  new Container(
          margin: new EdgeInsets.only(top: 10.0, bottom: 10.0, left: 15.0, right: 15.0),
          child: new Text('$message', style: new TextStyle(fontSize: 15.0, color: Colors.white))
      );


    return messageBody;
  }

  Map<String, dynamic> toJson()
  {
    return {
      'id': id,
      'type' : type,
      'message': message,
      'senderEmail' : senderEmail,
      'conversationId' : conversationId,
      'timestamp' : timestamp,
    };
  }

  Widget buildListItem({String contactName, Conversation conversation})
  {
    return new Container(
      margin: new EdgeInsets.only(top: 15.0, left: 16.0, right: 16.0),
      child: new Row(
        mainAxisAlignment: sending ? MainAxisAlignment.end : MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[

          new Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              sending ? new Container() : new Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  new Container(
                    margin: new EdgeInsets.only(right: 10.0),
                    width: 40.0,
                    height: 40.0,
                    child: conversation.getAvatar(),
                  ),
                ]),
            ],
          ),

          new Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              new Container(
                margin: new EdgeInsets.only(left: sending ? 60.0 : 0.0, right: sending ? 0.0 : 60.0),
                child: new Material(
                    elevation: 0.0,
                    color: type == TYPE_GIF ? Colors.transparent : sending ? Colors.teal[500] : Colors.blue[700],
                    borderRadius: new BorderRadius.only(
                      topLeft: new Radius.circular(sending ? 15.0 : 0.0),
                      topRight: new Radius.circular(sending ? 0.0 : 15.0),
                      bottomLeft: new Radius.circular(15.0),
                      bottomRight: new Radius.circular(15.0),
                    ),
                    child: new Container(
                      child: new Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          new Flexible(child: new Column(
                              crossAxisAlignment: sending ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[

                                body,

                                new Container(
                                  margin: new EdgeInsets.symmetric(horizontal: 10.0),
                                  child: new Opacity(
                                    opacity: 0.5,
                                    child: new Divider(
                                      height: 0.5,
                                      color: sending ? Colors.grey[100] : Colors.grey[400],
                                    ),
                                  )
                                ),
                                new Container(
                                  margin: new EdgeInsets.only(top:2.0, bottom: 2.0, left: 20.0, right: 15.0),
                                  child: new Text(creationDate, style: new TextStyle(fontSize: 9.0, color: type == TYPE_GIF ? Colors.grey[700] : sending ? Colors.grey[100] : Colors.white))
                                ),
                              ])
                          )
                        ],
                      ),
                    )
                ),
              )
            ],
          ),],
      ),
    );
  }
}

class Messages{
  static Future<Conversation> sendMessage(String content, Conversation conversation, Contact contact, {isGif = false}) async {

    CurrentUser user = LoginHandler.currentUser;
    final Completer<Conversation> completer = new Completer();

    String messageType = isGif ? ChatMessage.TYPE_GIF: ChatMessage.TYPE_TEXT;

    if(conversation == null) {
      Conversations.addNewConversation(contact, content).then(

      (conv) {

        conversation = conv;
        ChatMessage message = new ChatMessage(
            type: messageType,
            message: content,
            senderEmail: user.email,
            conversationId: conversation.id,
            timestamp: new DateTime.now().millisecondsSinceEpoch
        );

        ChatMessage mirrorMessage = new ChatMessage(
            type: messageType,
            message: content,
            senderEmail: user.email,
            conversationId: conversation.mirrorId,
            timestamp: new DateTime.now().millisecondsSinceEpoch
        );

        int timestamp = new DateTime.now().millisecondsSinceEpoch;

        String messageId = Firestore.instance.collection('messages').document().documentID;
        message.id = messageId;
        Firestore.instance.collection('messages').document(message.id).setData(
            message.toJson());

        String mirrorId = Firestore.instance.collection('messages').document().documentID;
        mirrorMessage.id = mirrorId;
        Firestore.instance.collection('messages').document(mirrorMessage.id).setData(
            mirrorMessage.toJson());

        Firestore.instance.collection('conversations').document(conversation.id).updateData(
        {
          'lastMessage' : content,
          'timestamp' : timestamp,
        });

        Firestore.instance.collection('conversations').document(conversation.mirrorId).updateData(
        {
          'lastMessage' : content,
          'timestamp' : timestamp,
        });

        completer.complete(conversation);
      });
    }
    else
    {
      ChatMessage message = new ChatMessage(
          type: messageType,
          message: content,
          senderEmail: user.email,
          conversationId: conversation.id,
          timestamp: new DateTime.now().millisecondsSinceEpoch
      );

      ChatMessage mirrorMessage = new ChatMessage(
          type: messageType,
          message: content,
          senderEmail: user.email,
          conversationId: conversation.mirrorId,
          timestamp: new DateTime.now().millisecondsSinceEpoch
      );

      String messageId = Firestore.instance.collection('messages').document().documentID;
      message.id = messageId;

      Firestore.instance.collection('messages').document(message.id).setData(
          message.toJson());

      String mirrorId = Firestore.instance.collection('messages').document().documentID;
      mirrorMessage.id = mirrorId;

      Firestore.instance.collection('messages').document(mirrorMessage.id).setData(
          mirrorMessage.toJson());

      int timestamp = new DateTime.now().millisecondsSinceEpoch;

      Firestore.instance.collection('conversations').document(conversation.id).updateData(
      {
        'lastMessage' : isGif ? 'GIF' : content,
        'timestamp' : timestamp,
      });

      Firestore.instance.collection('conversations').document(conversation.mirrorId).updateData(
      {
        'lastMessage' : isGif ? 'GIF' : content,
        'timestamp' : timestamp,
      });

      conversation.timestamp = timestamp;
      conversation.lastMessage = isGif ? 'GIF' : content;
      completer.complete(conversation);
    }

    return completer.future;
  }
}