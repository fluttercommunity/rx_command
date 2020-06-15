import 'dart:async';
import 'package:rxdart/rxdart.dart';
import 'package:rx_command/rx_command.dart';

class RxCommandListener<TParam, TResult> {
  StreamSubscription<TResult> valueSubscription;
  StreamSubscription<CommandResult> resultsSubscription;
  StreamSubscription<bool> busyChangeSubscription;
  StreamSubscription<bool> busySubscription;
  StreamSubscription errorSubscription;
  StreamSubscription<bool> canExecuteStateSubscription;

  final RxCommand<TParam, TResult> command;

  // Is called on every emitted value of the command
  final void Function(TResult value) onValue;
  // Is called when isExecuting changes
  final void Function(bool isBusy) onIsBusyChange;
  // Is called on exceptions in the wrapped command function
  final void Function(dynamic ex) onError;
  // Is called when canExecute changes
  final void Function(bool state) onCanExecuteChange;
  // is called with the value of the .results Observable of the command
  final void Function(CommandResult<TResult> result) onResult;

  // to make the handling of busy states even easier these are called on their respective states
  final void Function() onIsBusy;
  final void Function() onNotBusy;

  // optional you can directly pass in a debounce duration for the values of the command
  final Duration debounceDuration;

  RxCommandListener(
    this.command, {
    this.onValue,
    this.onIsBusyChange,
    this.onIsBusy,
    this.onNotBusy,
    this.onError,
    this.onCanExecuteChange,
    this.onResult,
    this.debounceDuration,
  }) {
    if (debounceDuration == null) {
      if (onValue != null) {
        valueSubscription = command.listen(onValue);
      }

      if (onResult != null) {
        resultsSubscription = command.results.listen(onResult);
      }

      if (onIsBusyChange != null) {
        busyChangeSubscription = command.isExecuting.listen(onIsBusyChange);
      }
      if (onIsBusy != null || onNotBusy != null) {
        busySubscription = command.isExecuting.listen((isBusy) {
          return isBusy ? this.onIsBusy?.call() : this.onNotBusy?.call();
        });
      }
    } else {
      if (onValue != null) {
        valueSubscription =
            command.debounceTime(debounceDuration).listen(onValue);
        if (onResult != null && debounceDuration != null) {
          resultsSubscription =
              command.results.debounceTime(debounceDuration).listen(onResult);
        }

        if (onIsBusyChange != null) {
          busyChangeSubscription = command.isExecuting
              .debounceTime(debounceDuration)
              .listen(onIsBusyChange);
        }

        if (onIsBusy != null || onNotBusy != null) {
          busySubscription = command.isExecuting
              .debounceTime(debounceDuration)
              .listen((isBusy) =>
                  isBusy ? this.onIsBusy?.call() : this.onNotBusy?.call());
        }
      }
    }
    if (onError != null) {
      errorSubscription = command.thrownExceptions.listen(onError);
    }

    if (onCanExecuteChange != null) {
      canExecuteStateSubscription =
          command.canExecute.listen(onCanExecuteChange);
    }
  }

  void dispose() {
    busyChangeSubscription?.cancel();
    valueSubscription?.cancel();
    resultsSubscription?.cancel();
    busySubscription?.cancel();
    errorSubscription?.cancel();
    canExecuteStateSubscription?.cancel();
  }
}
