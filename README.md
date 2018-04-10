# RxCommand

`RxCommand` is an [_Reactive Extensions_ (Rx)](http://reactivex.io/) based abstraction for event handlers. It is based on `ReactiveCommand` for the [ReactiveUI](https://reactiveui.net/) framework. It makes heavy use of the [RxDart](https://github.com/ReactiveX/rxdart) package.

If you don't know Rx think of it as Dart `Streams` on steroids. `RxCommand` capsules a given handler function that can then be executed by its `execute` method. The result of this method is then published through its `results` Observable (Observable wrap Dart Streams). Additionally it offers Observables for it's current execution state, fs the command can be executed and for all possibly thrown exceptions during command execution.


## Getting Started

Add to your `pubspec.yaml` dependencies to `rxdart`and `rx_command`. (As long as the package is not published to Dart Packages please see the dependency entry of the sample App) 

An `RxCommand` is a generic class of type `RxCommand<TParam, TRESULT>` where `TPARAM` is the type of data that is passed when calling `execute` and `TResult` denotes the return type of the handler function. To signal that a handler doesn't take a parameter or returns a value use the dummy type `Unit`

An example of the declaration from the included sample App

```C#
RxCommand<String,List<WeatherEntry>>  updateWeatherCommand;
RxCommand<bool,bool>  switchChangedCommand;
```

`updateWeatherCommand` expects a handler that takes a `String` as parameter and returns a `List<WeatherEntry>`. `switchChangedCommand` expects and returns a `bool` value 


 For the different variations of possible handler methods RxCommand offers several factory methods for synchronous and asynchronous handlers. Due to the limitation that Dart doesn't allow method overloading they are numbered and look like this.

```Dart
  /// Creates  a RxCommand for a synchronous handler function with no parameter and no return type 
  /// `action`: handler function
  /// `canExecute` : observable that can bve used to enable/diable the command based on some other state change
  /// if omitted the command can be executed always except it's already executing
  static RxCommand<Unit, Unit> createSync(Action action,[Observable<bool> canExecute])

```

The sample App contains a `Switch` widget that enables/disables the update command. The switch itself is bound to the `switchChangedCommand` that's result is then used as `canExcecute` of the `updateWeatherCommand`:

```C#
switchChangedCommand = RxCommand.createSync3<bool,bool>((b)=>b);

// We pass the result of switchChangedCommand as canExecute Observable to the upDateWeatherCommand
updateWeatherCommand = RxCommand.createAsync3<String,List<WeatherEntry>>(update,switchChangedCommand.results);
```









