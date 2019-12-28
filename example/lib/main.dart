import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

import 'homepage.dart';
import 'weather_viewmodel.dart';

void main() => runApp( MyApp());

class MyApp extends StatefulWidget {
  // This widget is the root of your application.
 
  @override
  MyAppState createState() {
    return  MyAppState();
  }
}


class MyAppState extends State<MyApp> {

  WeatherViewModel viewModelData;
  
  @override 
  void initState() {

      viewModelData =  WeatherViewModel();
      super.initState();
    }

  @override
  Widget build(BuildContext context) {
    // Place the Inherited Widget at the very base of the Widget tree        
    return  TheViewModel( 
                  theModel:  viewModelData,
                  child: 
                   MaterialApp(
                    title: 'Flutter Demo',
                    home:  HomePage()

 
                  ),
    );
  }
}


// InheritedWidgets allow you to propagate values down the widgettree. 
// it can then be accessed by just writing  TheViewModel.of(context)
class TheViewModel extends InheritedWidget
{
  final WeatherViewModel theModel;

  const TheViewModel({Key key, 
                      @required 
                      this.theModel, 
                      @required 
                      Widget child}) :  assert(theModel != null),assert(child != null),
                      super(key: key, child: child);

  static WeatherViewModel of(BuildContext context) => (context.inheritFromWidgetOfExactType(TheViewModel)as TheViewModel).theModel;                  


  @override
  bool updateShouldNotify(TheViewModel oldWidget) => theModel != oldWidget.theModel;
  
}

