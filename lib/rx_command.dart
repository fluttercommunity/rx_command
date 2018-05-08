library rx_command;

import 'dart:async';

import 'package:quiver_hashcode/hashcode.dart';
import 'package:rxdart/rxdart.dart';



typedef Action = void Function();
typedef Action1<TParam> = void Function(TParam param);


typedef Func<TResult> = TResult Function();
typedef Func1<TParam, TResult> = TResult Function(TParam param);

typedef AsyncAction = Future Function();
typedef AsyncAction1<TParam> = Future Function(TParam param);


typedef AsyncFunc<TResult> = Future<TResult> Function();
typedef AsyncFunc1<TParam, TResult> = Future<TResult> Function(TParam param);

typedef StreamProvider<TParam, TResult> = Stream<TResult> Function(TParam param);

/// Combined execution state of an `RxCommand`
/// Will be issued for any statechange of any of the fields
/// During normal command execution you will get this items if directly listening at the command.
/// 1. If the command was just newly created you will get `null, false, false` (data, error, isExecuting)
/// 2. When calling execute: `null, false, true`
/// 3. When exceution finishes: `the result, false, false`

class CommandResult<T>
{
  final T         data;
  final Exception error;
  final bool      isExecuting;

  // ignore: avoid_positional_boolean_parameters
  const CommandResult(this.data, this.error, this.isExecuting);

  bool get hasData => data != null;
  bool get hasError => error != null;

  @override
  bool operator == (Object other) => other is CommandResult<T> && other.data == data &&
                         other.error == error &&
                         other.isExecuting ==isExecuting;  
  @override
    int get hashCode => hash3(data.hashCode,error.hashCode,isExecuting.hashCode);
  

}



/// [RxCommand] capsules a given handler function that can then be executed by its [execute] method. 
/// The result of this method is then published through its [results] Observable (Observable wrap Dart Streams)
/// Additionally it offers Observables for it's current execution state, fs the command can be executed and for 
/// all possibly thrown exceptions during command execution.
/// [RxCommand] also implments the `Observable` interface so you can listen directly to the [RxCommand] which emitts 
/// [CommandResult<TRESULT>] which is often easier in combaination with Flutter `StreamBuilder` because you have all 
/// state information at one place.
///
/// An [RxCommand] is a generic class of type [RxCommand<TParam, TRESULT>] 
/// where [TParam] is the type of data that is passed when calling [execute] and 
/// [TResult] denotes the return type of the handler function. To signal that 
/// a handler doesn't take a parameter or returns no value use the dummy type `Null`
abstract class RxCommand<TParam, TResult> extends Observable<CommandResult<TResult>>
{
  bool _isRunning = false;
  bool _canExecute = true;
  bool _executionLocked = false;

  bool _emitLastResult;


  /// The result of the last sucessful call to execute
  TResult lastResult;


  RxCommand(this._commandResultsSubject, Observable<bool> canExecuteRestriction,  this._emitLastResult):super(_commandResultsSubject)
  {
      this
        .where( (x) => x.hasError)
          .listen((x) => _thrownExceptionsSubject.add(x.error));
          
      this
        .listen((x) => _isExecutingSubject.add(x.isExecuting));

       final _canExecuteParam = canExecuteRestriction == null ? new Observable<bool>.just(true) 
                                                  : canExecuteRestriction.handleError((error)
                                                    {
                                                        if (error is Exception)
                                                        {
                                                          _thrownExceptionsSubject.add(error);
                                                        }
                                                    })
                                                    .distinct();
                                                                                                  


      _canExecuteParam.listen((canExecute){
        _canExecute = canExecute && (!_isRunning);
        _executionLocked = !canExecute;
        _canExecuteSubject.add(_canExecute);
      });    


  }

  /// Creates  a RxCommand for a synchronous handler function with no parameter and no return type 
  /// [action]: handler function
  /// [canExecute] : observable that can bve used to enable/diable the command based on some other state change
  /// if omitted the command can be executed always except it's already executing
  /// [isExecuting] will issue a `bool` value on each state change. Even if you 
  /// subscribe to a newly created command it will issue `false`
  /// For the `Observable<CommandResult>` that [RxCommand] implement this normally doesn't make sense
  /// if you want to get an initial Result with `data==null, error==null, isExceuting==false` pass
  /// [emitInitialCommandResult=true].
  static RxCommand<Null, Null> createSync(Action action,{Observable<bool> canExecute, bool emitInitialCommandResult = false})
  {
      return new RxCommandSync<Null,Null>((_) {action(); return null;},canExecute, emitInitialCommandResult,false);
  }

  /// Creates  a RxCommand for a synchronous handler function with one parameter and no return type 
  /// `action`: handler function
  /// `canExecute` : observable that can bve used to enable/diable the command based on some other state change
  /// if omitted the command can be executed always except it's already executing
  /// [isExecuting] will issue a `bool` value on each state change. Even if you 
  /// subscribe to a newly created command it will issue `false`
  /// For the `Observable<CommandResult>` that [RxCommand] implement this normally doesn't make sense
  /// if you want to get an initial Result with `data==null, error==null, isExceuting==false` pass
  /// [emitInitialCommandResult=true].
  static RxCommand<TParam, Null> createSync1<TParam>(Action1<TParam> action, {Observable<bool> canExecute, bool emitInitialCommandResult = false})
  {
      return new RxCommandSync<TParam,Null>((x) {action(x); return null;},canExecute, emitInitialCommandResult,false);
  }

  /// Creates  a RxCommand for a synchronous handler function with no parameter that returns a value 
  /// `func`: handler function
  /// `canExecute` : observable that can bve used to enable/diable the command based on some other state change
  /// if omitted the command can be executed always except it's already executing
  /// [isExecuting] will issue a `bool` value on each state change. Even if you 
  /// subscribe to a newly created command it will issue `false`
  /// [emitLastResult] will include the value of the last successful execution in all [CommandResult] events unless there is no new result.
  /// For the `Observable<CommandResult>` that [RxCommand] implement this normally doesn't make sense
  /// if you want to get an initial Result with `data==null, error==null, isExceuting==false` pass
  /// [emitInitialCommandResult=true].
  static RxCommand<Null, TResult> createSync2<TResult>(Func<TResult> func,{Observable<bool> canExecute, bool emitInitialCommandResult = false, bool emitLastResult=false})
  {
      return new RxCommandSync<Null,TResult>((_) => func(),canExecute, emitInitialCommandResult,emitLastResult);
  }

  /// Creates  a RxCommand for a synchronous handler function with parameter that returns a value 
  /// `func`: handler function
  /// `canExecute` : observable that can bve used to enable/diable the command based on some other state change
  /// if omitted the command can be executed always except it's already executing
   /// [isExecuting] will issue a `bool` value on each state change. Even if you 
  /// subscribe to a newly created command it will issue `false`
  /// [emitLastResult] will include the value of the last successful execution in all [CommandResult] events unless there is no new result.
  /// For the `Observable<CommandResult>` that [RxCommand] implement this normally doesn't make sense
  /// if you want to get an initial Result with `data==null, error==null, isExceuting==false` pass
  /// [emitInitialCommandResult=true].
 static RxCommand<TParam, TResult> createSync3<TParam, TResult>(Func1<TParam,TResult> func,{Observable<bool> canExecute, bool emitInitialCommandResult = false, bool emitLastResult=false})
  {
      return new RxCommandSync<TParam,TResult>((x) => func(x),canExecute,emitInitialCommandResult,emitLastResult);
  }    


  // Assynchronous

  /// Creates  a RxCommand for an asynchronous handler function with no parameter and no return type 
  /// `action`: handler function
  /// `canExecute` : observable that can bve used to enable/diable the command based on some other state change
  /// if omitted the command can be executed always except it's already executing
   /// [isExecuting] will issue a `bool` value on each state change. Even if you 
  /// subscribe to a newly created command it will issue `false`
  /// For the `Observable<CommandResult>` that [RxCommand] implement this normally doesn't make sense
  /// if you want to get an initial Result with `data==null, error==null, isExceuting==false` pass
  /// [emitInitialCommandResult=true].
 static RxCommand<Null, Null> createAsync(AsyncAction action,{Observable<bool> canExecute, bool emitInitialCommandResult = false})
  {
      return new RxCommandAsync<Null,Null>((_)  { action(); return  null;},canExecute,emitInitialCommandResult,false);
  }


  /// Creates  a RxCommand for an asynchronous handler function with one parameter and no return type 
  /// `action`: handler function
  /// `canExecute` : observable that can bve used to enable/diable the command based on some other state change
  /// if omitted the command can be executed always except it's already executing
  /// [isExecuting] will issue a `bool` value on each state change. Even if you 
  /// subscribe to a newly created command it will issue `false`
  /// For the `Observable<CommandResult>` that [RxCommand] implement this normally doesn't make sense
  /// if you want to get an initial Result with `data==null, error==null, isExceuting==false` pass
  /// [emitInitialCommandResult=true].
  static RxCommand<TParam, Null> createAsync1<TParam>(AsyncAction1<TParam> action,{Observable<bool> canExecute, bool emitInitialCommandResult = false})
  {
      return new RxCommandAsync<TParam,Null>((x) {action(x); return null;} ,canExecute, emitInitialCommandResult,false);
  }

  /// Creates  a RxCommand for an asynchronous handler function with no parameter that returns a value 
  /// `func`: handler function
  /// `canExecute` : observable that can bve used to enable/diable the command based on some other state change
  /// if omitted the command can be executed always except it's already executing
  /// [isExecuting] will issue a `bool` value on each state change. Even if you 
  /// subscribe to a newly created command it will issue `false`
  /// [emitLastResult] will include the value of the last successful execution in all [CommandResult] events unless there is no new result.
  /// For the `Observable<CommandResult>` that [RxCommand] implement this normally doesn't make sense
  /// if you want to get an initial Result with `data==null, error==null, isExceuting==false` pass
  /// [emitInitialCommandResult=true].
  static RxCommand<Null, TResult> createAsync2<TResult>(AsyncFunc<TResult> func,{Observable<bool> canExecute, bool emitInitialCommandResult = false, bool emitLastResult=false})
  {
      return new RxCommandAsync<Null,TResult>((_) async => func(),canExecute, emitInitialCommandResult,emitLastResult);
  }

  /// Creates  a RxCommand for an asynchronous handler function with parameter that returns a value 
  /// `func`: handler function
  /// `canExecute` : observable that can bve used to enable/diable the command based on some other state change
  /// if omitted the command can be executed always except it's already executing
  /// [isExecuting] will issue a `bool` value on each state change. Even if you 
  /// subscribe to a newly created command it will issue `false`
  /// [emitLastResult] will include the value of the last successful execution in all [CommandResult] events unless there is no new result.
  /// For the `Observable<CommandResult>` that [RxCommand] implement this normally doesn't make sense
  /// if you want to get an initial Result with `data==null, error==null, isExceuting==false` pass
  /// [emitInitialCommandResult=true].
  static RxCommand<TParam, TResult> createAsync3<TParam, TResult>(AsyncFunc1<TParam,TResult> func, {Observable<bool> canExecute, bool emitInitialCommandResult = false, bool emitLastResult=false})
  {
      return new RxCommandAsync<TParam,TResult>((x) async => func(x),canExecute, emitInitialCommandResult,emitLastResult);
  }    

  /// Creates  a RxCommand from an "one time" observable. This is handy if used together with a streame generator function.  
  /// [provider]: provider function that returns a new Observable that will be subscribed on the call of [execute]
  /// [canExecute] : observable that can bve used to enable/diable the command based on some other state change
  /// if omitted the command can be executed always except it's already executing
  /// [isExecuting] will issue a `bool` value on each state change. Even if you 
  /// subscribe to a newly created command it will issue `false`
  /// [emitLastResult] will include the value of the last successful execution in all [CommandResult] events unless there is no new result.
  /// For the `Observable<CommandResult>` that [RxCommand] implement this normally doesn't make sense
  /// if you want to get an initial Result with `data==null, error==null, isExceuting==false` pass
  /// [emitInitialCommandResult=true].
  static RxCommand<TParam, TResult> createFromStream<TParam, TResult>(StreamProvider<TParam, TResult> provider, {Observable<bool> canExecute, bool emitInitialCommandResult = false, bool emitLastResult=false})
  {
      return new RxCommandStream<TParam, TResult>(provider,canExecute, emitInitialCommandResult,emitLastResult);
  }    

  /// Calls the wrapped handler function with an option input parameter
  void execute([TParam param]);

  void call([TParam param]) => execute(param); 

  /// Observable stream that outputs any result from the called handler function. If the handler function has void return type 
  /// it will still output one `Null` item so that you can listen for the end of the execution.
  Observable<TResult> get results => _resultsSubject;

  /// Observable stream that issues a bool on any execution state change of the command
  Observable<bool> get isExecuting => _isExecutingSubject.startWith(false).distinct();
  
  /// Observable stream that issues a bool on any change of the current executable state of the command. 
  /// Meaning if the command cann be executed or not. This will issue `false` while the command executes 
  /// but also if the command receives a false from the canExecute Observable that you can pass when creating the Command
  Observable<bool>  get canExecute  => _canExecuteSubject.startWith(true).distinct();

  /// When subribing to `thrownExceptions`you will every excetpion that was thrown in your handler function as an event on this Observable.
  /// If no subscription exists the Exception will be rethrown
  Observable<Exception> get thrownExceptions => _thrownExceptionsSubject;



  BehaviorSubject<CommandResult<TResult>> _commandResultsSubject;
  final BehaviorSubject<TResult> _resultsSubject = new BehaviorSubject<TResult>();  
  final BehaviorSubject<bool> _isExecutingSubject = new BehaviorSubject<bool>();  
  final BehaviorSubject<bool> _canExecuteSubject = new BehaviorSubject<bool>();  
  final PublishSubject<Exception> _thrownExceptionsSubject = new PublishSubject<Exception>();  

  /// By default `RxCommand` will catch all exceptions during exceution of the command. And publish them on `.thrownExceptions` 
  /// and in the `CommandResult`. If don't want this and have exceptions thrown, set this to true.
  bool throwExceptions = false;

  /// If you don't need a command any longer it is a good practise to 
  /// dispose it to make sure all stream subsriptions are cancelled to prevent memory leaks
  void dispose()
  {
      _isExecutingSubject.close();
      _canExecuteSubject.close();
      _thrownExceptionsSubject.close();
      _resultsSubject.close(); 
      _commandResultsSubject.close();
  }

}




/// Implementation of RxCommand to handle async handler functions. Normally you will not instanciate this directly but use one of the factory 
/// methods of RxCommand.
class RxCommandSync<TParam, TResult> extends RxCommand<TParam, TResult>
{
 
  Func1<TParam, TResult> _func;


  factory RxCommandSync(Func1<TParam, TResult> func, Observable<bool> canExecute, bool emitInitialCommandResult, bool buffer )
  {

    return new RxCommandSync._(func, new BehaviorSubject<CommandResult<TResult>>(seedValue: emitInitialCommandResult ?  new CommandResult<TResult>(null, null, false) : null ), canExecute, buffer);
  }

  RxCommandSync._(Func1<TParam, TResult> func, BehaviorSubject<CommandResult<TResult>> subject, 
                  Observable<bool> canExecute, bool buffer):_func=func, super(subject, canExecute, buffer);

  @override
  void execute([TParam param]) 
  {    
        if (!_canExecute)
        {
          return;
        }

        if (_isRunning)
        {
           return;
        }
        else
        {
          _isRunning = true;
          _canExecuteSubject.add(false);
        }

        _commandResultsSubject.add(new  CommandResult<TResult>(_emitLastResult ? lastResult : null, null,true));                 

        try {
          final  result = _func(param);
          lastResult = result;
          _commandResultsSubject.add(new  CommandResult<TResult>(result,null,false));    
          _resultsSubject.add(result);
        } 
        catch (error) 
        {
            if (throwExceptions)
            {
                _resultsSubject.addError(error);
                return;
            }

            if (error is Exception)
            {
              _commandResultsSubject.add(new CommandResult<TResult>(_emitLastResult ? lastResult : null,error,false));    
            }
            else
            {
              _commandResultsSubject.add(new CommandResult<TResult>(_emitLastResult ? lastResult : null,new Exception(error.toString()),false));    
            }
        }
        finally
        {
          _isRunning = false;
          _isExecutingSubject.add(false);
          _canExecuteSubject.add(!_executionLocked);
        }
  }
}


class RxCommandAsync<TParam, TResult> extends RxCommand<TParam, TResult>
{
 

  AsyncFunc1<TParam, TResult> _func;

  RxCommandAsync._(AsyncFunc1<TParam, TResult> func, BehaviorSubject<CommandResult<TResult>> subject, 
                  Observable<bool> canExecute, bool emitLastResult):_func= func, super(subject, canExecute, emitLastResult);
 
  factory RxCommandAsync(AsyncFunc1<TParam, TResult> func, Observable<bool> canExecute, bool emitInitialCommandResult, bool emitLastResult )
  {

    return new RxCommandAsync._(func, new BehaviorSubject<CommandResult<TResult>>(seedValue: emitInitialCommandResult ?  new CommandResult<TResult>(null, null, false) : null), canExecute, emitLastResult);
  }


  @override
  execute([TParam param]) 
  {


        // print("************ Execute***** canExecute: $_canExecute ***** isExecuting: $_isRunning");

        if (!_canExecute)
        {
          return;
        }

        if (_isRunning)
        {
           return;
        }
        else
        {
          _isRunning = true;
          _canExecuteSubject.add(false);
        }

        _commandResultsSubject.add(new CommandResult<TResult>(_emitLastResult ? lastResult : null,null,true));
  
        _func(param).asStream()          
          .handleError((error)
          {
            if (throwExceptions)
            {
                _resultsSubject.addError(error);
                return;
            }
            
              if (error is Exception)
              {
                _commandResultsSubject.add(new CommandResult<TResult>(_emitLastResult ? lastResult : null,error,false));    
              }
              else
              {
                _commandResultsSubject.add(new CommandResult<TResult>(_emitLastResult ? lastResult : null,new Exception(error.toString()),false));    
              }
              _isRunning = false;
              _isExecutingSubject.add(false);
              _canExecuteSubject.add(true);
              

          })
          
          .listen( (result) {
              _commandResultsSubject.add(new CommandResult<TResult>(result,null,false)); 
              lastResult = result;             
              _resultsSubject.add(result); 
              _isRunning = false;
              _canExecute = !_executionLocked;
              _canExecuteSubject.add(!_executionLocked);
         });
  }
} 


class RxCommandStream<TParam, TResult> extends RxCommand<TParam, TResult>
{
 
  StreamProvider<TParam,TResult> _observableProvider;


  RxCommandStream._(StreamProvider<TParam,TResult>  provider, BehaviorSubject<CommandResult<TResult>> subject, 
                  Observable<bool> canExecute, bool emitLastResult):_observableProvider= provider, super(subject, canExecute, emitLastResult);

   factory RxCommandStream(StreamProvider<TParam, TResult> provider, Observable<bool> canExecute, bool emitInitialCommandResult, bool emitLastResult )
  {

    return new RxCommandStream._(provider, new BehaviorSubject<CommandResult<TResult>>(seedValue: emitInitialCommandResult ?  new CommandResult<TResult>(null, null, false) : null), canExecute,emitLastResult);
  }


  @override
  execute([TParam param]) 
  {

        if (!_canExecute)
        {
          return;
        }

        if (_isRunning)
        {
           return;
        }
        else
        {
          _isRunning = true;
          _canExecuteSubject.add(false);
        }

        _isExecutingSubject.add(true);      
        _commandResultsSubject.add(new CommandResult<TResult>(_emitLastResult ? lastResult : null,null,true));
  

        Exception thrownException;

        var inputObservable = new Observable(_observableProvider(param))          
                                      .handleError((error)
                                      {
                                        
                                          if (error is Exception)
                                          { 
                                              thrownException = error;
                                          } 
                                          else
                                          {
                                            thrownException= new Exception(error.toString());
                                          }
                                      })
                                      .doOnData( (result) => _resultsSubject.add(result))
                                      .map( (result) {
                                        lastResult = result;                                       
                                        return new CommandResult(result, null, false);
                                      });

           _commandResultsSubject.addStream(inputObservable)                       
                                    .then((_) {

                                                if (thrownException != null)
                                                {
                                                    if (throwExceptions)
                                                    {
                                                        _resultsSubject.addError(thrownException);
                                                        _commandResultsSubject.addError(thrownException);
                                                    }
                                                    else
                                                    {
                                                      _thrownExceptionsSubject.add(thrownException);
                                                      _commandResultsSubject.add(new CommandResult<TResult>(null,thrownException,false));                                                      
                                                    }

                                                }
                                                _isRunning = false;
                                                _canExecuteSubject.add(!_executionLocked);
                                            }, onError: (error) {
                                                print(error);
                                            });
  }
} 
 
/// `MockCommand` allows you to easily moch an RxCommand for your Unit and UI tests
/// Mocking a command with `mockito` https://pub.dartlang.org/packages/mockito has its limitations.
class MockCommand<TParam,TResult>  extends RxCommand<TParam,TResult>
{

  List<CommandResult<TResult>> returnValuesForNextExecute;
  BehaviorSubject<CommandResult<TResult>> subject;


  /// the last value that was passed when execute or the command directly was called
  TParam lastPassedValueToExecute;

  /// Number of times execute or the command directly was called
  int executionCount = 0; 

  /// Factory constructor that can take an optional observable to control if the command can be executet
  factory MockCommand({Observable<bool> canExecute, bool emitInitialCommandResult = false, bool emitLastResult = false} )
  {

    return new MockCommand._(new BehaviorSubject<CommandResult<TResult>>(seedValue: emitInitialCommandResult ?  new CommandResult<TResult>(null, null, false) : null), canExecute,emitLastResult);
  }

  MockCommand._(this.subject, 
                Observable<bool> canExecute, bool emitLastResult):super(subject,canExecute, emitLastResult);


  /// to be able to simulate any output of the command when it is called you can here queue the output data for the next exeution call
  queueResultsForNextExecuteCall(List<CommandResult<TResult>> values)
  {
      returnValuesForNextExecute = values;
  }

  /// Can either be called directly or by calling the object itself because RxCommands are callable classes
  /// Will increase [executionCount] and assign [lastPassedValueToExecute] the value of [param]
  /// If you have queued a result with [queueResultsForNextExecuteCall] it will be copies tho the output stream.
  /// [isExecuting], [canExecute] and [results] will work as with a real command.  
  @override
  execute([TParam param])  {
    _canExecuteSubject.add(false);
    executionCount++;
    lastPassedValueToExecute  = param;
     print("Called Execute");
     if (returnValuesForNextExecute != null)
     {
        subject.addStream(new Observable<CommandResult<TResult>>
                                .fromIterable (returnValuesForNextExecute)
                                  .map((data) 
                                    { 
                                      if ((data.isExecuting || data.hasError) && _emitLastResult)
                                      {
                                          return new CommandResult<TResult>(lastResult, data.error, data.isExecuting);
                                      }
                                      return data;
                                    }));  
     }
     else
     {
       print("No values for execution queued");

     }
    _canExecuteSubject.add(true);
  }


  /// For a more fine grained control to simulate the different states of an [RxCommand]
  /// there are these functions
  /// `startExecution` will issue a [CommandResult] with
  /// data: null
  /// error: null
  /// isExecuting : true
  void startExecution()
  {
    subject.add(new CommandResult(_emitLastResult ? lastResult : null,null,true));
    _canExecuteSubject.add(false);
  }

  /// `endExecutionWithData` will issue a [CommandResult] with
  /// data: [data]
  /// error: null
  /// isExecuting : false
  void endExecutionWithData(TResult data)
  {
    lastResult = data;
    subject.add(new CommandResult<TResult>(data,null,false));
    _canExecuteSubject.add(true);
  }

  /// `endExecutionWithData` will issue a [CommandResult] with
  /// data: null
  /// error: Exeption([message])
  /// isExecuting : false
  void endExecutionWithError(String message)
  {
    subject.add(new CommandResult<TResult>(_emitLastResult ? lastResult : null,new Exception(message),false));
    _canExecuteSubject.add(true);
  }

  /// `endExecutionNoData` will issue a [CommandResult] with
  /// data: null
  /// error: null
  /// isExecuting : false
  void endExecutionNoData()
  {
    subject.add(new CommandResult<TResult>(_emitLastResult ? lastResult : null,null,true));
    _canExecuteSubject.add(true);
  }

}


