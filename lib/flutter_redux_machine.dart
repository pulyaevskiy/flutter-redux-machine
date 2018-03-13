/// Integrates redux_machine and Flutter.
library flutter_redux_machine;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:redux_machine/redux_machine.dart';

/// Provides access to the application's Redux [Store].
///
/// Instead of using this widget directly consider first extending
/// [StoreConnectedWidget] which simplifies many aspects of interacting with the
/// state store.
///
/// For more advanced use cases consider implementing custom [StatefulWidget]
/// using a descendant of [StoreConnectedState].
class StoreAccess extends InheritedWidget {
  final Store store;

  StoreAccess({Key key, @required this.store, @required Widget child})
      : super(key: key, child: child);

  static Store<S> of<S>(BuildContext context) {
    StoreAccess widget = context.inheritFromWidgetOfExactType(StoreAccess);
    return widget.store as Store<S>;
  }

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) {
    return false;
  }
}

/// Interface of a state mapper function used by [StoreConnectedWidget].
typedef StateMapper<S, T> = T Function(S state);

/// Widget connected to the application's Redux store.
///
/// Gets automatically rebuilt every time its state object changes in
/// the application's state.
///
/// This widget does not provide any life cycle hooks and generally useful in
/// situations when there is no need to dispatch any actions to initialize and/or
/// dispose any underlying resources.
///
/// For more complex use cases consider implementing custom [StatefulWidget]
/// which uses a descendant of [StoreConnectedState].
abstract class StoreConnectedWidget<S, T> extends StatefulWidget {
  StoreConnectedWidget(StateMapper<S, T> this.mapper, {Key key})
      : super(key: key);

  final StateMapper<S, T> mapper;

  @override
  State<StatefulWidget> createState() => new _StoreConnectedWidgetState<S, T>();

  /// Builds this widget.
  Widget build(BuildContext context, T state);
}

class _StoreConnectedWidgetState<S, T>
    extends StoreConnectedState<S, T, StoreConnectedWidget<S, T>> {
  T map(S state) => widget.mapper(state);

  @override
  Widget build(BuildContext context) => widget.build(context, state);
}

/// Base state class which can be used by any [StatefulWidget] that wishes to
/// be connected to a Redux store.
///
/// Provides two lyfe cycle hooks [connect] and [disconnect] which can be used
/// to allocate necessary resources and/or dispatch actions to the state store.
abstract class StoreConnectedState<S, T, W extends StatefulWidget>
    extends State<W> {
  /// Maps application [state] to the actual substate object relevant to this
  /// widget.
  T map(S state);

  /// Connects this state object to the Redux Store.
  ///
  /// This method is called only once during lifecycle of this state object.
  ///
  /// It is safe to access [store] and [state] objects from this method. The
  /// [state] object is always initialized with current value available in
  /// the [store].
  ///
  /// Descendants are allowed to override this method. This is usually useful
  /// to dispatch necessary actions. Overriden methods must always call super.
  @protected
  @mustCallSuper
  void connect() {
    _state = map(_store.state);
    _subscription = _store
        .changesFor(map)
        .listen(_onData, onDone: _onDone, cancelOnError: false);
  }

  /// Disconnects this state object from the Redux Store.
  ///
  /// This method is called only once during lifecycle of this state object.
  ///
  /// It is safe to access [store] and [state] objects from this method.
  ///
  /// Descendants are allowed to override this method. This is usually useful
  /// to dispatch necessary actions. Overriden methods must always call super.
  @protected
  @mustCallSuper
  void disconnect() {
    _subscription?.cancel();
    _subscription = null;
  }

  /// The Redux state store. Note that this field is only initialized during
  /// [didChangeDependencies] and can not be used in [initState].
  ///
  /// In general, consider using [connect] and [disconnect] instead of [initState]
  /// and [dispose].
  Store<S> get store => _store;
  Store<S> _store;

  /// Current state value.
  T get state => _state;
  T _state;

  StreamSubscription<T> _subscription;

  /// Whether this state object is connected to the state store.
  ///
  /// Returns `true` if there is active stream subscription for state changes.
  ///
  /// Returns `false` if called from [initState] since subscription is initialized
  /// in [didChangeDependencies].
  ///
  /// Note that stream subscription can be closed in case application's state
  /// store was disposed in which case this field also returns `false`.
  bool get isConnected => _subscription != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (isConnected) return;
    _store = StoreAccess.of(context);
    connect();
  }

  @override
  dispose() {
    disconnect();
    super.dispose();
  }

  void _onData(T data) {
    setState(() {
      _state = data;
    });
  }

  void _onDone() {
    // This can happen in case application's state store was disposed.
    _subscription = null;
  }
}
