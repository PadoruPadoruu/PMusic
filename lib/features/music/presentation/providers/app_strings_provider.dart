part of 'music_providers.dart';

final appStringsProvider = Provider<AppStrings>((ref) {
  final language = ref.watch(
    settingsControllerProvider.select(
      (settings) => settings.value?.language ?? AppLanguage.english,
    ),
  );
  return AppStrings(language);
});
