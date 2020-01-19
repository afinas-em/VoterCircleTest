class CommentModel {
  String comment;
  int date_time;
  String image;
  String name;
  int reply_count;
  bool like_status;
  String path;

  List<int> like_ids;
  List<CommentModel> replies;

  CommentModel();

  CommentModel.map(map, {int userId, String path}) {
    comment = map['comment'] ?? '';
    date_time = map['date_time'] ?? 0;
    image = map['image'] ?? '';
    name = map['name'] ?? '';
    reply_count = map['reply_count'] ?? 0;

    like_ids = [];
    for (int id in map['like_ids'] ?? []) like_ids.add(id);

    replies = [];

    like_status = false;
    if (userId != null) like_status = like_ids.contains(userId);

    this.path = path;
  }

  toJson() {
    return {
      'comment': comment,
      'date_time': date_time,
      'image': image,
      'like_ids': like_ids,
      'reply_count': reply_count,
      'name': name,
    };
  }
}
