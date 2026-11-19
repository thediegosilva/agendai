import 'package:material_ui/material_ui.dart';

/// Deduz o tipo do negócio pelo nome/descrição para escolher ícone e rótulo.
({IconData icon, String label}) businessCategory(String name, [String? desc]) {
  final t = '$name ${desc ?? ''}'.toLowerCase();
  bool has(List<String> words) => words.any(t.contains);
  if (has(['barbear', 'barber'])) {
    return (icon: Icons.content_cut_rounded, label: 'Barbearia');
  }
  if (has(['tatu', 'tattoo', 'ink', 'piercing'])) {
    return (icon: Icons.draw_rounded, label: 'Estúdio de tatuagem');
  }
  if (has(['unha', 'manicure', 'nail', 'esmalt'])) {
    return (icon: Icons.spa_rounded, label: 'Manicure');
  }
  if (has([
    'clínica',
    'clinica',
    'odonto',
    'fisio',
    'estética',
    'estetica',
    'saúde',
    'saude',
    'consult',
  ])) {
    return (icon: Icons.favorite_rounded, label: 'Clínica');
  }
  if (has([
    'salão',
    'salao',
    'beleza',
    'studio',
    'estúdio',
    'cabel',
    'hair',
    'makeup',
    'maquiag',
  ])) {
    return (icon: Icons.auto_awesome_rounded, label: 'Salão de beleza');
  }
  if (has(['pet', 'banho e tosa', 'veterin'])) {
    return (icon: Icons.pets_rounded, label: 'Pet shop');
  }
  return (icon: Icons.storefront_rounded, label: 'Estabelecimento');
}

/// Ícone de um serviço pelo nome.
IconData serviceIcon(String name) {
  final t = name.toLowerCase();
  bool has(List<String> words) => words.any(t.contains);
  if (has(['barba'])) return Icons.face_rounded;
  if (has(['corte', 'cabelo', 'tesoura'])) return Icons.content_cut_rounded;
  if (has(['unha', 'manicure', 'pedicure'])) return Icons.spa_rounded;
  if (has(['tatu', 'tattoo'])) return Icons.draw_rounded;
  if (has(['massag', 'relax'])) return Icons.self_improvement_rounded;
  if (has(['sobrancelha', 'cílio', 'cilio'])) return Icons.visibility_rounded;
  if (has(['color', 'luzes', 'tintura', 'mecha'])) return Icons.palette_rounded;
  if (has(['limpeza', 'pele', 'facial'])) return Icons.face_retouching_natural;
  return Icons.auto_awesome_rounded;
}
