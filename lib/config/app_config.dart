class AppConfig {
  const AppConfig._();

  static const String _defaultSupabaseUrl =
      'https://ryzedpbkzspwvrnrppij.supabase.co';

  // The previous project key was rejected by Supabase. A fresh client-safe
  // publishable/anon key is therefore supplied at launch instead of baking a
  // stale value into the source code.
  static const String _urlDefine = String.fromEnvironment('SUPABASE_URL');
  static const String _publishableDefine =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  static const String _anonDefine = String.fromEnvironment('SUPABASE_ANON_KEY');

  static String _clean(String value) {
    return value
        .trim()
        .replaceAll('"', '')
        .replaceAll("'", '')
        .replaceAll(',', '')
        .trim();
  }

  static bool _looksLikeUrl(String value) {
    final Uri? uri = Uri.tryParse(value);
    return uri != null &&
        uri.scheme == 'https' &&
        uri.host.endsWith('.supabase.co');
  }

  static bool _looksLikeClientKey(String value) {
    return value.startsWith('sb_publishable_') || value.startsWith('eyJ');
  }

  static String get supabaseUrl {
    final String candidate = _clean(_urlDefine);
    return _looksLikeUrl(candidate) ? candidate : _defaultSupabaseUrl;
  }

  static String get supabasePublishableKey {
    final String publishable = _clean(_publishableDefine);
    if (_looksLikeClientKey(publishable)) return publishable;

    final String anon = _clean(_anonDefine);
    if (_looksLikeClientKey(anon)) return anon;

    return '';
  }

  static bool get isSupabaseConfigured =>
      _looksLikeUrl(supabaseUrl) &&
      _looksLikeClientKey(supabasePublishableKey);
}
