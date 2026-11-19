/// URL da API. Sobrescreva com:
///   flutter run --dart-define=API_URL=http://10.0.2.2:3000   (emulador Android)
const apiUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://localhost:3000',
);
