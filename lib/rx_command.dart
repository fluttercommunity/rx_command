library rx_command;

import 'dart:async';

import 'package:rxdart/rxdart.dart';

/*
typedef TResult Func<TParam, TResult>(TParam param);



abstract class RxCommandFactory 
{

  static RxCommand<TParam, TResult> createSync<TParam, TResult>(Func<TParam, TResult> func)
  {
      return new RxCommandSync<TParam,TResult>(func);
  }
      
      
}
*/ 

typedef void Action();
typedef void Action1<TParam>(TParam param);


typedef TResult Func<TResult>();
typedef TResult Func1<TParam, TResult>(TParam param);

typedef Future AsyncAction();
typedef Future AsyncAction1<TParam>(TParam param);


typedef Future<TResult> AsyncFunc<TResult>();
typedef Future<TResult> AsyncFunc1<TParam, TResult>(TParam param);


abstract class RxCommandFactory 
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
      
  static RxCommand<TParam, TResult> createAsync3<TParam, TResult>(AsyncFunc1<TParam,TResult> func)
  {
      return new RxCommandAsync<TParam,TResult>((x) => func(x));
  }    



}



abstract class RxCommand<TParam, TRESULT>
{

  void execute([TParam param]);

  Observable<TRESULT> get results => _resultsSubject.observable;
  BehaviorSubject<TRESULT> _resultsSubject = new BehaviorSubject<TRESULT>();  
 

  Observable<bool> get isExecuting => _isExecutingSubject.observable.startWith(false).distinct();
  Observable<bool>  canExecute;
  Observable<Exception> get thrownExceptions => _thrownExceptionsSubject.observable;

  PublishSubject<bool> _isExecutingSubject = new PublishSubject<bool>();  
  PublishSubject<bool> _canExecuteSubject = new PublishSubject<bool>();  
  PublishSubject<Exception> _thrownExceptionsSubject = new PublishSubject<Exception>();  

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
 
 
  Func1<TParam, TResult> _func;

  RxCommandSync(Func1<TParam, TResult> func, [Observable<bool> canExecute] )
  {

    _func = func;

    var canExecuteParam = canExecute == null ? new Observable.just(true) 
                                              : canExecute.handleError((error)
                                                {
                                                    if (error is Exception)
                                                    {
                                                      _thrownExceptionsSubject.add(error);
                                                    }
                                                    return false;
                                                })
                                                .startWith(false);                                              


    this.canExecute =   new Observable(Observable
                        .combineLatest2(isExecuting, canExecuteParam, (isEx, canEx) => canEx && !isEx)
                              .distinct().asBroadcastStream());

  }

  @override
  void execute([TParam param]) 
  {    
      canExecute
        .where( (can) => can == true)
          .doOnEach((_){ 
              
              _isExecutingSubject.add(true);

              var result = _func(param);
              
              _isExecutingSubject.add(false);

            if (TResult is Unit )
            {
              _resultsSubject.add(Unit.Default as TResult);                
            }
            else
            {
              _resultsSubject.add(result);
            }

          })
          .handleError((error)
          {
              if (error is Exception)
              {
                _thrownExceptionsSubject.add(error);
              }
              print("+++++++++++++++++++++++++++++ Error: " + error.toString());

          })
          .first;   

  }
}


class RxCommandAsync<TParam, TResult> extends RxCommand<TParam, TResult>
{
 
  bool _isRunning = false;
  AsyncFunc1<TParam, TResult> _func;

  RxCommandAsync(AsyncFunc1<TParam, TResult> func, [Observable<bool> canExecute] )
  {

    _func = func;

    var canExecuteParam = canExecute == null ? new Observable.just(true) 
                                              : canExecute.handleError((error)
                                                {
                                                    if (error is Exception)
                                                    {
                                                      _thrownExceptionsSubject.add(error);
                                                    }
                                                    return false;
                                                })
                                                .startWith(false);                                              


    this.canExecute =   new Observable(Observable
                        .combineLatest2(isExecuting, canExecuteParam, (isEx, canEx) => canEx && !isEx)
                              .distinct().asBroadcastStream());

  }

  @override
  void execute([TParam param]) 
  {
        _isExecutingSubject.add(true);      
  
        isExecuting
        .where( (can) => can == false)
          .flatMap((_)  {
              print("____________Can:" + _.toString());

              return _func(param).asStream();
          })
          .handleError((error)
          {
              if (error is Exception)
              {
                _thrownExceptionsSubject.add(error);
              }
              print(error.toString());

          })
          .take(1)
          .listen( (result) {
                  print("--------------------------------- Listen");
                  if (TResult is Unit )
                  {
                    _resultsSubject.add(Unit.Default as TResult);                
                  }
                  else
                  {
                    _resultsSubject.add(result);
                  }
              _isRunning = false;
              _isExecutingSubject.add(false);
          });
  }
}



/// If you don't want to pass one of the generic parameters e.g. if you passed function has no parameter, just use Unit as Type
class Unit
{
  static Unit get Default => new Unit();

  bool operator == (o) => o is Unit;

}


