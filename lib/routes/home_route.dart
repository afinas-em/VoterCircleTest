import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:voter_circle_reply/common.dart';
import 'package:voter_circle_reply/models/comment.dart';
import 'package:voter_circle_reply/models/user.dart';

class HomeRoute extends StatefulWidget {
  @override
  _HomeRouteState createState() => _HomeRouteState();
}

class _HomeRouteState extends State<HomeRoute> {
  UserModel _user;
  bool _isLoggedIn = false;
  List<CommentModel> _comments = [];
  String _comment = '';
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _noMoreData = false;
  bool _isLoading = false;
  bool _addingComment = false;

  @override
  void initState() {
    super.initState();
    refreshUser();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          padding: EdgeInsets.all(16.0),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                      child: Text(
                    'Logged in as : ${_user?.name ?? '-'}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  )),
                  FlatButton(
                    color: primaryColor,
                    child: Text(
                      _isLoggedIn ? 'Logout' : 'Login',
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: () async {
                      FocusScope.of(context).requestFocus(FocusNode());
                      if (_isLoggedIn) await logoutCurrentUser();

                      await Navigator.pushNamed(context, Constants.ROUTE_LOGIN);
                      refreshUser();
                    },
                  )
                ],
              ),
              SizedBox(height: 10),
              PostWidget(),
              SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Text('Comments',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(width: 10),
                  if (_isLoading)
                    SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(),
                    ),
                ],
              ),
              SizedBox(height: 16),
              Expanded(
                child: Container(
                  child: ListView.builder(
                      controller: _scrollController,
                      itemCount: _comments.isEmpty ? 0 : _comments.length + 1,
                      itemBuilder: (context, index) {
                        if (index < _comments.length)
                          return CommentView(
                            _comments[index],
                            modelChanged: (model) {
                              setState(() {
                                if (!mounted) return;
                                _comments[index] = model;
                              });
                            },
                            currentUser: _user,
                          );

                        return FlatButton(
                          child: Text(_noMoreData
                              ? 'You have reached the bottom'
                              : 'Load more'),
                          onPressed: () {
                            if (_noMoreData) return;
                            loadComments(true);
                          },
                        );
                      }),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.black45),
                    borderRadius: BorderRadius.circular(10)),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                            contentPadding: EdgeInsets.only(left: 16),
                            hintText: 'Enter comment',
                            border: InputBorder.none),
                        onChanged: (txt) {
                          _comment = txt;
                        },
                      ),
                    ),
                    _addingComment
                        ? Container(
                            margin: EdgeInsets.only(right: 16),
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(),
                          )
                        : IconButton(
                            icon: Icon(
                              Icons.send,
                              color: _isLoggedIn ? primaryColor : Colors.grey,
                            ),
                            onPressed: () async {
                              if (!_isLoggedIn) return;
                              if (_addingComment) return;

                              _comment = _comment.trim();
                              if (_comment.isEmpty) {
                                Fluttertoast.showToast(msg: 'Enter comment');
                                return;
                              }

                              setState(() {
                                _addingComment = true;
                              });

                              FocusScope.of(context).requestFocus(FocusNode());

                              CommentModel newComment = CommentModel()
                                ..comment = _comment
                                ..date_time =
                                    DateTime.now().millisecondsSinceEpoch
                                ..image = _user.image
                                ..like_ids = []
                                ..reply_count = 0
                                ..like_status = false
                                ..replies = []
                                ..name = _user.name;

                              _controller.clear();
                              _comment = '';

                              final CollectionReference commentsRef =
                                  Firestore.instance.collection('comments');
                              DocumentReference document =
                                  await commentsRef.add(newComment.toJson());
                              newComment.path = document.path;
                              setState(() {
                                _comments.insert(0, newComment);
                              });
                              _scrollController.jumpTo(0);
                              setState(() {
                                _addingComment = false;
                              });
                            },
                          )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void refreshUser() async {
    var tmp = await getCurrentUser();
    setState(() {
      _user = tmp;
      _isLoggedIn = _user.id != null && _user.id != -1;
    });

    loadComments(false);
  }

  void loadComments(bool isPagination) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    QuerySnapshot snapShot;
    if (!isPagination) {
      snapShot = await Firestore.instance
          .collection('comments')
          .limit(5)
          .orderBy('date_time', descending: true)
          .getDocuments();
    } else {
      DocumentSnapshot lastDoc =
          await Firestore.instance.document(_comments.last.path).get();
      snapShot = await Firestore.instance
          .collection('comments')
          .startAfterDocument(lastDoc)
          .limit(5)
          .orderBy('date_time', descending: true)
          .getDocuments();
    }

    if (snapShot.documents.isEmpty) {
      setState(() {
        _noMoreData = true;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _noMoreData = false;
    });

    List<CommentModel> _tmp = [];
    for (DocumentSnapshot model in snapShot.documents)
      _tmp.add(CommentModel.map(model,
          userId: _user.id, path: model.reference.path));

    if (!isPagination) _comments.clear();

    setState(() {
      if (!mounted) return;

      if (_tmp.isEmpty) _noMoreData = true;
      _comments.addAll(_tmp);
      _isLoading = false;
    });
  }
}
