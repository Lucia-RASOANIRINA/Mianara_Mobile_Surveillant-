import 'package:flutter_test/flutter_test.dart';
import 'package:mianara_mobile/models/candidate.dart';
import 'package:mianara_mobile/models/dossier_requirement.dart';

void main() {
  group('requirementsFor', () {
    test(
      'uses the documented checklist for an S-series candidate in Fianarantsoa',
      () {
        final requirements = requirementsFor(
          const Candidate(examCenter: 'Fianarantsoa'),
        );

        expect(
          requirements.map((item) => item.id),
          contains('school_certificate'),
        );
        expect(requirements, hasLength(5));
      },
    );

    test('does not assume requirements for an undocumented profile', () {
      final requirements = requirementsFor(
        const Candidate(examCenter: 'Toamasina'),
      );

      expect(requirements, isEmpty);
    });
  });

  group('Candidate.canonicalSeries', () {
    test('maps former general Bac series to the current reference codes', () {
      expect(Candidate.canonicalSeries('A1'), 'L');
      expect(Candidate.canonicalSeries('A2'), 'L');
      expect(Candidate.canonicalSeries('C'), 'S');
      expect(Candidate.canonicalSeries('D'), 'S');
      expect(Candidate.canonicalSeries('OSE'), 'OSE');
      expect(Candidate.canonicalSeries('TI'), 'TI');
      expect(Candidate.canonicalSeries('TGC'), 'TGC');
      expect(Candidate.canonicalSeries('TT'), 'TT');
      expect(Candidate.canonicalSeries('TA'), 'TA');
    });

    test(
      'loads old local Bac profiles without retaining a removed exam type',
      () {
        final candidate = Candidate.fromMap({
          'exam_type': 'BEPC',
          'exam_series': 'C',
        });

        expect(candidate.examType, 'Baccalauréat');
        expect(candidate.examSeries, 'S');
      },
    );
  });
}
