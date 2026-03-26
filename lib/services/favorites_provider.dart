import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/video.dart';

class FavoritesProvider extends ChangeNotifier {
  static const _key = 'favorites';
  List<Video> _favorites = [];

  List<Video> get favorites => _favorites;

  FavoritesProvider() {
    _load();
  }

  bool isFav(String id) => _favorites.any((v) => v.id == id);

  Future<void> toggle(Video video) async {
    if (isFav(video.id)) {
      _favorites.removeWhere((v) => v.id == video.id);
    } else {
      _favorites.add(video);
    }
    notifyListeners();
    await _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _favorites.map((v) => jsonEncode(v.toJson())).toList();
    await prefs.setStringList(_key, data);
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_key) ?? [];
    _favorites = data.map((s) {
      final json = jsonDecode(s) as Map<String, dynamic>;
      return Video.fromLocalJson(json);
    }).toList();
    notifyListeners();
  }
}
