import 'dart:async';

import 'package:chat/components/ExpandableBottomAppBar.dart';
import 'package:chat/model/ChatMessage.dart';
import 'package:chat/model/Contact.dart';
import 'package:chat/model/Conversation.dart';
import 'package:chat/model/UserContacts.dart';
import 'package:chat/model/giphy/Giphy.dart';
import 'package:chat/model/giphy/GiphyResponse.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class ChatScreen extends StatefulWidget {
  final Conversation conversation;
  final Contact contact;

  ChatScreen({Key key, this.conversation, this.contact}) : super(key: key);

  @override
  _ChatScreenState createState() => new _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin{
  static const String GIPHY_API_KEY = 'LYh9PihneHBpFPg4ZhRZssrUb2xkSit5';
  bool reloading = false;
  bool loadingNext = false;
  double _appBarElevation = 0.0;
  FocusNode searchFocus = new FocusNode();
  TextEditingController composerController = new TextEditingController();
  List<ChatMessage> messages = [];
  bool isTyping = false;

  int lastLoadedMessage = 1;
  PersistentBottomSheetController bottomSheetController;
  GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  GlobalKey<ExpandableBottomAppBarState> _appBarKey = new GlobalKey<ExpandableBottomAppBarState>();
  bool showingBottomSheet = false;
  Animation<double> doubleAnimation;
  AnimationController controller;
  Animation curve;
  String composerKey = 'composer';
  List<GiphyImage> gifs = [];
  bool showingGifs = false;
  Giphy giphy = Giphy.instance();
  Conversation conversation;
  Contact contact;
  bool showAddContactButton = false;

  String get otherName
  {
    if(contact != null)
    {
      return contact.name;
    }
    else
    {
      if(conversation != null && conversation.members?.length == 1)
      {
        return conversation.members[0].name;
      }
      else if(conversation.members.length > 1)
      {
        return 'Grupo';
      }
      else
      {
        return '';
      }
    }
  }

  bool _handleScrollNotification(ScrollNotification notification) {

    final double elevation = notification.metrics.extentAfter <= 0.0 ? 0.0 : 1.0;
    if (elevation != _appBarElevation) {
      setState(() {
        _appBarElevation = elevation;
      });
    }

    if(notification is UserScrollNotification) {
      UserScrollNotification user = notification;

      if (notification.metrics.pixels >= notification.metrics.maxScrollExtent &&
          user.direction == ScrollDirection.reverse) {

      }
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    giphy.init(GIPHY_API_KEY);
    controller = new AnimationController(
        duration: new Duration(milliseconds: 300), vsync: this);
    controller.addListener((){setState(() {});});
    final Tween doubleTween = new Tween<double>(begin: 1.0, end: 0.0);
    curve = new CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn);
    doubleAnimation = doubleTween.animate(curve);
    conversation = widget.conversation;
    contact = widget.contact;

    if(contact != null && conversation == null)
    {
      Conversations.getConversations().then(
        (conversationList)
        {
          conversationList.forEach(
              (conversationItem)
              {
                conversationItem.members.forEach(
                    (member)
                    {
                      if(member.email == contact.email)
                      {
                       setState(() {
                         conversation = conversationItem;
                       });
                      }
                    }
                );
              }
          );
        }
      );
    }

    composerController.addListener((){
      if(showingGifs && composerController.text.length > 2) {
        giphy.search(composerController.text, offset: 0, limit: 15).then(
            (list)
            {
              if(list != null)
                setState(() {
                  gifs = list;
                });
            });
      }
      else if(composerController.text.length == 0){
        giphy.getTrending(offset: 0, limit: 15).then((list)
        {
          if(list != null && list.isNotEmpty)
            setState(() {
              gifs = list;
            });
          else if(mounted)
            gifs = list;
        });
      }
    });

    giphy.getTrending(offset: 0, limit: 15).then((list)
    {
      if(list != null && list.isNotEmpty)
        setState(() {
          gifs = list;
        });

      else if(mounted)
        gifs = list;
    });

    searchFocus.addListener(()
    {
      if(searchFocus.hasFocus && !isTyping){
        setState((){
          isTyping = true;
        });
      }
      else if(!searchFocus.hasFocus && isTyping)
      {
        setState((){
          isTyping = false;
        });
      }
    });

    isContact().then(
      (isContact)
        {
          if(isContact != null){
            if(!isContact)
            {
              setState(() {
                showAddContactButton = true;
              });
            }
          }
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    return buildBody();
  }

  Widget buildBody()
  {
    return new Scaffold(
      body: new Stack(
        alignment: Alignment.bottomCenter,
        children: <Widget>[
          new Scaffold(
            resizeToAvoidBottomPadding: false,
            key: _scaffoldKey,
            appBar: new AppBar(
              backgroundColor: Colors.white,
              elevation: 0.0,
              iconTheme: new IconThemeData(color: Colors.pink),
              title: new Text(otherName, style: new TextStyle(color: Colors.pink)),
            ),
            body: new NotificationListener<ScrollNotification>(
              onNotification: _handleScrollNotification,
              child: Stack(
                alignment: Alignment.topCenter,
                children: <Widget>[
                  buildChat(),
                  showAddContactButton ? createAddContactButton() : new Container()
                ],
              )
            ),
          ),
          createBottomAppBar(),
        ],
      ),
    );
  }

  Widget buildChat()
  {
    if(conversation != null)
      return new StreamBuilder<QuerySnapshot>(
        stream: Firestore.instance.collection('messages').where('conversationId', isEqualTo: conversation.id).orderBy('timestamp', descending: true).snapshots,
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) return new Text('Loading...');
          return new ListView(
            padding: new EdgeInsets.only(bottom: 150.0),
            reverse: true,
            children: snapshot.data.documents.map((DocumentSnapshot document) {
              ChatMessage m = new ChatMessage.parse(document);
              return m.buildListItem(contactName: otherName, conversation: conversation);
            }).toList(),
          );
        },
      );
      else
        return new Container();
  }

  Widget buildComposer()
  {
    return new Material(
        elevation: 2.0,
        color: Colors.white,
        borderRadius: new BorderRadius.only(
            topLeft: new Radius.circular(showingGifs ? 0.0 : 10.0),
            topRight: new Radius.circular(showingGifs ? 0.0 : 10.0)
        ),
        child: new Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            new Container(
              child: new Container(
                padding: new EdgeInsets.only(
                    left: 0.0,
                    right: 5.0,
                    bottom: showingGifs ? 0.0 : 25.0,
                    top: showingGifs ? 0.0 : 10.0
                ),
                child: new Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    new Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[

                        new Flexible(
                          child:
                          new AnimatedContainer(
                              duration: new Duration(milliseconds: 300),
                              margin:new EdgeInsets.only(left: 30.0),
                              child: new TextField(
                                  keyboardType: TextInputType.text,
                                  maxLines: showingGifs ? 1 : null,
                                  focusNode: searchFocus,
                                  controller: composerController,
                                  style: new TextStyle(fontSize: 14.0, color: Colors.black),
                                  decoration: new InputDecoration(hintText: showingGifs ? 'Search Gliphy' : 'Type a message', border: InputBorder.none))),
                        ),

                        new Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            new Container(
                                margin: new EdgeInsets.only(left: 10.0, right: 10.0),
                                child: new IconButton(icon: showingGifs ? new Icon(Icons.close, color: Colors.cyan) : new Icon(Icons.send, color: Colors.cyan), onPressed: (){
                                  FocusScope.of(context).requestFocus(new FocusNode());
                                  if(!showingGifs) {
                                    sendMessage(composerController.value.text);
                                  }
                                  else
                                  {
                                    composerController.value = new TextEditingValue(text: '');
                                    setState((){
                                      showingGifs = false;
                                      _appBarKey.currentState.setExpanded(showingGifs);
                                    });
                                  }
                                })),
                          ],
                        ),
                      ],
                    ),
                    new Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        new InkWell(
                            onTap: (){
                              setState((){
                                showingGifs = true;
                                _appBarKey.currentState.setExpanded(showingGifs);
                              });
                            },
                            child: new AnimatedContainer(
                              decoration: new BoxDecoration(color: Colors.pinkAccent, borderRadius: new BorderRadius.circular(5.0)),
                              height: isTyping && !showingGifs ? 30.0 : 0.0,
                              margin: new EdgeInsets.only(top: 5.0, bottom: 5.0, right: 20.0),
                              duration: new Duration(milliseconds: 300),
                              child: new Icon(Icons.gif, color: Colors.white, size: isTyping ? 30.0 : 0.0),
                            )
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        )
    );
  }

  createBottomAppBar(){
    return new ExpandableBottomAppBar(
      parentContext: context,
      key: _appBarKey,
      header: buildComposer(),
      body: new Container(
        color: Colors.white,
        child: buildGifGrid(),
      ),
    );
  }

  sendMessage(String message, {isGif = false})
  {
    if(message.isNotEmpty) {
      Messages.sendMessage(message, conversation, contact, isGif: isGif).then((conv)
      {
        setState(() {
          conversation = conv;
        });
      });

      setState(() {
        composerController.value = new TextEditingValue(text: '');
      });

    }
  }

  loadMessages()
  {
    Firestore.instance.collection('messages')
      .where('conversationId', isEqualTo: conversation.id).orderBy('timestamp', descending: true).getDocuments().then(
      (query)
      {
        List<ChatMessage> temp = [];
        query.documents.forEach(
          (doc)
          {
            temp.add(new ChatMessage.parse(doc));
          }
        );
        //temp.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        setState(() {
          messages = temp;
        });
      });
  }

  Widget buildGifGrid()
  {
    return new StaggeredGridView.countBuilder(
      reverse: true,
      padding: new EdgeInsets.symmetric(horizontal: 4.0),
      crossAxisCount: 4,
      itemCount: gifs.length,
      itemBuilder: (BuildContext context, int index) => gifs[index].createGridItem(onTap:
        (){
          sendMessage(gifs[index].url, isGif: true);
          composerController.value = new TextEditingValue(text: '');
          setState((){
            showingGifs = false;
            _appBarKey.currentState.setExpanded(showingGifs);
          });
        }
      ),
      staggeredTileBuilder: (int index) =>
      new StaggeredTile.count(2, index.isEven ? 2 : 1),
      mainAxisSpacing: 4.0,
      crossAxisSpacing: 4.0,
    );
  }

  @override
  void dispose() {
    super.dispose();
    controller.stop();
    controller.dispose();
  }

  Future<bool> isContact()
  {
    final Completer<bool> completer = new Completer();
    if(conversation != null) {
      UserContactsHandler.getContacts().then(
      (userContacts) {
          bool isContact = false;
          if (userContacts != null && userContacts.contacts != null) {
            userContacts.contacts.forEach(
            (c) {
              conversation.members.forEach(
                (m)
                {
                  if(c.email == m.email)
                    isContact = true;
                }
              );
            });
          }
          completer.complete(isContact);
        }
      );
    }
    else
    {
      completer.complete(null);
    }
    return completer.future;
  }

  Widget createAddContactButton()
  {
    return new Container(
      padding: new EdgeInsets.symmetric(vertical: 10.0),
      decoration: new BoxDecoration(gradient: LinearGradient(colors: [Colors.teal, Colors.blue])),
      child: new InkWell(
        onTap: addContact,
        child: new Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            new Text('+ Agregar a mis contactos', style: new TextStyle(color: Colors.white, fontSize: 16.0), textAlign: TextAlign.center)
          ],
        ),
      )
    );
  }

  addContact()
  {
    if(conversation.members.length == 1) {
      Contacts.addNewContact(conversation.members[0].email);
      setState(() {
        showAddContactButton = false;
      });
    }
  }
}
