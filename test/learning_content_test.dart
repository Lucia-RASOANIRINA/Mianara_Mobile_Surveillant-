import 'package:flutter_test/flutter_test.dart';
import 'package:mianara_mobile/models/learning_content.dart';

void main() {
  group('LearningCatalog', () {
    test('reads the configurable merchant number with approved items', () {
      final catalog = LearningCatalog.fromJson({
        'items': [
          {
            'id': 'course-1',
            'kind': 'course',
            'subjectCode': 'MATH',
            'title': 'Algèbre',
            'description': 'Présentation',
            'content': 'Contenu complet',
            'priceAmount': null,
            'currency': 'MGA',
            'durationMinutes': 30,
            'purchased': true,
          },
        ],
        'payment': {'merchantNumber': '+261 34 00 000 00'},
      });

      expect(catalog.items, hasLength(1));
      expect(catalog.merchantNumber, '+261 34 00 000 00');
    });

    test('rejects a malformed merchant number', () {
      expect(
        () => LearningCatalog.fromJson({
          'items': [],
          'payment': {'merchantNumber': 123},
        }),
        throwsFormatException,
      );
    });
  });

  group('LearningItem', () {
    test('full content remains gated by the server purchase flag', () {
      final unpaid = LearningItem.fromJson({
        'id': 'course-1',
        'kind': 'course',
        'subjectCode': 'MATH',
        'title': 'Algèbre',
        'description': 'Présentation',
        'content': 'Contenu complet',
        'priceAmount': 12000,
        'currency': 'MGA',
        'durationMinutes': 30,
        'purchased': false,
      });
      final paid = LearningItem.fromJson({
        ...unpaid.toJson(),
        'purchased': true,
      });

      expect(unpaid.accessibleContent, isNull);
      expect(unpaid.canSubmitCoachingPayment, isFalse);
      expect(paid.accessibleContent, 'Contenu complet');
      expect(paid.canSubmitCoachingPayment, isFalse);
    });

    test('only unpaid coaching items can submit a coaching payment', () {
      final coaching = LearningItem.fromJson({
        'id': 'listing-1',
        'kind': 'coaching',
        'subjectCode': 'MATH',
        'title': 'Private title',
        'description': 'Private description',
        'content': 'Private content',
        'priceAmount': 20000,
        'currency': 'MGA',
        'durationMinutes': 60,
        'purchased': false,
        'paymentStatus': 'rejected',
        'teacherName': 'Must not be retained',
      });

      expect(coaching.canSubmitCoachingPayment, isTrue);
      expect(coaching.toJson().containsKey('teacherName'), isFalse);
      expect(coaching.paymentStatus, 'rejected');
      expect(
        LearningItem.fromJson({...coaching.toJson(), 'purchased': true})
            .canSubmitCoachingPayment,
        isFalse,
      );
      expect(
        LearningItem.fromJson({
          ...coaching.toJson(),
          'paymentStatus': 'pending',
        }).canSubmitCoachingPayment,
        isFalse,
      );
    });

    test(
      'rejects malformed purchase state rather than defaulting unlocked',
      () {
        expect(
          () => LearningItem.fromJson({
            'id': 'course-1',
            'kind': 'course',
            'subjectCode': 'MATH',
            'title': 'Algèbre',
            'description': '',
            'content': 'Complet',
            'priceAmount': null,
            'currency': 'MGA',
            'durationMinutes': null,
          }),
          throwsFormatException,
        );
      },
    );
  });

  group('CoachingSession', () {
    test('allows chat only for active server-returned sessions', () {
      final active = CoachingSession.fromJson({
        'id': 'session-1',
        'listingId': 'listing-1',
        'subjectCode': 'MATH',
        'teacherSubject': 'Mathématiques',
        'status': 'active',
        'teacherName': 'Ignored identity',
      });
      final pending = CoachingSession.fromJson({
        'id': 'session-2',
        'listingId': 'listing-1',
        'subjectCode': 'MATH',
        'teacherSubject': 'Mathématiques',
        'status': 'pending_payment',
      });

      expect(active.canChat, isTrue);
      expect(pending.canChat, isFalse);
    });
  });
}
