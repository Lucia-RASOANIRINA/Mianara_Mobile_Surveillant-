class Candidate {
  const Candidate({
    this.firstName = '',
    this.lastName = '',
    this.birthDate = '',
    this.birthplace = '',
    this.gender = '',
    this.address = '',
    this.phone = '',
    this.email = '',
    this.birthCertificateNumber = '',
    this.examType = 'Baccalauréat',
    this.examSeries = 'C',
    this.examCenter = '',
    this.candidateStatus = 'Scolaire',
    this.firstParticipation = true,
    this.preferredLanguage = 'Français',
  });

  final String firstName;
  final String lastName;
  final String birthDate;
  final String birthplace;
  final String gender;
  final String address;
  final String phone;
  final String email;
  final String birthCertificateNumber;
  final String examType;
  final String examSeries;
  final String examCenter;
  final String candidateStatus;
  final bool firstParticipation;
  final String preferredLanguage;

  String get fullName => '$firstName $lastName'.trim();

  Map<String, Object?> toMap() => {
    'id': 1,
    'first_name': firstName,
    'last_name': lastName,
    'birth_date': birthDate,
    'birthplace': birthplace,
    'gender': gender,
    'address': address,
    'phone': phone,
    'email': email,
    'birth_certificate_number': birthCertificateNumber,
    'exam_type': examType,
    'exam_series': examSeries,
    'exam_center': examCenter,
    'candidate_status': candidateStatus,
    'first_participation': firstParticipation ? 1 : 0,
    'preferred_language': preferredLanguage,
  };

  factory Candidate.fromMap(Map<String, Object?> map) => Candidate(
    firstName: map['first_name'] as String? ?? '',
    lastName: map['last_name'] as String? ?? '',
    birthDate: map['birth_date'] as String? ?? '',
    birthplace: map['birthplace'] as String? ?? '',
    gender: map['gender'] as String? ?? '',
    address: map['address'] as String? ?? '',
    phone: map['phone'] as String? ?? '',
    email: map['email'] as String? ?? '',
    birthCertificateNumber: map['birth_certificate_number'] as String? ?? '',
    examType: map['exam_type'] as String? ?? 'Baccalauréat',
    examSeries: map['exam_series'] as String? ?? 'C',
    examCenter: map['exam_center'] as String? ?? '',
    candidateStatus: map['candidate_status'] as String? ?? 'Scolaire',
    firstParticipation: (map['first_participation'] as int? ?? 1) == 1,
    preferredLanguage: map['preferred_language'] as String? ?? 'Français',
  );
}
