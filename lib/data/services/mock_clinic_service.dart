import '../../domain/clinic_snapshot.dart';
import '../../domain/models.dart';

class MockClinicService {
  ClinicSnapshot load() => buildDemoSnapshot();
}

ClinicSnapshot buildDemoSnapshot() {
  var sequence = 0;
  String nextId(String prefix) {
    sequence += 1;
    return '$prefix-$sequence';
  }
  final patients = <Patient>[];
  final procedures = <Procedure>[];
    final today = dateOnly(DateTime.now());
    DateTime shift(int days) => today.add(Duration(days: days));

    final maria = Patient(
      id: nextId('pac'),
      name: 'Maria Souza',
      phone: '(11) 98888-1001',
      cpf: '390.533.447-05',
      birthDate: DateTime(1978, 4, 12),
    );
    final joao = Patient(
      id: nextId('pac'),
      name: 'João Lima',
      phone: '(11) 97777-2002',
      cpf: '529.982.247-25',
      birthDate: DateTime(1965, 9, 3),
    );
    final ana = Patient(
      id: nextId('pac'),
      name: 'Ana Costa',
      phone: '(21) 96666-3003',
      cpf: '153.509.460-56',
      birthDate: DateTime(1984, 1, 28),
    );
    final pedro = Patient(
      id: nextId('pac'),
      name: 'Pedro Alves',
      phone: '(31) 95555-4004',
      cpf: '111.444.777-35',
      birthDate: DateTime(2014, 7, 19),
      guardian: 'Lucia Alves',
    );
    patients.addAll([maria, joao, ana, pedro]);

    procedures.add(
      Procedure(
        id: nextId('pro'),
        patientId: maria.id,
        modality: Modality.unitario,
        surgeryDate: shift(-40),
        statusLabel: implantStatusLabel(ImplantStatus.osseointegracao),
        sites: [
          ToothSite(
            fdi: 36,
            role: ToothRole.pilar,
            piece: ImplantPiece(
              manufacturer: 'Neodent',
              model: 'Drive GM',
              size: '3.5 × 11.5 mm',
              serial: 'ND-36001',
              lot: 'L24-118',
              manufacturedOn: DateTime(2024, 11, 2),
              expiresOn: DateTime(2029, 11, 2),
              anvisa: '80123450001',
            ),
          ),
        ],
        visits: [
          Visit(
            id: nextId('con'),
            date: shift(-33),
            note: 'Sutura removida, sem intercorrência',
            statusLabel: implantStatusLabel(ImplantStatus.osseointegracao),
          ),
        ],
        followUps: [
          FollowUp(
            id: nextId('ret'),
            date: shift(-33),
            reason: ReturnReason.sutura,
            status: ReturnStatus.realizado,
            reminderEnabled: true,
            reminderHour: 8,
          ),
          FollowUp(
            id: nextId('ret'),
            date: shift(-1),
            reason: ReturnReason.osseointegracao,
            status: ReturnStatus.agendado,
            reminderEnabled: true,
            reminderHour: 8,
          ),
        ],
        photos: [
          ClinicPhoto(id: nextId('fot'), caption: 'Oclusal pós-operatória, dente 36'),
        ],
      ),
    );

    procedures.add(
      Procedure(
        id: nextId('pro'),
        patientId: joao.id,
        modality: Modality.ponte,
        surgeryDate: shift(-12),
        statusLabel: implantStatusLabel(ImplantStatus.instalado),
        sites: [
          ToothSite(
            fdi: 14,
            role: ToothRole.pilar,
            piece: ImplantPiece(
              manufacturer: 'Straumann',
              model: 'BLX',
              size: '3.75 × 10 mm',
              serial: 'ST-14002',
              lot: 'B25-014',
              manufacturedOn: DateTime(2025, 2, 1),
              expiresOn: DateTime(2030, 2, 1),
            ),
          ),
          ToothSite(fdi: 15, role: ToothRole.pontico),
          ToothSite(
            fdi: 16,
            role: ToothRole.pilar,
            piece: ImplantPiece(
              manufacturer: 'Straumann',
              model: 'BLX',
              size: '4.0 × 10 mm',
              serial: 'ST-16003',
              lot: 'B25-016',
              manufacturedOn: DateTime(2025, 2, 1),
              expiresOn: DateTime(2030, 2, 1),
            ),
          ),
        ],
        followUps: [
          FollowUp(
            id: nextId('ret'),
            date: shift(1),
            reason: ReturnReason.sutura,
            status: ReturnStatus.agendado,
            reminderEnabled: true,
            reminderHour: 8,
          ),
          FollowUp(
            id: nextId('ret'),
            date: shift(78),
            reason: ReturnReason.instalarPonte,
            status: ReturnStatus.agendado,
            reminderEnabled: true,
            reminderHour: 9,
          ),
        ],
      ),
    );

    procedures.add(
      Procedure(
        id: nextId('pro'),
        patientId: ana.id,
        modality: Modality.protocolo,
        arch: Arch.superior,
        surgeryDate: shift(-2),
        statusLabel: implantStatusLabel(ImplantStatus.instalado),
        notes: 'Pilar 16 com enxerto no mesmo ato',
        sites: [
          for (final tooth in [16, 14, 24, 26])
            ToothSite(
              fdi: tooth,
              role: ToothRole.pilar,
              piece: ImplantPiece(
                manufacturer: 'Nobel Biocare',
                model: 'NobelActive',
                size: tooth == 16 ? '4.3 × 13 mm' : '3.5 × 13 mm',
                serial: 'NB-$tooth',
              ),
              grafts: tooth == 16
                  ? [
                      GraftMaterial(
                        origin: GraftOrigin.biomaterial,
                        manufacturer: 'Geistlich',
                        model: 'Bio-Oss',
                        size: '0.5 g',
                        lot: 'GO-5521',
                        expiresOn: DateTime(2028, 6, 1),
                      ),
                    ]
                  : [],
            ),
        ],
        followUps: [
          FollowUp(
            id: nextId('ret'),
            date: today,
            reason: ReturnReason.sutura,
            status: ReturnStatus.agendado,
            reminderEnabled: true,
            reminderHour: 8,
          ),
          FollowUp(
            id: nextId('ret'),
            date: shift(180),
            reason: ReturnReason.instalarProtocolo,
            status: ReturnStatus.agendado,
            reminderEnabled: false,
            reminderHour: 8,
          ),
        ],
        photos: [
          ClinicPhoto(id: nextId('fot'), caption: 'Arcada superior, protocolo'),
        ],
      ),
    );

    procedures.add(
      Procedure(
        id: nextId('pro'),
        patientId: pedro.id,
        modality: Modality.enxerto,
        surgeryDate: shift(-20),
        statusLabel: graftStatusLabel(GraftStatus.maturacao),
        sites: [
          ToothSite(
            fdi: 46,
            role: ToothRole.pilar,
            grafts: [
              GraftMaterial(
                origin: GraftOrigin.autogeno,
                donorSite: 'Ramo mandibular direito',
              ),
            ],
          ),
        ],
        followUps: [
          FollowUp(
            id: nextId('ret'),
            date: shift(14),
            reason: ReturnReason.sutura,
            status: ReturnStatus.agendado,
            reminderEnabled: true,
            reminderHour: 8,
          ),
          FollowUp(
            id: nextId('ret'),
            date: shift(160),
            reason: ReturnReason.instalarImplante,
            status: ReturnStatus.agendado,
            reminderEnabled: true,
            reminderHour: 8,
          ),
        ],
      ),
    );
  return ClinicSnapshot(
    profile: const DentistProfile(
      name: 'Dra. Helena Vargas',
      email: 'helena@consultorio.exemplo',
      cro: 'CRO-SP 00000',
    ),
    signedIn: false,
    patients: patients,
    procedures: procedures,
    sequence: sequence,
  );
}
