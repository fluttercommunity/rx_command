## [5.3.0] - 15.01.2020

 * updated to rxdart 0.25.0
 * fixed iOS build settings in example project

## [5.2.1] - 16.09.2020

 * documentation fixes and small improvements by @AlexBacich thanks a lot!!!
 
## [5.2.0] - 03.08.2020

 * Fhttps://github.com/fluttercommunity/rx_command/issues/44
 
## [5.1.0] - 23.06.2020

 * PR by @AlexBacich and @nosmirck with a lot of little fixes

 * Updated dependency to rxdart
 
## [5.0.3] - 19.03.2020

 * Added helpful factory constructors to CommandResult

## [5.0.2] - 29.01.2020

 * https://github.com/fluttercommunity/rx_command/issues/36

## [5.0.1] - 29.12.2019

 * Removed Flutter dependency

## [5.0.0] - 28.12.2019

 * Adapted to rxdart ^0.23.1 by abandoning Observables and use the new extension methods

## [4.3.4] - 28.12.2019

 * Fix for https://github.com/fluttercommunity/rx_command/issues/32

 * Fix for https://github.com/fluttercommunity/rx_command/issues/33

## [4.3.3] - 03.12.2019

 * fix for https://github.com/fluttercommunity/rx_command/issues/31

 * https://github.com/fluttercommunity/rx_command/issues/28

## [4.3.2] - 23.08.2019

 * fix for https://github.com/fluttercommunity/rx_command/issues/26

 If you encounter any problems please file an issue.

## [4.3.1+2] - 16.07.2019

 * PR with spelling corrections

## [4.3.1+1] - 26.06.2019

 * updated logo in readme

## [4.3.1] - 07.05.2019

 * Version bump to rxdart: ^0.22.0

## [4.3.0] - 29.03.2019

* Bug fix in RxCommandListener
* Adding `next`property:

```  	
  /// This property is a utility which allows us to chain RxCommands together.
  Future<TResult> get next => Observable.merge([this, this.thrownExceptions.cast<TResult>()]).take(1).last;
```

## [4.2.0] - 15.02.2019

* Thrown exceptions that are no descendants of the type Exceptions are no longer wrapped in an Exception object

## [4.1.2] - 05.02.2019

* bugfix: If you created a command with `RxCommand.createFromStream` the isExecuting state was not set correctly

## [4.1.1] - 04.02.2019

* bugfix https://github.com/fluttercommunity/rx_command/issues/9

## [4.1.0] - 01.01.2019

* added RxCommandListener

## [4.0.2] - 30.10.2018

* removed dependency to json_annotations

## [4.0.1] - 07.09.2018

* Updated to rxdart v 0.19.0

## [4.0.0] - 07.09.2018

* **BREAKING CHANGE** All creation functions got renamed to be more descriptive than the numbered ones. The new variants are:

```Dart
static RxCommand<TParam, TResult> createSync<TParam, TResult>(Func1<TParam, TResult> func,...
static RxCommand<void, TResult> createSyncNoParam<TResult>(Func<TResult> func,...
static RxCommand<TParam, void> createSyncNoResult<TParam>(Action1<TParam> action,...
static RxCommand<void, void> createSyncNoParamNoResult(Action action,...

static RxCommand<TParam, TResult> createAsync<TParam, TResult>(AsyncFunc1<TParam, TResult> func,...
static RxCommand<void, TResult> createAsyncNoParam<TResult>(AsyncFunc<TResult> func,...
static RxCommand<TParam, void> createAsyncNoResult<TParam>(AsyncAction1<TParam> action,...
static RxCommand<void, void> createAsyncNoParamNoResult(AsyncAction action,...
```



## [3.0.0] - 07.09.2018

* IMPORTANT: As of V3.0 `CommandResult` objects are now emitted on the `.results` property and the pure results of the wrapped function on the RxCommand itself. So I switched the two because while working on RxVMS it turned out that I use the pure result much more often. Also the name of `.results` matches much better with `CommandResult`. If you don't want to change your code you can just stay on 2.06 if you don't need any of V 3.0 features. 
* Also you now can set an `initialLastResult` when creating an RxCommand.

## [2.0.3] - 21.06.2018

* Moved package to [Flutter Community](https://github.com/fluttercommunity)

## [2.0.4] - 19.08.2018

* Fixed `quiver_hashcode` dependency issue.

## [2.0.2] - 19.06.2018

* Update to RxDart 0.18.0

## [2.0.1] - 15.06.2018

* Bug fix. `createAsync` and `createAsync1` were missing an await.

## [2.0.0] - 06.06.2018

* Till now the `results` Observable and the `RxCommand` itself behaved like a `BehaviourSubjects`. This can lead to problems when using with Flutter.
From now on the default is `PublishSubject`. If you need `BehaviourSubject` behaviour, meaning every new listener gets the last received value, you can set `emitsLastValueToNewSubscriptions = true` when creating `RxCommand`.


## [1.1.0] - 08.05.2018

* Updated to accommodate a a breaking API change in RxDart 0.16.7 because no longer do Subjects expose an `observable` property because Subjects now implement Observable interface directly like other Rx implementation.

## [1.0.9] - 26.04.2018

* Added an `emitLastResult` parameter to RxCommand factory functions. If true the last result will be transmitted in the data field of `CommandResults` while `isExecuting==true` or `hasError==true`.


## [1.0.8] - 25.04.2018

* RxCommand no longer issues an initial `CommandResult(null,null,false)` unless you set `emitInitialCommandResult: true` when creating the command.

## [1.0.7] - 20.04.2018

* Forgot to run tests and missed an error that I introduced following an analyser hint that I should use `const` instead of `new` 

## [1.0.6] - 20.04.2018

* Polishing and including `analysis_options.yaml` 

## [1.0.5] - 20.04.2018

* Improvements and docs for MockCommand 

## [1.0.4] - 19.04.2018

* Added MockCommand 


## [1.0.3] - 17.04.2018

* RxCommands created by RxCommand.createFromStream no longer emit a final event after the last item of the source stream was received


## [1.0.2] - 16.04.2018

* Added CommandResult, now RxCommand is itself an Observable that emits CommandResults

## [1.0.1] - 11.04.2018

* Small update in docs

## [1.0.0] - 11.04.2018

* Made RxCommand a callable class so that you now can directly assign it to your widget handlers

## [0.0.3] - 10.04.2018

* Trying to fix the documentation link

## [0.0.2] - 10.04.2018

* Removed the necessity of type `Unit`. Instead now `Null` is used

## [0.0.1] - 10.04.2018

* Initial release.