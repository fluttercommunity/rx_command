import 'dart:async';

import 'package:test/test.dart';

import 'package:rx_command/rx_command.dart';

void main() {


  test('Execute simple sync action', () {
    final command  = RxCommand.createSync( () => print("action"));
                                                              

    expect(command.canExecute, emits(true));
    expect(command.isExecuting, emits(false));

    
    expect(command.results, emits(null));

    command.execute();

    expect(command.canExecute, emits(true));
    expect(command.isExecuting, emits(false));    
  });


  test('Execute simple sync action with exception no listeners', () {
    final command  = RxCommand.createSync( () => throw new Exception("Intentional"));
                                                              

    expect(command.canExecute, emits(true));
    expect(command.isExecuting, emits(false));

    
    expect(command.results, emitsError(isException));

    command.execute();

    expect(command.canExecute, emits(true));
    expect(command.isExecuting, emits(false));

  });


  test('Execute simple sync action with exception with listeners', () {
    final command  = RxCommand.createSync( () => throw new Exception("Intentional"));

     command.thrownExceptions.listen((e) => print(e.toString()));                                                                 

    expect(command.canExecute, emits(true));
    expect(command.isExecuting, emits(false));

    command.execute();

    expect(command.canExecute, emits(true));
    expect(command.isExecuting, emits(false));


  });




      


  test('Execute simple sync action with parameter', () {

    final command  = RxCommand.createSync1<String>((x) {
      print("action: " + x.toString()  );
      return null;
    });

    expect(command.canExecute, emits(true));
    expect(command.isExecuting, emits(false));

    expect(command.results, emits(null));

    command.execute( "Parameter");


    expect(command.canExecute, emits(true));
    expect(command.isExecuting, emits(false));    
  });




  test('Execute simple sync function without parameter', () {

    final command  = RxCommand.createSync2<String>(() {
      print("action: ");
      return "4711";
    });

    expect(command.canExecute, emits(true));
    expect(command.isExecuting, emits(false));

    expect(command.results, emits("4711"));

    command.execute();


    expect(command.canExecute, emits(true));
    expect(command.isExecuting, emits(false));    
  });



  test('Execute simple sync function with parameter', () {

    final command  = RxCommand.createSync3<String,String>((s) {
      print("action: " + s);
      return s + s;
    });

    expect(command.canExecute, emits(true));
    expect(command.isExecuting, emits(false));

    expect(command.results, emits("47114711"));

    command.execute("4711");


    expect(command.canExecute, emits(true));
    expect(command.isExecuting, emits(false));    
  });


  Future<String> slowAsyncFunction(String s) async
  {
      print("___Start____Action__________");

      await new Future.delayed(new Duration(seconds: 2));
      print("___End____Action__________");
      return s;
  }



 test('Execute simple async function with parameter', () {

    final command  = RxCommand.createAsync3<String,String>(slowAsyncFunction);

    command.canExecute.listen((b){print("Can execute:" + b.toString());});
    command.isExecuting.listen((b){print("Is executing:" + b.toString());});

    command.results.listen((s){print("Results:" + s);});


    expect(command.canExecute, emits(true),reason: "Canexecute before false");
    expect(command.isExecuting, emits(false),reason: "Canexecute before true");

    expect(command.results, emits("Done"));


    command.execute("Done");
    command.execute("Done");


    expect(command.canExecute, emits(true),reason: "Canexecute after false");
    expect(command.isExecuting, emits(false));    
  });


Future<String> slowAsyncFunctionFail(String s) async
  {
      print("___Start____Action___Will throw_______");

      throw new Exception("Intentionally");
  }



 test('async function with exception and no listeners', () {

    final command  = RxCommand.createAsync3<String,String>(slowAsyncFunctionFail);

    expect(command.canExecute, emits(true));
    expect(command.isExecuting, emits(false));

    expect(command.results, emitsError(isException));    



    command.execute("Done");

    expect(command.canExecute, emits(true));
    expect(command.isExecuting, emits(false));
 
  });

 
 test('async function with exception with listeners', () {

    final command  = RxCommand.createAsync3<String,String>(slowAsyncFunctionFail);

    command.thrownExceptions.listen((e) => print(e.toString()));      


    expect(command.canExecute, emits(true));
    expect(command.isExecuting, emits(false));

    command.execute("Done");
 
    expect(command.canExecute, emits(true));
    expect(command.isExecuting, emits(false));
  });



}
