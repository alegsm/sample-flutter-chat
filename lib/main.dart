import 'package:chat/chat/AddContactScreen.dart';
import 'package:chat/chat/ChatHomeScreen.dart';
import 'package:flutter/material.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Demo',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new ChatHomeScreen(),
      routes: <String, WidgetBuilder>{
        ChatHomeScreen.route: (context) => new ChatHomeScreen(),
        AddContactScreen.route: (context) => new AddContactScreen(),
      },
    );
  }
}
