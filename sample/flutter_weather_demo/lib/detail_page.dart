import 'package:flutter/material.dart';

import 'weather_viewmodel.dart';


class DetailPage extends StatelessWidget
{

  final WeatherEntry weatherEntry;

  DetailPage(this.weatherEntry);

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(title: new Text("Detail View")),
      body: new Container(padding: new EdgeInsets.only(left: 20.0,bottom: 10.0),
                          child: 
                    new Column(children: <Widget>
                    [
                      // Top row City name + weather
                      new Row( mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>
                        [
                          new Text(weatherEntry.cityName,
                                    style: new TextStyle(fontSize: 35.0),),

                          new Image.network(weatherEntry.iconURL,
                                    alignment: Alignment.center,
                                    scale: 1.0,
                                    repeat: ImageRepeat.noRepeat,
                                    width: 120.0,
                                    height: 120.0,
                                    fit: BoxFit.contain,)
                        ],
                      ),
                      buildConditionRow("condition", weatherEntry.description),
                      
                      buildConditionRow("Temperature", weatherEntry.temperature.toStringAsFixed(1) + "°"),
                      
                      buildConditionRow("Wind", weatherEntry.wind.toStringAsFixed(1) + " m/s"),                   

                    ],
                  )
                )
      );
                    
  }

  Widget buildConditionRow(String condition, String description)
  {
    return
        new Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: new Row( 
            children: <Widget>
            [
                  new Expanded(flex: 1,
                            child: 
                          new Text(condition,
                                   style: new TextStyle(fontSize: 20.0),),
                  ),

                  new Expanded(flex: 1,
                                child: 
                      new Text(description,
                                style: new TextStyle(fontSize: 20.0),
                                textAlign: TextAlign.start,
                                ),
                                ),
            ]),
        ); 
  }
  
}