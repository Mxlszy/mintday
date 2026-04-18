class SupabaseConfig {
  const SupabaseConfig._();

  static const String url = 'https://mmrkfilgxneqvflpzrko.supabase.co';
  static const String anonKey =
      'sb_publishable_CNlm5DjSvPD7toKphGA9zg_6RjfZnPr';

  static bool get isConfigured =>
      !url.startsWith('YOUR_') && !anonKey.startsWith('YOUR_');
}
