import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../models/ai_message.dart';

class MinimaxAiService {
  static const String _envApiKey = String.fromEnvironment('MINIMAX_API_KEY');
  static const String _envBaseUrl = String.fromEnvironment(
    'MINIMAX_BASE_URL',
    defaultValue: 'https://api.minimaxi.com/v1',
  );
  static const String _envModel = String.fromEnvironment(
    'MINIMAX_MODEL',
    defaultValue: 'MiniMax-M2.7',
  );
  static const String _localConfigAsset = 'assets/config/local_ai_config.json';

  final http.Client _client;

  bool _isInitialized = false;
  String? _runtimeApiKey;
  String? _runtimeBaseUrl;
  String? _runtimeModel;

  MinimaxAiService({http.Client? client}) : _client = client ?? http.Client();

  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    try {
      final raw = await rootBundle.loadString(_localConfigAsset);
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        final apiKey = decoded['apiKey'];
        final baseUrl = decoded['baseUrl'];
        final model = decoded['model'];

        if (apiKey is String && apiKey.trim().isNotEmpty) {
          _runtimeApiKey = apiKey.trim();
        }
        if (baseUrl is String && baseUrl.trim().isNotEmpty) {
          _runtimeBaseUrl = baseUrl.trim();
        }
        if (model is String && model.trim().isNotEmpty) {
          _runtimeModel = model.trim();
        }
      }
    } catch (_) {
      // Local asset config is optional in development.
    }
  }

  bool get isConfigured => _resolvedApiKey.trim().isNotEmpty;
  String get modelName => _resolvedModel;

  Future<MinimaxAiResponse> generateReply({
    required String userText,
    required MinimaxPromptContext context,
    required List<MinimaxHistoryMessage> history,
  }) async {
    await init();

    final apiKey = _resolvedApiKey;
    if (apiKey.trim().isEmpty) {
      throw const MinimaxAiException('未配置 MiniMax API Key');
    }

    final messages = <Map<String, dynamic>>[
      {'role': 'system', 'content': _buildSystemPrompt(context)},
      ...history
          .where((item) => item.content.trim().isNotEmpty)
          .map(
            (item) => {'role': _mapRole(item.role), 'content': item.content},
          ),
      {'role': 'user', 'content': userText},
    ];

    final uri = Uri.parse('$_resolvedBaseUrl/chat/completions');
    final response = await _client
        .post(
          uri,
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': _resolvedModel,
            'messages': messages,
            'temperature': 1.0,
            'n': 1,
          }),
        )
        .timeout(const Duration(seconds: 30));

    final body = _decodeJson(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw MinimaxAiException(_extractErrorMessage(body, response.body));
    }

    final rawContent = _extractContent(body);
    if (rawContent.isEmpty) {
      throw const MinimaxAiException('MiniMax 返回了空内容');
    }

    return MinimaxAiResponse(
      rawContent: rawContent,
      displayContent: _stripThinking(rawContent),
    );
  }

  String get _resolvedApiKey => _runtimeApiKey ?? _envApiKey;
  String get _resolvedBaseUrl => _runtimeBaseUrl ?? _envBaseUrl;
  String get _resolvedModel => _runtimeModel ?? _envModel;

  String _mapRole(MessageRole role) {
    return switch (role) {
      MessageRole.user => 'user',
      MessageRole.assistant => 'assistant',
      MessageRole.system => 'system',
    };
  }

  String _buildSystemPrompt(MinimaxPromptContext context) {
    final lines = <String>[
      '你是 MintDay 的 AI 成长伙伴。',
      '你要根据用户真实数据，给出温柔、具体、可信的简体中文回复。',
      '回复要求：',
      '1. 全程使用简体中文。',
      '2. 不要提“作为 AI”或“我无法访问数据”，因为数据已经提供给你。',
      '3. 不要编造不存在的目标、步骤或统计。',
      '4. 优先共情，再给鼓励、观察或一个今天就能执行的小建议。',
      '5. 回答尽量控制在 2 到 5 句话，必要时可以用短条目。',
      '6. 如果用户在问进度、建议、状态，可以自然引用下面的数据。',
      '用户数据快照：',
      '今天日期：${context.todayLabel}',
      '活跃目标数：${context.activeGoalCount}',
      '活跃目标：${context.activeGoalTitles.isEmpty ? '暂无' : context.activeGoalTitles.join('、')}',
      '今日已打卡目标数：${context.checkedTodayCount}',
      '最长连续记录：${context.longestStreak} 天',
      '累计打卡次数：${context.totalCheckIns}',
      '步骤完成：${context.completedSteps}/${context.totalSteps}',
      '整体步骤完成率：${context.goalProgressPercent}%',
      '最近 7 天心情趋势：${context.moodTrendLabel}',
      '最近 7 天心情均值：${context.moodAverageLabel}',
      '最近 7 天心情序列：${context.moodSeriesLabel}',
      '今日专注时长：${context.todayFocusLabel}',
      '优先目标：${context.primaryGoalTitle ?? '暂无'}',
      '最值得先完成的一步：${context.primaryPendingStepLabel ?? '暂无'}',
    ];

    if (context.goalStepHints.isNotEmpty) {
      lines.add('未完成步骤参考：${context.goalStepHints.join('；')}');
    }

    return lines.join('\n');
  }

  Map<String, dynamic>? _decodeJson(String body) {
    if (body.trim().isEmpty) return null;

    final decoded = jsonDecode(body);
    return decoded is Map<String, dynamic> ? decoded : null;
  }

  String _extractErrorMessage(Map<String, dynamic>? body, String rawBody) {
    final error = body?['error'];
    if (error is Map<String, dynamic>) {
      final message = error['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
    }

    final message = body?['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
    }

    return rawBody.trim().isEmpty ? 'MiniMax 请求失败' : rawBody.trim();
  }

  String _extractContent(Map<String, dynamic>? body) {
    final choices = body?['choices'];
    if (choices is! List || choices.isEmpty) return '';

    final firstChoice = choices.first;
    if (firstChoice is! Map<String, dynamic>) return '';

    final message = firstChoice['message'];
    if (message is! Map<String, dynamic>) return '';

    final content = message['content'];
    if (content is String) return content.trim();

    if (content is List) {
      final buffer = StringBuffer();
      for (final item in content) {
        if (item is Map<String, dynamic>) {
          final text = item['text'];
          if (text is String) {
            buffer.write(text);
          }
        }
      }
      return buffer.toString().trim();
    }

    return '';
  }

  String _stripThinking(String rawContent) {
    final withoutThinking = rawContent
        .replaceAll(RegExp(r'<think>[\s\S]*?</think>'), '')
        .trim();

    return withoutThinking.isEmpty ? rawContent.trim() : withoutThinking;
  }
}

class MinimaxPromptContext {
  final String todayLabel;
  final int activeGoalCount;
  final List<String> activeGoalTitles;
  final int checkedTodayCount;
  final int longestStreak;
  final int totalCheckIns;
  final int completedSteps;
  final int totalSteps;
  final int goalProgressPercent;
  final String moodTrendLabel;
  final String moodAverageLabel;
  final String moodSeriesLabel;
  final String todayFocusLabel;
  final String? primaryGoalTitle;
  final String? primaryPendingStepLabel;
  final List<String> goalStepHints;

  const MinimaxPromptContext({
    required this.todayLabel,
    required this.activeGoalCount,
    required this.activeGoalTitles,
    required this.checkedTodayCount,
    required this.longestStreak,
    required this.totalCheckIns,
    required this.completedSteps,
    required this.totalSteps,
    required this.goalProgressPercent,
    required this.moodTrendLabel,
    required this.moodAverageLabel,
    required this.moodSeriesLabel,
    required this.todayFocusLabel,
    required this.primaryGoalTitle,
    required this.primaryPendingStepLabel,
    required this.goalStepHints,
  });
}

class MinimaxHistoryMessage {
  final MessageRole role;
  final String content;

  const MinimaxHistoryMessage({required this.role, required this.content});
}

class MinimaxAiResponse {
  final String rawContent;
  final String displayContent;

  const MinimaxAiResponse({
    required this.rawContent,
    required this.displayContent,
  });
}

class MinimaxAiException implements Exception {
  final String message;

  const MinimaxAiException(this.message);

  @override
  String toString() => message;
}
