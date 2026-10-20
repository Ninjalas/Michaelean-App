/// Status of a person's participation, from the official event record.
/// Registration alone never appears here: it isn't attendance (spec §10.3).
enum ParticipationStatus { attended, participated }

/// Role recorded on the event, not inferred (creating an event doesn't make
/// someone its host).
enum EventRole { participant, organizer, host, volunteer }

class EventRecord {
  final String id;
  final String eventName;
  final DateTime date;
  final String? imageAsset;
  final ParticipationStatus status;
  final EventRole role;

  const EventRecord({
    required this.id,
    required this.eventName,
    required this.date,
    this.imageAsset,
    required this.status,
    required this.role,
  });
}
