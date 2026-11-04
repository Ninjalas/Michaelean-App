// MOCK DATA — sample guests already registered for the sample events. The
// names are invented; they are not real SMCL students. Courses and year
// levels are spread across the dropdown choices for illustration only.

import '../models/guest.dart';

const _names = [
  'Angelo Reyes',
  'Bianca Cruz',
  'Carlo Mendoza',
  'Daniela Flores',
  'Ethan Villanueva',
  'Faith Ramos',
  'Gabriel Aquino',
  'Hannah Dela Cruz',
  'Isaac Bautista',
  'Jolina Navarro',
  'Kevin Soriano',
  'Lara Mercado',
  'Miguel Tolentino',
  'Nina Salazar',
];

List<EventGuest> _seed(String eventId, int count, int offset) => [
      for (var i = 0; i < count; i++)
        EventGuest(
          id: 'seed-$eventId-$i',
          name: _names[(offset + i) % _names.length],
          course: registrationCourses[(offset + i) % registrationCourses.length],
          yearLevel: registrationYearLevels[(offset + i * 3) % registrationYearLevels.length],
        ),
    ];

/// Guests already registered per event id. The mock student and teacher are
/// deliberately not in any list, so each can register. ev4 has exactly its
/// capacity (see mock_campus.dart), so it shows as full.
final mockSeedGuests = <String, List<EventGuest>>{
  'ev1': _seed('ev1', 9, 0),
  'ev2': _seed('ev2', 7, 3),
  'ev3': _seed('ev3', 14, 1),
  'ev4': _seed('ev4', 6, 5),
  'ev5': _seed('ev5', 5, 8),
  'ev6': _seed('ev6', 4, 2),
  'ev7': const [],
};
