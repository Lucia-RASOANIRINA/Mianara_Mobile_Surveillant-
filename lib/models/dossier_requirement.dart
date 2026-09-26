import 'candidate.dart';

class DossierRequirement {
  const DossierRequirement({required this.id, required this.label});

  final String id;
  final String label;
}

List<DossierRequirement> requirementsFor(Candidate candidate) {
  final matchesDocumentedExample =
      candidate.examType == 'Baccalauréat' &&
      candidate.examSeries == 'S' &&
      candidate.examCenter.toLowerCase().contains('fianarantsoa') &&
      candidate.candidateStatus == 'Scolaire' &&
      candidate.firstParticipation;
  if (!matchesDocumentedExample) return const [];

  final requirements = <DossierRequirement>[
    const DossierRequirement(
      id: 'birth_certificate',
      label: 'Copie de l’acte de naissance',
    ),
    const DossierRequirement(
      id: 'school_certificate',
      label: 'Certificat de scolarité',
    ),
    const DossierRequirement(id: 'identity_photos', label: 'Photos d’identité'),
    const DossierRequirement(
      id: 'registration_form',
      label: 'Formulaire d’inscription',
    ),
    const DossierRequirement(
      id: 'registration_fee',
      label: 'Frais d’inscription',
    ),
  ];

  return requirements;
}
