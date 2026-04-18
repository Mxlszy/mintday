import 'package:flutter/material.dart';

import '../../models/nft_asset.dart';
import 'creative_nft_templates.dart';
import 'moment_nft_card.dart';
import 'nft_card_render_data.dart';
import 'nft_collectible_card.dart';

Widget buildNftArtwork({
  required NftCategory category,
  required NftCardRenderData data,
  String? templateId,
  bool compact = false,
}) {
  switch (category) {
    case NftCategory.moment:
      return MomentNftCard(data: data, compact: compact);
    case NftCategory.creative:
    case NftCategory.collection:
      return buildCreativeNftTemplate(
        templateId: templateId,
        data: data,
        compact: compact,
      );
    case NftCategory.achievement:
    case NftCategory.milestone:
    case NftCategory.streak:
    case NftCategory.custom:
      return NftCollectibleCard(
        title: data.title,
        description: data.description,
        category: category,
        createdAt: data.createdAt,
        rarity: data.rarity,
        compact: compact,
      );
  }
}
