import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils.dart';
import '../../models/comment.dart';
import '../../models/social_post.dart';
import '../../providers/social_provider.dart';
import '../../widgets/friend_avatar.dart';
import '../../widgets/local_image_preview.dart';

class PostDetailPage extends StatefulWidget {
  const PostDetailPage({super.key, required this.post});

  final SocialPost post;

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _composerController = TextEditingController();
  final FocusNode _composerFocusNode = FocusNode();
  final Set<String> _expandedReplyParents = <String>{};

  Comment? _replyTarget;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _composerController.addListener(_handleComposerChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final provider = context.read<SocialProvider>();
      await provider.preparePost(widget.post);
      await provider.loadComments(widget.post.id, refresh: true);
    });
  }

  @override
  void dispose() {
    _composerController.removeListener(_handleComposerChanged);
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    _composerController.dispose();
    _composerFocusNode.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.extentAfter < 220) {
      context.read<SocialProvider>().loadMoreComments(widget.post.id);
    }
  }

  void _handleComposerChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _sharePost(SocialPost post) async {
    await Share.share(_buildShareText(post));
    if (!mounted) return;
    await context.read<SocialProvider>().recordShare(post.id);
  }

  Future<void> _sendComment() async {
    final text = _composerController.text.trim();
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

      _composerController.clear();
      setState(() {
        _replyTarget = null;
      });
      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
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
            comment.parentId == null ? '删除后，这条评论下的回复也会一起删除。' : '确认删除这条回复吗？',
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
    _composerFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('动态详情')),
      body: Consumer<SocialProvider>(
        builder: (context, provider, _) {
          final post = provider.resolvePost(widget.post);
          final comments = provider.commentsForPost(widget.post.id);
          final threads = _buildThreads(comments);
          final isLoading = provider.isLoadingCommentsFor(widget.post.id);
          final isLoadingMore = provider.isLoadingMoreCommentsFor(
            widget.post.id,
          );
          final hasMore = provider.hasMoreCommentsFor(widget.post.id);

          return CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.spacingL,
                    AppTheme.spacingL,
                    AppTheme.spacingL,
                    AppTheme.spacingM,
                  ),
                  child: _DetailPostCard(
                    post: post,
                    onLike: () =>
                        provider.toggleLike(post.id, fallbackPost: post),
                    onCommentTap: () => _composerFocusNode.requestFocus(),
                    onShare: () => _sharePost(post),
                    onImageTap: (index) =>
                        _openGallery(post, initialIndex: index),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.spacingL,
                    0,
                    AppTheme.spacingL,
                    AppTheme.spacingM,
                  ),
                  child: Row(
                    children: [
                      Text('全部评论', style: AppTextStyle.h3),
                      const SizedBox(width: 8),
                      Text('${post.commentCount}', style: AppTextStyle.caption),
                    ],
                  ),
                ),
              ),
              if (isLoading && threads.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  ),
                )
              else if (threads.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingXL,
                      ),
                      child: Text(
                        '还没有评论，来留下第一句鼓励吧。',
                        style: AppTextStyle.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.spacingL,
                    0,
                    AppTheme.spacingL,
                    140,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index >= threads.length) {
                          return Padding(
                            padding: const EdgeInsets.only(
                              top: AppTheme.spacingM,
                              bottom: AppTheme.spacingL,
                            ),
                            child: Center(
                              child: isLoadingMore
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppTheme.primary,
                                      ),
                                    )
                                  : Text(
                                      '上滑继续加载更多评论',
                                      style: AppTextStyle.caption,
                                    ),
                            ),
                          );
                        }

                        final thread = threads[index];
                        final replies = _visibleRepliesForThread(thread);
                        final canExpandReplies =
                            thread.replies.length > replies.length;

                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppTheme.spacingL,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _CommentBubble(
                                comment: thread.root,
                                canDelete:
                                    thread.root.authorId ==
                                    provider.currentUserId,
                                onReply: () => _startReply(thread.root),
                                onDelete: () => _deleteComment(thread.root),
                                onToggleLike: () =>
                                    provider.toggleCommentLike(thread.root.id),
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
                                            padding: const EdgeInsets.only(
                                              bottom: AppTheme.spacingS,
                                            ),
                                            child: _CommentBubble(
                                              comment: reply,
                                              isReply: true,
                                              canDelete:
                                                  reply.authorId ==
                                                  provider.currentUserId,
                                              onReply: () =>
                                                  _startReply(thread.root),
                                              onDelete: () =>
                                                  _deleteComment(reply),
                                              onToggleLike: () => provider
                                                  .toggleCommentLike(reply.id),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),
                              if (canExpandReplies)
                                Padding(
                                  padding: const EdgeInsets.only(left: 44),
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
                      childCount:
                          threads.length + ((hasMore || isLoadingMore) ? 1 : 0),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      bottomNavigationBar: _ComposerBar(
        controller: _composerController,
        focusNode: _composerFocusNode,
        replyTarget: _replyTarget,
        isSending: _isSending,
        onCancelReply: () => setState(() => _replyTarget = null),
        onSubmit: _sendComment,
      ),
    );
  }

  void _openGallery(SocialPost post, {required int initialIndex}) {
    if (post.imagePaths.isEmpty) return;
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      builder: (_) => _FullscreenGallery(
        images: post.imagePaths,
        initialIndex: initialIndex,
      ),
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

class _DetailPostCard extends StatelessWidget {
  const _DetailPostCard({
    required this.post,
    required this.onLike,
    required this.onCommentTap,
    required this.onShare,
    required this.onImageTap,
  });

  final SocialPost post;
  final VoidCallback onLike;
  final VoidCallback onCommentTap;
  final VoidCallback onShare;
  final ValueChanged<int> onImageTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.neuSubtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FriendAvatar(
                label: post.userName,
                avatarAssetPath: post.userAvatar,
                avatarConfig: post.avatarConfig,
                size: 46,
                borderRadius: 18,
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            post.userName,
                            style: AppTextStyle.body.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (post.isOfficial) ...[
                          const SizedBox(width: 8),
                          _Capsule(
                            label: '官方',
                            background: AppTheme.primaryMuted,
                            foreground: AppTheme.primary,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatRelativeTime(post.createdAt)} · ${post.visibility.label}',
                      style: AppTextStyle.caption,
                    ),
                  ],
                ),
              ),
              _PostTypeChip(type: post.type),
            ],
          ),
          if (post.title != null) ...[
            const SizedBox(height: AppTheme.spacingM),
            Text(post.title!, style: AppTextStyle.h3),
          ],
          if (post.subtitle != null) ...[
            const SizedBox(height: 6),
            Text(post.subtitle!, style: AppTextStyle.bodySmall),
          ],
          const SizedBox(height: AppTheme.spacingM),
          Text(post.content, style: AppTextStyle.body),
          if (post.goalTitle != null) ...[
            const SizedBox(height: AppTheme.spacingM),
            _InfoTile(
              icon: Icons.track_changes_rounded,
              label: post.goalTitle!,
              color: AppTheme.primary,
            ),
          ],
          if (post.type == PostType.checkIn) ...[
            const SizedBox(height: AppTheme.spacingM),
            Wrap(
              spacing: AppTheme.spacingS,
              runSpacing: AppTheme.spacingS,
              children: [
                _InfoTile(
                  icon: Icons.emoji_emotions_outlined,
                  label: post.moodEmoji,
                  color: AppTheme.accentStrong,
                ),
                if (post.streak != null)
                  _InfoTile(
                    icon: Icons.local_fire_department_rounded,
                    label: '连续 ${post.streak} 天',
                    color: AppTheme.error,
                  ),
              ],
            ),
          ],
          if (post.type == PostType.goalComplete ||
              post.type == PostType.milestone) ...[
            const SizedBox(height: AppTheme.spacingM),
            Wrap(
              spacing: AppTheme.spacingS,
              runSpacing: AppTheme.spacingS,
              children: _buildMetaChips(post),
            ),
          ],
          if (post.type == PostType.nftMint || post.imagePaths.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingM),
            _PostImageStrip(images: post.imagePaths, onTap: onImageTap),
          ],
          const SizedBox(height: AppTheme.spacingM),
          Row(
            children: [
              _ActionButton(
                icon: post.isLikedByMe ? Icons.favorite : Icons.favorite_border,
                color: AppTheme.error,
                label: '${post.likeCount}',
                onTap: onLike,
              ),
              const SizedBox(width: AppTheme.spacingS),
              _ActionButton(
                icon: Icons.chat_bubble_outline_rounded,
                color: AppTheme.textSecondary,
                label: '${post.commentCount}',
                onTap: onCommentTap,
              ),
              const SizedBox(width: AppTheme.spacingS),
              _ActionButton(
                icon: Icons.ios_share_rounded,
                color: AppTheme.textSecondary,
                label: '${post.shareCount}',
                onTap: onShare,
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMetaChips(SocialPost post) {
    final data = post.extraData;
    final chips = <Widget>[];
    if (post.type == PostType.goalComplete) {
      final daysSpent = data['daysSpent'];
      final checkInCount = data['checkInCount'];
      if (daysSpent != null) {
        chips.add(
          _InfoTile(
            icon: Icons.calendar_month_outlined,
            label: '$daysSpent 天',
            color: AppTheme.bonusBlue,
          ),
        );
      }
      if (checkInCount != null) {
        chips.add(
          _InfoTile(
            icon: Icons.check_circle_outline_rounded,
            label: '$checkInCount 次打卡',
            color: AppTheme.accentStrong,
          ),
        );
      }
    } else if (post.type == PostType.milestone) {
      final currentValue = data['currentValue'];
      final targetValue = data['targetValue'];
      if (currentValue != null && targetValue != null) {
        chips.add(
          _InfoTile(
            icon: Icons.flag_outlined,
            label: '$currentValue / $targetValue',
            color: AppTheme.bonusBlue,
          ),
        );
      }
      if (data['isMinted'] == true) {
        chips.add(
          _InfoTile(
            icon: Icons.auto_awesome_rounded,
            label: '已铸造 NFT',
            color: AppTheme.goldAccent,
          ),
        );
      }
    }
    return chips;
  }
}

class _ComposerBar extends StatelessWidget {
  const _ComposerBar({
    required this.controller,
    required this.focusNode,
    required this.replyTarget,
    required this.isSending,
    required this.onCancelReply,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final Comment? replyTarget;
  final bool isSending;
  final VoidCallback onCancelReply;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppTheme.spacingL,
        AppTheme.spacingS,
        AppTheme.spacingL,
        max(AppTheme.spacingL, MediaQuery.of(context).padding.bottom),
      ),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (replyTarget != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '回复 @${replyTarget!.authorName}',
                      style: AppTextStyle.bodySmall,
                    ),
                  ),
                  InkWell(
                    onTap: onCancelReply,
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
                  controller: controller,
                  focusNode: focusNode,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSubmit(),
                  decoration: InputDecoration(
                    hintText: replyTarget == null
                        ? '写下你的评论...'
                        : '回复 @${replyTarget!.authorName}',
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingS),
              Material(
                color: controller.text.trim().isEmpty || isSending
                    ? AppTheme.textHint.withValues(alpha: 0.18)
                    : AppTheme.accent,
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                child: InkWell(
                  onTap: controller.text.trim().isEmpty || isSending
                      ? null
                      : onSubmit,
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
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
    );
  }
}

class _PostImageStrip extends StatelessWidget {
  const _PostImageStrip({required this.images, required this.onTap});

  final List<String> images;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return const SizedBox.shrink();
    final visibleImages = images.take(3).toList(growable: false);
    return SizedBox(
      height: 136,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: visibleImages.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppTheme.spacingS),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => onTap(index),
            child: Hero(
              tag: 'post-image-${visibleImages[index]}-$index',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                child: SizedBox(
                  width: 136,
                  child: _PostImage(imagePath: visibleImages[index]),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PostImage extends StatelessWidget {
  const _PostImage({required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (_, error, stackTrace) =>
            _ImageFallback(imagePath: imagePath),
      );
    }
    if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (_, error, stackTrace) =>
            _ImageFallback(imagePath: imagePath),
      );
    }
    return LocalImagePreview(
      imagePath: imagePath,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback({required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surfaceVariant,
      alignment: Alignment.center,
      child: Text(
        imagePath.split('/').last,
        style: AppTextStyle.caption,
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _FullscreenGallery extends StatefulWidget {
  const _FullscreenGallery({required this.images, required this.initialIndex});

  final List<String> images;
  final int initialIndex;

  @override
  State<_FullscreenGallery> createState() => _FullscreenGalleryState();
}

class _FullscreenGalleryState extends State<_FullscreenGallery> {
  late final PageController _controller = PageController(
    initialPage: widget.initialIndex,
  );
  late int _currentIndex = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.images.length,
            onPageChanged: (value) => setState(() => _currentIndex = value),
            itemBuilder: (context, index) {
              return Center(
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Hero(
                    tag: 'post-image-${widget.images[index]}-$index',
                    child: _PostImage(imagePath: widget.images[index]),
                  ),
                ),
              );
            },
          ),
          Positioned(
            top: 18,
            left: 18,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded, color: Colors.white),
            ),
          ),
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${_currentIndex + 1} / ${widget.images.length}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PostTypeChip extends StatelessWidget {
  const _PostTypeChip({required this.type});

  final PostType type;

  @override
  Widget build(BuildContext context) {
    final (label, background, foreground) = switch (type) {
      PostType.checkIn => ('打卡', AppTheme.primaryMuted, AppTheme.primary),
      PostType.achievement => (
        '成就',
        AppTheme.accentLight,
        AppTheme.accentStrong,
      ),
      PostType.milestone => (
        '里程碑',
        AppTheme.surfaceVariant,
        AppTheme.bonusBlue,
      ),
      PostType.nftMint => ('NFT', AppTheme.accentLight, AppTheme.bonusBlue),
      PostType.goalComplete => (
        '完成',
        AppTheme.primaryMuted,
        AppTheme.bonusMint,
      ),
      PostType.thought => (
        '想法',
        AppTheme.surfaceVariant,
        AppTheme.textSecondary,
      ),
    };
    return _Capsule(
      label: label,
      background: background,
      foreground: foreground,
    );
  }
}

class _Capsule extends StatelessWidget {
  const _Capsule({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
      ),
      child: Text(
        label,
        style: AppTextStyle.caption.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTextStyle.bodySmall.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusS),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(AppTheme.radiusS),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(label, style: AppTextStyle.caption),
          ],
        ),
      ),
    );
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
              if (!isReply ||
                  comment.replyToName == null ||
                  comment.replyToName!.isEmpty)
                Text(comment.content, style: AppTextStyle.body)
              else
                Text.rich(
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
                ),
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

String _buildShareText(SocialPost post) {
  final title = post.title ?? post.goalTitle ?? 'MintDay 动态';
  return '$title\n${post.content}';
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
