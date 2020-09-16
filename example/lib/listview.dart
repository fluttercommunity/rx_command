import 'package:flutter/material.dart';

import 'main.dart';
import 'weather_viewmodel.dart';

class WeatherListView extends StatelessWidget {
  WeatherListView();
  @override
  Widget build(BuildContext context) {
    // Streambuilder rebuilds its subtree on every item the stream issues
    return StreamBuilder<List<WeatherEntry>>(
      //We access our ViewModel through the inherited Widget
      stream: TheViewModel.of(context).updateWeatherCommand,
      builder:
          (BuildContext context, AsyncSnapshot<List<WeatherEntry>> snapshot) {
        // only if we get data
        if (snapshot.hasData && snapshot.data.isNotEmpty) {
          return ListView.builder(
            itemCount: snapshot.data.length,
            itemBuilder: (BuildContext context, int index) => ListTile(
              title: Text(snapshot.data[index].cityName),
              subtitle: Text(snapshot.data[index].description),
              leading: Image.network(
                snapshot.data[index].iconURL,
                frameBuilder: (BuildContext context, Widget child, int frame,
                    bool wasSynchronouslyLoaded) {
                  return child;
                },
                loadingBuilder: (BuildContext context, Widget child,
                    ImageChunkEvent loadingProgress) {
                  if (loadingProgress == null) return child;
                  return CircularProgressIndicator();
                },
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.error,
                  size: 40,
                ),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${snapshot.data[index].temperature}°C'),
                  Text('${snapshot.data[index].wind}km/h'),
                ],
              ),
            ),
          );
        } else {
          return Text("No items");
        }
      },
    );
  }
}
