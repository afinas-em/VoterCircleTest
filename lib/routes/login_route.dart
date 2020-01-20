import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voter_circle_reply/common.dart';
import 'package:voter_circle_reply/models/user.dart';

class LoginRoute extends StatefulWidget {
  @override
  _LoginRouteState createState() => _LoginRouteState();
}

class _LoginRouteState extends State<LoginRoute> {
  String _username = '';

  String _password = '';

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(
          builder: (context) => SafeArea(
                child: Container(
                  color: Colors.white,
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: <Widget>[
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              SizedBox(
                                height: 30,
                              ),
                              TextField(
                                  onChanged: (txt) {
                                    _username = txt;
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'Username',
                                    alignLabelWithHint: false,
                                    border: OutlineInputBorder(
                                        borderSide:
                                            BorderSide(color: Colors.black)),
                                  )),
                              SizedBox(
                                height: 10.0,
                              ),
                              TextField(
                                  onChanged: (txt) {
                                    _password = txt;
                                  },
                                  obscureText: true,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    alignLabelWithHint: false,
                                    border: OutlineInputBorder(
                                        borderSide:
                                            BorderSide(color: Colors.black)),
                                  )),
                              SizedBox(
                                height: 16.0,
                              ),
                              MaterialButton(
                                onPressed: () {

                                  _username = _username.trim();
                                  _password = _password.trim();

                                  if (_username.isEmpty || _password.isEmpty) {
                                    Scaffold.of(context).showSnackBar(SnackBar(
                                        content: Text('Invalid credentials')));
                                    return;
                                  }

                                  checkCredentials(context);
                                },
                                padding: EdgeInsets.symmetric(
                                    horizontal: 30, vertical: 10),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Text(
                                      'Login',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 18),
                                    ),
                                    if (_isLoading)
                                      Container(
                                        margin: EdgeInsets.only(left: 16),
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      )
                                  ],
                                ),
                                color: primaryColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                      FlatButton(
                        child: Text(
                          "Skip Login",
                          style:
                              TextStyle(decoration: TextDecoration.underline),
                        ),
                        onPressed: () {
                          FocusScope.of(context).requestFocus(FocusNode());
                          Navigator.of(context).pop();
                        },
                      ),

//              FlatButton(
//                child: Text(
//                  "No account yet, SignUp",
//                  style: TextStyle(decoration: TextDecoration.underline),
//                ),
//                onPressed: () {
//                  _showSignUpDialog(context);
//                },
//              ),
                    ],
                  ),
                ),
              )),
    );
  }

  void checkCredentials(context) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    var snapshots = await Firestore.instance
        .collection('users')
        .where("name", isEqualTo: _username)
        .where('password', isEqualTo: _password)
        .getDocuments();

    if (snapshots.documents.isEmpty) {
      Scaffold.of(context).showSnackBar(SnackBar(
        content: Text('Credentials not matching'),
      ));
    } else {
      UserModel user = UserModel.map(snapshots.documents[0].data);
      SharedPreferences pref = await SharedPreferences.getInstance();
      await pref.setInt(Constants.SHARED_PREF_USER_ID, user.id);
      await pref.setString(Constants.SHARED_PREF_USER_NAME, user.name);
      await pref.setString(Constants.SHARED_PREF_USER_IMAGE, user.image);

      FocusScope.of(context).requestFocus(FocusNode());
      Navigator.of(context).pop();
    }

    setState(() {
      _isLoading = false;
    });
  }
}
