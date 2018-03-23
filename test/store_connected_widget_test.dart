// Copyright (c) 2018, Anatoly Pulyaevskiy. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_redux_machine/flutter_redux_machine.dart';
import 'package:redux_machine/redux_machine.dart';
import 'app.dart';

void main() {
  group('StoreConnectedWidget', () {
    testWidgets('rebuilds', (WidgetTester tester) async {
      Store<AppState> store = buildStore('Welcome');
      final app = new ReduxApp(store: store, child: new OnlineIcon());
      await tester.pumpWidget(app);
      expect(find.text('offline'), findsOneWidget);
      store.dispatch(Actions.goOnline());
      await tester.pumpWidget(app);
      expect(find.text('online'), findsOneWidget);
      store.dispatch(Actions.goOffline());
      await tester.pumpWidget(app);
      expect(find.text('offline'), findsOneWidget);
    });
  });
}

class OnlineIcon extends StoreConnectedWidget<AppState, bool> {
  OnlineIcon() : super((state) => state.isOnline);

  @override
  Widget build(BuildContext context, bool isOnline) {
    final message = isOnline ? 'online' : 'offline';
    return new Center(child: new Text(message));
  }
}
