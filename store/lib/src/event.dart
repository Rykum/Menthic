class Event {
  final int id;
  final DateTime ts;
  final String type;
  final Map<String, dynamic> payload;
  final String origin;
  const Event({
    required this.id,
    required this.ts,
    required this.type,
    required this.payload,
    required this.origin,
  });
}

class EventDraft {
  final DateTime ts;
  final String type;
  final Map<String, dynamic> payload;
  final String origin;
  const EventDraft({
    required this.ts,
    required this.type,
    required this.payload,
    this.origin = 'manual',
  });
}
