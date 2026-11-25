import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_calculator/features/skins/data/skin_repository.dart';
import 'package:retro_calculator/features/skins/presentation/skin_controller.dart';

void main() {
  test(
    'selecciona LCD, ignora IDs desconocidos y vuelve al tema gratuito',
    () async {
      final SkinController controller = SkinController();
      await controller.loadCatalog(const SkinRepository());
      expect(controller.catalog, hasLength(2));
      controller.select('lcd_classica');
      expect(controller.selected.id, 'lcd_classica');
      expect(controller.selected.tokens.segmentOn, const Color(0xFFB8E986));
      controller.select('inexistente');
      expect(controller.selected.id, 'lcd_classica');
      controller.reset();
      expect(controller.selected.id, 'classic_amber');
      expect(controller.selected.tokens.segmentOn, const Color(0xFFFFB000));
    },
  );
}
