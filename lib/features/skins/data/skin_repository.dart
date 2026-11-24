import '../domain/skin.dart';

class SkinRepository {
  const SkinRepository();

  Future<List<Skin>> load() async => const <Skin>[
    Skin.classicAmber,
    Skin.lcdClasica,
  ];
}
