import 'dart:io';

import 'package:flutter/services.dart';

class WorkOsIdentity {
  const WorkOsIdentity({required this.id, required this.email, required this.name});

  final String id;
  final String email;
  final String name;
}

class WorkOsAuthException implements Exception {
  const WorkOsAuthException(this.message);

  final String message;
}

abstract class WorkOsAuth {
  Future<WorkOsIdentity> signIn({required String clientId, required String redirectUri});

  Future<void> signOut({required String redirectUri});
}

class NativeWorkOsAuth implements WorkOsAuth {
  static const _channel = MethodChannel('br.com.implateflow/workos');

  @override
  Future<WorkOsIdentity> signIn({required String clientId, required String redirectUri}) async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      throw const WorkOsAuthException('O login do WorkOS está disponível no Android e no iOS.');
    }
    try {
      final result = await _channel.invokeMapMethod<String, String>('signIn', {
        'clientId': clientId,
        'redirectUri': redirectUri,
      });
      final id = result?['id'];
      final email = result?['email'];
      final name = result?['name'];
      if (id == null || email == null || name == null || id.isEmpty || email.isEmpty) {
        throw const WorkOsAuthException('Não foi possível concluir o login.');
      }
      return WorkOsIdentity(id: id, email: email, name: name);
    } on PlatformException catch (error) {
      throw WorkOsAuthException(error.message ?? 'Não foi possível concluir o login.');
    }
  }

  @override
  Future<void> signOut({required String redirectUri}) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    try {
      await _channel.invokeMethod<void>('signOut', {
        'redirectUri': redirectUri,
      });
    } on PlatformException catch (error) {
      throw WorkOsAuthException(error.message ?? 'Não foi possível sair.');
    }
  }
}
