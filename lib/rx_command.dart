library rx_command;

import 'dart:async';

import 'package:rxdart/rxdart.dart';

typedef void Action();
typedef void Action1<TParam>(TParam param);


typedef TResult Func<TResult>();
typedef TResult Func1<TParam, TResult>(TParam param);

typedef Future AsyncAction();
typedef Future AsyncAction1<TParam>(TParam param);


typedef Future<TResult> AsyncFunc<TResult>();
typedef Future<TResult> AsyncFunc1<TParam, TResult>(TParam param);

typedef Stream<TResult> StreamProvider<TParam, TResult>(TParam param);

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

  const CommandResult(this.data, this.error, this.isExecuting);

  bool get hasData => data != null;
  bool get hasError => error != null;  
}



/// `RxCommand` capsules a given handler function that can then be executed by its `execute` method. 
/// The result of this method is then published through its `results` Observable (Observable wrap Dart Streams)
/// Additionally it offers Observables for it's current execution state, fs the command can be executed and for 
/// all possibly thrown exceptions during command execution.
/// `RxCommand` also implments the `Observable` interface so you can listen directly to the `RxCommand` which emitts 
/// `CommandResult<TRESULT>` which is often easier in combaination with Flutter `StreamBuilder` because you have all 
/// state information at one place.
///
/// An `RxCommand` is a generic class of type `RxCommand<TParam, TRESULT>` 
/// where [TPARAM] is the type of data that is passed when calling `execute` and 
/// [TResult] denotes the return type of the handler function. To signal that 
/// a handler doesn't take a parameter or returns no value use the dummy type `Null`
abstract class RxCommand<TParam, TRESULT> extends Observable<CommandResult<TRESULT>>
{
  
  RxCommand(this._commandResultsSubject):super(_commandResultsSubject.observable)
  {
      this
        .where( (x) => x.hasError)
          .listen((x) => _thrownExceptionsSubject.add(x.error));
          
      this
        .listen((x) => _isExecutingSubject.add(x.isExecuting));
        
  }

  /// Creates  a RxCommand for a synchronous handler function with no parameter and no return type 
  /// `action`: handler function
  /// `canExecute` : observable that can bve used to enable/diable the command based on some other state change
  /// if omitted the command can be executed always except it's already executing
  static RxCommand<Null, Null> createSync(Action action,[Observable<bool> canExecute])
  {
      return new RxCommandSync<Null,Null>((_) {action(); return null;},canExecute);
  }

  /// Creates  a RxCommand for a synchronous handler function with one parameter and no return type 
  /// `action`: handler function
  /// `canExecute` : observable that can bve used to enable/diable the command based on some other state change
  /// if omitted the command can be executed always except it's already executing
  static RxCommand<TParam, Null> createSync1<TParam>(Action1<TParam> action, [Observable<bool> canExecute])
  {
      return new RxCommandSync<TParam,Null>((x) {action(x); return null;},canExecute);
  }

  /// Creates  a RxCommand for a synchronous handler function with no parameter that returns a value 
  /// `func`: handler function
  /// `canExecute` : observable that can bve used to enable/diable the command based on some other state change
  /// if omitted the command can be executed always except it's already executing
  static RxCommand<Null, TResult> createSync2<TResult>(Func<TResult> func,[Observable<bool> canExecute])
  {
      return new RxCommandSync<Null,TResult>((_) => func(),canExecute);
  }

  /// Creates  a RxCommand for a synchronous handler function with parameter that returns a value 
  /// `func`: handler function
  /// `canExecute` : observable that can bve used to enable/diable the command based on some other state change
  /// if omitted the command can be executed always except it's already executing
  static RxCommand<TParam, TResult> createSync3<TParam, TResult>(Func1<TParam,TResult> func,[Observable<bool> canExecute])
  {
      return new RxCommandSync<TParam,TResult>((x) => func(x),canExecute);
  }    


  // Assynchronous

  /// Creates  a RxCommand for an asynchronous handler function with no parameter and no return type 
  /// `action`: handler function
  /// `canExecute` : observable that can bve used to enable/diable the command based on some other state change
  /// if omitted the command can be executed always except it's already executing
  static RxCommand<Null, Null> createAsync(AsyncAction action,[Observable<bool> canExecute])
  {
      return new RxCommandAsync<Null,Null>((_) async {action(); return  null;},canExecute);
  }


  /// Creates  a RxCommand for an asynchronous handler function with one parameter and no return type 
  /// `action`: handler function
  /// `canExecute` : observable that can bve used to enable/diable the command based on some other state change
  /// if omitted the command can be executed always except it's already executing
  static RxCommand<TParam, Null> createAsync1<TParam>(AsyncAction1<TParam> action,[Observable<bool> canExecute])
  {
      return new RxCommandAsync<TParam,Null>((x) async {action(x); return null;} ,canExecute);
  }

  /// Creates  a RxCommand for an asynchronous handler function with no parameter that returns a value 
  /// `func`: handler function
  /// `canExecute` : observable that can bve used to enable/diable the command based on some other state change
  /// if omitted the command can be executed always except it's already executing
  static RxCommand<Null, TResult> createAsync2<TResult>(AsyncFunc<TResult> func,[Observable<bool> canExecute])
  {
      return new RxCommandAsync<Null,TResult>((_) async => func(),canExecute);
  }

  /// Creates  a RxCommand for an asynchronous handler function with parameter that returns a value 
  /// `func`: handler function
  /// `canExecute` : observable that can bve used to enable/diable the command based on some other state change
  /// if omitted the command can be executed always except it's already executing
  static RxCommand<TParam, TResult> createAsync3<TParam, TResult>(AsyncFunc1<TParam,TResult> func, [Observable<bool> canExecute])
  {
      return new RxCommandAsync<TParam,TResult>((x) async => func(x),canExecute);
  }    

  /// Creates  a RxCommand from an "one time" observable. This is handy if used together with a streame generator function.  
  /// [provider]: provider function that returns a new Observable that will be subscribed on the call of [execute]
  /// [canExecute] : observable that can bve used to enable/diable the command based on some other state change
  /// if omitted the command can be executed always except it's already executing
  static RxCommand<TParam, TResult> createFromStream<TParam, TResult>(StreamProvider<TParam, TResult> provider, [Observable<bool> canExecute])
  {
      return new RxCommandStream<TParam, TResult>(provider,canExecute);
  }    

  /// Calls the wrapped handler function with an option input parameter
  execute([TParam param]);

  call([TParam param]) => execute(param); 

  /// Observable stream that outputs any result from the called handler function. If the handler function has void return type 
  /// it will still output one `Null` item so that you can listen for the end of the execution.
  Observable<TRESULT> get results => _resultsSubject.observable;

  /// Observable stream that issues a bool on any execution state change of the command
  Observable<bool> get isExecuting => _isExecutingSubject.observable.startWith(false).distinct();
  
  /// Observable stream that issues a bool on any change of the current executable state of the command. 
  /// Meaning if the command cann be executed or not. This will issue `false` while the command executes 
  /// but also if the command receives a false from the canExecute Observable that you can pass when creating the Command
  Observable<bool>  get canExecute  => _canExecuteSubject.observable.startWith(true).distinct();

  /// When subribing to `thrownExceptions`you will every excetpion that was thrown in your handler function as an event on this Observable.
  /// If no subscription exists the Exception will be rethrown
  Observable<Exception> get thrownExceptions => _thrownExceptionsSubject.observable;



  BehaviorSubject<CommandResult<TRESULT>> _commandResultsSubject;
  BehaviorSubject<TRESULT> _resultsSubject = new BehaviorSubject<TRESULT>();  
  BehaviorSubject<bool> _isExecutingSubject = new BehaviorSubject<bool>();  
  BehaviorSubject<bool> _canExecuteSubject = new BehaviorSubject<bool>();  
  PublishSubject<Exception> _thrownExceptionsSubject = new PublishSubject<Exception>();  

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
      this._commandResultsSubject.close();
  }

}




/// Implementation of RxCommand to handle async handler functions. Normally you will not instanciate this directly but use one of the factory 
/// methods of RxCommand.
class RxCommandSync<TParam, TResult> extends RxCommand<TParam, TResult>
{
 
  bool _isRunning = false;
  bool _canExecute = true;
 
  Func1<TParam, TResult> _func;

  RxCommandSync._(Func1<TParam, TResult> func, BehaviorSubject<CommandResult<TResult>> subject, 
                  Observable<bool> canExecute):super(subject)
  {
    var canExecuteParam = canExecute == null ? new Observable.just(true) 
                                              : canExecute.handleError((error)
                                                {
                                                    if (error is Exception)
                                                    {
                                                      _thrownExceptionsSubject.add(error);
                                                    }
                                                })
                                                .distinct();
                                                                                              


  canExecuteParam.listen((canExecute){
    _canExecute = canExecute && (!_isRunning);
    _canExecuteSubject.add(_canExecute);
  });    



    _func = func;

  }

  factory RxCommandSync(Func1<TParam, TResult> func, [Observable<bool> canExecute] )
  {

    return new RxCommandSync._(func, new BehaviorSubject<CommandResult<TResult>>(seedValue: new CommandResult<TResult>(null, null, false)), canExecute);
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

        _commandResultsSubject.add(new CommandResult<TResult>(null,null,true));                 

        try {
          var result = _func(param);
          _commandResultsSubject.add(new CommandResult<TResult>(result,null,false));    
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
              _commandResultsSubject.add(new CommandResult<TResult>(null,error,false));    
            }
            else
            {
              _commandResultsSubject.add(new CommandResult<TResult>(null,new Exception(error.toString()),false));    
            }
        }
        finally
        {
          _isRunning = false;
          _isExecutingSubject.add(false);
          _canExecuteSubject.add(true);
        }
  }
}


class RxCommandAsync<TParam, TResult> extends RxCommand<TParam, TResult>
{
 
  bool _isRunning = false;
  bool _canExecute = true;

  AsyncFunc1<TParam, TResult> _func;

  RxCommandAsync._(AsyncFunc1<TParam, TResult> func, BehaviorSubject<CommandResult<TResult>> subject, 
                  Observable<bool> canExecute):super(subject)
  {
    var canExecuteParam = canExecute == null ? new Observable.just(true) 
                                              : canExecute.handleError((error)
                                                {
                                                    if (error is Exception)
                                                    {
                                                      _thrownExceptionsSubject.add(error);
                                                    }
                                                })
                                                .distinct();
                                                                                              


  canExecuteParam.listen((canExecute){
    _canExecute = canExecute && (!_isRunning);
    _canExecuteSubject.add(_canExecute);
  });    



    _func = func;

  }

  factory RxCommandAsync(AsyncFunc1<TParam, TResult> func, [Observable<bool> canExecute] )
  {

    return new RxCommandAsync._(func, new BehaviorSubject<CommandResult<TResult>>(seedValue: new CommandResult<TResult>(null, null, false)), canExecute);
  }


  @override
  execute([TParam param]) 
  {


        // 
        
        ("************ Execute***** canExecute: $_canExecute ***** isExecuting: $_isRunning");

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

        _commandResultsSubject.add(new CommandResult<TResult>(null,null,true));
  
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
                _commandResultsSubject.add(new CommandResult<TResult>(null,error,false));    
              }
              else
              {
                _commandResultsSubject.add(new CommandResult<TResult>(null,new Exception(error.toString()),false));    
              }
              _isRunning = false;
              _isExecutingSubject.add(false);
              _canExecuteSubject.add(true);
              

          })
          
          .listen( (result) {
              _commandResultsSubject.add(new CommandResult<TResult>(result,null,false));    
              _resultsSubject.add(result); 
              _isRunning = false;
              _canExecuteSubject.add(true);
         });
  }
} 


class RxCommandStream<TParam, TResult> extends RxCommand<TParam, TResult>
{
 
  bool _isRunning = false;
  bool _canExecute = true;


  StreamProvider<TParam,TResult> observableProvider;


  RxCommandStream._(StreamProvider<TParam,TResult>  provider, BehaviorSubject<CommandResult<TResult>> subject, 
                  Observable<bool> canExecute):super(subject)
  {
    var canExecuteParam = canExecute == null ? new Observable.just(true) 
                                              : canExecute.handleError((error)
                                                {
                                                    if (error is Exception)
                                                    {
                                                      _thrownExceptionsSubject.add(error);
                                                    }
                                                })
                                                .distinct();
                                                                                              


    canExecuteParam.listen((canExecute){
      _canExecute = canExecute && (!_isRunning);
      _canExecuteSubject.add(_canExecute);
    });    


    observableProvider = provider;

  }

   factory RxCommandStream(StreamProvider<TParam, TResult> provider, [Observable<bool> canExecute] )
  {

    return new RxCommandStream._(provider, new BehaviorSubject<CommandResult<TResult>>(seedValue: new CommandResult<TResult>(null, null, false)), canExecute);
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
        _commandResultsSubject.add(new CommandResult<TResult>(null,null,true));
  

        Exception thrownException;

        var inputObservable = new Observable(observableProvider(param))          
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
                                      .doOnData( (result) {
                                        _resultsSubject.add(result);
                                      })
                                      .map( (result) => new CommandResult(result, null, false));

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
                                                _canExecuteSubject.add(true);
                                            }, onError: (error) {
                                                print(error);
                                            });
  }
} 
 




