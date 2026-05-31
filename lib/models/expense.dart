class Expense {
  final int? id;
  final String type;
  final double amount;
  final String? note;
  final DateTime date;
  final String? location;
  final String? imagePath;
  final bool reimbursed;
  final String? plateNumber;

  Expense({
    this.id,
    required this.type,
    required this.amount,
    this.note,
    required this.date,
    this.location,
    this.imagePath,
    this.reimbursed = false,
    this.plateNumber,
  });

  Expense copyWith({
    int? id,
    String? type,
    double? amount,
    String? note,
    DateTime? date,
    String? location,
    String? imagePath,
    bool? reimbursed,
    String? plateNumber,
  }) {
    return Expense(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      date: date ?? this.date,
      location: location ?? this.location,
      imagePath: imagePath ?? this.imagePath,
      reimbursed: reimbursed ?? this.reimbursed,
      plateNumber: plateNumber ?? this.plateNumber,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'note': note ?? '',
      'date': date.toIso8601String(),
      'location': location ?? '',
      'imagePath': imagePath ?? '',
      'reimbursed': reimbursed ? 1 : 0,
      'plateNumber': plateNumber ?? '',
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      type: map['type'] as String,
      amount: (map['amount'] as num).toDouble(),
      note: map['note'] as String?,
      date: DateTime.parse(map['date'] as String),
      location: map['location'] as String?,
      imagePath: map['imagePath'] as String?,
      reimbursed: (map['reimbursed'] ?? 0) == 1,
      plateNumber: map['plateNumber'] as String?,
    );
  }
}