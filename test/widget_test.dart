import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:anime_verse/data/dummy_data.dart';
import 'package:anime_verse/main.dart';
import 'package:anime_verse/providers/app_state_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App starts on the sign in screen', (WidgetTester tester) async {
    // Gunakan ukuran layar ponsel (360x800 logical pixels)
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Welcome Back!'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
  });

  test('AppStateProvider toggles favorites and filters anime list', () async {
    final provider = AppStateProvider();
    final sampleAnime = DummyData.animeList.first;

    expect(provider.isFavorite(sampleAnime.id), isFalse);
    expect(provider.favorites.isEmpty, isTrue);

    provider.toggleFavorite(sampleAnime);
    expect(provider.isFavorite(sampleAnime.id), isTrue);
    expect(provider.favorites.length, 1);

    // Test search filter on home
    provider.setHomeSearchQuery('Clover');
    final searchResult = provider.getFilteredAnimeForHome();
    expect(searchResult.any((a) => a.id == sampleAnime.id), isTrue);

    // Test genre filter
    provider.setHomeSearchQuery('');
    provider.setSelectedGenre('Action');
    final actionResult = provider.getFilteredAnimeForHome();
    expect(actionResult.isNotEmpty, isTrue);
    for (final anime in actionResult) {
      expect(anime.genre.contains('Action'), isTrue);
    }

    // Toggle off favorite
    provider.toggleFavorite(sampleAnime);
    expect(provider.isFavorite(sampleAnime.id), isFalse);
    expect(provider.favorites.isEmpty, isTrue);
  });
}
