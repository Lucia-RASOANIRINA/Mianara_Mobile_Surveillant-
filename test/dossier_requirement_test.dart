import 'package:flutter_test/flutter_test.dart';
import 'package:mianara_mobile/models/candidate.dart';
import 'package:mianara_mobile/models/dossier_requirement.dart';

void main() {
  group('requirementsFor', () {
    test('uses the checklist for the exact profile described in the brief', () {
      final requirements = requirementsFor(
        const Candidate(examCenter: 'Fianarantsoa'),
      );

      expect(
        requirements.map((item) => item.id),
        contains('school_certificate'),
      );
      expect(requirements, hasLength(5));
    });

    test('does not assume requirements for an undocumented profile', () {
      final requirements = requirementsFor(
        const Candidate(examCenter: 'Toamasina'),
      );

      expect(requirements, isEmpty);
    });
  });
}
