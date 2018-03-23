// Copyright (c) 2018, Anatoly Pulyaevskiy. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_redux_machine/flutter_redux_machine.dart';
import 'package:redux_machine/redux_machine.dart';

Store<AppState> buildStore(String message) {
  final builder =
      new StoreBuilder<AppState>(initialState: new AppState(message, false));
  builder.bind(Actions.goOnline, _onlineStatusReducer);
  builder.bind(Actions.goOffline, _onlineStatusReducer);

  return builder.build();
}

abstract class Actions {
  static const goOnline = const VoidActionBuilder('goOnline');
  static const goOffline = const VoidActionBuilder('goOffline');
}

class AppState {
  final String message;
  final bool isOnline;

  AppState(this.message, this.isOnline);
}

class ReduxApp extends StatefulWidget {
  ReduxApp({this.store, this.child}) : super();

  final Store<AppState> store;
  final Widget child;

  @override
  ReduxAppState createState() => new ReduxAppState();
}

class ReduxAppState extends State<ReduxApp> {
  @override
  Widget build(BuildContext context) {
    return new StoreAccess(
      store: widget.store,
      child: new MaterialApp(
        home: new Scaffold(
          body: widget.child,
          floatingActionButton: new FloatingActionButton(
            onPressed: _handleTap,
          ),
        ),
      ),
    );
  }

  _handleTap() {
    setState(() {});
  }
}

AppState _onlineStatusReducer(AppState state, Action<void> action) {
  final isOnline = action.name == 'goOnline';
  return new AppState(state.message, isOnline);
}
