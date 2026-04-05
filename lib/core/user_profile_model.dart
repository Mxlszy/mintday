/// 主控台用户资料快照（后续可接 DatabaseService / 同步扩展字段）。
class UserProfileModel {
  /// 展示昵称（当前产品默认）。
  final String nickname;

  /// 像素头像资源路径；为 null 时使用程序生成的像素角色。
  final String? avatarAssetPath;

  /// 头像旁欢迎语。
  final String welcomeMessage;

  const UserProfileModel({
    this.nickname = '忠实用户',
    this.avatarAssetPath,
    this.welcomeMessage = 'Mint 你的新一天！',
  });

  /// 默认主控台展示配置。
  static const UserProfileModel defaultProfile = UserProfileModel();

  UserProfileModel copyWith({
    String? nickname,
    String? avatarAssetPath,
    String? welcomeMessage,
    bool clearAvatarAsset = false,
  }) {
    return UserProfileModel(
      nickname: nickname ?? this.nickname,
      avatarAssetPath:
          clearAvatarAsset ? null : (avatarAssetPath ?? this.avatarAssetPath),
      welcomeMessage: welcomeMessage ?? this.welcomeMessage,
    );
  }
}
