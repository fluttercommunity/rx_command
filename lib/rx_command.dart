library rx_command;

import 'dart:async';

import 'package:quiver/core.dart';
import 'package:rxdart/rxdart.dart';

export 'rx_command_listener.dart';

typedef Action = void Function();
typedef Action1<TParam> = void Function(TParam param);

typedef Func<TResult> = TResult Function();
typedef Func1<TParam, TResult> = TResult Function(TParam param);

typedef AsyncAction = Future Function();
typedef AsyncAction1<TParam> = Future Function(TParam param);

typedef AsyncFunc<TResult> = Future<TResult> Function();
typedef AsyncFunc1<TParam, TResult> = Future<TResult> Function(TParam param);

typedef StreamProvider<TParam, TResult> = Stream<TResult> Function(
    TParam? param);

/// Combined execution state of an `RxCommand`
/// Will be issued for any state change of any of the fields
/// During normal command execution you will get this items listening at the command's [.results] observable.
/// 1. If the command was just newly created you will get `null, null, false` (data, error, isExecuting)
/// 2. When calling execute: `null, null, true`
/// 3. When execution finishes: `the result, null, false`
/// 3. When execution finishes: `param data, the result, null, false`
/// `param data` is the data that you pass as parameter when calling the command
class CommandResult<TParam, TResult> {
  final TParam? paramData;
  final TResult? data;
  final Object? error;
  final bool isExecuting;

  const CommandResult(this.paramData, this.data, this.error, this.isExecuting);

  const CommandResult.data(TParam? param, TResult data)
      : this(param, data, null, false);

  const CommandResult.error(TParam? param, dynamic error)
      : this(param, null, error, false);

  const CommandResult.isLoading([TParam? param])
      : this(param, null, null, true);

  const CommandResult.blank() : this(null, null, null, false);

  bool get hasData => data != null;

  bool get hasError => error != null;

  @override
  bool operator ==(Object other) =>
      other is CommandResult<TParam, TResult> &&
      other.paramData == paramData &&
      other.data == data &&
      other.error == error &&
      other.isExecuting == isExecuting;

  @override
  int get hashCode =>
      hash3(data.hashCode, error.hashCode, isExecuting.hashCode);

  @override
  String toString() {
    return 'ParamData $paramData - Data: $data - HasError: $hasError - IsExecuting: $isExecuting';
  }
}

/// [CommandError] wraps an occurring error together with the argument that was
/// passed when the command was called.
/// This sort of objects are emitted on the `.thrownExceptions` ValueListenable
/// of the Command
class CommandError<TParam> {
  final Object? error;
  final TParam? paramData;

  CommandError(
    this.paramData,
    this.error,
  );

  @override
  bool operator ==(Object other) =>
      other is CommandError<TParam> &&
      other.paramData == paramData &&
      other.error == error;

  @override
  int get hashCode => hash2(error.hashCode, paramData.hashCode);

  @override
  String toString() {
    return '$error - for param: $paramData';
  }
}

/// [RxCommand] capsules a given handler function that can then be executed by its [execute] method.
/// The result of this method is then published through its Observable (Observable wrap Dart Streams)
/// Additionally it offers Observables for it's current execution state, if the command can be executed and for
/// all possibly thrown exceptions during command execution.
///
/// [RxCommand] implements the `Observable` interface so you can listen directly to the [RxCommand] which emits the
/// results of the wrapped function. If this function has a [void] return type
/// it will still output one `void` item so that you can listen for the end of the execution.
///
/// The [results] Observable emits [CommandResult<TRESULT>] which is often easier in combination with Flutter `StreamBuilder`
/// because you have all state information at one place.
///
/// An [RxCommand] is a generic class of type [RxCommand<TParam, TRESULT>]
/// where [TParam] is the type of data that is passed when calling [execute] and
/// [TResult] denotes the return type of the handler function. To signal that
/// a handler doesn't take a parameter or returns no value use the type `void`
abstract class RxCommand<TParam, TResult> extends StreamView<TResult> {
  bool _isRunning = false;
  bool _canExecute = true;
  bool _executionLocked = false;

  /// Flag that we always should include the last successful value in `CommandResult`
  /// for isExecuting or error states
  final bool _includeLastResultInCommandResults;

  ///Flag to signal the wrapped command has no return value which means
  ///`notifyListener` has to be called directly
  final bool _noReturnValue;

  ///Flag to signal the wrapped command expects not parameter value
  final bool _noParamValue;

  /// optional Name that is included in log messages.
  final String? _debugName;
  final bool _resultSubjectIsBehaviourSubject;

  RxCommand(
      this._resultsSubject,
      Stream<bool?>? restriction,
      this._includeLastResultInCommandResults,
      this._resultSubjectIsBehaviourSubject,
      this.lastResult,
      bool noReturnValue,
      String? debugName,
      bool noParamValue)
      : _noReturnValue = noReturnValue,
        _noParamValue = noParamValue,
        _debugName = debugName,
        super(_resultsSubject) {
    _commandResultsSubject = _resultSubjectIsBehaviourSubject
        ? BehaviorSubject<CommandResult<TParam, TResult>>()
        : PublishSubject<CommandResult<TParam, TResult>>();

    _commandResultsSubject.where((x) => x.hasError).listen(
        (x) => _thrownExceptionsSubject.add(CommandError(x.paramData, x.error)),
        onError: (x) {});

    _commandResultsSubject.listen((x) => _isExecutingSubject.add(x.isExecuting),
        onError: (x) {});

    final _canExecuteParam = restriction == null
        ? Stream<bool>.value(true)
        : restriction.handleError((error) {
            if (error is Exception) {
              _thrownExceptionsSubject.add(CommandError(null, error));
            }
          }).distinct();

    _canExecuteParam.listen((canExecute) {
      _canExecute = (canExecute ?? false) && (!_isRunning);
      _executionLocked = !(canExecute ?? false);
      _canExecuteSubject.add(_canExecute);
    });
  }

  /// Creates  a RxCommand for a synchronous handler function with no parameter and no return type
  /// [action]: handler function
  /// [restriction] : observable that can be used to enable/disable the command based on some other state change
  /// if omitted the command can be executed always except it's already executing
  /// [isExecuting] will issue a `bool` value on each state change. Even if you
  /// subscribe to a newly created command it will issue `false`
  /// For the `Observable<CommandResult>` that [RxCommand] publishes in [results] this normally doesn't make sense
  /// if you want to get an initial Result with `data==null, error==null, isExecuting==false` pass
  /// [emitInitialCommandResult]=true.
  /// By default the [results] Observable and the [RxCommand] itself behave like a PublishSubject. If you want that it acts like
  /// a BehaviourSubject, meaning every listener gets the last received value, you can set [emitsLastValueToNewSubscriptions = true].
  /// [debugName] optional identifier that is included when you register a [globalExceptionHandler]
  /// or a [loggingHandler]
  static RxCommand<void, void> createSyncNoParamNoResult(Action action,
      {Stream<bool>? restriction,
      bool emitInitialCommandResult = false,
      bool emitsLastValueToNewSubscriptions = false,
      String? debugName}) {
    return RxCommandSync<void, void>(
      null,
      action,
      restriction,
      emitInitialCommandResult,
      false,
      emitsLastValueToNewSubscriptions,
      null,
      true,
      debugName,
      true,
    );
  }

  /// Creates  a RxCommand for a synchronous handler function with one parameter and no return type
  /// `action`: handler function
  /// `canExecute` : observable that can be used to enable/disable the command based on some other state change
  /// if omitted the command can be executed always except it's already executing
  /// [isExecuting] will issue a `bool` value on each state change. Even if you
  /// subscribe to a newly created command it will issue `false`
  /// For the `Observable<CommandResult>` that [RxCommand] publishes in [results]  this normally doesn't make sense
  /// if you want to get an initial Result with `data==null, error==null, isExecuting==false` pass
  /// [emitInitialCommandResult=true].
  /// By default the [results] Observable and the [RxCommand] itself behave like a PublishSubject. If you want that it acts like
  /// a BehaviourSubject, meaning every listener gets the last received value, you can set [emitsLastValueToNewSubscriptions = true].
  /// [debugName] optional identifier that is included when you register a [globalExceptionHandler]
  /// or a [loggingHandler]
  static RxCommand<TParam, void> createSyncNoResult<TParam>(
    Action1<TParam> action, {
    Stream<bool>? restriction,
    bool emitInitialCommandResult = false,
    bool emitsLastValueToNewSubscriptions = false,
    bool? catchAlways,
    String? debugName,
  }) {
    return RxCommandSync<TParam, void>(
      action,
      null,
      restriction,
      emitInitialCommandResult,
      false,
      emitsLastValueToNewSubscriptions,
      null,
      true,
      debugName,
      false,
    );
  }

  /// Creates  a RxCommand for a synchronous handler function with no parameter that returns a value
  /// `func`: handler function
  /// `canExecute` : observable that can be used to enable/disable the command based on some other state change
  /// if omitted the command can be executed always except it's already executing
  /// [isExecuting] will issue a `bool` value on each state change. Even if you
  /// subscribe to a newly created command it will issue `false`
  /// [emitLastResult] will include the value of the last successful execution in all [CommandResult] events unless there is no result.
  /// For the `Observable<CommandResult>` that [RxCommand] publishes in [results]  this normally doesn't make sense
  /// if you want to get an initial Result with `data==null, error==null, isExecuting==false` pass
  /// [emitInitialCommandResult=true].
  /// By default the [results] Observable and the [RxCommand] itself behave like a PublishSubject. If you want that it acts like
  /// a BehaviourSubject, meaning every listener gets the last received value, you can set [emitsLastValueToNewSubscriptions = true].
  /// [initialLastResult] sets the value of the [lastResult] property before the first item was received. This is helpful if you use
  /// [lastResult] as `initialData` of a `StreamBuilder`
  /// [debugName] optional identifier that is included when you register a [globalExceptionHandler]
  /// or a [loggingHandler]
  static RxCommand<void, TResult> createSyncNoParam<TResult>(
    Func<TResult> func, {
    Stream<bool>? restriction,
    bool emitInitialCommandResult = false,
    bool emitLastResult = false,
    bool emitsLastValueToNewSubscriptions = false,
    TResult? initialLastResult,
    String? debugName,
  }) {
    return RxCommandSync<void, TResult>(
      null,
      func,
      restriction,
      emitInitialCommandResult,
      emitLastResult,
      emitsLastValueToNewSubscriptions,
      initialLastResult,
      false,
      debugName,
      true,
    );
  }

  /// Creates  a RxCommand for a synchronous handler function with parameter that returns a value
  /// `func`: handler function
  /// `canExecute` : observable that can be used to enable/disable the command based on some other state change
  /// if omitted the command can be executed always except it's already executing
  /// [isExecuting] will issue a `bool` value on each state change. Even if you
  /// subscribe to a newly created command it will issue `false`
  /// For the `Observable<CommandResult>` that [RxCommand] implement this normally doesn't make sense
  /// if you want to get an initial Result with `data==null, error==null, isExecuting==false` pass
  /// [emitInitialCommandResult=true].
  /// [emitLastResult] will include the value of the last successful execution in all [CommandResult] events unless there is no result.
  /// By default the [results] Observable and the [RxCommand] itself behave like a PublishSubject. If you want that it acts like
  /// a BehaviourSubject, meaning every listener gets the last received value, you can set [emitsLastValueToNewSubscriptions = true].
  /// [initialLastResult] sets the value of the [lastResult] property before the first item was received. This is helpful if you use
  /// [lastResult] as `initialData` of a `StreamBuilder`
  /// [debugName] optional identifier that is included when you register a [globalExceptionHandler]
  /// or a [loggingHandler]
  static RxCommand<TParam, TResult> createSync<TParam, TResult>(
      Func1<TParam, TResult> func,
      {Stream<bool>? restriction,
      bool emitInitialCommandResult = false,
      bool emitLastResult = false,
      bool emitsLastValueToNewSubscriptions = false,
      TResult? initialLastResult,
      String? debugName}) {
    return RxCommandSync<TParam, TResult>(
        (x) => func(x),
        null,
        restriction,
        emitInitialCommandResult,
        emitLastResult,
        emitsLastValueToNewSubscriptions,
        initialLastResult,
        false,
        debugName,
        false);
  }

  // Asynchronous

  /// Creates  a RxCommand for an asynchronous handler function with no parameter and no return type
  /// `action`: handler function
  /// `canExecute` : observable that can be used to enable/disable the command based on some other state change
  /// if omitted the command can be executed always except it's already executing
  /// [isExecuting] will issue a `bool` value on each state change. Even if you
  /// subscribe to a newly created command it will issue `false`
  /// For the `Observable<CommandResult>` that [RxCommand] implement this normally doesn't make sense
  /// if you want to get an initial Result with `data==null, error==null, isExecuting==false` pass
  /// [emitInitialCommandResult=true].
  /// By default the [results] Observable and the [RxCommand] itself behave like a PublishSubject. If you want that it acts like
  /// a BehaviourSubject, meaning every listener gets the last received value, you can set [emitsLastValueToNewSubscriptions = true].
  /// [debugName] optional identifier that is included when you register a [globalExceptionHandler]
  /// or a [loggingHandler]
  static RxCommand<void, void> createAsyncNoParamNoResult(AsyncAction action,
      {Stream<bool>? restriction,
      bool emitInitialCommandResult = false,
      bool emitsLastValueToNewSubscriptions = false,
      String? debugName}) {
    return RxCommandAsync<void, void>(
      null,
      action,
      restriction,
      emitInitialCommandResult,
      false,
      emitsLastValueToNewSubscriptions,
      null,
      true,
      debugName,
      true,
    );
  }

  /// Creates  a RxCommand for an asynchronous handler function with one parameter and no return type
  /// `action`: handler function
  /// `canExecute` : observable that can be used to enable/disable the command based on some other state change
  /// if omitted the command can be executed always except it's already executing
  /// [isExecuting] will issue a `bool` value on each state change. Even if you
  /// subscribe to a newly created command it will issue `false`
  /// For the `Observable<CommandResult>` that [RxCommand] implement this normally doesn't make sense
  /// if you want to get an initial Result with `data==null, error==null, isExecuting==false` pass
  /// [emitInitialCommandResult=true].
  /// By default the [results] Observable and the [RxCommand] itself behave like a PublishSubject. If you want that it acts like
  /// a BehaviourSubject, meaning every listener gets the last received value, you can set [emitsLastValueToNewSubscriptions = true].
  /// [debugName] optional identifier that is included when you register a [globalExceptionHandler]
  /// or a [loggingHandler]
  static RxCommand<TParam, void> createAsyncNoResult<TParam>(
      AsyncAction1<TParam> action,
      {Stream<bool>? restriction,
      bool emitInitialCommandResult = false,
      bool emitsLastValueToNewSubscriptions = false,
      String? debugName}) {
    return RxCommandAsync<TParam, void>(
      action,
      null,
      restriction,
      emitInitialCommandResult,
      false,
      emitsLastValueToNewSubscriptions,
      null,
      false,
      debugName,
      false,
    );
  }

  /// Creates  a RxCommand for an asynchronous handler function with no parameter that returns a value
  /// `func`: handler function
  /// `canExecute` : observable that can be used to enable/disable the command based on some other state change
  /// if omitted the command can be executed always except it's already executing
  /// [isExecuting] will issue a `bool` value on each state change. Even if you
  /// subscribe to a newly created command it will issue `false`
  /// for the `Observable<CommandResult>` that [RxCommand] publishes in [results] this normally doesn't make sense
  /// if you want to get an initial Result with `data==null, error==null, isExecuting==false` pass
  /// [emitInitialCommandResult=true].
  /// [emitLastResult] will include the value of the last successful execution in all [CommandResult] events unless there is no result.
  /// By default the [results] Observable and the [RxCommand] itself behave like a PublishSubject. If you want that it acts like
  /// a BehaviourSubject, meaning every listener gets the last received value, you can set [emitsLastValueToNewSubscriptions = true].
  /// [initialLastResult] sets the value of the [lastResult] property before the first item was received. This is helpful if you use
  /// [lastResult] as `initialData` of a `StreamBuilder`
  /// [debugName] optional identifier that is included when you register a [globalExceptionHandler]
  /// or a [loggingHandler]
  static RxCommand<void, TResult> createAsyncNoParam<TResult>(
      AsyncFunc<TResult> func,
      {Stream<bool>? restriction,
      bool emitInitialCommandResult = false,
      bool emitLastResult = false,
      bool emitsLastValueToNewSubscriptions = false,
      TResult? initialLastResult,
      String? debugName}) {
    return RxCommandAsync<void, TResult>(
      null,
      func,
      restriction,
      emitInitialCommandResult,
      emitLastResult,
      emitsLastValueToNewSubscriptions,
      initialLastResult,
      false,
      debugName,
      true,
    );
  }

  /// Creates  a RxCommand for an asynchronous handler function with parameter that returns a value
  /// `func`: handler function
  /// `canExecute` : observable that can be used to enable/disable the command based on some other state change
  /// if omitted the command can be executed always except it's already executing
  /// [isExecuting] will issue a `bool` value on each state change. Even if you
  /// subscribe to a newly created command it will issue `false`
  /// For the `Observable<CommandResult>` that [RxCommand] publishes in [results] this normally doesn't make sense
  /// if you want to get an initial Result with `data==null, error==null, isExecuting==false` pass
  /// [emitInitialCommandResult=true].
  /// [emitLastResult] will include the value of the last successful execution in all [CommandResult] events unless there is no result.
  /// By default the [results] Observable and the [RxCommand] itself behave like a PublishSubject. If you want that it acts like
  /// a BehaviourSubject, meaning every listener gets the last received value, you can set [emitsLastValueToNewSubscriptions = true].
  /// [initialLastResult] sets the value of the [lastResult] property before the first item was received. This is helpful if you use
  /// [lastResult] as `initialData` of a `StreamBuilder`
  /// [debugName] optional identifier that is included when you register a [globalExceptionHandler]
  /// or a [loggingHandler]
  static RxCommand<TParam, TResult> createAsync<TParam, TResult>(
      AsyncFunc1<TParam, TResult> func,
      {Stream<bool?>? restriction,
      bool emitInitialCommandResult = false,
      bool emitLastResult = false,
      bool emitsLastValueToNewSubscriptions = false,
      TResult? initialLastResult,
      String? debugName}) {
    return RxCommandAsync<TParam, TResult>(
        func,
        null,
        restriction,
        emitInitialCommandResult,
        emitLastResult,
        emitsLastValueToNewSubscriptions,
        initialLastResult,
        false,
        debugName,
        false);
  }

  /// Creates  a RxCommand from an "one time" observable. This is handy if used together with a streame generator function.
  /// [provider]: provider function that returns a Observable that will be subscribed on the call of [execute]
  /// [restriction] : observable that can be used to enable/disable the command based on some other state change
  /// if omitted the command can be executed always except it's already executing
  /// [isExecuting] will issue a `bool` value on each state change. Even if you
  /// subscribe to a newly created command it will issue `false`
  /// For the `Observable<CommandResult>` that [RxCommand] publishes in [results] this normally doesn't make sense
  /// if you want to get an initial Result with `data==null, error==null, isExecuting==false` pass
  /// [emitInitialCommandResult=true].
  /// [emitLastResult] will include the value of the last successful execution in all [CommandResult] events unless there is no result.
  /// By default the [results] Observable and the [RxCommand] itself behave like a PublishSubject. If you want that it acts like
  /// a BehaviourSubject, meaning every listener gets the last received value, you can set [emitsLastValueToNewSubscriptions = true].
  /// [initialLastResult] sets the value of the [lastResult] property before the first item was received. This is helpful if you use
  /// [lastResult] as `initialData` of a `StreamBuilder`
  /// [debugName] optional identifier that is included when you register a [globalExceptionHandler]
  /// or a [loggingHandler]
  static RxCommand<TParam, TResult> createFromStream<TParam, TResult>(
      StreamProvider<TParam, TResult> provider,
      {Stream<bool>? restriction,
      bool emitInitialCommandResult = false,
      bool emitLastResult = false,
      bool emitsLastValueToNewSubscriptions = false,
      TResult? initialLastResult,
      String? debugName}) {
    return RxCommandStream<TParam, TResult>(
        provider,
        restriction,
        emitInitialCommandResult,
        emitLastResult,
        emitsLastValueToNewSubscriptions,
        initialLastResult,
        false,
        debugName,
        false);
  }

  /// Calls the wrapped handler function with an option input parameter
  void execute([TParam? param]);

  /// This makes RxCommand a callable class, so instead of `myCommand.execute()` you can write `myCommand()`
  void call([TParam? param]) => execute(param);

  /// The result of the last successful call to execute. This is especially handy to use as `initialData` of Flutter `StreamBuilder`
  TResult? lastResult;

  /// emits [CommandResult<TRESULT>] the combined state of the command, which is often easier in combination with Flutter `StreamBuilder`
  /// because you have all state information at one place.
  Stream<CommandResult<TParam, TResult>> get results => _commandResultsSubject;

  /// Observable stream that issues a bool on any execution state change of the command
  Stream<bool> get isExecuting =>
      _isExecutingSubject.startWith(false).distinct();

  /// Observable stream that issues a bool on any change of the current executable state of the command.
  /// Meaning if the command cann be executed or not. This will issue `false` while the command executes
  /// but also if the command receives a false from the canExecute Observable that you can pass when creating the Command
  Stream<bool> get canExecute => _canExecuteSubject.startWith(true).distinct();

  /// When subribing to `thrownExceptions`you will every excetpion that was thrown in your handler function as an event on this Observable.
  /// If no subscription exists the Exception will be rethrown
  Stream<dynamic> get thrownExceptions => _thrownExceptionsSubject;

  /// optional hander that will get called on any exception that happens inside
  /// any Command of the app. Ideal for logging. [commandName]
  /// the [debugName] of the Command
  static void Function(String? commandName, CommandError<Object> error)?
      globalExceptionHandler;

  /// optional handler that will get called on all `Command` executions. [commandName]
  /// the [debugName] of the Command
  static void Function(String? commandName, CommandResult result)?
      loggingHandler;

  /// This property is a utility which allows us to chain RxCommands together.
  Future<TResult> get next =>
      Rx.merge<TResult>([this, this.thrownExceptions.cast<TResult>()])
          .take(1)
          .last;

  late Subject<CommandResult<TParam, TResult>> _commandResultsSubject;
  final Subject<TResult> _resultsSubject;
  final BehaviorSubject<bool> _isExecutingSubject = BehaviorSubject<bool>();
  final BehaviorSubject<bool> _canExecuteSubject = BehaviorSubject<bool>();
  final PublishSubject<CommandError<TParam>> _thrownExceptionsSubject =
      PublishSubject<CommandError<TParam>>();

  /// By default `RxCommand` will catch all exceptions during execution of the command. And publish them on `.thrownExceptions`
  /// and in the `CommandResult`. If don't want this and have exceptions thrown, set this to true.
  bool throwExceptions = false;

  /// If you don't need a command any longer it is a good practise to
  /// dispose it to make sure all stream subscriptions are cancelled to prevent memory leaks
  void dispose() {
    _commandResultsSubject.close();
    _isExecutingSubject.close();
    _canExecuteSubject.close();
    _thrownExceptionsSubject.close();
    _resultsSubject.close();
  }
}

/// Implementation of RxCommand to handle async handler functions. Normally you will not instantiate this directly but use one of the factory
/// methods of RxCommand.
class RxCommandSync<TParam, TResult> extends RxCommand<TParam, TResult> {
  final TResult Function(TParam)? _func;
  final TResult Function()? _funcNoParam;

  factory RxCommandSync(
    Func1<TParam, TResult>? func,
    TResult Function()? funcNoParam,
    Stream<bool>? restriction,
    bool emitInitialCommandResult,
    bool emitLastResult,
    bool emitsLastValueToNewSubscriptions,
    TResult? initialLastResult,
    bool noReturnValue,
    String? debugName,
    bool noParamValue,
  ) {
    return RxCommandSync._(
      func,
      funcNoParam,
      emitsLastValueToNewSubscriptions || emitInitialCommandResult
          ? BehaviorSubject<TResult>()
          : PublishSubject<TResult>(),
      restriction,
      emitLastResult,
      emitsLastValueToNewSubscriptions || emitInitialCommandResult,
      emitInitialCommandResult,
      initialLastResult,
      noReturnValue,
      debugName,
      noParamValue,
    );
  }

  RxCommandSync._(
    Func1<TParam, TResult>? func,
    TResult Function()? funcNoParam,
    Subject<TResult> subject,
    Stream<bool>? restriction,
    bool buffer,
    bool isBehaviourSubject,
    bool emitInitialCommandResult,
    TResult? initialLastResult,
    bool noReturnValue,
    String? debugName,
    bool noParamValue,
  )   : _func = func,
        _funcNoParam = funcNoParam,
        super(
          subject,
          restriction,
          buffer,
          isBehaviourSubject,
          initialLastResult,
          noReturnValue,
          debugName,
          noParamValue,
        ) {
    if (emitInitialCommandResult) {
      _commandResultsSubject.add(
          CommandResult<TParam, TResult>(null, initialLastResult, null, false));
    }
  }

  @override
  void execute([TParam? param]) {
    if (!_canExecute) {
      return;
    }

    if (_isRunning) {
      return;
    } else {
      _isRunning = true;
      _canExecuteSubject.add(false);
    }

    _commandResultsSubject.add(CommandResult<TParam, TResult>(param,
        _includeLastResultInCommandResults ? lastResult : null, null, true));

    TResult? result;
    late CommandResult<TParam, TResult> commandResult;
    try {
      if (_noParamValue) {
        assert(_funcNoParam != null);
        result = _funcNoParam!();
      } else {
        assert(_func != null);
        assert(param != null || null is TParam,
            'You passed a null value to the command ${_debugName ?? ''} that has a non-nullable type as TParam');
        result = _func!(param as TParam);
      }
      if (_noReturnValue) {
        result = null;
      }
      lastResult = result;
      if (result != null || null is TResult) {
        _resultsSubject.add(result as TResult);
      }
      commandResult =
          CommandResult<TParam, TResult>(param, result, null, false);
      _commandResultsSubject.add(commandResult);
    } catch (error) {
      if (error is AssertionError) rethrow;
      if (throwExceptions) {
        _resultsSubject.addError(error);
        _commandResultsSubject.addError(error);
        _isExecutingSubject.add(
            false); // Has to be done because in this case no command result is queued
        return;
      }

      commandResult = CommandResult<TParam, TResult>(param,
          _includeLastResultInCommandResults ? lastResult : null, error, false);
      _commandResultsSubject.add(commandResult);

      RxCommand.globalExceptionHandler
          ?.call(_debugName, CommandError(param, error));
    } finally {
      _isRunning = false;
      _canExecute = !_executionLocked;
      _canExecuteSubject.add(!_executionLocked);
      RxCommand.loggingHandler?.call(_debugName, commandResult);
    }
  }
}

class RxCommandAsync<TParam, TResult> extends RxCommand<TParam, TResult> {
  final Future<TResult> Function(TParam)? _func;
  final Future<TResult> Function()? _funcNoParam;

  RxCommandAsync._(
    AsyncFunc1<TParam, TResult>? func,
    Future<TResult> Function()? funcNoParam,
    Subject<TResult> subject,
    Stream<bool?>? restriction,
    bool emitLastResult,
    bool isBehaviourSubject,
    bool emitInitialCommandResult,
    TResult? initialLastResult,
    bool noResult,
    String? debugName,
    bool noParamValue,
  )   : _func = func,
        _funcNoParam = funcNoParam,
        super(subject, restriction, emitLastResult, isBehaviourSubject,
            initialLastResult, noResult, debugName, noParamValue) {
    if (emitInitialCommandResult) {
      _commandResultsSubject
          .add(CommandResult<TParam, TResult>(null, null, null, false));
    }
  }

  factory RxCommandAsync(
      AsyncFunc1<TParam, TResult>? func,
      Future<TResult> Function()? funcNoParam,
      Stream<bool?>? registration,
      bool emitInitialCommandResult,
      bool emitLastResult,
      bool emitsLastValueToNewSubscriptions,
      TResult? initialLastResult,
      bool noResult,
      String? debugName,
      bool noParamValue) {
    return RxCommandAsync._(
        func,
        funcNoParam,
        emitsLastValueToNewSubscriptions || emitInitialCommandResult
            ? BehaviorSubject<TResult>()
            : PublishSubject<TResult>(),
        registration,
        emitLastResult,
        emitsLastValueToNewSubscriptions || emitInitialCommandResult,
        emitInitialCommandResult,
        initialLastResult,
        noResult,
        debugName,
        noParamValue);
  }

  @override
  execute([TParam? param]) {
    //print("************ Execute***** canExecute: $_canExecute ***** isExecuting: $_isRunning");

    if (!_canExecute) {
      return;
    }

    if (_isRunning) {
      return;
    } else {
      _isRunning = true;
      _canExecuteSubject.add(false);
    }

    _commandResultsSubject.add(CommandResult<TParam, TResult>(param,
        _includeLastResultInCommandResults ? lastResult : null, null, true));

    assert(
        (!_noParamValue && (param != null || null is TParam) ||
            (_noParamValue && param == null)),
        'You called a RxCommand with no parameters with a parameter or one with a parameter without or a null value!');
    final asyncFunc =
        _noParamValue ? _funcNoParam! : () => _func!(param as TParam);

    asyncFunc().asStream().handleError((error) {
      if (throwExceptions) {
        if (error is Object) {
          _resultsSubject.addError(error);
          _commandResultsSubject.addError(error);
        }
        _isRunning = false;
        _isExecutingSubject.add(
            false); // Has to be done because in this case no command result is queued
        _canExecute = !_executionLocked;
        _canExecuteSubject.add(!_executionLocked);
        return;
      }

      final commandResult = CommandResult<TParam, TResult>(param,
          _includeLastResultInCommandResults ? lastResult : null, error, false);
      _commandResultsSubject.add(commandResult);

      RxCommand.globalExceptionHandler
          ?.call(_debugName, CommandError(param, error));
      RxCommand.loggingHandler?.call(_debugName, commandResult);

      _isRunning = false;
      _canExecute = !_executionLocked;
      _canExecuteSubject.add(!_executionLocked);
    }).listen((result) {
      final commandResult =
          CommandResult<TParam, TResult>(param, result, null, false);
      _commandResultsSubject.add(commandResult);
      lastResult = result;
      _resultsSubject.add(result);

      RxCommand.loggingHandler?.call(_debugName, commandResult);

      _isRunning = false;
      _canExecute = !_executionLocked;
      _canExecuteSubject.add(!_executionLocked);
    });
  }
}

class RxCommandStream<TParam, TResult> extends RxCommand<TParam, TResult> {
  StreamProvider<TParam, TResult> _streamProvider;

  StreamSubscription<StreamNotification<TResult>>? _inputStreamSubscription;

  RxCommandStream._(
      StreamProvider<TParam, TResult> streamProvider,
      Subject<TResult> subject,
      Stream<bool>? restriction,
      bool emitLastResult,
      bool isBehaviourSubject,
      bool emitInitialCommandResult,
      TResult? initialLastResult,
      bool noResult,
      String? debugName,
      bool noParamValue)
      : _streamProvider = streamProvider,
        super(subject, restriction, emitLastResult, isBehaviourSubject,
            initialLastResult, noResult, debugName, noParamValue) {
    if (emitInitialCommandResult) {
      _commandResultsSubject
          .add(CommandResult<TParam, TResult>(null, null, null, false));
    }
  }

  factory RxCommandStream(
      StreamProvider<TParam, TResult> streamProvider,
      Stream<bool>? restriction,
      bool emitInitialCommandResult,
      bool emitLastResult,
      bool emitsLastValueToNewSubscriptions,
      TResult? initialLastResult,
      bool noResult,
      String? debugName,
      bool noParamValue) {
    return RxCommandStream._(
        streamProvider,
        emitsLastValueToNewSubscriptions || emitInitialCommandResult
            ? BehaviorSubject<TResult>()
            : PublishSubject<TResult>(),
        restriction,
        emitLastResult,
        emitsLastValueToNewSubscriptions || emitInitialCommandResult,
        emitInitialCommandResult,
        initialLastResult,
        noResult,
        debugName,
        noParamValue);
  }

  @override
  execute([TParam? param]) {
    if (!_canExecute) {
      return;
    }

    if (_isRunning) {
      return;
    } else {
      _isRunning = true;
      _canExecuteSubject.add(false);
    }

    _commandResultsSubject.add(CommandResult<TParam, TResult>(param,
        _includeLastResultInCommandResults ? lastResult : null, null, true));

    var inputStream = _streamProvider(param);

    _inputStreamSubscription = inputStream.materialize().listen(
      (StreamNotification<TResult> notification) {
        if (notification.isData) {
          _resultsSubject.add(notification.requireDataValue);
          var commandResult =
              CommandResult(param, notification.requireDataValue, null, true);
          _commandResultsSubject.add(commandResult);
          RxCommand.loggingHandler?.call(_debugName, commandResult);

          lastResult = notification.requireDataValue;
        } else if (notification.isError) {
          if (throwExceptions) {
            _resultsSubject
                .addError(notification.errorAndStackTraceOrNull!.error);
            _commandResultsSubject
                .addError(notification.errorAndStackTraceOrNull!.error);
          } else {
            final commandResult = CommandResult<TParam, TResult>(param, null,
                notification.errorAndStackTraceOrNull!.error, false);
            _commandResultsSubject.add(commandResult);
            RxCommand.loggingHandler?.call(_debugName, commandResult);
          }
          RxCommand.globalExceptionHandler?.call(
              _debugName,
              CommandError(
                  param, notification.errorAndStackTraceOrNull!.error));
        } else if (notification.isDone) {
          final commandResult = CommandResult(param, lastResult, null, false);
          _commandResultsSubject.add(commandResult);

          RxCommand.loggingHandler?.call(_debugName, commandResult);
          _isRunning = false;
          _canExecuteSubject.add(!_executionLocked);
        }
      },
      onError: (error) {
        print(error);
      },
    );
  }

  @override
  void dispose() {
    _inputStreamSubscription?.cancel();
    super.dispose();
  }
}

/// `MockCommand` allows you to easily mock an RxCommand for your Unit and UI tests
/// Mocking a command with `mockito` https://pub.dartlang.org/packages/mockito has its limitations.
class MockCommand<TParam, TResult> extends RxCommand<TParam, TResult> {
  List<CommandResult<TParam, TResult>>? returnValuesForNextExecute;

  /// the last value that was passed when execute or the command directly was called
  TParam? lastPassedValueToExecute;

  /// Number of times execute or the command directly was called
  int executionCount = 0;

  /// Factory constructor that can take an optional observable to control if the command can be executet
  factory MockCommand({
    Stream<bool>? restriction,
    bool emitInitialCommandResult = false,
    bool emitLastResult = false,
    bool emitsLastValueToNewSubscriptions = false,
    TResult? initialLastResult,
    String? debugName,
  }) {
    return MockCommand._(
        emitsLastValueToNewSubscriptions
            ? BehaviorSubject<TResult>()
            : PublishSubject<TResult>(),
        restriction,
        emitLastResult,
        false,
        emitInitialCommandResult,
        initialLastResult,
        debugName);
  }

  MockCommand._(
    Subject<TResult> subject,
    Stream<bool>? restriction,
    bool emitLastResult,
    bool isBehaviourSubject,
    bool emitInitialCommandResult,
    TResult? initialLastResult,
    String? debugName,
  ) : super(subject, restriction, emitLastResult, isBehaviourSubject,
            initialLastResult, false, debugName, false) {
    if (emitInitialCommandResult) {
      _commandResultsSubject
          .add(CommandResult<TParam, TResult>(null, null, null, false));
    }
    _commandResultsSubject
        .where((result) => result.hasData)
        .listen((result) => _resultsSubject.add(result.data!));
  }

  /// to be able to simulate any output of the command when it is called you can here queue the output data for the next exeution call
  queueResultsForNextExecuteCall(List<CommandResult<TParam, TResult>> values) {
    returnValuesForNextExecute = values;
  }

  /// Can either be called directly or by calling the object itself because RxCommands are callable classes
  /// Will increase [executionCount] and assign [lastPassedValueToExecute] the value of [param]
  /// If you have queued a result with [queueResultsForNextExecuteCall] it will be copies tho the output stream.
  /// [isExecuting], [canExecute] and [results] will work as with a real command.
  @override
  execute([TParam? param]) {
    _canExecuteSubject.add(false);
    executionCount++;
    lastPassedValueToExecute = param;
    print("Called Execute");
    if (returnValuesForNextExecute != null) {
      _commandResultsSubject.addStream(
        Stream<CommandResult<TParam, TResult>>.fromIterable(
                returnValuesForNextExecute!)
            .map(
          (data) {
            if ((data.isExecuting || data.hasError) &&
                _includeLastResultInCommandResults) {
              return CommandResult<TParam, TResult>(
                  param, lastResult, data.error, data.isExecuting);
            }
            return data;
          },
        ),
      );
    } else {
      print("No values for execution queued");
    }
    _canExecuteSubject.add(true);
  }

  /// For a more fine grained control to simulate the different states of an [RxCommand]
  /// there are these functions
  /// `startExecution` will issue a [CommandResult] with
  /// paramData: null
  /// data: null
  /// error: null
  /// isExecuting : true
  void startExecution([TParam? param]) {
    lastPassedValueToExecute = param;
    _commandResultsSubject.add(CommandResult(param,
        _includeLastResultInCommandResults ? lastResult : null, null, true));
    _canExecuteSubject.add(false);
  }

  /// `endExecutionWithData` will issue a [CommandResult] with
  /// data: [data]
  /// error: null
  /// isExecuting : false
  void endExecutionWithData(TResult data) {
    lastResult = data;
    _commandResultsSubject
        .add(CommandResult(lastPassedValueToExecute, data, null, false));
    _canExecuteSubject.add(true);
  }

  /// `endExecutionWithData` will issue a [CommandResult] with
  /// data: null
  /// error: Exeption([message])
  /// isExecuting : false
  void endExecutionWithError(String message) {
    _commandResultsSubject.add(CommandResult(
        lastPassedValueToExecute,
        _includeLastResultInCommandResults ? lastResult : null,
        Exception(message),
        false));
    _canExecuteSubject.add(true);
  }

  /// `endExecutionNoData` will issue a [CommandResult] with
  /// data: null
  /// error: null
  /// isExecuting : false
  void endExecutionNoData() {
    _commandResultsSubject.add(CommandResult(lastPassedValueToExecute,
        _includeLastResultInCommandResults ? lastResult : null, null, true));
    _canExecuteSubject.add(true);
  }
}
