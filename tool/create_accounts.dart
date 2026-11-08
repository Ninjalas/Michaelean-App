// ignore_for_file: avoid_print (a command-line tool talks by printing)

// Creates the student accounts in Supabase from private/students.csv
// (docs/backend-plan.md). Run in the project folder:
//
//   dart run tool/create_accounts.dart           dry run: checks the list, changes nothing
//   dart run tool/create_accounts.dart --create  creates the accounts
//
// --create needs private/.env with two lines (never commit this file):
//   SUPABASE_URL=https://xxmicigqharmocbwpafz.supabase.co
//   SUPABASE_SECRET_KEY=<the secret / service_role key from Project Settings → API Keys>
//
// Each new account's password is added to private/passwords.csv right away,
// so a run that stops halfway loses nothing. Running it again skips accounts
// that already exist (their passwords are already in that file).

import 'dart:convert';
import 'dart:io';
import 'dart:math';

const programs = {'ACT-CS', 'ACT-IT', 'ACS', 'BSCS'};

class Student {
  final String lastName, firstName, suffix, program;
  final int yearLevel;
  Student(this.lastName, this.firstName, this.suffix, this.program, this.yearLevel);

  String get email => loginEmail(firstName, lastName);
}

/// FirstName.LastName@smcl.edu.ph with the full first name, spaces and periods
/// removed, and ñ/accents turned into plain letters (decided 2026-11-08).
String loginEmail(String firstName, String lastName) =>
    '${_plain(firstName)}.${_plain(lastName)}@smcl.edu.ph';

const _letters = {
  'ñ': 'n', 'Ñ': 'N', 'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ü': 'u',
  'Á': 'A', 'É': 'E', 'Í': 'I', 'Ó': 'O', 'Ú': 'U', 'Ü': 'U',
};

String _plain(String name) {
  final plain = name.split('').map((c) => _letters[c] ?? c).join();
  // Stop on letters we don't know how to convert, rather than guess.
  if (!RegExp(r"^[A-Za-z0-9 .'\-]+$").hasMatch(plain)) {
    throw FormatException('Unexpected character in name "$name"');
  }
  return plain.replaceAll(RegExp(r"[ .'\-]"), '');
}

/// Reads last_name,first_name,suffix,program,year_level rows. Throws on any
/// row that doesn't fit, naming the line.
List<Student> parseStudents(String csv) {
  final lines = const LineSplitter().convert(csv.replaceFirst('﻿', ''));
  final students = <Student>[];
  for (var i = 1; i < lines.length; i++) {
    if (lines[i].trim().isEmpty) continue;
    final f = lines[i].split(',').map((s) => s.trim()).toList();
    final year = f.length == 5 ? int.tryParse(f[4]) : null;
    if (year == null || year < 1 || year > 4 || !programs.contains(f[3]) ||
        f[0].isEmpty || f[1].isEmpty) {
      throw FormatException('students.csv line ${i + 1} looks wrong: ${lines[i]}');
    }
    students.add(Student(f[0], f[1], f[2], f[3], year));
  }
  return students;
}

/// Emails used by more than one student (compared ignoring case).
List<String> duplicateEmails(List<Student> students) {
  final seen = <String>{};
  return [for (final s in students) if (!seen.add(s.email.toLowerCase())) s.email];
}

final _random = Random.secure();

/// Easy to type on a phone: xxxx-xxxx-xxxx, no look-alike letters (l, o, i, 0, 1).
String newPassword() {
  const chars = 'abcdefghjkmnpqrstuvwxyz23456789';
  String part() => List.generate(4, (_) => chars[_random.nextInt(chars.length)]).join();
  return '${part()}-${part()}-${part()}';
}

/// Sample masked ID: entry year from the year level (A.Y. 2026–2027), random end.
String maskedId(int yearLevel) =>
    '${2027 - yearLevel}-****-${_random.nextInt(100).toString().padLeft(2, '0')}';

Map<String, String> readEnv(String path) => {
      for (final line in File(path).readAsLinesSync())
        if (line.contains('=') && !line.trimLeft().startsWith('#'))
          line.substring(0, line.indexOf('=')).trim(): line.substring(line.indexOf('=') + 1).trim(),
    };

Future<void> main(List<String> args) async {
  final students = parseStudents(File('private/students.csv').readAsStringSync());
  final dupes = duplicateEmails(students);
  if (dupes.isNotEmpty) {
    stderr.writeln('Stopped: these emails belong to more than one student: $dupes');
    exit(1);
  }
  for (final s in students) {
    print('${s.program} ${s.yearLevel}  ${s.email}');
  }
  print('${students.length} students, all emails unique.');

  if (!args.contains('--create')) {
    print('Dry run: nothing was created. Add --create to make the accounts.');
    return;
  }

  final env = readEnv('private/.env');
  final url = env['SUPABASE_URL'], key = env['SUPABASE_SECRET_KEY'];
  if (url == null || key == null || key.isEmpty) {
    stderr.writeln('private/.env needs SUPABASE_URL and SUPABASE_SECRET_KEY.');
    exit(1);
  }

  final out = File('private/passwords.csv');
  if (!out.existsSync()) {
    // The BOM makes Excel show ñ correctly.
    out.writeAsStringSync('﻿last_name,first_name,program,year_level,email,password\n');
  }

  final client = HttpClient();
  var created = 0, skipped = 0;
  for (final s in students) {
    final password = newPassword();
    final req = await client.postUrl(Uri.parse('$url/auth/v1/admin/users'));
    req.headers.contentType = ContentType.json;
    req.headers.set('apikey', key);
    // Older service_role keys are JWTs and also go in Authorization; new sb_secret_ keys must not.
    if (key.startsWith('eyJ')) req.headers.set('authorization', 'Bearer $key');
    req.write(jsonEncode({
      'email': s.email,
      'password': password,
      'email_confirm': true, // no confirmation email is ever sent
      'user_metadata': {
        'role': 'student',
        'first_name': s.firstName,
        'last_name': s.lastName,
        'suffix': s.suffix,
        'program': s.program,
        'year_level': s.yearLevel,
        'masked_id': maskedId(s.yearLevel),
      },
    }));
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();

    if (res.statusCode == 200 || res.statusCode == 201) {
      out.writeAsStringSync(
          '${s.lastName},${s.firstName},${s.program},${s.yearLevel},${s.email},$password\n',
          mode: FileMode.append);
      created++;
      print('Created ${s.email}');
    } else if (res.statusCode == 422 && body.contains('email_exists')) {
      skipped++;
      print('Already exists, skipped: ${s.email}');
    } else {
      client.close();
      stderr.writeln('Stopped at ${s.email}: ${res.statusCode} $body');
      stderr.writeln('Created $created before stopping; their passwords are in private/passwords.csv.');
      exit(1);
    }
  }
  client.close();
  print('Done: $created created, $skipped already existed. Passwords: private/passwords.csv');
}
