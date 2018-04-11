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

/// `RxCommand` capsules a given handler function that can then be executed by its `execute` method. 
/// The result of this method is then published through its `results` Observable (Observable wrap Dart Streams). 
/// Additionally it offers Observables for it's current execution state, fs the command can be executed and for 
/// all possibly thrown exceptions during command execution.
///
/// An `RxCommand` is a generic class of type `RxCommand<TParam, TRESULT>` 
/// where `TPARAM` is the type of data that is passed when calling `execute` and 
/// `TResult` denotes the return type of the handler function. To signal that 
/// a handler doesn't take a parameter or returns a value use the dummy type `Null`
abstract class RxCommand<TParam, TRESULT>
{

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



  BehaviorSubject<TRESULT> _resultsSubject = new BehaviorSubject<TRESULT>();  
  BehaviorSubject<bool> _isExecutingSubject = new BehaviorSubject<bool>();  
  BehaviorSubject<bool> _canExecuteSubject = new BehaviorSubject<bool>();  
  BehaviorSubject<Exception> _thrownExceptionsSubject = new BehaviorSubject<Exception>();  


  /// If you don't need a command any longer it is a good practise to 
  /// dispose it to make sure all stream subsriptions are cancelled to prevent memory leaks
  void dispose()
  {
      _isExecutingSubject.close();
      _canExecuteSubject.close();
      _thrownExceptionsSubject.close();
      _resultsSubject.close(); 
  }

}

/// Implementation of RxCommand to handle async handler functions. Normally you will not instanciate this directly but use one of the factory 
/// methods of RxCommand.
class RxCommandSync<TParam, TResult> extends RxCommand<TParam, TResult>
{
 
  bool _isRunning = false;
  bool _canExecute = true;
 
  Func1<TParam, TResult> _func;

  RxCommandSync(Func1<TParam, TResult> func, [Observable<bool> canExecute] )
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

        try {
          var result = _func(param);
          _resultsSubject.add(result);          
        } 
        catch (error) 
        {
            if (!_thrownExceptionsSubject.hasListener)
            {
                _resultsSubject.addError(error);
            }
            if (error is Exception)
            {
              _thrownExceptionsSubject.add(error);
            }
            else
            {
              _thrownExceptionsSubject.add(new Exception(error.toString()));                
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

  RxCommandAsync(AsyncFunc1<TParam, TResult> func, [Observable<bool> canExecute] )
  {


    var canExecuteParam = canExecute == null ? new Observable.just(true) 
                                              : canExecute.handleError((error)
                                                {
                                                    if (error is Exception)
                                                    {
                                                      _thrownExceptionsSubject.add(error);
                                                    }
                                                    return false;
                                                })
                                                .distinct();
                                                                                              


  canExecuteParam.listen((canExecute){
    _canExecute = canExecute;
    //print("------------------_Canexecute changed: $_canExecute -----------------");
    _canExecuteSubject.add(_canExecute);
  });    

    _func = func;

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

        _isExecutingSubject.add(true);      
  
        _func(param).asStream()          
          .handleError((error)
          {
              if (!_thrownExceptionsSubject.hasListener)
              {
                 _resultsSubject.addError(error);
              }
              if (error is Exception)
              {
                _thrownExceptionsSubject.add(error);
              }
              else
              {
                _thrownExceptionsSubject.add(new Exception(error.toString()));                
              }
              _isRunning = false;
              _isExecutingSubject.add(false);
              _canExecuteSubject.add(true);
              

          })
          .take(1)
          .listen( (result) {
             _resultsSubject.add(result);
              _isRunning = false;
              _isExecutingSubject.add(false);
              _canExecuteSubject.add(true);
          });
  }
}





