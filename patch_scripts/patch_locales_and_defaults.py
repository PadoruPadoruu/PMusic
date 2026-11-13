import re
from pathlib import Path

def patch_app_strings():
    path = Path('lib/features/music/presentation/providers/app_strings.dart')
    if not path.exists():
        print(f"[SKIP] {path} not found.")
        return

    content = path.read_text(encoding='utf-8')

    # Replace enum AppLanguage and extension AppLanguageLabel with the enhanced enum version
    pattern = re.compile(
        r"enum AppLanguage \{.*?extension AppLanguageLabel on AppLanguage \{.*?\n\}\n",
        re.DOTALL,
    )

    replacement = """enum AppLanguage {
  english,
  spanish,
  portuguese,
  french,
  korean,
  chinese,
  traditionalChinese,
  japanese;

  String get label => switch (this) {
    AppLanguage.spanish => 'Español',
    AppLanguage.english => 'English',
    AppLanguage.portuguese => 'Português',
    AppLanguage.french => 'Français',
    AppLanguage.korean => '한국어',
    AppLanguage.chinese => '简体中文',
    AppLanguage.traditionalChinese => '繁體中文',
    AppLanguage.japanese => '日本語',
  };

  String get code => switch (this) {
    AppLanguage.spanish => 'es',
    AppLanguage.english => 'en',
    AppLanguage.portuguese => 'pt',
    AppLanguage.french => 'fr',
    AppLanguage.korean => 'ko',
    AppLanguage.chinese => 'zh',
    AppLanguage.traditionalChinese => 'zh_TW',
    AppLanguage.japanese => 'ja',
  };

  static AppLanguage fromCode(String? code) => AppLanguageLabel.fromCode(code);
}

String systemFontNameForPlatform(AppPlatformType platform) =>
    switch (platform) {
      AppPlatformType.android || AppPlatformType.linux => 'Roboto',
      AppPlatformType.ios || AppPlatformType.macos => 'San Francisco',
      AppPlatformType.windows => 'Segoe UI',
      AppPlatformType.unsupported => 'System',
    };

extension AppLanguageLabel on AppLanguage {
  static AppLanguage fromCode(String? code) {
    return switch (code) {
      'es' => AppLanguage.spanish,
      'en' => AppLanguage.english,
      'pt' => AppLanguage.portuguese,
      'fr' => AppLanguage.french,
      'ko' => AppLanguage.korean,
      'zh' => AppLanguage.chinese,
      'zh_TW' || 'zh_HK' || 'zh-Hant' => AppLanguage.traditionalChinese,
      'ja' => AppLanguage.japanese,
      _ => AppLanguage.english,
    };
  }
}
"""
    if pattern.search(content):
        content = pattern.sub(replacement, content, count=1)
        path.write_text(content, encoding='utf-8')
        print(f"[OK] Patched {path}")
    else:
        print(f"[INFO] {path} already patched or structure changed.")


def patch_provider_fallbacks():
    files_to_flip = [
        Path('lib/main.dart'),
        Path('lib/features/music/presentation/providers/app_strings_provider.dart'),
        Path('lib/features/music/presentation/providers/music_providers.dart'),
    ]

    for path in files_to_flip:
        if not path.exists():
            continue
        content = path.read_text(encoding='utf-8')
        updated = content.replace(
            '?? AppLanguage.spanish', '?? AppLanguage.english'
        ).replace(
            "artist: entry.artist.isEmpty ? 'Desconocido' : entry.artist",
            "artist: entry.artist.isEmpty ? 'Unknown' : entry.artist",
        )

        if path.name == 'main.dart' and "scriptCode: 'Hant'" not in updated:
            updated = updated.replace(
                "locale: Locale(language.code),",
                "locale: language == AppLanguage.traditionalChinese\n"
                "          ? const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant', countryCode: 'TW')\n"
                "          : Locale(language.code),",
            )
            updated = updated.replace(
                "Locale('zh'),",
                "Locale('zh'),\n"
                "        Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant', countryCode: 'TW'),\n"
                "        Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant', countryCode: 'HK'),",
            )

        if updated != content:
            path.write_text(updated, encoding='utf-8')
            print(f"[OK] Updated fallbacks in {path}")

    # Patch Spanish StateError messages in settings_controller.dart
    settings_path = Path('lib/features/music/presentation/providers/settings_controller.dart')
    if settings_path.exists():
        sc = settings_path.read_text(encoding='utf-8')
        replacements = {
            'No se pudo preparar la migración de descargas.': 'Could not prepare downloads migration.',
            'No se pudo cerrar la migración de descargas.': 'Could not close downloads migration.',
            'No se pudo guardar el directorio de descargas.': 'Could not save downloads directory.',
            'No se pudo guardar el fondo de la app.': 'Could not save app background.',
            'No se pudo quitar el fondo de la app.': 'Could not remove app background.',
        }
        for es_str, en_str in replacements.items():
            sc = sc.replace(es_str, en_str)
        settings_path.write_text(sc, encoding='utf-8')
        print(f"[OK] Patched StateError strings in {settings_path}")


if __name__ == '__main__':
    patch_app_strings()
    patch_provider_fallbacks()