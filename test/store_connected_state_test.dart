// Copyright (c) 2018, Anatoly Pulyaevskiy. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_redux_machine/flutter_redux_machine.dart';
import 'package:redux_machine/redux_machine.dart';
import 'app.dart';

void main() {
  group('StoreConnectedState', () {
    testWidgets('disconnects on store dispose', (WidgetTester tester) async {
      Store<AppState> store = buildStore('Welcome');

      final app = new ReduxApp(store: store, child: new OnlineIcon());
      await tester.pumpWidget(app);
      expect(find.text('offline'), findsOneWidget);
      await tester.pumpWidget(app);
      expect(find.text('online'), findsOneWidget);

      store.dispose();

      await tester.pumpWidget(app);
      expect(find.text('disconnected'), findsOneWidget);
    });
  });
}

class OnlineIconState extends StoreConnectedState<AppState, bool, OnlineIcon> {
  @override
  bool map(AppState state) => state.isOnline;

  @override
  void connect() {
    super.connect();
    // Will make this widget refresh on next frame.
    store.dispatch(Actions.goOnline());
  }

  @override
  Widget build(BuildContext context) {
    if (isConnected) {
      final message = state ? 'online' : 'offline';
      return new Center(child: new Text(message));
    } else {
      return new Center(child: new Text('disconnected'));
    }
  }
}

class OnlineIcon extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new OnlineIconState();
}
