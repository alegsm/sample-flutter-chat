import 'package:chat/model/Contact.dart';
import 'package:flutter/material.dart';

class AddContactScreen extends StatefulWidget {
  static String route = '/newContact';
  @override
  _AddContactScreenState createState() => new _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {

  TextEditingController controller = new TextEditingController(text: '');

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(backgroundColor: Colors.white,
        iconTheme: new IconThemeData(color: Colors.teal),
        elevation: 1.0,
        title: new Text('New contact', style: new TextStyle(color: Colors.teal)),
      ),
      body: new Container(
        child: new Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            new Container(
              margin: new EdgeInsets.only(bottom: 30.0),
              child: new Text('Add a contact', style: new TextStyle(color: Colors.teal, fontSize: 25.0)),
            ),
            new Container(
              margin: new EdgeInsets.symmetric(horizontal: 30.0),
              child: new TextField(
                controller: controller,
                onSubmitted: (text){
                  if(text.isNotEmpty)
                    addContact(text.toLowerCase());
                },
                textAlign: TextAlign.center,
                decoration: new InputDecoration(hintText: 'write your contacts email', border: new OutlineInputBorder()),
              ),
            ),
            new Container(
              decoration: new BoxDecoration(color: Colors.teal, borderRadius: new BorderRadius.circular(10.0)),
              padding: new EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
              margin: new EdgeInsets.only(top: 20.0),
              child: new InkWell(
                onTap: (){
                  if(controller.text.isNotEmpty)
                    addContact(controller.text.toLowerCase());
                },
                child: new Text('Add', style: new TextStyle(color: Colors.white, fontSize: 16.0)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  addContact(String email)
  {
    Contacts.addNewContact(email);
    Navigator.pop(context);
  }
}
