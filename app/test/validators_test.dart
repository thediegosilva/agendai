import 'package:agendai/features/auth/presentation/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('validateEmail', () {
    test('rejeita vazio e formato inválido', () {
      expect(validateEmail(''), isNotNull);
      expect(validateEmail('maria@'), isNotNull);
    });
    test('aceita e-mail válido', () {
      expect(validateEmail('maria@email.com'), isNull);
    });
  });

  test('validateNewPassword exige 8 caracteres', () {
    expect(validateNewPassword('1234567'), isNotNull);
    expect(validateNewPassword('12345678'), isNull);
  });
}
