import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/video.dart';

class FavoritesProvider extends ChangeNotifier {
  static const _key = 'favorites_v2';
  List<CinemanaVideo> _favs = [];
  List<CinemanaVideo> get favorites => _favs;

  FavoritesProvider() { _load(); }

  bool isFav(String id) => _favs.any((v) => v.id == id);

  Future<void> toggle(CinemanaVideo v) async {
    if (isFav(v.id)) {
      _favs.removeWhere((x) => x.id == v.id);
    } else {
      _favs.insert(0, v);
    }
    notifyListeners();
    await _save();
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_key, _favs.map((v) => jsonEncode(v.toJson())).toList());
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final list = p.getStringList(_key) ?? [];
    _favs = list.map((s) => CinemanaVideo.fromLocalJson(jsonDecode(s))).toList();
    notifyListeners();
  }
}
