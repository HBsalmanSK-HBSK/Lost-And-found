class CommentModel {
  int? id;
  int postId;
  int userId;
  String content;
  String createdAt;

  CommentModel({
    this.id,
    required this.postId,
    required this.userId,
    required this.content,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'postId': postId,
      'userId': userId,
      'content': content,
      'createdAt': createdAt,
    };
  }

  factory CommentModel.fromMap(Map<String, dynamic> map) => CommentModel(
    id: map['id'] as int?,
    postId: map['postId'],
    userId: map['userId'],
    content: map['content'],
    createdAt: map['createdAt'],
  );
}
