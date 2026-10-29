import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/dummy_data.dart';
import '../models/anime.dart';

class AppStateProvider extends ChangeNotifier {
  // 1. STATE (Data Privat)
  // Ini adalah "Source of Truth" kita.
  // Data ini privat (diawali '_') agar tidak bisa diubah dari luar class.
  List<Anime> _favorites = [];
  static const String _storageKey = 'favorite_anime_list';
  String _selectedGenre = "All";
  String _homeSearchQuery = "";
  String _favoriteSearchQuery = "";

  // 2. GETTER (Akses Publik)
  // Widget lain hanya bisa 'mendapatkan' datanya, tidak bisa mengubah.
  List<Anime> get favorites => _favorites;
  String get selectedGenre => _selectedGenre;
  String get homeSearchQuery => _homeSearchQuery;
  String get favoriteSearchQuery => _favoriteSearchQuery;

  /// METHOD: Untuk update query HomeScreen
  void setHomeSearchQuery(String query) {
    _homeSearchQuery = query;
    notifyListeners();
  }

  /// METHOD: Untuk update query FavoriteScreen
  void setFavoriteSearchQuery(String query) {
    _favoriteSearchQuery = query;
    notifyListeners();
  }

  void setSelectedGenre(String genre) {
    _selectedGenre = genre;
    notifyListeners(); // Beri tahu listener (HomeScreen & GenreList)
  }

  List<Anime> getFilteredAnimeForHome() {
    List<Anime> result = DummyData.animeList;

    // Apply genre filter
    if (_selectedGenre != "All") {
      result = result.where((anime) {
        // Pecah genre string (misal: "Action, Adventure") menjadi list ["Action", "Adventure"]
        final genres = anime.genre.split(',').map((g) => g.trim()).toList();
        // Cek apakah list genre anime mengandung genre yang dipilih
        return genres.contains(_selectedGenre);
      }).toList();
    }

    // TERAPKAN FILTER SEARCH (setelah filter genre)
    if (_homeSearchQuery.isNotEmpty) {
      result = result.where((anime) {
        // Bandingkan dalam lowercase agar case-insensitive
        return anime.title
            .toLowerCase()
            .contains(_homeSearchQuery.toLowerCase());
      }).toList();
    }

    return result;
  }

  bool isFavorite(String animeId) {
    return _favorites.any((anime) => anime.id == animeId);
  }

  // Method utama untuk menambah atau menghapus dari favorit
  void toggleFavorite(Anime anime) {
    if (isFavorite(anime.id)) {
      removeFavorite(anime.id);
    } else {
      addFavorite(anime);
    }
  }

  void addFavorite(Anime anime) {
    if (!isFavorite(anime.id)) {
      _favorites.add(anime);
      _saveFavorites();
      notifyListeners();
    }
  }

  void removeFavorite(String animeId) {
    _favorites.removeWhere((anime) => anime.id == animeId);
    _saveFavorites();
    notifyListeners();
  }

  AppStateProvider() {
    _loadFavorites(); // Panggil _loadFavorites saat provider dibuat
  }

  // Simpan daftar favorit ke SharedPreferences
  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // 1. Konversi List<Anime> menjadi List<Map<String, dynamic>>
      final List<Map<String, dynamic>> favoritesJson = _favorites.map((anime) {
        return {
          'id': anime.id,
          'title': anime.title,
          'imagePath': anime.imagePath,
          'genre': anime.genre,
          'rating': anime.rating,
          'totalEpisodes': anime.totalEpisodes,
          'description': anime.description,
        };
      }).toList();
      // Encode List<Map> menjadi String JSON dan Simpan String JSON ke SharedPreferences
      await prefs.setString(_storageKey, json.encode(favoritesJson));
    } catch (e) {
      debugPrint('Error saving favorites: $e');
    }
  }

  /// Load favorites from SharedPreferences
  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // 1. Baca String JSON dari SharedPreferences
      final String? favoritesJson = prefs.getString(_storageKey);

      if (favoritesJson != null) {
        // 2. Decode String JSON menjadi List<dynamic> (List of Maps)
        final List<dynamic> decoded = json.decode(favoritesJson);
        // 3. Konversi List<dynamic> menjadi List<Anime>
        _favorites = decoded.map((item) {
          return Anime(
            id: item['id'],
            title: item['title'],
            imagePath: item['imagePath'],
            genre: item['genre'],
            rating: item['rating'],
            totalEpisodes: item['totalEpisodes'],
            description: item['description'],
          );
        }).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    }
  }

  /// Get filtered favorites for FavoriteScreen (based on favorite search)
  List<Anime> getFilteredFavorites() {
    List<Anime> result = _favorites; // Mulai dari daftar favorit

    // TERAPKAN FILTER SEARCH FAVORIT
    if (_favoriteSearchQuery.isNotEmpty) {
      result = result.where((anime) {
        return anime.title
            .toLowerCase()
            .contains(_favoriteSearchQuery.toLowerCase());
      }).toList();
    }

    return result;
  }
}
