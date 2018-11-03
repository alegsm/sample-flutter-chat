import 'package:chat/PushNotifications/Firebase/Firebase.dart';
import 'package:chat/chat/AddContactScreen.dart';
import 'package:chat/chat/ChatScreen.dart';
import 'package:chat/model/Contact.dart';
import 'package:chat/model/Conversation.dart';
import 'package:chat/model/LoginHandler.dart';
import 'package:chat/model/UserContacts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ChatHomeScreen extends StatefulWidget {

  static const String route = '/ChatHome';
  final String businessId;
  ChatHomeScreen({this.businessId});

  @override
  _ChatHomeScreenState createState() => new _ChatHomeScreenState();
}

class _ChatHomeScreenState extends State<ChatHomeScreen>  with SingleTickerProviderStateMixin{

  GlobalKey<RefreshIndicatorState> refreshKey = new GlobalKey<RefreshIndicatorState>();
  bool newConversation = false;
  double _appBarElevation = 1.0;
  FocusNode searchFocus = new FocusNode();
  TextEditingController searchController = new TextEditingController();
  bool isSearching = false;

  bool isLoading = false;
  double barRadius = 10.0;
  double searchBarPadding = 5.0;
  double searchBarMargin = 30.0;
  double searchBarTopMargin = 10.0;
  double searchBarElevation = 0.0;
  double searchBarHeight = 45.0;
  double searchBarFontSize = 16.0;
  double closeIconSize = 0.0;
  double closeIconMargin = 0.0;
  double searchBarLeftPadding = 10.0;
  bool showingResults = false;
  bool loggedIn = false;
  List<Contact> contacts = [];
  List<Conversation> conversations = [];

  @override
  void initState()
  {
    super.initState();
    FirebaseHandler.init();
    LoginHandler.login().then((_){
      if(LoginHandler.currentUser.email != null)
      {
        setState(() {
          loggedIn = true;
        });
      }
    });

    searchFocus.addListener((){
      if(searchFocus.hasFocus && !isSearching)
      {
        setState((){
          searching();
        });
      }
    });
  }

  void searching()
  {
    isSearching = true;
    searchBarPadding = 15.0;
    searchBarMargin = 0.0;
    searchBarTopMargin = 0.0;
    searchBarElevation = 1.0;
    searchBarHeight = 50.0;
    _appBarElevation = 0.0;
    searchBarFontSize = 20.0;
    closeIconSize = 50.0;
    closeIconMargin = 5.0;
    searchBarLeftPadding = 20.0;
    barRadius = 0.0;
  }

  void notSearching()
  {
    isSearching = false;
    searchBarPadding = 5.0;
    searchBarMargin = 30.0;
    searchBarTopMargin = 10.0;
    searchBarElevation = 0.0;
    searchBarHeight = 45.0;
    searchBarFontSize = 16.0;
    closeIconSize = 0.0;
    closeIconMargin = 0.0;
    searchBarLeftPadding = 10.0;
    barRadius = 20.0;
  }

  Widget createBody()
  {
    return new DefaultTabController(
      length: 2,
      child: new Scaffold(
        appBar: new AppBar(
          backgroundColor: Colors.white,
          iconTheme: new IconThemeData(color: Colors.teal),
          elevation: _appBarElevation,
          title: new Text('C H A T', style: new TextStyle(color: Colors.teal)),
          bottom: new TabBar(tabs: [
            new Tab(
              icon: new Icon(Icons.person, color: Colors.teal),
            ),
            new Tab(
              icon: new Icon(Icons.chat_bubble, color: Colors.teal),
            ),
          ]),
        ),
        body: generateBody(),
      ));
  }

  @override
  Widget build(BuildContext context)
  {
    return createBody();
  }

  Widget generateBody()
  {
    return new TabBarView(
      children: [
        generateContactList(),
        generateConversationsList()
      ]);
  }

  Widget generateContactList()
  {
    return new ListView(
      children: <Widget>[
        new InkWell(
          onTap: ()
          {
            Navigator.of(context).pushNamed(AddContactScreen.route);
          },
          child: new Container(
            margin: new EdgeInsets.symmetric(vertical: 10.0),
            child: new Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                new Container(
                  margin: new EdgeInsets.only(left: 16.0),
                  padding: new EdgeInsets.only(right: 10.0),
                  child: new SizedBox(
                    width: 40.0,
                    height: 40.0,
                    child: new Icon(Icons.person_add, color: Colors.teal, size: 30.0),
                  ),
                ),
                new Container(
                  margin: new EdgeInsets.only(right: 16.0),
                  child: new Text('add new Contact', style: new TextStyle(color: Colors.teal)),
                ),
              ],
            ),
          ),
        ),
        loggedIn ? new StreamBuilder<QuerySnapshot>(
          stream: Firestore.instance.collection('usercontacts').where('userEmail', isEqualTo: LoginHandler.currentUser.email).snapshots,
          builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.data != null && snapshot.data.documents != null && snapshot.data.documents.isNotEmpty) {
              UserContacts users = new UserContacts.parse(snapshot.data.documents[0]);
              UserContactsHandler.users = users;
              return new Column(
                children: users.contacts.map((Contact c) {
                  if (c.email != LoginHandler.currentUser.email) {
                    contacts.add(c);
                    return c.createListItem(
                            () {
                          Conversation mConversation;
                          conversations.forEach(
                                  (cnv) {
                                cnv.members.forEach(
                                        (m) {
                                      if (m.email == c.email) {
                                        mConversation = cnv;
                                      }
                                    }
                                );
                              }
                          );
                          if (mConversation != null) {
                            Navigator.of(context).push(new MaterialPageRoute(
                                builder: (context) =>
                                new ChatScreen(conversation: mConversation)));
                          }
                          else {
                            Navigator.of(context).push(new MaterialPageRoute(
                                builder: (context) =>
                                new ChatScreen(contact: c)));
                          }
                        });
                  }
                  else
                    return new Container();
                }).toList(),
              );

            }
            else {
              return new Text('Loading...');
            }
          },
        ) : new Container()
      ],
    );
  }

  Widget generateConversationsList()
  {
    return loggedIn ? new StreamBuilder<QuerySnapshot>(
      stream: Firestore.instance.collection('conversations').where('ownerEmail', isEqualTo: LoginHandler.currentUser.email).snapshots,
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) return new Text('Loading...');
        return new ListView(
          children: snapshot.data.documents.map((DocumentSnapshot document) {
            Conversation c = new Conversation.parse(document);
              conversations.add(c);
              return c.createListItem(context);
          }).toList(),
        );
      },
    ) : new Container();
  }

  Widget generateSearchBar()
  {
    return new SliverList(
      delegate: new SliverChildListDelegate(
        <Widget>[
          createSearchBar(),
        ]
      )
    );
  }

  Widget createSearchBar()
  {
    return new Container(
      child: new AnimatedContainer(
        duration: new Duration(milliseconds: 500),
        curve: Curves.bounceOut,
        margin: new EdgeInsets.fromLTRB(searchBarMargin, searchBarTopMargin, searchBarMargin, 0.0),
        child: new Material(
          color: Colors.white,
          borderRadius: new BorderRadius.circular(barRadius),
          elevation: searchBarElevation,
          child: new Row(
            children: <Widget>[
              new Expanded(
                  child: new AnimatedContainer(
                    duration: new Duration(milliseconds: 500),
                    curve: Curves.bounceOut,
                    padding: new EdgeInsets.fromLTRB(searchBarLeftPadding, searchBarPadding, 5.0, searchBarPadding),
                    child:
                    new TextField(
                      style: new TextStyle(fontSize: searchBarFontSize, color: Colors.black),
                      focusNode: searchFocus,
                      controller: searchController,
                      onSubmitted: (val){
                        setState((){
                          //notSearching();
                          showingResults = true;
                        });
                      },
                      decoration: new InputDecoration(
                        border: InputBorder.none,
                        hintText: "¿Qué buscas?",
                        prefixIcon: new Icon(Icons.search, color: Colors.pink),
                        hintStyle: new TextStyle(fontSize: 16.0),
                      ),
                    ),
                  )
              ),

              new Column(
                children: <Widget>[
                  new AnimatedContainer(
                    margin: new EdgeInsets.only(right: closeIconMargin),
                    width: closeIconSize,
                    height: closeIconSize,
                    duration: new Duration(milliseconds: 500),
                    curve: Curves.bounceOut,
                    child:
                    new IconButton(icon: new Icon(Icons.clear), onPressed: (){
                      setState(()
                      {
                        if(showingResults)
                          showingResults = false;
                        else
                          notSearching();
                        searchController.text = '';
                        FocusScope.of(context).requestFocus(new FocusNode());
                      });
                    }),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  reloadConversations()
  {
    Conversations.getConversations().then(
      (list)
      {
        if(list != null)
        {
          setState(() {
            conversations = list;
          });
        }
      }
    );
  }

}
