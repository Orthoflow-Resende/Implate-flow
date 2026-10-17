class AppConfig {
  const AppConfig._();

  static const workOsClientId = String.fromEnvironment('WORKOS_CLIENT_ID');

  static const workOsRedirectUri = String.fromEnvironment(
    'WORKOS_REDIRECT_URI',
    defaultValue: 'br.com.implateflow://auth/callback',
  );
}
