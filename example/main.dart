// Copyright (c) 2018, Anatoly Pulyaevskiy. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_redux_machine/flutter_redux_machine.dart';
import 'package:redux_machine/redux_machine.dart';

/// Example actions.
abstract class Actions {
  static const fetchComments = const VoidActionBuilder('fetchComments');
  static const fetchCommentsAsync =
      const AsyncVoidActionBuilder('fetchCommentsAsync');
}

/// Example application state.
class AppState {
  final bool isOnline;
  final List<String> comments;

  AppState(this.isOnline, this.comments);
}

Store<AppState> buildStore() {
  final builder =
      new StoreBuilder<AppState>(initialState: new AppState(false, null));
  // TODO: bind reducers.
  return builder.build();
}

/// Example using [StoreAccess].
class MyApp extends StatelessWidget {
  Widget build(BuildContext) {
    final store = buildStore();
    return new StoreAccess(
      store: store,
      child: new MaterialApp(/* .. */),
    );
  }
}

class MyWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    final store = StoreAccess.of(context);
    return new Container(child: new Text(store.state.welcomeMessage));
  }
}

/// Example using [StoreConnectedWidget].
class OnlineIcon extends StoreConnectedWidget<AppState, bool> {
  /// Note that [StoreConnectedWidget] requires a mapper function.
  OnlineIcon() : super((state) => state.isOnline);

  @override
  Widget build(BuildContext context, bool isOnline) {
    final icon = isOnline ? Icons.cloud : Icons.cloud_off;
    return new Icon(icon);
  }
}

/// Example of using [StoreConnectedState] dispatching regular [Action] on
/// connect.
class CommentsView extends StatefulWidget {
  @override
  _CommentsViewState createState() => new _CommentsViewState();
}

class _CommentsViewState
    extends StoreConnectedState<AppState, List<String>, CommentsView> {
  /// [map] function defines to which part of application state
  /// this widget connects. In this case we are only interested in the list
  /// of comments.
  @override
  List<String> map(AppState state) => state.comments;

  @override
  void connect() {
    super.connect(); // must always call super
    /// It is safe to access current state from [connect] as it's been
    /// initialized already.
    if (state == null) {
      /// In this case if it's `null` we want to trigger an API call to fetch
      /// comments.
      /// The [store] property provides access to the application's state Store.
      store.dispatch(Actions.fetchComments());
    }
  }

  @override
  Widget build(BuildContext context) {
    /// Current list of comments can be accessed from [state] property.
    if (state == null)
      return new Center(child: new CircularProgressIndicator());
    if (state.isEmpty) return new Center(child: new Text('No comments.'));
    return new ListView(
      children: state
          .map((comment) => new ListTile(title: new Text(comment)))
          .toList(),
    );
  }
}

/// Example of using [StoreConnectedState] dispatching [AsyncAction] on
/// connect and handling error response.
class CommentsViewWithError extends StatefulWidget {
  @override
  _CommentsViewWithErrorState createState() =>
      new _CommentsViewWithErrorState();
}

class _CommentsViewWithErrorState
    extends StoreConnectedState<AppState, List<String>, CommentsView> {
  @override
  List<String> map(AppState state) => state.comments;

  /// Additional state for optional error
  var _error;

  @override
  void connect() {
    super.connect(); // must always call super
    if (state == null) {
      final action = Actions.fetchCommentsAsync();
      action.done.catchError(_handleFetchError);
      store.dispatch(action);
    }
  }

  void _handleFetchError(error) {
    /// Only update if we are still mounted, otherwise discard
    if (mounted)
      setState(() {
        _error = error;
      });
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      /// A very basic example of showing an error message.
      return new Center(child: new Text(_error.toString()));
    }
    if (state == null)
      return new Center(child: new CircularProgressIndicator());
    if (state.isEmpty) return new Center(child: new Text('No comments.'));
    return new ListView(
      children: state
          .map((comment) => new ListTile(title: new Text(comment)))
          .toList(),
    );
  }
}
