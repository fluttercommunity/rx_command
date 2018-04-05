import 'package:flutter/material.dart';

import 'listview.dart';
import 'main.dart';

 
 class HomePage extends StatelessWidget
 {
  @override
  Widget build(BuildContext context) {
      return 
         new Scaffold(
            appBar: new AppBar(title: new Text("WeatherDemo")),
            body: 
              new Column(children: <Widget>
              [
               new Padding(padding: const EdgeInsets.all(5.0),child: 
                      new TextField(
                              autocorrect: false,
                              decoration: new InputDecoration(
                                                  hintText: "Filter cities",
                                                  hintStyle: new TextStyle(color: new Color.fromARGB(150, 0, 0, 0)),
                                                  ),
                              style: new TextStyle(
                                            fontSize: 20.0,
                                            color: new Color.fromARGB(255, 0, 0, 0)),
                              onChanged: TheViewModel.of(context).onFilterEntryChanged,),
                ),

                new Expanded( child: 
                      new WeatherListView()),  // Have to wrap the ListView into an Expanded otherwise the Column throws an exception
                
                new Padding(padding: const EdgeInsets.all(8.0),child: 
                      new MaterialButton(                               
                              child: 
                                new Text("Update"), // Watch the Button is again a composition
                              color: new Color.fromARGB(255, 33, 150, 243),
                              textColor: new Color.fromARGB(255, 255, 255, 255),
                              onPressed: () => TheViewModel.of(context).updateWeatherCommand.execute("")
                              ),
                ),
                
              ],
            ),
          );
  }
   
 }
 
