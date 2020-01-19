import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:voter_circle_reply/common.dart';
import 'package:voter_circle_reply/routes/home_route.dart';
import 'package:voter_circle_reply/routes/login_route.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(primarySwatch: primaryColor),
      initialRoute: Constants.ROUTE_HOME,
      debugShowCheckedModeBanner: false,
      routes: {
        Constants.ROUTE_HOME: (context) => HomeRoute(),
        Constants.ROUTE_LOGIN: (context) => LoginRoute(),
      },
    );
  }
}

class Test extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Container(
          color: Colors.white,
          child: StreamBuilder(
            stream: Firestore.instance.collection('comments').snapshots(),
            builder: ((context, snapshot) {
              if (snapshot.hasError) return Text("Error ${snapshot.error}");

              switch (snapshot.connectionState) {
                case ConnectionState.waiting:
                  return Text('Loading');
                default:
                  return Text(snapshot.data.documents[0]['comment']);
              }
            }),
          ),
        ),
      ),
    );
  }
}
