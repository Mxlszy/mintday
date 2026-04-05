import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import '../../core/neumorphic.dart';
import '../../core/pixel_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils.dart';
import '../../models/check_in.dart';
import '../../widgets/local_image_preview.dart';

class CheckInDetailPage extends StatelessWidget {
  final CheckIn checkIn;
  final String goalTitle;

  const CheckInDetailPage({
    super.key,
    required this.checkIn,
    required this.goalTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('打卡详情')),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        children: [
          _SummaryCard(checkIn: checkIn, goalTitle: goalTitle),
          if (checkIn.note != null && checkIn.note!.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingL),
            _TextSection(title: '记录内容', content: checkIn.note!),
          ],
          if (_hasReflectionContent) ...[
            const SizedBox(height: AppTheme.spacingL),
            _ReflectionSection(checkIn: checkIn),
          ],
          if (checkIn.imagePaths.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingL),
            _ImageSection(imagePaths: checkIn.imagePaths),
          ],
        ],
      ),
    );
  }

  bool get _hasReflectionContent {
    return (checkIn.reflectionProgress?.isNotEmpty ?? false) ||
        (checkIn.reflectionBlocker?.isNotEmpty ?? false) ||
        (checkIn.reflectionNext?.isNotEmpty ?? false);
  }
}

class _SummaryCard extends StatelessWidget {
  final CheckIn checkIn;
  final String goalTitle;

  const _SummaryCard({
    required this.checkIn,
    required this.goalTitle,
  });

  @override
  Widget build(BuildContext context) {
    return NeuContainer(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              NeuIconButton(
                size: 52,
                child: Text(
                  checkIn.moodEmoji,
                  style: AppTextStyle.body.copyWith(fontSize: 28),
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(goalTitle, style: AppTextStyle.h3),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        PixelIcon(
                          icon: PixelIcons.clock,
                          size: 11,
                          color: AppTheme.textHint,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${AppUtils.friendlyDate(checkIn.date)} · ${DateFormat('HH:mm').format(checkIn.createdAt)}',
                          style: AppTextStyle.caption,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          Wrap(
            spacing: AppTheme.spacingS,
            runSpacing: AppTheme.spacingS,
            children: [
              _NeuTag(label: checkIn.mode.label),
              _NeuTag(label: checkIn.status.label, isPrimary: true),
              if (checkIn.duration != null)
                _NeuTag(label: AppUtils.formatDuration(checkIn.duration!)),
              if (checkIn.imagePaths.isNotEmpty)
                _NeuTag(label: '${checkIn.imagePaths.length} 张图片'),
            ],
          ),
        ],
      ),
    );
  }
}

class _TextSection extends StatelessWidget {
  final String title;
  final String content;

  const _TextSection({
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return NeuContainer(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      isSubtle: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyle.label),
          const SizedBox(height: AppTheme.spacingS),
          Text(content, style: AppTextStyle.body),
        ],
      ),
    );
  }
}

class _ReflectionSection extends StatelessWidget {
  final CheckIn checkIn;

  const _ReflectionSection({required this.checkIn});

  @override
  Widget build(BuildContext context) {
    return NeuContainer(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      isSubtle: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PixelIcon(
                icon: PixelIcons.book,
                size: 14,
                color: AppTheme.primary,
              ),
              const SizedBox(width: 8),
              Text('反思内容', style: AppTextStyle.label),
            ],
          ),
          if (checkIn.reflectionProgress?.isNotEmpty ?? false) ...[
            const SizedBox(height: AppTheme.spacingM),
            _ReflectionRow(
              label: '今天最小的推进',
              value: checkIn.reflectionProgress!,
            ),
          ],
          if (checkIn.reflectionBlocker?.isNotEmpty ?? false) ...[
            const SizedBox(height: AppTheme.spacingM),
            _ReflectionRow(
              label: '遇到的阻碍',
              value: checkIn.reflectionBlocker!,
            ),
          ],
          if (checkIn.reflectionNext?.isNotEmpty ?? false) ...[
            const SizedBox(height: AppTheme.spacingM),
            _ReflectionRow(
              label: '明天想推进什么',
              value: checkIn.reflectionNext!,
            ),
          ],
        ],
      ),
    );
  }
}

class _ReflectionRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReflectionRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyle.caption),
        const SizedBox(height: 4),
        Text(value, style: AppTextStyle.body),
      ],
    );
  }
}

class _ImageSection extends StatelessWidget {
  final List<String> imagePaths;

  const _ImageSection({required this.imagePaths});

  @override
  Widget build(BuildContext context) {
    return NeuContainer(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('附加图片', style: AppTextStyle.label),
          const SizedBox(height: AppTheme.spacingS),
          Wrap(
            spacing: AppTheme.spacingS,
            runSpacing: AppTheme.spacingS,
            children: imagePaths.map((imagePath) {
              return SizedBox(
                width: 104,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusM),
                      child: LocalImagePreview(
                        imagePath: imagePath,
                        width: 104,
                        height: 104,
                        onTap: () =>
                            _showPreviewDialog(context, imagePath),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      path.basename(imagePath),
                      style: AppTextStyle.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _showPreviewDialog(BuildContext context, String imagePath) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(AppTheme.spacingL),
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
            boxShadow: AppTheme.neuRaised,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ),
              Flexible(
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(AppTheme.radiusL),
                  child: LocalImagePreview(
                    imagePath: imagePath,
                    width: 320,
                    height: 320,
                    borderRadius: AppTheme.radiusL,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingS),
              Text(
                path.basename(imagePath),
                style: AppTextStyle.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NeuTag extends StatelessWidget {
  final String label;
  final bool isPrimary;

  const _NeuTag({
    required this.label,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isPrimary ? AppTheme.primaryMuted : AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: AppTextStyle.caption.copyWith(
          color: isPrimary ? AppTheme.primary : AppTheme.textSecondary,
          fontWeight: isPrimary ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }
}
