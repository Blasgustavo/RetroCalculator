import 'package:flutter/foundation.dart';

import '../data/skin_repository.dart';
import '../domain/skin.dart';

class SkinController extends ChangeNotifier {
  Skin _selected = Skin.classicAmber;
  List<Skin> _catalog = const <Skin>[Skin.classicAmber, Skin.lcdClasica];

  Skin get selected => _selected;

  List<Skin> get catalog => List<Skin>.unmodifiable(_catalog);

  Future<void> loadCatalog(SkinRepository repository) async {
    _catalog = await repository.load();
    notifyListeners();
  }

  void select(String id) {
    for (final Skin skin in catalog) {
      if (skin.id == id) {
        _selected = skin;
        notifyListeners();
        return;
      }
    }
  }

  void reset() => select(Skin.classicAmber.id);
}
