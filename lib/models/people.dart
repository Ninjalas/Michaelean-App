import 'campus.dart';
import 'event_record.dart';
import 'user_profile.dart';

/// Who may see one part of a student's profile (spec §10.1).
enum PrivacyLevel {
  public('Public'),
  connections('Connections'),
  onlyMe('Only me');

  const PrivacyLevel(this.label);
  final String label;
}

/// A student's three privacy settings; all default to Connections.
class PrivacySettings {
  final PrivacyLevel upcomingEvents; // events they're going to
  final PrivacyLevel eventHistory; // past events they attended
  final PrivacyLevel connections; // their list of connections

  const PrivacySettings({
    this.upcomingEvents = PrivacyLevel.connections,
    this.eventHistory = PrivacyLevel.connections,
    this.connections = PrivacyLevel.connections,
  });

  PrivacySettings copyWith({
    PrivacyLevel? upcomingEvents,
    PrivacyLevel? eventHistory,
    PrivacyLevel? connections,
  }) =>
      PrivacySettings(
        upcomingEvents: upcomingEvents ?? this.upcomingEvents,
        eventHistory: eventHistory ?? this.eventHistory,
        connections: connections ?? this.connections,
      );
}

/// Where the viewer stands with another student. [blocked] means the viewer
/// blocked them. Teachers don't connect, so they always see [none].
enum ConnectionStatus { none, requestSent, requestReceived, connected, blocked }

/// A student in a list: search, suggestions, connections, Going lists.
class PersonSummary {
  final String id;
  final String name;
  final String section; // e.g. "BSCS 3A"
  final String? photoAsset;
  final ConnectionStatus status;
  final int mutual; // connections the viewer and this student share

  const PersonSummary({
    required this.id,
    required this.name,
    required this.section,
    this.photoAsset,
    this.status = ConnectionStatus.none,
    this.mutual = 0,
  });
}

/// Another student's profile as one viewer may see it. A list that is null
/// is hidden from this viewer by the student's privacy settings.
class PersonProfile {
  final PersonSummary person;
  final String maskedId;
  final List<IdentityTag> tags;
  final String? about;
  final int connectionCount;
  final List<PersonSummary> mutualConnections;

  /// Name only: one of them blocked the other.
  final bool limited;
  final List<PersonSummary>? connections;
  final List<CampusEvent>? upcoming; // soonest first
  final List<EventRecord>? history; // newest first

  const PersonProfile({
    required this.person,
    required this.maskedId,
    this.tags = const [],
    this.about,
    this.connectionCount = 0,
    this.mutualConnections = const [],
    this.limited = false,
    this.connections,
    this.upcoming,
    this.history,
  });
}

/// Who is going to an event, or who went (spec §10.1), as one viewer may
/// see it. [shown] are named (their settings allow it), connections first;
/// everyone else is only counted. The viewer is never in [shown].
class EventAttendees {
  final bool past; // "Went" (attendance records), else "Going" (registrations)
  final List<PersonSummary> shown;
  final bool includesViewer;
  final int total; // everyone, including the viewer and unnamed sample registrations

  const EventAttendees({
    required this.past,
    required this.shown,
    required this.includesViewer,
    required this.total,
  });

  /// Counted but not named: hidden by their settings, or sample registrations.
  int get others => total - shown.length - (includesViewer ? 1 : 0);
}

/// The user's own Connections section: requests to answer, connections, and
/// requests they sent and can cancel.
class ConnectionsOverview {
  final List<PersonSummary> incoming; // oldest first
  final List<PersonSummary> connections; // by name
  final List<PersonSummary> sent; // oldest first

  const ConnectionsOverview({
    required this.incoming,
    required this.connections,
    required this.sent,
  });
}
