enum MessageRole { user, assistant, system }

class AiMessage {
  final String id;
  final String content;
  final MessageRole role;
  final DateTime createdAt;
  final String? relatedGoalId;

  const AiMessage({
    required this.id,
    required this.content,
    required this.role,
    required this.createdAt,
    this.relatedGoalId,
  });
}
