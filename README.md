Integrates [redux_machine][] and Flutter.

## StoreAccess

An `InheritedWidget` which provides access to the application's state store.

```dart
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
  Widget build(BuildContext) {
    final store = StoreAccess.of(context);
    return new Container(child: new Text(store.state.welcomeMessage));
  }
}
```

## StoreConnectedWidget

A simple widget connected to the application's state store. Rebuilds
automatically each time connected state object updates.

Usually useful in simple scenarios when there is no need to dispatch Store
actions or keep additional state. For advanced use cases see
`StoreConnectedState`.

Below is an example of a `StoreConnectedWidget` which reacts to online status
changes:

```dart
class OnlineIcon extends StoreConnectedWidget<AppState, bool> {
  /// Note that [StoreConnectedWidget] requires a mapper function.
  OnlineIcon() : super((state) => state.isOnline);

  @override
  Widget build(BuildContext context, bool isOnline) {
    final icon = isOnline ? Icons.cloud : Icons.cloud_off;
    return new Icon(icon);
  }
}
```

## StoreConnectedState

A state object connected to a Redux store. Useful in advanced scenarios where
`StoreConnectedWidget` does not provide enough flexibility.

Essentially works the same way as `StoreConnectedWidget`, e.g. rebuilds every
time connected state object is updated.

However since this is a regular Flutter `State` you are free to declare
extra state properties or react to life cycle events (`initState`, `dispose`, etc).

This class provides two additional life cycle hooks:

* `connect()` method, called only once in the beginning of the object's life
  cycle. Normally useful to dispatch actions to the state store.
* `disconnect()` method, called only once in the end of the object's life cycle
  before it's disposed. Similarly useful to dispatch actions to the state store
  or release any other allocated resources (e.g. cancel stream subscriptions).

It is recommended to use `connect()` and `disconnect()` instead of `initState()`
and `dispose()`. See documentation for more details.

```dart
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
```

In the above example there is one downside - there is no way to react to a
possible error when fetching comments from an API.

We can improve on that by leveraging `AsyncAction` from [redux_machine][]
library. `AsyncAction` is like regular Redux action but also carries a `Future`
with it, so we can be notified about two facts: when it completes with success
or with an error.

> Note that `AsyncAction` carries `Future<void>` so there is no way to attach
> payload to it. This is intentional is we normally should receive updated
> state through the state store subscription. The main purpose of `AsyncAction`
> is to tell us when it's done and if there was an error.
> This allows us to escape from declaring traditional trio of actions:
> doSomething, doSomethingSuccess and doSomethingError, which is probably the
> most annoying part of otherwise amazing Redux pattern.

Here is how we can rewrite `CommentsView` using `AsyncAction`:

```dart
/// Example actions.
abstract class Actions {
  static const fetchComments = const VoidActionBuilder('fetchComments');
  /// New action using [AsyncVoidActionBuidler].
  static const fetchCommentsAsync =
      const AsyncVoidActionBuidler('fetchCommentsAsync');
}

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
      /// We are only interested in failed scenario in this case.
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
```

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[redux_machine]: https://github.com/pulyaevskiy/redux-machine
[tracker]: https://github.com/pulyaevskiy/flutter-redux-machine/issues
