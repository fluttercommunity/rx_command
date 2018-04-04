import 'package:test/test.dart';

import 'package:rx_command/rx_command.dart';

void main() {


  test('Execute simple sync action', () {
    final command  = RxCommandFactory.createSync( () => print("action"));
                                                              

    expect(command.canExecute, emits(true));
    expect(command.isExecuting, emits(false));

    
    expect(command.results, emits(Unit.Default));

    command.execute(null);

    expect(command.canExecute, emits(true));
    expect(command.isExecuting, emits(false));    
  });



  test('Execute simple sync action with parameter', () {

    final command  = RxCommandFactory.createSync1<String>((x) {
      print("action: " + x.toString()  );
      return Unit.Default;
    });

    expect(command.canExecute, emits(true));
    expect(command.isExecuting, emits(false));

    expect(command.results, emits(Unit.Default));

    command.execute( "Parameter");


    expect(command.canExecute, emits(true));
    expect(command.isExecuting, emits(false));    
  });




  test('Execute simple sync function without parameter', () {

    final command  = RxCommandFactory.createSync2<String>(() {
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

    final command  = RxCommandFactory.createSync3<String,String>((s) {
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






}
