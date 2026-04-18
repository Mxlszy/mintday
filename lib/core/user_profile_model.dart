import '../models/avatar_config.dart';

class UserProfileModel {
  final String nickname;
  final String? avatarAssetPath;
  final AvatarConfig? avatarConfig;
  final String welcomeMessage;

  const UserProfileModel({
    this.nickname = '忠实用户',
    this.avatarAssetPath,
    this.avatarConfig,
    this.welcomeMessage = 'Mint 你的新一天！',
  });

  static const UserProfileModel defaultProfile = UserProfileModel();

  UserProfileModel copyWith({
    String? nickname,
    String? avatarAssetPath,
    AvatarConfig? avatarConfig,
    String? welcomeMessage,
    bool clearAvatarAsset = false,
    bool clearAvatarConfig = false,
  }) {
    return UserProfileModel(
      nickname: nickname ?? this.nickname,
      avatarAssetPath: clearAvatarAsset
          ? null
          : (avatarAssetPath ?? this.avatarAssetPath),
      avatarConfig: clearAvatarConfig
          ? null
          : (avatarConfig ?? this.avatarConfig),
      welcomeMessage: welcomeMessage ?? this.welcomeMessage,
    );
  }
}
