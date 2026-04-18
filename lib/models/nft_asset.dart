import 'dart:convert';

enum NftCategory {
  achievement('achievement', '成就'),
  milestone('milestone', '里程碑'),
  streak('streak', '连续打卡'),
  custom('custom', '自定义'),
  moment('moment', '打卡瞬间'),
  creative('creative', '创意合成'),
  collection('collection', '合集');

  const NftCategory(this.value, this.label);

  final String value;
  final String label;

  static NftCategory fromValue(String value) {
    return NftCategory.values.firstWhere(
      (item) => item.value == value,
      orElse: () => NftCategory.custom,
    );
  }
}

enum NftStatus {
  pending('pending', '待铸造'),
  minting('minting', '铸造中'),
  minted('minted', '已铸造'),
  failed('failed', '铸造失败');

  const NftStatus(this.value, this.label);

  final String value;
  final String label;

  static NftStatus fromValue(String value) {
    return NftStatus.values.firstWhere(
      (item) => item.value == value,
      orElse: () => NftStatus.pending,
    );
  }
}

enum NftRarity {
  common('common', 'Common'),
  rare('rare', 'Rare'),
  epic('epic', 'Epic'),
  legendary('legendary', 'Legendary');

  const NftRarity(this.value, this.label);

  final String value;
  final String label;

  static NftRarity fromValue(String value) {
    return NftRarity.values.firstWhere(
      (item) => item.value == value,
      orElse: () => NftRarity.common,
    );
  }
}

class NftAsset {
  final String id;
  final String title;
  final String description;
  final NftCategory category;
  final String? sourceId;
  final String? checkInId;
  final String? templateId;
  final String? metadata;
  final String imagePath;
  final NftStatus status;
  final String? txHash;
  final String? tokenId;
  final NftRarity? rarity;
  final DateTime createdAt;
  final DateTime? mintedAt;

  const NftAsset({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.sourceId,
    this.checkInId,
    this.templateId,
    this.metadata,
    required this.imagePath,
    required this.status,
    this.txHash,
    this.tokenId,
    this.rarity,
    required this.createdAt,
    this.mintedAt,
  });

  NftAsset copyWith({
    String? id,
    String? title,
    String? description,
    NftCategory? category,
    String? sourceId,
    String? checkInId,
    String? templateId,
    String? metadata,
    String? imagePath,
    NftStatus? status,
    String? txHash,
    String? tokenId,
    NftRarity? rarity,
    DateTime? createdAt,
    DateTime? mintedAt,
  }) {
    return NftAsset(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      sourceId: sourceId ?? this.sourceId,
      checkInId: checkInId ?? this.checkInId,
      templateId: templateId ?? this.templateId,
      metadata: metadata ?? this.metadata,
      imagePath: imagePath ?? this.imagePath,
      status: status ?? this.status,
      txHash: txHash ?? this.txHash,
      tokenId: tokenId ?? this.tokenId,
      rarity: rarity ?? this.rarity,
      createdAt: createdAt ?? this.createdAt,
      mintedAt: mintedAt ?? this.mintedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category.value,
      'source_id': sourceId,
      'check_in_id': checkInId,
      'template_id': templateId,
      'metadata': metadata,
      'image_path': imagePath,
      'status': status.value,
      'tx_hash': txHash,
      'token_id': tokenId,
      'rarity': rarity?.value,
      'created_at': createdAt.toIso8601String(),
      'minted_at': mintedAt?.toIso8601String(),
    };
  }

  factory NftAsset.fromMap(Map<String, dynamic> map) {
    return NftAsset(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      category: NftCategory.fromValue(map['category'] as String),
      sourceId: map['source_id'] as String?,
      checkInId: map['check_in_id'] as String?,
      templateId: map['template_id'] as String?,
      metadata: map['metadata'] as String?,
      imagePath: map['image_path'] as String,
      status: NftStatus.fromValue(map['status'] as String),
      txHash: map['tx_hash'] as String?,
      tokenId: map['token_id'] as String?,
      rarity: map['rarity'] == null
          ? null
          : NftRarity.fromValue(map['rarity'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      mintedAt: map['minted_at'] != null
          ? DateTime.parse(map['minted_at'] as String)
          : null,
    );
  }

  NftRarity get effectiveRarity => rarity ?? NftRarity.common;

  Map<String, dynamic> get metadataMap {
    final raw = metadata;
    if (raw == null || raw.trim().isEmpty) {
      return const <String, dynamic>{};
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
    } catch (_) {}
    return const <String, dynamic>{};
  }

  String get heroTag => 'nft-asset-$id';
}
