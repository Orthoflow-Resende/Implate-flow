import 'package:flutter_test/flutter_test.dart';
import 'package:implate_flow/data/repositories/api_clinic_repository.dart';
import 'package:implate_flow/data/services/clinic_api.dart';
import 'package:implate_flow/domain/clinic_snapshot.dart';
import 'package:implate_flow/domain/models.dart';

void main() {
  test('login carrega o prontuário e o paciente novo segue para a API', () async {
    final transport = _FakeTransport();
    final repository = ApiClinicRepository(
      api: ClinicApi(baseUrl: 'http://127.0.0.1:3000', transport: transport),
      initial: const ClinicSnapshot(
        profile: DentistProfile(name: '', email: ''),
        signedIn: false,
        patients: [],
        procedures: [],
        sequence: 0,
      ),
    );

    repository.signIn(name: 'Ana Costa', email: 'ana@example.com', accessToken: 'token');
    await repository.refresh();

    expect(repository.current.signedIn, isTrue);
    expect(repository.current.patients.single.name, 'Helena');
    expect(repository.current.profile.cro, '12345/RJ');

    final created = repository.createPatient(
      name: 'João Lima',
      phone: '21988887777',
      birthDate: DateTime(1981, 3, 4),
    );
    await repository.settled;

    expect(created.id, matches(RegExp(r'^[0-9a-f-]{36}$')));
    final post = transport.calls.where((call) => call.method == 'POST' && call.path == '/v1/patients').single;
    final body = post.body as Map<String, Object?>;
    expect(body['id'], created.id);
    expect(body['birthDate'], '1981-03-04');
    expect(post.token, 'token');
  });

  test('erro da API volta para o prontuário do servidor', () async {
    final transport = _FakeTransport()..rejectPatients = true;
    final repository = ApiClinicRepository(
      api: ClinicApi(baseUrl: 'http://127.0.0.1:3000', transport: transport),
      initial: const ClinicSnapshot(
        profile: DentistProfile(name: '', email: ''),
        signedIn: false,
        patients: [],
        procedures: [],
        sequence: 0,
      ),
    );
    final errors = <String>[];
    repository.syncErrors.listen(errors.add);
    repository.signIn(name: 'Ana', email: 'ana@example.com', accessToken: 'token');
    await repository.refresh();
    repository.createPatient(name: 'João Lima', phone: '', birthDate: DateTime(1981, 3, 4));
    await repository.settled;
    expect(errors, ['Informe o nome do paciente.']);
    expect(repository.current.patients.single.name, 'Helena');
  });
}

class _FakeTransport implements ClinicTransport {
  var rejectPatients = false;
  final calls = <({String method, String path, Object? body, String? token})>[];

  @override
  Future<ClinicHttpResponse> send({
    required String method,
    required String path,
    Object? body,
    String? token,
  }) async {
    calls.add((method: method, path: path, body: body, token: token));
    if (method == 'GET' && path == '/v1/chart') {
      return ClinicHttpResponse(statusCode: 200, body: _chart);
    }
    if (rejectPatients && method == 'POST' && path == '/v1/patients') {
      return const ClinicHttpResponse(
        statusCode: 400,
        body: {
          'error': {'message': 'Informe o nome do paciente.'},
        },
      );
    }
    if (method == 'PUT' && path.endsWith('/locations')) {
      return const ClinicHttpResponse(statusCode: 200, body: {'locationIds': <String>[]});
    }
    return ClinicHttpResponse(statusCode: 201, body: body);
  }
}

const _chart = {
  'profile': {
    'name': 'Ana Costa',
    'email': 'ana@example.com',
    'phone': '',
    'cro': '12345/RJ',
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
