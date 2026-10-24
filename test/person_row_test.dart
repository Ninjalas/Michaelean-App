// A person row's button sits at the right edge, not in the middle of the row.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:michaelean_app/models/people.dart';
import 'package:michaelean_app/widgets/person_row.dart';

void main() {
  testWidgets("a person row's button sits at the right edge", (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PersonRow(
          person: const PersonSummary(
              id: 'a', name: 'Ana Cruz', section: 'BSCS 3A', status: ConnectionStatus.none),
          onTap: () {},
          trailing: TextButton(onPressed: () {}, child: const Text('Cancel')),
        ),
      ),
    ));
    expect(tester.getTopRight(find.byType(TextButton)).dx, 390);
  });
}
