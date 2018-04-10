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
                      // Handle events to show / hide spinner
                      new StreamBuilder<bool>(   
                          stream: TheViewModel.of(context).updateWeatherCommand.isExecuting, 
                          builder: (BuildContext context, AsyncSnapshot<bool> isRunning)  
                              {
                                 // if true we show a buys Spinner otherwise the ListView
                                if (isRunning.hasData && isRunning.data == true)
                                {
                                    return new Center(child: new Container(width: 50.0, height:50.0, child: new CircularProgressIndicator())); 
                                }
                                else
                                {
                                   return new WeatherListView();                                  }
                            })                                              
                          ),
                
                
                new Padding(padding: const EdgeInsets.all(8.0),
                    child: 
                        // We use a stream builder to toggle the enabled state of the button
                      new Row(
                        children: <Widget>[
                          new Expanded(
                                child: new StreamBuilder<bool>(   // Streambuilder rebuilds its subtree on every item the stream issues
                                stream: TheViewModel.of(context).updateWeatherCommand.canExecute,   //We access our ViewModel through the inherited Widget
                                builder: (BuildContext context, AsyncSnapshot<bool> snapshot)  
                                    {
                                      var handler;
                                      if (snapshot.hasData)
                                      {
                                          // Depending on teh Value we get from the stream we set or clear the Handler
                                          handler = snapshot.data ? TheViewModel.of(context).updateWeatherCommand.execute :null; 
                                      }
                                      return new RaisedButton(                               
                                              child: 
                                                  new Text("Update"), 
                                              color: new Color.fromARGB(255, 33, 150, 243),
                                              textColor: new Color.fromARGB(255, 255, 255, 255),
                                              onPressed: handler,
                                              );
                                      
                                  }),
                          ),
                                new StateFullSwitch(state: true,
                                    onChanged: TheViewModel.of(context).switchChangedCommand.execute)
                        ],
                      )                                              
                
                ),
                
              ],
            ),
          );
  }
   
 }
 
 /// As the normal switch does not even remeber and display its current state 
 ///  we us this one 
class StateFullSwitch extends StatefulWidget
{
    final bool state;
    final ValueChanged<bool> onChanged;

    StateFullSwitch({this.state, this.onChanged});

    @override
    StateFullSwitchState createState() {
    return new StateFullSwitchState(state, onChanged);
    }

}

class StateFullSwitchState extends State<StateFullSwitch> 
{
    
    bool state;
    ValueChanged<bool> handler;
    
    StateFullSwitchState(this.state, this.handler);    

    @override 
    Widget build(BuildContext context) {
        return new Switch(value: state, onChanged: (b) { setState(()=> state = b); handler(b);});
        }
}