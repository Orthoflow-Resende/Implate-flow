import 'models.dart';

class ClinicSnapshot {
  const ClinicSnapshot({
    required this.profile,
    required this.signedIn,
    required this.patients,
    required this.procedures,
    required this.sequence,
    this.implants = const [],
  });

  final DentistProfile profile;
  final bool signedIn;
  final List<Patient> patients;
  final List<Procedure> procedures;
  final List<InstalledImplant> implants;
  final int sequence;

  List<InstalledImplant> implantsFor(String patientId, {bool activeOnly = false}) {
    return [
      for (final implant in implants)
        if (implant.patientId == patientId && (!activeOnly || implant.active)) implant,
    ];
  }

  ClinicSnapshot copyWith({
    DentistProfile? profile,
    bool? signedIn,
    List<Patient>? patients,
    List<Procedure>? procedures,
    List<InstalledImplant>? implants,
    int? sequence,
  }) {
    return ClinicSnapshot(
      profile: profile ?? this.profile,
      signedIn: signedIn ?? this.signedIn,
      patients: patients ?? this.patients,
      procedures: procedures ?? this.procedures,
      implants: implants ?? this.implants,
      sequence: sequence ?? this.sequence,
    );
  }
}
