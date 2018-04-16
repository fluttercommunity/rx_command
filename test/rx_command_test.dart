import 'dart:async';

import 'package:test/test.dart';

import 'package:rx_command/rx_command.dart';


  
  StreamMatcher crm( data, bool hasError, bool isExceuting)
  {
      return new StreamMatcher((x) async {
                                              CommandResult event =  await x.next;
                                              if (event.data != data)
                                                return "Wong data $data != ${event.data}";
                                                
                                              if (!hasError && event.error != null)
                                                return "Had error while not expected";

                                              if (hasError && !(event.error is Exception))
                                                return "Wong error type";

                                              if (event.isExecuting != isExceuting)
                                                return "Wong isExecuting $isExceuting";

                                              return null;
                                          }, "Wrong value emmited:");
  }
    
  


void main() {




  test('Execute simple sync action', () {
    final command  = RxCommand.createSync( () => print("action"));
                                                              

    expect(command.canExecute, emits(true));
    expect(command.isExecuting, emits(false));

    
    expect(command.results, emits(null));
    expect(command, emitsInOrder([crm(null,false,false), crm(null,false,true),crm(null,false,false)]));

    command.execute();


    expect(command.canExecute, emits(true));
    expect(command.isExecuting, emits(false));    
  });


  test('Execute simple sync action with exception  throwExceptions==true', () {
    final command  = RxCommand.createSync( () => throw new Exception("Intentional"));
    command.throwExceptions = true;
                                                              

    expect(command.canExecute, emits(true));
    expect(command.isExecuting, emits(false));

    
    expect(command.results, emitsError(isException));

    command.execute();

    expect(command.canExecute, emits(true));
    expect(command.isExecuting, emits(false));

  });


  test('Execute simple sync action with exception and throwExceptions==false', () {
    final command  = RxCommand.createSync( () => throw new Exception("Intentional"));

    expect(command.canExecute, emits(true));
    expect(command.isExecuting, emits(false));
    expect(command, emitsInOrder([crm(null,false,false), crm(null,false,true),crm(null,true,false)]));


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

    expect(command, emitsInOrder([crm(null,false,false), crm(null,false,true),crm(null,false,false)]));


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
   

    expect(command, emitsInOrder([crm(null,false,false), crm(null,false,true),crm("4711",false,false)]));


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

    expect(command, emitsInOrder([crm(null,false,false), crm(null,false,true),crm("47114711",false,false)]));


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

    expect(command, emitsInOrder([crm(null,false,false), crm(null,false,true),crm("Done",false,false)]));


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



 test('async function with exception and throwExceptions==true', () {

    final command  = RxCommand.createAsync3<String,String>(slowAsyncFunctionFail);
    command.throwExceptions = true;

    expect(command.canExecute, emits(true));
    expect(command.isExecuting, emits(false));

    expect(command, emitsInOrder([crm(null,false,false), crm(null,false,true)]));


    command.execute("Done");

    expect(command.canExecute, emits(true));
    expect(command.isExecuting, emits(false));
 
  });

 
 test('async function with exception with and throwExceptions==false', () {

    final command  = RxCommand.createAsync3<String,String>(slowAsyncFunctionFail);

    command.thrownExceptions.listen((e) => print(e.toString()));      


    expect(command.canExecute, emits(true));
    expect(command.isExecuting, emits(false));

    expect(command, emitsInOrder([crm(null,false,false), crm(null,false,true),crm(null,true,false)]));


    command.execute("Done");
 
    expect(command.canExecute, emits(true));
    expect(command.isExecuting, emits(false));
  });



}
