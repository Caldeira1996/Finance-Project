class Transaction {
  final String id;
  final String title;
  final double value;
  final DateTime date;

  Transaction({
    required this.id,
    required this.title,
    required this.value,
    required this.date,
  });

  // Método para converter JSON para Transaction
  factory Transaction.fromJson(Map<String, dynamic> json) {
    if (json['id'] == null ||
        json['title'] == null ||
        json['value'] == null ||
        json['date'] == null) {
      throw FormatException(
        'Dados JSON incomplestos para criar uma Transação.',
      );
    }

    return Transaction(
      id: json['id'],
      title: json['title'],
      value: double.parse(json['value'].toString()),
      date: DateTime.parse(json['date']),
    );
  }

  // Método para converter Transaction para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'value': value,
      'date': date.toIso8601String(),
    };
  }

  // Cria uma copia da transação com os campos atualizados
  Transaction copyWith({
    String? ud,
    String? title,
    double? value,
    DateTime? date,
  }) {
    return Transaction(
      id: id,
      title: title ?? this.title,
      value: value ?? this.value,
      date: date ?? this.date,
    );
  }
}
