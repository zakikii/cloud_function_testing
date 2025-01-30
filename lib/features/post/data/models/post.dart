// models/post.dart
class Post {
  final String id;
  final String userId;
  final String userEmail;
  final String content;
  final DateTime createdAt;
  final List<Comment>? comments;

  Post({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.content,
    required this.createdAt,
    this.comments,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      userEmail: json['userEmail'] ?? '',
      content: json['content'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      comments: json['comments'] != null
          ? List<Comment>.from(json['comments'].map((x) => Comment.fromJson(x)))
          : [],
    );
  }
}

class Comment {
  final String id;
  final String userId;
  final String userEmail;
  final String content;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.content,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      userEmail: json['userEmail'] ?? '',
      content: json['content'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}
