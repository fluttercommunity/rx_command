import 'package:flutter/material.dart';
import 'detail_page.dart';
import 'main.dart';
import 'weather_viewmodel.dart';

class WeatherListView extends StatelessWidget {


  WeatherListView();
    @override
    Widget build(BuildContext context) {
      return new StreamBuilder<List<WeatherEntry>>(   // Streambuilder rebuilds its subtree on every item the stream issues
              stream: TheViewModel.of(context).newWeatherEvents,   //We access our ViewModel through the inherited Widget
              builder: (BuildContext context, AsyncSnapshot<List<WeatherEntry>> snapshot)  // in Dart Lambdas with body don't use =>
                  {
                    // only if we get data
                    if (snapshot.hasData && snapshot.data.length > 0)
                    {
                        return new ListView.builder(
                                    itemCount: snapshot.data.length,
                                    itemBuilder : (BuildContext context, int index) => 
                                                      buildRow(context,index,snapshot.data)                                            
                      );
                    }
                    else
                    {
                      return new Text("No items");
                    }
                }                                              
              );
                            
    }            
                  
    Widget buildRow(BuildContext context, int index, List<WeatherEntry> listData) {
      return 
        new GestureDetector(
            child: 
              new Wrap(spacing: 40.0,
                    children: <Widget>
                    [
                      new Image(image: new NetworkImage(listData[index].iconURL)),
                      
                      new Text(listData[index].cityName, style: new TextStyle(fontSize: 20.0))
                    ],
                  ),

            onTap: () => Navigator.push(context, 
                            new MaterialPageRoute( builder: (BuildContext context) => new DetailPage(listData[index])
                    ))
        );
        
      
    }
}
      
  
 