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

/*
abstract class RxCommandFactory 
{

  //Fatrory functions for dynchronous commands

  static RxCommand<Unit, Unit> createSync(Action action)
  {
      return new RxCommandSync<Unit,Unit>((_) {action(); return Unit.Default;});
  }

  static RxCommand<TParam, Unit> createSync1<TParam>(Action1<TParam> action)
  {
      return new RxCommandSync<TParam,Unit>((x) {action(x); return Unit.Default;});
  }

  static RxCommand<Unit, TResult> createSync2<TResult>(Func<TResult> func)
  {
      return new RxCommandSync<Unit,TResult>((_) => func());
  }

  static RxCommand<TParam, TResult> createSync3<TParam, TResult>(Func1<TParam,TResult> func)
  {
      return new RxCommandSync<TParam,TResult>((x) => func(x));
  }    





}

*/
abstract class RxCommand<TParam, TRESULT>
{

  static RxCommand<Unit, Unit> createSync(Action action)
  {
      return new RxCommandSync<Unit,Unit>((_) {action(); return Unit.Default;});
  }

  static RxCommand<TParam, Unit> createSync1<TParam>(Action1<TParam> action)
  {
      return new RxCommandSync<TParam,Unit>((x) {action(x); return Unit.Default;});
  }

  static RxCommand<Unit, TResult> createSync2<TResult>(Func<TResult> func)
  {
      return new RxCommandSync<Unit,TResult>((_) => func());
  }

  static RxCommand<TParam, TResult> createSync3<TParam, TResult>(Func1<TParam,TResult> func)
  {
      return new RxCommandSync<TParam,TResult>((x) => func(x));
  }    



  static RxCommand<Unit, Unit> createAsync(AsyncAction action)
  {
      return new RxCommandAsync<Unit,Unit>((_) async {action(); return  Unit.Default;});
  }


  static RxCommand<TParam, Unit> createAsync1<TParam>(AsyncAction1<TParam> action)
  {
      return new RxCommandAsync<TParam,Unit>((x) async {action(x); return Unit.Default;});
  }

  static RxCommand<Unit, TResult> createAsync2<TResult>(AsyncFunc<TResult> func)
  {
      return new RxCommandAsync<Unit,TResult>((_) async => func());
  }


  static RxCommand<TParam, TResult> createAsync3<TParam, TResult>(AsyncFunc1<TParam,TResult> func)
  {
      return new RxCommandAsync<TParam,TResult>((x) async => func(x));
  }    


  execute([TParam param]);

  Observable<TRESULT> get results => _resultsSubject.observable;
  BehaviorSubject<TRESULT> _resultsSubject = new BehaviorSubject<TRESULT>();  
 

  Observable<bool> get isExecuting => _isExecutingSubject.observable.startWith(false).distinct();
  Observable<bool>  get canExecute  => _canExecuteSubject.observable.startWith(true).distinct();
  Observable<Exception> get thrownExceptions => _thrownExceptionsSubject.observable;

  BehaviorSubject<bool> _isExecutingSubject = new BehaviorSubject<bool>();  
  BehaviorSubject<bool> _canExecuteSubject = new BehaviorSubject<bool>();  
  BehaviorSubject<Exception> _thrownExceptionsSubject = new BehaviorSubject<Exception>();  

  void dispose()
  {
      _isExecutingSubject.close();
      _canExecuteSubject.close();
      _thrownExceptionsSubject.close();
      _resultsSubject.close(); 
  }

}


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
                                                    return false;
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



/// If you don't want to pass one of the generic parameters e.g. if you passed function has no parameter, just use Unit as Type
class Unit
{
  static Unit get Default => new Unit();

  bool operator == (o) => o is Unit;

}


