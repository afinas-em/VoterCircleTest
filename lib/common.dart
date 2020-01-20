import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:voter_circle_reply/models/comment.dart';

import 'models/user.dart';

var primaryColor = Colors.lightBlue;

Future<UserModel> getCurrentUser() async {
  var sp = await SharedPreferences.getInstance();
  int id = sp.getInt(Constants.SHARED_PREF_USER_ID);
  String name = sp.getString(Constants.SHARED_PREF_USER_NAME);
  String image = sp.getString(Constants.SHARED_PREF_USER_IMAGE);
  UserModel tmp;
  if (id == null || id == -1)
    tmp = UserModel(id: -1, name: '-', image: '');
  else
    tmp = UserModel(id: id, name: name, image: image);

  return tmp;
}

logoutCurrentUser() async {
  var sp = await SharedPreferences.getInstance();
  await sp.clear();
  await sp.setInt(Constants.SHARED_PREF_USER_ID, -1);
}

class Constants {
  static const String SHARED_PREF_USER_ID = 'user_id';
  static const String SHARED_PREF_USER_NAME = 'user_name';
  static const String SHARED_PREF_USER_IMAGE = 'user_image';

  static const String ROUTE_HOME = '/';
  static const String ROUTE_LOGIN = 'login';
}

class PostWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: primaryColor.withOpacity(0.5),
      ),
      child: Center(
        child: Text(
          "POST DATA",
          style: TextStyle(
              color: Colors.blue.withOpacity(0.6),
              fontSize: 30,
              fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class CommentView extends StatelessWidget {
  final CommentModel _comment;
  final Function(CommentModel) modelChanged;
  final UserModel currentUser;

  bool _isLiking = false;

  CommentView(this._comment, {this.modelChanged, this.currentUser});

  @override
  Widget build(BuildContext context) => Container(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  height: 35.0,
                  width: 35.0,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    image: DecorationImage(image: NetworkImage(_comment.image)),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Text(
                            _comment.name,
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                              child: Text(
                                  timeago.format(
                                      DateTime.fromMillisecondsSinceEpoch(
                                          _comment.date_time)),
                                  style: TextStyle(
                                      color: Colors.black45, fontSize: 13)))
                        ],
                      ),
                      SizedBox(height: 5),
                      Text(
                        _comment.comment,
                        style: TextStyle(fontSize: 16),
                      )
                    ],
                  ),
                )
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 40.0),
              child: Row(
                children: <Widget>[
                  LikeButton(
                    _comment.like_status,
                    _comment.like_ids.length,
                    likeClicked: () {
                      if (currentUser.id == -1) {
                        Scaffold.of(context).showSnackBar(
                            SnackBar(content: Text('Login required')));
                        return;
                      }

                      if (_isLiking) return;

                      _isLiking = true;

                      Firestore.instance.runTransaction((transaction) async {
                        DocumentSnapshot document = await transaction
                            .get(Firestore.instance.document(_comment.path));
                        if (document.exists) {
                          var ids = _comment.like_ids;

                          if (ids.contains(currentUser.id))
                            ids.remove(currentUser.id);
                          else
                            ids.add(currentUser.id);

                          transaction
                              .update(document.reference, {'like_ids': ids});

                          _comment.like_ids = ids;
                          _comment.like_status = ids.contains(currentUser.id);
                          modelChanged(_comment);
                        }

                        _isLiking = false;
                      });
                    },
                  ),
                  if (_comment.reply_count > 0 && _comment.replies.isEmpty)
                    FlatButton(
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: EdgeInsets.all(0),
                      child: Text(
                        'View ${_comment.reply_count} replies',
                        style: TextStyle(color: Colors.black45, fontSize: 13),
                      ),
                      onPressed: () async {
                        var query = await Firestore.instance
                            .collection('${_comment.path}/replies')
                            .orderBy('date_time', descending: false)
                            .getDocuments();
                        _comment.replies = [];
                        for (DocumentSnapshot snapshot in query.documents)
                          _comment.replies.add(CommentModel.map(snapshot,
                              userId: currentUser.id,
                              path: snapshot.reference.path));

                        modelChanged(_comment);
                      },
                    ),
                  FlatButton(
                    padding: EdgeInsets.all(0),
                    child: Text(
                      'Reply',
                      style: TextStyle(color: Colors.black45, fontSize: 13),
                    ),
                    onPressed: () {
                      if (currentUser.id == -1) {
                        Scaffold.of(context).showSnackBar(
                            SnackBar(content: Text('Login to required')));
                        return;
                      }

                      showReplyAlert(context,
                          path: _comment.path,
                          user: currentUser, replySuccess: (replies) async {
                        _comment.replies = replies;
                        _comment.reply_count += 1;
                        modelChanged(_comment);

                        final DocumentReference document =
                            Firestore.instance.document(_comment.path);
                        await document
                            .updateData({'reply_count': _comment.reply_count});
                      });
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: _comment.replies
                    .map((model) => CommentView(
                          model,
                          modelChanged: (changedModel) {
                            int index = _comment.replies.indexOf(model);
                            _comment.replies[index] = changedModel;
                            modelChanged(_comment);
                          },
                          currentUser: currentUser,
                        ))
                    .toList(),
              ),
            )
          ],
        ),
      );

  Future<void> showReplyAlert(context,
      {String path,
      Function(List<CommentModel> replies) replySuccess,
      UserModel user}) {
    String _comment = '';
    bool _isPosting = false;

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
                title: Text('Comment Reply'),
                content: Container(
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.black45),
                      borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    children: <Widget>[
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                              contentPadding: EdgeInsets.only(left: 16),
                              hintText: 'Enter Reply',
                              border: InputBorder.none),
                          onChanged: (txt) {
                            _comment = txt;
                          },
                        ),
                      ),
                      _isPosting
                          ? Container(
                              margin: EdgeInsets.only(right: 10, left: 5),
                              height: 25,
                              width: 25,
                              child: CircularProgressIndicator())
                          : IconButton(
                              icon: Icon(
                                Icons.send,
                                color: primaryColor,
                              ),
                              onPressed: () async {
                                _comment = _comment.trim();
                                if (_comment.isEmpty) {
                                  Fluttertoast.showToast(msg: 'Enter comment');
                                  return;
                                }

                                if (_isPosting) return;

                                setState(() {
                                  _isPosting = true;
                                });

                                CommentModel newComment = CommentModel()
                                  ..comment = _comment
                                  ..date_time =
                                      DateTime.now().millisecondsSinceEpoch
                                  ..image = user.image
                                  ..like_ids = []
                                  ..reply_count = 0
                                  ..like_status = false
                                  ..replies = []
                                  ..name = user.name;

                                FocusScope.of(context)
                                    .requestFocus(FocusNode());

                                final CollectionReference commentsRef =
                                    Firestore.instance
                                        .collection('$path/replies');
                                DocumentReference document =
                                    await commentsRef.add(newComment.toJson());
                                newComment.path = document.path;

                                var query = await Firestore.instance
                                    .collection('$path/replies')
                                    .orderBy('date_time', descending: false)
                                    .getDocuments();

                                final List<CommentModel> tmpReplies = [];
                                for (DocumentSnapshot snapshot
                                    in query.documents)
                                  tmpReplies.add(CommentModel.map(snapshot,
                                      userId: currentUser.id,
                                      path: snapshot.reference.path));

                                Navigator.of(context).pop();
                                replySuccess(tmpReplies);
                                setState(() {
                                  _isPosting = false;
                                });
                              },
                            )
                    ],
                  ),
                ),
                actions: []);
          },
        );
      },
    );
  }
}

class LikeButton extends StatelessWidget {
  final bool like_status;
  final Function likeClicked;
  final int like_count;

  LikeButton(this.like_status, this.like_count, {this.likeClicked});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      child: FlatButton.icon(
        padding: EdgeInsets.only(right: 10),
        icon: Icon(like_status ? Icons.favorite : Icons.favorite_border,
            color: Colors.red),
        onPressed: likeClicked,
        label: Text('$like_count', style: TextStyle(fontSize: 13)),
      ),
    );
  }
}
