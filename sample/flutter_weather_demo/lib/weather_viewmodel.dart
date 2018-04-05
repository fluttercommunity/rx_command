import 'dart:convert';
import 'package:rxdart/rxdart.dart';

import 'package:http/http.dart' as http;

import 'json/weather_in_cities.dart';
import 'package:rx_command/rx_command.dart';


  class WeatherViewModel {
  

    final _newWeatherSubject = new BehaviorSubject<List<WeatherEntry>>() ;
    final _inputSubject = new BehaviorSubject<String>() ;


    Observable<List<WeatherEntry>> get newWeatherEvents  => _newWeatherSubject.observable;


    // Callback function that will be registered to the TextFields OnChanged Event
    onFilterEntryChanged(String s) => _inputSubject.add(s); 


    RxCommand<String,Unit>  updateWeatherCommand;


    WeatherViewModel()
    {

        updateWeatherCommand = RxCommand.createSync1<String>(update);

        updateWeatherCommand.execute();

        // initialize input listener for the Searchfield
        _inputSubject.observable
          .debounce( new Duration(milliseconds: 500))  // make sure we start processing if the user make a short pause 
            .listen( (filterText)
            {
              update( filterText);
            });  
    }



    void update(String filtertext )
    {
        
      const String url = "http://api.openweathermap.org/data/2.5/box/city?bbox=5,47,14,54,20&appid=27ac337102cc4931c24ba0b50aca6bbd";  
      

      var httpStream = new Observable(http.get(url).asStream()); 

        _newWeatherSubject.addStream(
            httpStream
              .where((data) => data.statusCode == 200)  // only continue if valid response
                .map( (data) // convert JSON result in ModelObject
                {
                      return new WeatherInCities.fromJson(JSON.decode(data.body)).Cities
                        .where( (weatherInCity) =>  filtertext.isEmpty || weatherInCity.Name.toUpperCase().startsWith(filtertext.toUpperCase()))
                          .map((weatherInCity) => new WeatherEntry(weatherInCity) )
                            .toList();
                }));
          
    }
 
    }
                          
 

class WeatherEntry {
   String cityName;
   String iconURL;
   double wind;
   double rain;
   double temperature;
   String description;

  WeatherEntry(City city)
  {
      this.cityName = city.Name;
      this.iconURL = city.weather != null ?  "http://openweathermap.org/img/w/${city.weather[0].Icon}.png" :  null;
      this.description = city.weather != null ?  city.weather[0].Description : null;
      this.wind =city.wind.Speed;
      this.rain = rain;
      this.temperature = city.main.Temp;

  }
}
