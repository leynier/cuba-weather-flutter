import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:cuba_weather/src/blocs/blocs.dart';
import 'package:cuba_weather/src/widgets/widgets.dart';

class WeatherWidget extends StatefulWidget {
  final String initialLocation;
  final List<String> locations;

  WeatherWidget({
    Key key,
    @required this.locations,
    @required this.initialLocation,
  })  : assert(locations != null),
        super(key: key);

  @override
  State<WeatherWidget> createState() => _WeatherWidgetState(
        locations: this.locations,
        initialLocation: this.initialLocation,
      );
}

class _WeatherWidgetState extends State<WeatherWidget> {
  final String initialLocation;
  final List<String> locations;
  Completer<void> _refreshCompleter;

  _WeatherWidgetState({
    @required this.locations,
    @required this.initialLocation,
  }) : assert(locations != null);

  @override
  void initState() {
    super.initState();
    _refreshCompleter = Completer<void>();
    if (this.initialLocation != null) {
      BlocProvider.of<WeatherBloc>(context).add(FetchWeather(
        location: this.initialLocation,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0.0,
        leading: Icon(Icons.menu),
        //centerTitle: true,
        title: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Image.asset(
                    'images/logo.png',
                    fit: BoxFit.cover,
                    height: 35.0,
                  ),
                  Text('Cuba Weather', textAlign: TextAlign.center,)
                ],
              ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () async {
              final location = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LocationSelectionWidget(
                    locations: this.locations,
                  ),
                ),
              );
              if (location != null) {
                BlocProvider.of<WeatherBloc>(context).add(FetchWeather(
                  location: location,
                ));
              }
            },
          ),
          PopupMenuButton<int>(
            onSelected: (i) async {
              if (i == 0) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InformationWidget(),
                  ),
                );
              } else if (i == 1) {
                final location = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LocationList(
                      locations: this.locations,
                    ),
                  ),
                );
                if (location != null) {
                  BlocProvider.of<WeatherBloc>(context).add(FetchWeather(
                    location: location,
                  ));
                }
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem<int>(
                  value: 1,
                  child: Text('Localizaciones'),
                ),
                PopupMenuItem<int>(
                  value: 0,
                  child: Text('Información'),
                ),
              ];
            },
          ),
        ],
      ),
      body: Center(
        child: BlocListener<WeatherBloc, WeatherState>(
          listener: (context, state) {
            if (state is WeatherLoaded) {
              _refreshCompleter?.complete();
              _refreshCompleter = Completer();
            }
          },
          child: BlocBuilder<WeatherBloc, WeatherState>(
            builder: (context, state) {
              if (state is WeatherEmpty) {
                return GradientContainerWidget(
                  color: Colors.blue,
                  child: Center(
                    child: Container(
                      margin: EdgeInsets.all(20),
                      padding: EdgeInsets.only(bottom: 200),
                      child: Text(
                        'Por favor, seleccione una localización presionando '
                        'sobre el ícono de una lupa en la parte superior '
                        'derecha de la pantalla.',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              }
              if (state is WeatherLoading) {
                return GradientContainerWidget(
                  color: Colors.blue,
                  child: Center(
                    child: CircularProgressIndicator(
                      backgroundColor: Colors.white,
                    ),
                  ),
                );
              }
              if (state is WeatherLoaded) {
                final weather = state.weather;

                return GradientContainerWidget(
                  color: Colors.blue,
                  child: RefreshIndicator(
                    onRefresh: () {
                      BlocProvider.of<WeatherBloc>(context).add(
                        RefreshWeather(location: weather.cityName),
                      );
                      return _refreshCompleter.future;
                    },
                    child: ListView(
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.only(top: 100.0),
                          child: Center(
                            child:
                                NameLocationWidget(location: weather.cityName),
                          ),
                        ),
                        Center(
                          child: LastUpdatedWidget(dateTime: weather.dt.date),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 50.0),
                          child: Center(
                            child: CombinedWeatherWidget(
                              weather: weather,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              if (state is WeatherError) {
                return GradientContainerWidget(
                  color: Colors.blue,
                  child: Center(
                    child: Container(
                      margin: EdgeInsets.all(20),
                      padding: EdgeInsets.only(bottom: 200),
                      child: Text(
                        'Error: ${state.errorMessage}',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              }
              return null;
            },
          ),
        ),
      ),
    );
  }
}
