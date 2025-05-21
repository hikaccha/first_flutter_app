import 'package:flutter/material.dart';

void main() {
  runApp(const WeatherApp());
}

class WeatherApp extends StatefulWidget {
  const WeatherApp({super.key});

  @override
  State<WeatherApp> createState() => _WeatherAppState();
}

class _WeatherAppState extends State<WeatherApp> {
  String location = ''; // Default location
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: Scaffold(
        appBar: AppBar(title: const Text('Weather App')),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return DefaultTabController(
      length: 3,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: <Widget>[
            _buildSearchBar(),
            const SizedBox(height: 16.0),
            // Content area (TabBarView)
            Expanded(
              child: TabBarView(
                children: <Widget>[
                  _buildWeatherTab('Current'),
                  _buildWeatherTab('Today'),
                  _buildWeatherTab('Weekly'),
                ],
              ),
            ),
            // Tab buttons at the bottom
            TabBar(
              tabs: [
                Tab(icon: const Icon(Icons.access_time), text: 'Currently'),
                Tab(icon: const Icon(Icons.calendar_today), text: 'Today'),
                Tab(icon: const Icon(Icons.view_week), text: 'Weekly'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Enter location',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
              },
            ),
            Tooltip(
              message: 'Use current location',
              child: IconButton(
                onPressed: () {
                  setState(() {
                    location = 'Geolocation';
                  });
                },
                icon: const Icon(Icons.navigation),
              ),
            ),
          ],
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
      onChanged: (value) {
        setState(() {
          location = value;
        });
      },
      onSubmitted: (value) {
        setState(() {
          location = value;
        });
      },
    );
  }

  Widget _buildWeatherTab(String tabName) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const SizedBox(height: 16),
          Text(
            tabName,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            location.isEmpty ? 'No location selected' : location,
            style: const TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }
}
