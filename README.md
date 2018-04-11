# RxCommand

`RxCommand` is an [_Reactive Extensions_ (Rx)](http://reactivex.io/) based abstraction for event handlers. It is based on `ReactiveCommand` for the [ReactiveUI](https://reactiveui.net/) framework. It makes heavy use of the [RxDart](https://github.com/ReactiveX/rxdart) package.

>PRs are always welcome ;-)

If you don't know Rx think of it as Dart `Streams` on steroids. `RxCommand` capsules a given handler function that can then be executed by its `execute` method or directly assigned to a widget's handler because it's a callable class. The result of this method is then published through its `results` Observable (Observable wrap Dart Streams). Additionally it offers Observables for it's current execution state, if the command can be executed and for all possibly thrown exceptions during command execution.

A very simple example

```Dart
final command = RxCommand.createSync3<int, String>((myInt) => "$myInt");

command.results.listen((s) => print(s)); // Setup the listener that now waits for events, not doing anything

// Somwhere else
command.execute(10); // the listener will print "10"
```

Getting a bit more impressive:

```Dart
// This command will be executed everytime the text in a TextField changes
final textChangedCommand = RxCommand.createSync3((s) => s);

// handler for results
textChangedCommand.results
  .debounce( new Duration(milliseconds: 500))  // Rx magic: make sure we start processing 
                                               // only if the user make a short pause typing 
    .listen( (filterText)
    {
      updateWeatherCommand.execute( filterText); // I could omit he execute because RxCommand is a callable class but here it 
                                                  //  makes the intention clearer
    });  

```


## Getting Started

Add to your `pubspec.yaml` dependencies to `rxdart`and `rx_command`.  

An `RxCommand` is a generic class of type `RxCommand<TParam, TRESULT>` where `TPARAM` is the type of data that is passed when calling `execute` and `TResult` denotes the return type of the handler function. To signal that a handler doesn't take a parameter or returns a `Null` value. 

An example of the declaration from the included sample App

```Dart
RxCommand<String,List<WeatherEntry>>  updateWeatherCommand;
RxCommand<bool,bool>  switchChangedCommand;
```

`updateWeatherCommand` expects a handler that takes a `String` as parameter and returns a `List<WeatherEntry>`. `switchChangedCommand` expects and returns a `bool` value 

### Creating RxCommands

 For the different variations of possible handler methods RxCommand offers several factory methods for synchronous and asynchronous handlers. Due to the limitation that Dart doesn't allow method overloading they are numbered and look like this.

```Dart
  /// Creates  a RxCommand for a synchronous handler function with no parameter and no return type 
  /// `action`: handler function
  /// `canExecute` : observable that can bve used to enable/diable the command based on some other state change
  /// if omitted the command can be executed always except it's already executing
  static RxCommand<Null, Null> createSync(Action action,[Observable<bool> canExecute])

```

The sample App contains a `Switch` widget that enables/disables the update command. The switch itself is bound to the `switchChangedCommand` that's result is then used as `canExcecute` of the `updateWeatherCommand`:

```Dart
switchChangedCommand = RxCommand.createSync3<bool,bool>((b)=>b);

// We pass the result of switchChangedCommand as canExecute Observable to the upDateWeatherCommand
updateWeatherCommand = RxCommand.createAsync3<String,List<WeatherEntry>>(update,switchChangedCommand.results);
```

As the _Update_ `Button`'s building is based on a `StreamBuilder`that listens on the `canExecute` Observable of the `updateWeatherCommand` the buttons enabled/disabled state gets automatically updated when the `Switch's` state changes


### Using RxCommands

`RxCommand` is typically used in a ViewModel of a Page, which is made accessible to the Widgets via an `InheritedWidget`. Its `execute`method can then directly be assigned as event handler of the Widgets.

The `result` of the command is best used with a `StreamBuilder` or inside a StatefulWidget.

By subscribing (listening) to the `isExecuting` property of a RxCommand you can react on any execution state change of the command. E.g. show a spinner while the command is running.

By subscribing to the `canExecute` property of a RxCommand you can react on any state change of the executability of the command.

As RxCommand is a callable class you can assign it directly to handler functions of Flutter widgets like:

```Dart
new TextField(onChanged: TheViewModel.of(context).textChangedCommand,)
```

### Disposing subscriptions (listeners)
When subscribing to an Observable with `.listen` you should store the returned `StreamSubscription` and call `.cancel` on it if you want to cancel this subscription to a later point or if the object where the subscription is made is getting destroyed to avoid memory leaks.
`RxCommand` has a `dispose` function that will cancel all active subscriptions on its observables. Calling `dispose`before a command gets out of scope is a good practise.

## Exploring the sample App 

The best way to understand how `RxCommand` is used is to look at the supplied sample app which is a simple app that queries a REST API for weather data.

### The ViewModel

It follow the MVVM design pattern so all business logic is bundled in the `WeatherViewModel` class in weather_viewmodel.dart.

It is made accessible to the Widgets by using an [InheritedWidget](https://docs.flutter.io/flutter/widgets/InheritedWidget-class.html) which is defined in main.dart and returns and instance of `WeatherViewModel`when used like `TheViewModel.of(context)`

The view model publishes two commands 

* `updateWeatherCommand` which makes a call to the weather API and filters the result based on a string that is passed to execute. Its result will be bound to a `StreamBuilder`in your View.
* `switchChangedCommand` which will be bound to a `Switch` widget to enable/disable the `updateWeatherCommand.


### The View

`main.dart` creates the ViewModel and places it at the very base of the app`s widget tree.

`homepage.dart` creates a `Column` with a 

* `TextField` where you can enter a filter text which binds to the ViewModels `textChangedCommand`.

* a middle block which can either be a `ListView` (`WeatherListView`) or a busy spinner. It is created by a `StreamBuilder` which listens to <br/> `TheViewModel.of(context).updateWeatherCommand.isExecuting`<br/>
* A row with the Update `Button` and a `Switch` that toggles if an update should be possible or not by binding to `TheViewModel.of(context).switchChangedCommand)`. To change the enabled state of the button the button is build by a `StreamBuilder` that listens to the  `TheViewModel.of(context).updateWeatherCommand.canExecute` 

`listview.dart` implements `WeatherListView` which consists again of a StreamBuilder which updates automatically by listening on `TheViewModel.of(context).updateWeatherCommand.results`








