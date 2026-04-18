import 'dart:convert';

import 'avatar_config.dart';

class Comment {
  const Comment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    this.authorAvatarConfig,
    required this.content,
    this.parentId,
    this.replyToName,
    required this.createdAt,
    required this.likeCount,
    required this.isLiked,
  });

  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final Map<String, dynamic>? authorAvatarConfig;
  final String content;
  final String? parentId;
  final String? replyToName;
  final DateTime createdAt;
  final int likeCount;
  final bool isLiked;

  AvatarConfig? get parsedAuthorAvatarConfig {
    if (authorAvatarConfig == null) return null;
    return AvatarConfig.fromJson(
      Map<String, dynamic>.from(authorAvatarConfig!),
    );
  }

  Comment copyWith({
    String? id,
    String? postId,
    String? authorId,
    String? authorName,
    String? authorAvatar,
    Map<String, dynamic>? authorAvatarConfig,
    String? content,
    String? parentId,
    String? replyToName,
    DateTime? createdAt,
    int? likeCount,
    bool? isLiked,
  }) {
    return Comment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      authorAvatarConfig: authorAvatarConfig ?? this.authorAvatarConfig,
      content: content ?? this.content,
      parentId: parentId ?? this.parentId,
      replyToName: replyToName ?? this.replyToName,
      createdAt: createdAt ?? this.createdAt,
      likeCount: likeCount ?? this.likeCount,
      isLiked: isLiked ?? this.isLiked,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'post_id': postId,
      'author_id': authorId,
      'author_name': authorName,
      'author_avatar': authorAvatar,
      'author_avatar_config': authorAvatarConfig == null
          ? null
          : jsonEncode(authorAvatarConfig),
      'content': content,
      'parent_id': parentId,
      'reply_to_name': replyToName,
      'created_at': createdAt.toIso8601String(),
      'like_count': likeCount,
    };
  }

  factory Comment.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic>? authorAvatarConfig;
    final avatarConfigRaw = map['author_avatar_config'];
    if (avatarConfigRaw is String && avatarConfigRaw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(avatarConfigRaw);
        if (decoded is Map<String, dynamic>) {
          authorAvatarConfig = decoded;
        } else if (decoded is Map) {
          authorAvatarConfig = Map<String, dynamic>.from(decoded);
        }
      } catch (_) {}
    }

    return Comment(
      id: map['id'] as String,
      postId: map['post_id'] as String,
      authorId: map['author_id'] as String,
      authorName: map['author_name'] as String,
      authorAvatar: map['author_avatar'] as String?,
      authorAvatarConfig: authorAvatarConfig,
      content: map['content'] as String? ?? '',
      parentId: map['parent_id'] as String?,
      replyToName: map['reply_to_name'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      likeCount: map['like_count'] as int? ?? 0,
      isLiked: (map['is_liked'] as int? ?? 0) == 1,
    );
  }
}
