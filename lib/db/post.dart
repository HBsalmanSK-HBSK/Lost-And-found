class PostModel {
  int? id;
  int userId;
  String description;
  String createdAt;
  String? photo; // new field to store local path

  PostModel({
    this.id,
    required this.userId,
    required this.description,
    required this.createdAt,
    this.photo,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'description': description,
      'createdAt': createdAt,
      'photo': photo,
    };
  }

  factory PostModel.fromMap(Map<String, dynamic> map) => PostModel(
    id: map['id'] as int?,
    userId: map['userId'],
    description: map['description'],
    createdAt: map['createdAt'],
    photo: map['photo'] as String?,
  );
}
