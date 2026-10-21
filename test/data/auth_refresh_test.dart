import 'package:flutter_test/flutter_test.dart';
import 'package:implate_flow/data/repositories/api_clinic_repository.dart';
import 'package:implate_flow/data/services/clinic_api.dart';
import 'package:implate_flow/domain/clinic_snapshot.dart';
import 'package:implate_flow/domain/models.dart';

void main() {
  test('401 dispara refresh e repete a chamada com o novo token', () async {
    final transport = _FakeTransport()..unauthorizedOnce = true;
    final repository = ApiClinicRepository(
      api: ClinicApi(baseUrl: 'http://127.0.0.1:3000', transport: transport),
      initial: _emptySnapshot,
    );
    var refreshes = 0;
    repository.bindUnauthorized(() async {
      refreshes++;
      return 'fresh-token';
    });
    repository.signIn(name: 'Ana', email: 'ana@example.com', accessToken: 'stale-token');
    await repository.refresh();

    expect(refreshes, 1);
    expect(repository.current.patients.single.name, 'Helena');
    expect(transport.tokens, ['stale-token', 'fresh-token']);
  });

  test('token vazio restaura sessão via refresh antes da primeira chamada', () async {
    final transport = _FakeTransport();
    final repository = ApiClinicRepository(
      api: ClinicApi(baseUrl: 'http://127.0.0.1:3000', transport: transport),
      initial: _emptySnapshot.copyWith(
        signedIn: true,
        profile: const DentistProfile(name: 'Ana', email: 'ana@example.com'),
      ),
    );
    var refreshes = 0;
    repository.bindUnauthorized(() async {
      refreshes++;
      return 'restored-token';
    });

    await repository.refresh();

    expect(refreshes, 1);
    expect(repository.current.patients.single.name, 'Helena');
    expect(transport.tokens, ['restored-token']);
  });

  test('refresh concorrente compartilhado não chama WorkOS duas vezes', () async {
    final transport = _FakeTransport();
    final repository = ApiClinicRepository(
      api: ClinicApi(baseUrl: 'http://127.0.0.1:3000', transport: transport),
      initial: _emptySnapshot.copyWith(signedIn: true),
    );
    var refreshes = 0;
    repository.bindUnauthorized(() async {
      refreshes++;
      await Future<void>.delayed(const Duration(milliseconds: 20));
      return 'shared-token';
    });

    await Future.wait([repository.refresh(), repository.refresh()]);

    expect(refreshes, 1);
    expect(transport.tokens, everyElement('shared-token'));
  });

  test('falha no refresh mantém o 401 original', () async {
    final transport = _FakeTransport()..unauthorizedOnce = true;
    final repository = ApiClinicRepository(
      api: ClinicApi(baseUrl: 'http://127.0.0.1:3000', transport: transport),
      initial: _emptySnapshot,
    );
    final errors = <String>[];
    repository.syncErrors.listen(errors.add);
    var refreshes = 0;
    repository.bindUnauthorized(() async {
      refreshes++;
      return null;
    });
    repository.signIn(name: 'Ana', email: 'ana@example.com', accessToken: 'stale-token');
    await repository.refresh();
    await repository.settled;

    expect(refreshes, 1);
    expect(errors, isNotEmpty);
    expect(transport.tokens.first, 'stale-token');
  });
}

const _emptySnapshot = ClinicSnapshot(
  profile: DentistProfile(name: '', email: ''),
  signedIn: false,
  patients: [],
  procedures: [],
  sequence: 0,
);

class _FakeTransport implements ClinicTransport {
  var unauthorizedOnce = false;
  final tokens = <String?>[];

  @override
  Future<ClinicHttpResponse> send({
    required String method,
    required String path,
    Object? body,
    String? token,
  }) async {
    tokens.add(token);
    if (unauthorizedOnce) {
      unauthorizedOnce = false;
      return const ClinicHttpResponse(
        statusCode: 401,
        body: {
          'error': {'message': 'Sessão expirada.'},
        },
      );
    }
    if (method == 'GET' && path == '/v1/chart') {
      return ClinicHttpResponse(statusCode: 200, body: _chart);
    }
    return ClinicHttpResponse(statusCode: 201, body: body);
  }
}

const _chart = {
  'profile': {
    'name': 'Ana Costa',
    'email': 'ana@example.com',
    'phone': '',
    'cro': 'RJ 12345',
    'reminderEnabled': true,
    'reminderDaysBefore': 15,
    'emailChannel': true,
    'pushChannel': true,
    'locations': <Map<String, Object?>>[],
  },
  'patients': [
    {
      'id': '11111111-1111-4111-8111-111111111111',
      'name': 'Helena',
      'phone': '',
      'email': '',
      'cpf': '',
      'locationIds': <String>[],
      'notifyByEmail': false,
      'notifyByPhone': false,
      'birthDate': '1980-01-02T00:00:00.000',
      'notes': '',
      'guardian': '',
    },
  ],
  'procedures': <Map<String, Object?>>[],
};
