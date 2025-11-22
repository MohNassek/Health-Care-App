class HealthRecord {
  int? id;
  String date; // ISO string yyyy-MM-dd
  int steps;
  int calories;
  int water; // ml

  HealthRecord({this.id, required this.date, required this.steps, required this.calories, required this.water});

  factory HealthRecord.fromMap(Map<String, dynamic> m) => HealthRecord(
        id: m['id'] as int?,
        date: m['date'] as String,
        steps: m['steps'] as int,
        calories: m['calories'] as int,
        water: m['water'] as int,
      );

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'date': date,
      'steps': steps,
      'calories': calories,
      'water': water,
    };
    if (id != null) map['id'] = id;
    return map;
  }

  HealthRecord copyWith({int? id, String? date, int? steps, int? calories, int? water}) {
    return HealthRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      steps: steps ?? this.steps,
      calories: calories ?? this.calories,
      water: water ?? this.water,
    );
  }
}
