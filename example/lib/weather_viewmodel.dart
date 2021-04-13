import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:rx_command/rx_command.dart';
import 'package:rxdart/rxdart.dart';

import 'json/weather_in_cities.dart';

class WeatherViewModel {
  RxCommand<String, List<WeatherEntry>> updateWeatherCommand;
  RxCommand<bool, bool> switchChangedCommand;
  RxCommand<String, String> textChangedCommand;

  WeatherViewModel() {
    // Command expects a bool value when executed and issues the value on it's result Stream (stream)
    switchChangedCommand =
        RxCommand.createSync<bool, bool>((b) => b, initialLastResult: true);

    // We pass the result of switchChangedCommand as canExecute Stream to the upDateWeatherCommand
    updateWeatherCommand = RxCommand.createAsync<String, List<WeatherEntry>>(
        update,
        canExecute: switchChangedCommand,
        emitsLastValueToNewSubscriptions: true,
        initialLastResult: []);

    // Will be called on every change of the searchfield
    textChangedCommand = RxCommand.createSync((s) => s, initialLastResult: '');

    // handler for results
    // make sure we start processing only if the user make a short pause typing
    textChangedCommand.debounceTime(Duration(milliseconds: 500)).listen(
      (filterText) {
        // I could omit he execute because RxCommand is a callable
        // class  but here it makes the intention clearer
        updateWeatherCommand.execute(filterText);
      },
    );

    updateWeatherCommand.thrownExceptions.listen((ex) => print(ex.toString()));

    // Update data on startup
    updateWeatherCommand.execute();
  }

  // Async function that queries the REST API and converts the result into the form our ListViewBuilder can consume
  Future<List<WeatherEntry>> update(String filtertext) {
    const url =
        "http://api.openweathermap.org/data/2.5/box/city?bbox=12,32,15,37,10&appid=27ac337102cc4931c24ba0b50aca6bbd";

    var httpStream = http.get(url).asStream();

    return httpStream
        .where(
            (data) => data.statusCode == 200) // only continue if valid response
        .map(
      (data) {
        // convert JSON result into a List of WeatherEntries
        return WeatherInCities.fromJson(
                json.decode(data.body) as Map<String, dynamic>)
            .cities // we are only interested in the Cities part of the response
            .where((weatherInCity) =>
                filtertext == null ||
                filtertext
                    .isEmpty || // if filtertext is null or empty we return all returned entries
                weatherInCity.name.toUpperCase().startsWith(filtertext
                    .toUpperCase())) // otherwise only matching entries
            .map((weatherInCity) => WeatherEntry(
                weatherInCity)) // Convert City object to WeatherEntry
            .toList(); // aggregate entries to a List
      },
    ).first; // Return result as Future
  }
}

class WeatherEntry {
  String cityName;
  String iconURL;
  double wind;
  double rain;
  double temperature;
  String description;

  WeatherEntry(City city) {
    this.cityName = city.name;
    this.iconURL = city.weather != null
        ? "http://openweathermap.org/img/w/${city.weather[0].icon}.png"
        : null;
    this.description =
        city.weather != null ? city.weather[0].description : null;
    this.wind = city.wind.speed;
    this.rain = rain;
    this.temperature = city.main.temp;
  }
}
