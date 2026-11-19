final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

String? validateEmail(String? value) {
  if (value == null || value.trim().isEmpty) return 'Informe o e-mail';
  if (!_emailRegex.hasMatch(value.trim())) return 'E-mail inválido';
  return null;
}

String? validateNewPassword(String? value) {
  if (value == null || value.length < 8) {
    return 'A senha precisa ter pelo menos 8 caracteres';
  }
  return null;
}

String? validateName(String? value) {
  if (value == null || value.trim().length < 2) return 'Informe seu nome';
  return null;
}
