// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weather_in_cities.dart';

// **************************************************************************
// Generator: JsonSerializableGenerator
// **************************************************************************

WeatherInCities _$WeatherInCitiesFromJson(Map<String, dynamic> json) =>
    new WeatherInCities(
        json['cnt'] as int,
        (json['calctime'] as num)?.toDouble(),
        json['cod'] as int,
        (json['list'] as List)
            ?.map((e) =>
                e == null ? null : new City.fromJson(e as Map<String, dynamic>))
            ?.toList());

abstract class _$WeatherInCitiesSerializerMixin {
  int get Cnt;
  double get Calctime;
  int get Cod;
  List<City> get Cities;
  Map<String, dynamic> toJson() => <String, dynamic>{
        'cnt': Cnt,
        'calctime': Calctime,
        'cod': Cod,
        'list': Cities
      };
}

City _$CityFromJson(Map<String, dynamic> json) => new City(
    json['id'] as int,
    json['coord'] == null
        ? null
        : new Coord.fromJson(json['coord'] as Map<String, dynamic>),
    json['clouds'] == null
        ? null
        : new Clouds.fromJson(json['clouds'] as Map<String, dynamic>),
    json['dt'] as int,
    json['name'] as String,
    json['main'] == null
        ? null
        : new Main.fromJson(json['main'] as Map<String, dynamic>),
    json['rain'] == null
        ? null
        : new Rain.fromJson(json['rain'] as Map<String, dynamic>),
    (json['weather'] as List)
        ?.map((e) =>
            e == null ? null : new Weather.fromJson(e as Map<String, dynamic>))
        ?.toList(),
    json['wind'] == null
        ? null
        : new Wind.fromJson(json['wind'] as Map<String, dynamic>));

abstract class _$CitySerializerMixin {
  int get Id;
  Coord get coord;
  Clouds get clouds;
  int get Dt;
  String get Name;
  Main get main;
  Rain get rain;
  List<Weather> get weather;
  Wind get wind;
  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': Id,
        'coord': coord,
        'clouds': clouds,
        'dt': Dt,
        'name': Name,
        'main': main,
        'rain': rain,
        'weather': weather,
        'wind': wind
      };
}

Coord _$CoordFromJson(Map<String, dynamic> json) => new Coord(
    (json['Lat'] as num)?.toDouble(), (json['Lon'] as num)?.toDouble());

abstract class _$CoordSerializerMixin {
  double get Lat;
  double get Lon;
  Map<String, dynamic> toJson() => <String, dynamic>{'Lat': Lat, 'Lon': Lon};
}

Clouds _$CloudsFromJson(Map<String, dynamic> json) =>
    new Clouds(json['today'] as int);

abstract class _$CloudsSerializerMixin {
  int get Today;
  Map<String, dynamic> toJson() => <String, dynamic>{'today': Today};
}

Main _$MainFromJson(Map<String, dynamic> json) => new Main(
    (json['sea_level'] as num)?.toDouble(),
    json['humidity'] as int,
    (json['grnd_level'] as num)?.toDouble(),
    (json['pressure'] as num)?.toDouble(),
    (json['temp_max'] as num)?.toDouble(),
    (json['temp'] as num)?.toDouble(),
    (json['temp_min'] as num)?.toDouble());

abstract class _$MainSerializerMixin {
  double get SeaLevel;
  int get Humidity;
  double get GrndLevel;
  double get Pressure;
  double get TempMax;
  double get Temp;
  double get TempMin;
  Map<String, dynamic> toJson() => <String, dynamic>{
        'sea_level': SeaLevel,
        'humidity': Humidity,
        'grnd_level': GrndLevel,
        'pressure': Pressure,
        'temp_max': TempMax,
        'temp': Temp,
        'temp_min': TempMin
      };
}

Rain _$RainFromJson(Map<String, dynamic> json) =>
    new Rain((json['3h'] as num)?.toDouble());

abstract class _$RainSerializerMixin {
  double get The3h;
  Map<String, dynamic> toJson() => <String, dynamic>{'3h': The3h};
}

Weather _$WeatherFromJson(Map<String, dynamic> json) => new Weather(
    json['icon'] as String,
    json['description'] as String,
    json['id'] as int,
    json['main'] as String);

abstract class _$WeatherSerializerMixin {
  String get Icon;
  String get Description;
  int get Id;
  String get Main;
  Map<String, dynamic> toJson() => <String, dynamic>{
        'icon': Icon,
        'description': Description,
        'id': Id,
        'main': Main
      };
}

Wind _$WindFromJson(Map<String, dynamic> json) => new Wind(
    (json['deg'] as num)?.toDouble(), (json['speed'] as num)?.toDouble());

abstract class _$WindSerializerMixin {
  double get Deg;
  double get Speed;
  Map<String, dynamic> toJson() =>
      <String, dynamic>{'deg': Deg, 'speed': Speed};
}
