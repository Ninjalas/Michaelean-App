import 'package:flutter_test/flutter_test.dart';

import '../tool/create_accounts.dart';

void main() {
  test('login email uses the full first name, plain letters', () {
    expect(loginEmail('Stephen Michael', 'Hadi'), 'StephenMichael.Hadi@smcl.edu.ph');
    expect(loginEmail('Ma. Diane', 'Zulueta'), 'MaDiane.Zulueta@smcl.edu.ph');
    expect(loginEmail('Kimberly Ingrid', 'Acuña'), 'KimberlyIngrid.Acuna@smcl.edu.ph');
    expect(loginEmail('Juan', 'Dela Cruz'), 'Juan.DelaCruz@smcl.edu.ph');
    expect(() => loginEmail('Zoë', 'Ng'), throwsFormatException);
  });

  test('student list: suffix kept out of the email, bad rows rejected', () {
    final s = parseStudents('last_name,first_name,suffix,program,year_level\n'
        'Diolata,Rufino,III,BSCS,3\n');
    expect(s.single.email, 'Rufino.Diolata@smcl.edu.ph');
    expect(s.single.suffix, 'III');
    expect(() => parseStudents('header\nCruz,Ana,,BSIT,3\n'), throwsFormatException);
    expect(() => parseStudents('header\nCruz,Ana,,BSCS,5\n'), throwsFormatException);
  });

  test('duplicate emails are found, ignoring case', () {
    final s = parseStudents('h\nCruz,Ana,,BSCS,3\nCRUZ,ana,,ACS,2\nLim,Bo,,ACS,2\n');
    expect(duplicateEmails(s), ['ana.CRUZ@smcl.edu.ph']);
  });

  test('passwords look like xxxx-xxxx-xxxx and differ', () {
    final p = newPassword();
    expect(p, matches(RegExp(r'^[a-z2-9]{4}-[a-z2-9]{4}-[a-z2-9]{4}$')));
    expect(newPassword(), isNot(p));
  });
}
