class LearningCatalog {
  const LearningCatalog({required this.items, this.merchantNumber});

  final List<LearningItem> items;
  final String? merchantNumber;

  factory LearningCatalog.fromJson(Object? json) {
    if (json is! Map) {
      throw const FormatException('Catalogue pédagogique invalide.');
    }
    final value = Map<String, Object?>.from(json);
    final rawItems = value['items'];
    final payment = value['payment'];
    if (rawItems is! List || (payment != null && payment is! Map)) {
      throw const FormatException('Catalogue pédagogique invalide.');
    }
    final rawMerchantNumber = payment is Map ? payment['merchantNumber'] : null;
    if (rawMerchantNumber != null && rawMerchantNumber is! String) {
      throw const FormatException('Numéro marchand invalide.');
    }
    return LearningCatalog(
      items: rawItems.map(LearningItem.fromJson).toList(),
      merchantNumber: rawMerchantNumber as String?,
    );
  }
}

class LearningItem {
  const LearningItem({
    required this.id,
    required this.kind,
    required this.subjectCode,
    required this.title,
    required this.description,
    required this.content,
    required this.priceAmount,
    required this.currency,
    required this.durationMinutes,
    required this.purchased,
    this.paymentStatus,
  });

  final String id;
  final String kind;
  final String subjectCode;
  final String title;
  final String description;
  final String content;
  final num? priceAmount;
  final String currency;
  final int? durationMinutes;
  final bool purchased;
  final String? paymentStatus;

  String? get accessibleContent => purchased ? content : null;
  bool get canSubmitCoachingPayment =>
      kind == 'coaching' &&
      !purchased &&
      priceAmount != null &&
      paymentStatus != 'pending';

  factory LearningItem.fromJson(Object? json) {
    if (json is! Map) {
      throw const FormatException('Contenu pédagogique invalide.');
    }
    final value = Map<String, Object?>.from(json);
    final id = value['id'];
    final kind = value['kind'];
    final subjectCode = value['subjectCode'];
    final title = value['title'];
    final description = value['description'];
    final content = value['content'];
    final currency = value['currency'];
    final purchased = value['purchased'];
    final price = value['priceAmount'];
    final duration = value['durationMinutes'];
    if (id is! String ||
        kind is! String ||
        !const {'course', 'training', 'coaching'}.contains(kind) ||
        subjectCode is! String ||
        title is! String ||
        description is! String ||
        content is! String ||
        currency != 'MGA' ||
        purchased is! bool ||
        (price != null && price is! num) ||
        (duration != null && duration is! int)) {
      throw const FormatException('Contenu pédagogique invalide.');
    }
    final paymentStatus = value['paymentStatus'];
    return LearningItem(
      id: id,
      kind: kind,
      subjectCode: subjectCode,
      title: title,
      description: description,
      content: content,
      priceAmount: price as num?,
      currency: currency as String,
      durationMinutes: duration as int?,
      purchased: purchased,
      paymentStatus:
          paymentStatus is String &&
              const {'pending', 'approved', 'rejected'}.contains(paymentStatus)
          ? paymentStatus
          : null,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'kind': kind,
    'subjectCode': subjectCode,
    'title': title,
    'description': description,
    'content': content,
    'priceAmount': priceAmount,
    'currency': currency,
    'durationMinutes': durationMinutes,
    'purchased': purchased,
    if (paymentStatus != null) 'paymentStatus': paymentStatus,
  };
}

class CoachingSession {
  const CoachingSession({
    required this.id,
    required this.listingId,
    required this.subjectCode,
    required this.teacherSubject,
    required this.status,
  });

  final String id;
  final String listingId;
  final String subjectCode;
  final String teacherSubject;
  final String status;
  bool get canChat => status == 'active';

  factory CoachingSession.fromJson(Object? json) {
    if (json is! Map) {
      throw const FormatException('Séance de tutorat invalide.');
    }
    final value = Map<String, Object?>.from(json);
    if (value['id'] is! String ||
        value['listingId'] is! String ||
        value['subjectCode'] is! String ||
        value['teacherSubject'] is! String ||
        !const {'active', 'pending_payment'}.contains(value['status'])) {
      throw const FormatException('Séance de tutorat invalide.');
    }
    return CoachingSession(
      id: value['id']! as String,
      listingId: value['listingId']! as String,
      subjectCode: value['subjectCode']! as String,
      teacherSubject: value['teacherSubject']! as String,
      status: value['status']! as String,
    );
  }
}

class CoachingMessage {
  const CoachingMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String sender;
  final String text;
  final DateTime createdAt;

  factory CoachingMessage.fromJson(Object? json) {
    if (json is! Map) {
      throw const FormatException('Message de tutorat invalide.');
    }
    final value = Map<String, Object?>.from(json);
    final id = value['id'] ?? '';
    final sender = value['sender'];
    final text = value['text'];
    final createdAt = value['createdAt'];
    if (id is! String ||
        sender is! String ||
        !const {'teacher', 'candidate'}.contains(sender) ||
        text is! String ||
        createdAt is! String) {
      throw const FormatException('Message de tutorat invalide.');
    }
    final parsedDate = DateTime.tryParse(createdAt);
    if (parsedDate == null) {
      throw const FormatException('Date du message invalide.');
    }
    return CoachingMessage(
      id: id,
      sender: sender,
      text: text,
      createdAt: parsedDate,
    );
  }
}
