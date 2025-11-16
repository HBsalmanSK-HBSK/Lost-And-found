class MessageModel {
  int? id;
  int fromUserId;
  int toUserId;
  String content;
  String createdAt;

  MessageModel({
    this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.content,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'content': content,
      'createdAt': createdAt,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) => MessageModel(
    id: map['id'] as int?,
    fromUserId: map['fromUserId'],
    toUserId: map['toUserId'],
    content: map['content'],
    createdAt: map['createdAt'],
  );
}
