import 'models.dart';

class ClinicSnapshot {
  const ClinicSnapshot({
    required this.profile,
    required this.signedIn,
    required this.patients,
    required this.procedures,
    required this.sequence,
  });

  final DentistProfile profile;
  final bool signedIn;
  final List<Patient> patients;
  final List<Procedure> procedures;
  final int sequence;

  ClinicSnapshot copyWith({
    DentistProfile? profile,
    bool? signedIn,
    List<Patient>? patients,
    List<Procedure>? procedures,
    int? sequence,
  }) {
    return ClinicSnapshot(
      profile: profile ?? this.profile,
      signedIn: signedIn ?? this.signedIn,
      patients: patients ?? this.patients,
      procedures: procedures ?? this.procedures,
      sequence: sequence ?? this.sequence,
    );
  }
}
