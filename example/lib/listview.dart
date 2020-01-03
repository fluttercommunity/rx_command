import 'package:flutter/material.dart';

import 'main.dart';
import 'weather_viewmodel.dart';

class WeatherListView extends StatelessWidget {
  WeatherListView();
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<WeatherEntry>>(
        // Streambuilder rebuilds its subtree on every item the stream issues
        stream: TheViewModel.of(context)
            .updateWeatherCommand, //We access our ViewModel through the inherited Widget
        builder: (BuildContext context,
                AsyncSnapshot<List<WeatherEntry>>
                    snapshot) // in Dart Lambdas with body don't use =>
            {
          // only if we get data
          if (snapshot.hasData && snapshot.data.isNotEmpty) {
            return ListView.builder(
                itemCount: snapshot.data.length,
                itemBuilder: (BuildContext context, int index) =>
                    buildRow(context, index, snapshot.data));
          } else {
            return Text("No items");
          }
        });
  }

  Widget buildRow(
      BuildContext context, int index, List<WeatherEntry> listData) {
    return Wrap(
      spacing: 40.0,
      children: <Widget>[
        Image(image: NetworkImage(listData[index].iconURL)),
        Text(listData[index].cityName, style: TextStyle(fontSize: 20.0))
      ],
    );
  }
}
