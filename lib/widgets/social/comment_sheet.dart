import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils.dart';
import '../../models/comment.dart';
import '../../models/social_post.dart';
import '../../providers/social_provider.dart';
import '../friend_avatar.dart';

Future<void> showCommentSheet(BuildContext context, SocialPost post) async {
  final provider = context.read<SocialProvider>();
  await provider.preparePost(post);
  if (!context.mounted) return;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => CommentSheet(post: provider.resolvePost(post)),
  );
}

class CommentSheet extends StatefulWidget {
  const CommentSheet({super.key, required this.post});

  final SocialPost post;

  @override
  State<CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<CommentSheet> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final Set<String> _expandedReplyParents = <String>{};

  ScrollController? _sheetScrollController;
  Comment? _replyTarget;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleComposerChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialComments();
    });
  }

  void _handleComposerChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_handleComposerChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadInitialComments() async {
    await context.read<SocialProvider>().loadComments(
      widget.post.id,
      refresh: true,
    );
  }

  Future<void> _sendComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      final comment = await context.read<SocialProvider>().addComment(
        widget.post.id,
        text,
        parentId: _replyTarget?.id,
        replyToName: _replyTarget?.authorName,
      );
      if (comment == null || !mounted) return;

      _controller.clear();
      setState(() {
        _replyTarget = null;
      });

      final controller = _sheetScrollController;
      if (controller != null && controller.hasClients) {
        await controller.animateTo(
          0,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _deleteComment(Comment comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('删除评论'),
          content: Text(
            comment.parentId == null ? '删除后该评论下的回复也会一起删除。' : '确认删除这条回复吗？',
            style: AppTextStyle.bodySmall,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;

    final success = await context.read<SocialProvider>().deleteComment(
      comment.id,
    );
    if (!mounted) return;
    AppUtils.showSnackBar(
      context,
      success ? '评论已删除' : '删除失败，请稍后重试',
      isError: !success,
    );
  }

  void _startReply(Comment comment) {
    setState(() {
      _replyTarget = comment.parentId == null
          ? comment
          : Comment(
              id: comment.parentId ?? comment.id,
              postId: comment.postId,
              authorId: comment.authorId,
              authorName: comment.replyToName ?? comment.authorName,
              authorAvatar: comment.authorAvatar,
              authorAvatarConfig: comment.authorAvatarConfig,
              content: comment.content,
              parentId: null,
              replyToName: null,
              createdAt: comment.createdAt,
              likeCount: comment.likeCount,
              isLiked: comment.isLiked,
            );
    });
    _focusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyTarget = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.76,
      minChildSize: 0.42,
      maxChildSize: 0.94,
      builder: (context, scrollController) {
        _sheetScrollController = scrollController;

        return Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppTheme.radiusXL),
            ),
          ),
          child: Consumer<SocialProvider>(
            builder: (context, provider, _) {
              final resolvedPost = provider.resolvePost(widget.post);
              final comments = provider.commentsForPost(widget.post.id);
              final threads = _buildThreads(comments);
              final isLoading = provider.isLoadingCommentsFor(widget.post.id);
              final isLoadingMore = provider.isLoadingMoreCommentsFor(
                widget.post.id,
              );
              final hasMore = provider.hasMoreCommentsFor(widget.post.id);
              final currentUserId = provider.currentUserId;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.spacingL,
                      AppTheme.spacingM,
                      AppTheme.spacingM,
                      AppTheme.spacingS,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Center(
                                child: Container(
                                  width: 42,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: AppTheme.border,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppTheme.spacingM),
                              Text(
                                resolvedPost.commentCount > 0
                                    ? '${resolvedPost.commentCount} 条评论'
                                    : '评论',
                                style: AppTextStyle.h3,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(
                            Icons.close_rounded,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (notification.metrics.extentAfter < 180 &&
                            hasMore &&
                            !isLoadingMore) {
                          provider.loadMoreComments(widget.post.id);
                        }
                        return false;
                      },
                      child: isLoading && threads.isEmpty
                          ? Center(
                              child: CircularProgressIndicator(
                                color: AppTheme.primary,
                              ),
                            )
                          : threads.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.spacingXL,
                                ),
                                child: Text(
                                  '还没有评论，来说点什么吧',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyle.bodySmall,
                                ),
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              padding: const EdgeInsets.fromLTRB(
                                AppTheme.spacingL,
                                AppTheme.spacingM,
                                AppTheme.spacingL,
                                AppTheme.spacingL,
                              ),
                              itemCount:
                                  threads.length + (isLoadingMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index >= threads.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                      top: AppTheme.spacingM,
                                    ),
                                    child: Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppTheme.primary,
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                final thread = threads[index];
                                final replies = _visibleRepliesForThread(
                                  thread,
                                );
                                final canExpandReplies =
                                    thread.replies.length > replies.length;

                                return Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppTheme.spacingL,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _CommentBubble(
                                        comment: thread.root,
                                        canDelete:
                                            thread.root.authorId ==
                                            currentUserId,
                                        onReply: () => _startReply(thread.root),
                                        onDelete: () =>
                                            _deleteComment(thread.root),
                                        onToggleLike: () => provider
                                            .toggleCommentLike(thread.root.id),
                                      ),
                                      if (replies.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            left: 44,
                                            top: AppTheme.spacingS,
                                          ),
                                          child: Column(
                                            children: replies
                                                .map(
                                                  (reply) => Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          bottom:
                                                              AppTheme.spacingS,
                                                        ),
                                                    child: _CommentBubble(
                                                      comment: reply,
                                                      isReply: true,
                                                      canDelete:
                                                          reply.authorId ==
                                                          currentUserId,
                                                      onReply: () =>
                                                          _startReply(
                                                            thread.root,
                                                          ),
                                                      onDelete: () =>
                                                          _deleteComment(reply),
                                                      onToggleLike: () =>
                                                          provider
                                                              .toggleCommentLike(
                                                                reply.id,
                                                              ),
                                                    ),
                                                  ),
                                                )
                                                .toList(),
                                          ),
                                        ),
                                      if (canExpandReplies)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            left: 44,
                                          ),
                                          child: TextButton(
                                            onPressed: () {
                                              setState(() {
                                                _expandedReplyParents.add(
                                                  thread.root.id,
                                                );
                                              });
                                            },
                                            child: const Text('查看更多回复'),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.fromLTRB(
                      AppTheme.spacingL,
                      AppTheme.spacingS,
                      AppTheme.spacingL,
                      max(
                        AppTheme.spacingL,
                        MediaQuery.of(context).padding.bottom,
                      ),
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      border: Border(top: BorderSide(color: AppTheme.border)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_replyTarget != null)
                          Container(
                            margin: const EdgeInsets.only(
                              bottom: AppTheme.spacingS,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusM,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '回复 @${_replyTarget!.authorName}',
                                    style: AppTextStyle.bodySmall,
                                  ),
                                ),
                                InkWell(
                                  onTap: _cancelReply,
                                  borderRadius: BorderRadius.circular(999),
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: Icon(
                                      Icons.close_rounded,
                                      size: 18,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _controller,
                                focusNode: _focusNode,
                                minLines: 1,
                                maxLines: 4,
                                textInputAction: TextInputAction.send,
                                onSubmitted: (_) => _sendComment(),
                                decoration: InputDecoration(
                                  hintText: _replyTarget == null
                                      ? '写下你的评论...'
                                      : '回复 @${_replyTarget!.authorName}',
                                ),
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacingS),
                            Material(
                              color:
                                  _controller.text.trim().isEmpty || _isSending
                                  ? AppTheme.textHint.withValues(alpha: 0.18)
                                  : AppTheme.accent,
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusM,
                              ),
                              child: InkWell(
                                onTap:
                                    _controller.text.trim().isEmpty ||
                                        _isSending
                                    ? null
                                    : _sendComment,
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusM,
                                ),
                                child: const SizedBox(
                                  width: 52,
                                  height: 52,
                                  child: Icon(
                                    Icons.send_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  List<_CommentThread> _buildThreads(List<Comment> comments) {
    final commentMap = {for (final comment in comments) comment.id: comment};
    final repliesByParent = <String, List<Comment>>{};
    final roots = <Comment>[];

    for (final comment in comments) {
      final parentId = comment.parentId;
      if (parentId == null || !commentMap.containsKey(parentId)) {
        roots.add(comment);
        continue;
      }
      repliesByParent.putIfAbsent(parentId, () => <Comment>[]).add(comment);
    }

    final threads = roots.map((root) {
      final replies = List<Comment>.from(repliesByParent[root.id] ?? const []);
      replies.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      final latestReplyTime = replies.isEmpty
          ? root.createdAt
          : replies.last.createdAt;
      return _CommentThread(
        root: root,
        replies: replies,
        latestActivityAt: latestReplyTime.isAfter(root.createdAt)
            ? latestReplyTime
            : root.createdAt,
      );
    }).toList();

    threads.sort((a, b) => b.latestActivityAt.compareTo(a.latestActivityAt));
    return threads;
  }

  List<Comment> _visibleRepliesForThread(_CommentThread thread) {
    if (_expandedReplyParents.contains(thread.root.id) ||
        thread.replies.length <= 2) {
      return thread.replies;
    }
    return thread.replies.take(2).toList();
  }
}

class _CommentBubble extends StatelessWidget {
  const _CommentBubble({
    required this.comment,
    required this.canDelete,
    required this.onReply,
    required this.onDelete,
    required this.onToggleLike,
    this.isReply = false,
  });

  final Comment comment;
  final bool canDelete;
  final bool isReply;
  final VoidCallback onReply;
  final VoidCallback onDelete;
  final VoidCallback onToggleLike;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FriendAvatar(
          label: comment.authorName,
          avatarAssetPath: comment.authorAvatar,
          avatarConfig: comment.parsedAuthorAvatarConfig,
          size: isReply ? 32 : 36,
          borderRadius: isReply ? 12 : 14,
        ),
        const SizedBox(width: AppTheme.spacingS),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          comment.authorName,
                          style: AppTextStyle.bodySmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          _formatRelativeTime(comment.createdAt),
                          style: AppTextStyle.caption,
                        ),
                      ],
                    ),
                  ),
                  if (canDelete)
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'delete') {
                          onDelete();
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: Text('删除'),
                        ),
                      ],
                      icon: Icon(
                        Icons.more_horiz_rounded,
                        size: 18,
                        color: AppTheme.textHint,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              _CommentContent(comment: comment, isReply: isReply),
              const SizedBox(height: 8),
              Row(
                children: [
                  InkWell(
                    onTap: onToggleLike,
                    borderRadius: BorderRadius.circular(999),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            comment.isLiked
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 16,
                            color: AppTheme.error,
                          ),
                          if (comment.likeCount > 0) ...[
                            const SizedBox(width: 4),
                            Text(
                              '${comment.likeCount}',
                              style: AppTextStyle.caption.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  InkWell(
                    onTap: onReply,
                    borderRadius: BorderRadius.circular(999),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      child: Text(
                        '回复',
                        style: AppTextStyle.caption.copyWith(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CommentContent extends StatelessWidget {
  const _CommentContent({required this.comment, required this.isReply});

  final Comment comment;
  final bool isReply;

  @override
  Widget build(BuildContext context) {
    if (!isReply ||
        comment.replyToName == null ||
        comment.replyToName!.isEmpty) {
      return Text(comment.content, style: AppTextStyle.body);
    }

    return Text.rich(
      TextSpan(
        style: AppTextStyle.body,
        children: [
          TextSpan(
            text: '回复 @${comment.replyToName} ',
            style: AppTextStyle.body.copyWith(
              color: AppTheme.accentStrong,
              fontWeight: FontWeight.w700,
            ),
          ),
          TextSpan(text: comment.content),
        ],
      ),
    );
  }
}

class _CommentThread {
  const _CommentThread({
    required this.root,
    required this.replies,
    required this.latestActivityAt,
  });

  final Comment root;
  final List<Comment> replies;
  final DateTime latestActivityAt;
}

String _formatRelativeTime(DateTime value) {
  final diff = DateTime.now().difference(value);
  if (diff.inMinutes < 1) return '刚刚';
  if (diff.inHours < 1) return '${diff.inMinutes} 分钟前';
  if (diff.inDays < 1) return '${diff.inHours} 小时前';
  if (diff.inDays == 1) return '昨天';
  if (diff.inDays < 7) return '${diff.inDays} 天前';
  return AppUtils.friendlyDate(value);
}
