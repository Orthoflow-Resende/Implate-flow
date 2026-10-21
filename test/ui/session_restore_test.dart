import 'package:flutter_test/flutter_test.dart';
import 'package:implate_flow/data/repositories/api_clinic_repository.dart';
import 'package:implate_flow/data/services/clinic_api.dart';
import 'package:implate_flow/data/services/workos_auth.dart';
import 'package:implate_flow/domain/clinic_snapshot.dart';
import 'package:implate_flow/domain/models.dart';
import 'package:implate_flow/ui/view_models.dart';

void main() {
  test('sessão local restaura access token via currentIdentity', () async {
    final transport = _FakeTransport();
    final repository = ApiClinicRepository(
      api: ClinicApi(baseUrl: 'http://127.0.0.1:3000', transport: transport),
      initial: const ClinicSnapshot(
        profile: DentistProfile(name: 'Ana Local', email: 'ana@example.com'),
        signedIn: true,
        patients: [],
        procedures: [],
        sequence: 0,
      ),
    );
    final auth = _RecordingAuth(
      identity: const WorkOsIdentity(
        id: 'user_1',
        email: 'ana@example.com',
        name: 'Ana WorkOS',
        accessToken: 'restored-token',
      ),
    );

    final session = SessionViewModel(
      repository,
      auth,
      workOsClientId: 'client_test',
    );
    await session.restored;
    await repository.settled;

    expect(session.signedIn, isTrue);
    expect(auth.currentIdentityCalls, 1);
    expect(repository.current.profile.name, 'Ana Costa');
    expect(transport.tokens, ['restored-token']);
  });

  test('401 após restore usa currentIdentity de novo', () async {
    final transport = _FakeTransport()..unauthorizedOnce = true;
    final repository = ApiClinicRepository(
      api: ClinicApi(baseUrl: 'http://127.0.0.1:3000', transport: transport),
      initial: const ClinicSnapshot(
        profile: DentistProfile(name: 'Ana', email: 'ana@example.com'),
        signedIn: true,
        patients: [],
        procedures: [],
        sequence: 0,
      ),
    );
    final tokens = <String>['token-a', 'token-b'];
    final auth = _RecordingAuth(
      identityBuilder: () {
        final token = tokens.isEmpty ? 'token-b' : tokens.removeAt(0);
        return WorkOsIdentity(
          id: 'user_1',
          email: 'ana@example.com',
          name: 'Ana',
          accessToken: token,
        );
      },
    );

    final session = SessionViewModel(
      repository,
      auth,
      workOsClientId: 'client_test',
    );
    await session.restored;
    await repository.settled;

    expect(auth.currentIdentityCalls, 2);
    expect(transport.tokens, containsAll(['token-a', 'token-b']));
    expect(repository.current.patients.single.name, 'Helena');
  });
}

class _RecordingAuth implements WorkOsAuth {
  _RecordingAuth({WorkOsIdentity? identity, WorkOsIdentity Function()? identityBuilder})
      : _identity = identity,
        _identityBuilder = identityBuilder;

  final WorkOsIdentity? _identity;
  final WorkOsIdentity Function()? _identityBuilder;
  var currentIdentityCalls = 0;

  @override
  Future<WorkOsIdentity> signIn({required String clientId, required String redirectUri}) {
    throw UnimplementedError();
  }

  @override
  Future<WorkOsIdentity?> currentIdentity({required String clientId}) async {
    currentIdentityCalls++;
    expect(clientId, 'client_test');
    return _identityBuilder?.call() ?? _identity;
  }

  @override
  Future<void> signOut({required String redirectUri}) async {}
}

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
