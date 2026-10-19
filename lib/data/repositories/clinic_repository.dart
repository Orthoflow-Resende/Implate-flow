import '../../domain/clinic_snapshot.dart';
import '../../domain/models.dart';

abstract class ClinicRepository {
  Stream<ClinicSnapshot> watch();

  Stream<String> get syncErrors => const Stream<String>.empty();

  ClinicSnapshot get current;

  List<String> get delayNoticeFollowUpIds;

  void applyOverdueNotices();

  void bindUnauthorized(Future<String?> Function() refresh) {}

  void signIn({required String name, required String email, String accessToken = ''});

  void signOut();

  Future<void> refresh() async {}

  Patient createPatient({
    required String name,
    required String phone,
    String email = '',
    String cpf = '',
    required DateTime birthDate,
    String notes = '',
    String guardian = '',
    List<String> locationIds = const [],
    bool notifyByEmail = false,
    bool notifyByPhone = false,
  });

  void updatePatient(Patient patient);

  void saveProcedures(List<Procedure> created);

  void updateProcedure(Procedure procedure);

  void addPhoto(String procedureId, ClinicPhoto photo);

  void addVisit({
    required String procedureId,
    required String note,
    required String statusLabel,
  });

  void completeFollowUp({
    required String followUpId,
    required String note,
    required String statusLabel,
    required ReturnStatus returnStatus,
  });

  void issueCertificate(String procedureId, {String? pdfPath});

  void reprocessStageNotice({required String procedureId, required String noticeId});

  void failStageNotice({required String procedureId, required String noticeId});

  void updateProfile(DentistProfile profile);

  String allocateId(String prefix);
}
