class UserModel {
  String name;
  String image;
  int id =-1;

  UserModel({this.id, this.name, this.image});

  UserModel.map(map) {
    name = map['name'] ?? '';
    image = map['image'] ?? '';
    id = map['id'] ?? -1;
  }
}
