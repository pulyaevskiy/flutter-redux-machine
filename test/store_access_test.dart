// Copyright (c) 2018, Anatoly Pulyaevskiy. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_redux_machine/flutter_redux_machine.dart';
import 'package:redux_machine/redux_machine.dart';
import 'app.dart';

void main() {
  group('StoreAccess', () {
    Store<AppState> store = buildStore('Welcome');

    testWidgets('of', (WidgetTester tester) async {
      final app = new ReduxApp(store: store, child: new Welcome());
      await tester.pumpWidget(app);
      expect(find.text('Welcome 1'), findsOneWidget);
    });

    testWidgets('updateShouldNotify', (WidgetTester tester) async {
      final app = new ReduxApp(store: store, child: new Welcome());
      await tester.pumpWidget(app);
      expect(find.text('Welcome 1'), findsOneWidget);
      await tester.pumpWidget(app);
      expect(find.text('Welcome 1'), findsOneWidget);
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpWidget(app);
      expect(find.text('Welcome 1'), findsOneWidget);
    });
  });
}

class Welcome extends StatefulWidget {
  @override
  WelcomeState createState() {
    return new WelcomeState();
  }
}

class WelcomeState extends State<Welcome> {
  int _buildCount = 0;
  @override
  Widget build(BuildContext context) {
    _buildCount++;
    final store = StoreAccess.of<AppState>(context);
    return new Center(
      child: new Text('${store.state.message} ${_buildCount}'),
    );
  }
}
