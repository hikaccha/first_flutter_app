import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart'; // Add this import for SystemChannels

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather App',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const WeatherApp(),
    );
  }
}

class CitySuggestion {
  final String name;
  final String? admin1; //地域（APIによってはnullの場合がある）
  final String country;
  final double latitude;
  final double longitude;

  CitySuggestion({
    required this.name,
    this.admin1,
    required this.country,
    required this.latitude,
    required this.longitude,
  });

  factory CitySuggestion.fromJson(Map<String, dynamic> json) {
    return CitySuggestion(
      name: json['name'],
      admin1: json['admin1'], // null許容
      country: json['country'],
      latitude: json['latitude'],
      longitude: json['longitude'],
    );
  }

  // 候補リストに表示するための文字列
  @override
  String toString() {
    return '${name}${admin1 != null ? ', $admin1' : ''}, $country';
  }
}

class WeatherApp extends StatefulWidget {
  const WeatherApp({super.key});

  @override
  State<WeatherApp> createState() => _WeatherAppState();
}

class _WeatherAppState extends State<WeatherApp> {
  String location = ''; // 現在表示している場所の情報（都市名など）
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false; // 位置情報取得中のローディング状態

  //追加： 検索候補のリスト
  List<CitySuggestion> _suggestions = [];
  // 追加： 検索候補を表示するかどうかのフラグ
  bool _showSuggestions = false;

  // エラー関連の状態変数
  bool _hasApiError = false;
  bool _hasCityError = false;
  String _errorMessage = '';

  // Add this as a class variable in your _WeatherAppState class
  final FocusNode _searchFocusNode = FocusNode();

  // 天気データを保持する変数
  Map<String, dynamic>? _weatherData;

  // 天気コードから天気情報に変換するマップ
  final Map<int, Map<String, dynamic>> _weatherCodeMap = {
    0: {'description': 'Clear sky', 'icon': Icons.wb_sunny},
    1: {'description': 'Mainly clear', 'icon': Icons.wb_sunny},
    2: {'description': 'Partly cloudy', 'icon': Icons.cloud_queue},
    3: {'description': 'Overcast', 'icon': Icons.cloud},
    45: {'description': 'Fog', 'icon': Icons.cloud},
    48: {'description': 'Depositing rime fog', 'icon': Icons.ac_unit},
    51: {'description': 'Light drizzle', 'icon': Icons.grain},
    53: {'description': 'Moderate drizzle', 'icon': Icons.grain},
    55: {'description': 'Dense drizzle', 'icon': Icons.beach_access},
    56: {'description': 'Light freezing drizzle', 'icon': Icons.ac_unit},
    57: {'description': 'Dense freezing drizzle', 'icon': Icons.ac_unit},
    61: {'description': 'Slight rain', 'icon': Icons.grain},
    63: {'description': 'Moderate rain', 'icon': Icons.beach_access},
    65: {'description': 'Heavy rain', 'icon': Icons.beach_access},
    66: {'description': 'Light freezing rain', 'icon': Icons.ac_unit},
    67: {'description': 'Heavy freezing rain', 'icon': Icons.ac_unit},
    71: {'description': 'Slight snow fall', 'icon': Icons.ac_unit},
    73: {'description': 'Moderate snow fall', 'icon': Icons.ac_unit},
    75: {'description': 'Heavy snow fall', 'icon': Icons.ac_unit},
    77: {'description': 'Snow grains', 'icon': Icons.ac_unit},
    80: {'description': 'Slight rain showers', 'icon': Icons.grain},
    81: {'description': 'Moderate rain showers', 'icon': Icons.beach_access},
    82: {'description': 'Violent rain showers', 'icon': Icons.beach_access},
    85: {'description': 'Slight snow showers', 'icon': Icons.ac_unit},
    86: {'description': 'Heavy snow showers', 'icon': Icons.ac_unit},
    95: {'description': 'Thunderstorm', 'icon': Icons.flash_on},
    96: {'description': 'Thunderstorm with hail', 'icon': Icons.flash_on},
    99: {'description': 'Heavy thunderstorm with hail', 'icon': Icons.flash_on},
  };

  // 天気コードから天気情報を取得するヘルパーメソッド
  Map<String, dynamic> _getWeatherInfo(int weatherCode) {
    return _weatherCodeMap[weatherCode] ??
        {'description': 'Unknown', 'icon': Icons.question_mark};
  }

  @override
  void initState() {
    super.initState();
    Geolocator.checkPermission();

    // Add a listener to the focus node to show keyboard when focus is requested
    _searchFocusNode.addListener(() {
      if (_searchFocusNode.hasFocus) {
        SystemChannels.textInput.invokeMethod('TextInput.show');
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getCurrentLocation(context);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // 位置情報の権限と位置情報を取得する関数
  Future<void> _getCurrentLocation(BuildContext context) async {
    setState(() {
      _isLoading = true;
      _showSuggestions = false;
    });

    try {
      // 位置情報サービスが有効かチェック
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationErrorDialog(
          context,
          'Location services are disabled. Please enable location services in your device settings.',
        );
        return;
      }

      // 位置情報の権限をチェック
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        // 権限がない場合、リクエスト
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showLocationErrorDialog(
            context,
            'Location permissions are denied. Please allow location access to use this feature.',
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showLocationErrorDialog(
          context,
          'Location permissions are permanently denied. Please enable them in your device settings.',
          showSettings: true,
        );
        return;
      }

      // 権限があれば位置情報を取得（高精度設定）
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      setState(() {
        location =
            '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
        _isLoading = false;
      });

      // デバッグ情報を表示
      print(
        'GPS Position obtained - Lat: ${position.latitude}, Lon: ${position.longitude}, '
        'Accuracy: ${position.accuracy}m, Timestamp: ${position.timestamp}',
      );

      // 位置情報を使って天気データをフェッチ
      _fetchWeatherData(position.latitude, position.longitude);
    } catch (e) {
      print('Location error: $e');
      setState(() {
        location = 'Error: $e';
        _isLoading = false;
      });
      _showLocationErrorDialog(context, 'Error getting location: $e');
    }
  }

  // 位置情報エラーを表示するダイアログ
  void _showLocationErrorDialog(
    BuildContext context,
    String message, {
    bool showSettings = false,
  }) {
    setState(() {
      _isLoading = false;
    });

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            if (showSettings)
              TextButton(
                child: const Text('Open Settings'),
                onPressed: () {
                  Navigator.of(context).pop();
                  Geolocator.openAppSettings();
                  // または Geolocator.openLocationSettings(); を使用
                },
              ),
          ],
        );
      },
    );
  }

  Future<void> _fetchSuggestions(String query) async {
    if (query.isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false; // クエリがからの場合は候補を非表示にする
        _hasCityError = false;
        _errorMessage = '';
      });
      return;
    }

    final apiUrl =
        'https://geocoding-api.open-meteo.com/v1/search?name=$query&count=10'; // countやlanguageは任意
    final uri = Uri.parse(apiUrl);

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] != null) {
          setState(() {
            _suggestions =
                (data['results'] as List)
                    .map((json) => CitySuggestion.fromJson(json))
                    .toList();
            _showSuggestions = _suggestions.isNotEmpty; //候補があれば表示

            // 候補がない場合はエラーを表示
            if (_suggestions.isEmpty) {
              _hasCityError = true;
              _errorMessage =
                  'No cities found matching "$query". Please try another search.';
            } else {
              _hasCityError = false;
              _errorMessage = '';
            }
          });
        } else {
          setState(() {
            _suggestions = [];
            _showSuggestions = false;
            _hasCityError = true;
            _errorMessage = 'No cities found. Please try another search.';
          });
        }
      } else {
        // APIエラーの場合の処理(Exercise 03に関連)
        print('Geocoding API Error: ${response.statusCode}');
        setState(() {
          _suggestions = []; // エラー時は候補をクリア
          _showSuggestions = false;
          _hasCityError = true;
          _errorMessage =
              'City search service error (${response.statusCode}). Please try again later.';
        });
      }
    } catch (e) {
      // ネットワークエラーなどの場合の処理(Exercise 03に関連)
      print('Geocoding API Error: $e');
      setState(() {
        _suggestions = []; // エラー時は候補をクリアする
        _showSuggestions = false;
        _hasCityError = true;
        _errorMessage =
            'Failed to connect to city search service. Please check your connection.';
      });
    }
  }

  void _selectCity(CitySuggestion suggestion) {
    _searchController.text = suggestion.name;

    setState(() {
      _suggestions = [];
      _showSuggestions = false;
      location = suggestion.toString();
      _hasCityError = false;
      _errorMessage = '';
    });
    FocusScope.of(context).unfocus();

    // 選択された都市の天気データを取得
    _fetchWeatherData(suggestion.latitude, suggestion.longitude);
  }

  // 天気データを取得するメソッド
  Future<void> _fetchWeatherData(double lat, double lon) async {
    setState(() {
      _isLoading = true;
      // APIを呼び出すときは既存のエラーをクリア
      _hasApiError = false;
      _errorMessage = '';
    });

    try {
      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon'
        '&current_weather=true&hourly=temperature_2m,weathercode,windspeed_10m'
        '&daily=weathercode,temperature_2m_max,temperature_2m_min'
        '&timezone=auto',
      );

      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          _weatherData = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        print('Weather API Error: ${response.statusCode}');
        setState(() {
          _isLoading = false;
          _hasApiError = true;
          _errorMessage =
              'Weather API error: ${response.statusCode}. Please try again.';
        });
      }
    } catch (e) {
      print('Weather API Error: $e');
      setState(() {
        _isLoading = false;
        _hasApiError = true;
        _errorMessage =
            'Failed to connect to weather service. Please check your connection.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather App'),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 4,
      ),
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage( // 背景画像を設定
            image: NetworkImage( // 画像をネットワークから取得
              'https://images.unsplash.com/photo-1519681393784-d120267933ba?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=2070&q=80',
            ),
            fit: BoxFit.cover, // 画像をコンテナにフィットさせる
          ),
        ),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return DefaultTabController(
      length: 3,
      child: Container(
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.3)),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
            },
            child: Column(
              children: <Widget>[
                _buildSearchBar(),
                const SizedBox(height: 16.0),
                Expanded(
                  child: TabBarView(
                    children: <Widget>[
                      _buildWeatherTab('Current'),
                      _buildWeatherTab('Today'),
                      _buildWeatherTab('Weekly'),
                    ],
                  ),
                ),
                TabBar(
                  tabs: [
                    Tab(icon: const Icon(Icons.access_time), text: 'Currently'),
                    Tab(icon: const Icon(Icons.calendar_today), text: 'Today'),
                    Tab(icon: const Icon(Icons.view_week), text: 'Weekly'),
                  ],
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  indicatorColor: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            _searchFocusNode.requestFocus();
          },
          child: TextField(
            keyboardType: TextInputType.text,
            controller: _searchController,
            autofocus: false,
            focusNode: _searchFocusNode,
            showCursor: true,
            enableInteractiveSelection: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search location',
              hintStyle: const TextStyle(color: Colors.white70),
              prefixIcon: const Icon(Icons.search, color: Colors.white),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _suggestions = [];
                        _showSuggestions = false;
                        location = '';
                      });
                    },
                  ),
                  Tooltip(
                    message: 'Use current location',
                    child: IconButton(
                      onPressed:
                          _isLoading
                              ? null
                              : () => _getCurrentLocation(context),
                      icon:
                          _isLoading
                              ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                              : const Icon(
                                Icons.navigation,
                                color: Colors.white,
                              ),
                    ),
                  ),
                ],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(color: Colors.white),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(color: Colors.white70),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(color: Colors.white),
              ),
            ),
            onChanged: (value) {
              _fetchSuggestions(value);
            },
            onSubmitted: (value) {
              setState(() {
                _showSuggestions = false;
              });
              if (value.isEmpty) {
                setState(() {
                  _hasCityError = true;
                  _errorMessage = 'Please enter a city name to search';
                });
                return;
              }

              if (_suggestions.isNotEmpty) {
                _selectCity(_suggestions.first);
              } else {
                _fetchSuggestions(value).then((_) {
                  if (_suggestions.isNotEmpty) {
                    _selectCity(_suggestions.first);
                  } else {
                    setState(() {
                      location = 'City not found: $value';
                      _hasCityError = true;
                      _errorMessage =
                          'No cities found matching "$value". Please try another search.';
                    });
                  }
                });
              }
            },
          ),
        ),

        if (_showSuggestions)
          Container(
            constraints: BoxConstraints(
              maxHeight: 200,
              maxWidth: MediaQuery.of(context).size.width - 16,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _suggestions.length > 5 ? 5 : _suggestions.length,
              itemBuilder: (context, index) {
                final suggestion = _suggestions[index];
                return ListTile(
                  title: Text(
                    suggestion.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  subtitle: Text(
                    suggestion.admin1 != null
                        ? '${suggestion.admin1}, ${suggestion.country}'
                        : suggestion.country,
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                  onTap: () {
                    _selectCity(suggestion);
                  },
                );
              },
            ),
          ),
      ],
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
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            location.isEmpty ? 'No location selected' : location,
            style: const TextStyle(fontSize: 18, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          _isLoading
              ? const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              )
              : _buildWeatherContent(tabName),
        ],
      ),
    );
  }

  Widget _buildWeatherContent(String tabName) {
    if (_hasApiError || _hasCityError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48.0),
              const SizedBox(height: 16.0),
              Text(
                _errorMessage,
                style: const TextStyle(fontSize: 16.0),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_weatherData == null) return const SizedBox();

    switch (tabName) {
      case 'Current':
        final current = _weatherData!['current_weather'];
        final weatherCode = current['weathercode'] as int;
        final weatherInfo = _getWeatherInfo(weatherCode);

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Weather: ${weatherInfo['description']}',
                style: const TextStyle(color: Colors.white),
              ),
              Text(
                'Temperature: ${current['temperature']}°C',
                style: const TextStyle(color: Colors.white),
              ),
              Text(
                'Wind Speed: ${current['windspeed']} km/h',
                style: const TextStyle(color: Colors.white),
              ),
              Text(
                'Updated: ${current['time']}',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        );
      case 'Today':
        final hourly = _weatherData!['hourly'];
        final times = hourly['time'] as List<dynamic>;
        final temps = hourly['temperature_2m'] as List<dynamic>;
        final weatherCodes = hourly['weathercode'] as List<dynamic>;
        final windSpeeds = hourly['windspeed_10m'] as List<dynamic>;

        final now = DateTime.now();
        final currentHourIndex = times.indexWhere((time) {
          final timeDate = DateTime.parse(time.toString());
          return timeDate.isAfter(now) ||
              (timeDate.hour == now.hour && timeDate.day == now.day);
        });

        final startIndex = currentHourIndex >= 0 ? currentHourIndex : 0;
        final endIndex =
            startIndex + 24 < times.length ? startIndex + 24 : times.length;

        final items = List.generate(endIndex - startIndex, (index) {
          final i = index + startIndex;
          final time = DateTime.parse(times[i].toString());
          final weatherCode = weatherCodes[i] as int;
          final weatherInfo = _getWeatherInfo(weatherCode);
          return '${time.hour}:00 - ${weatherInfo['description']} ${temps[i]}°C ${windSpeeds[i]} km/h';
        });

        return Expanded(
          child: ListView(
            children:
                items
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Center(
                          child: Text(
                            item,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    )
                    .toList(),
          ),
        );
      case 'Weekly':
        if (_weatherData!.containsKey('daily')) {
          final daily = _weatherData!['daily'];
          final times = daily['time'] as List<dynamic>;
          final weatherCodes = daily['weathercode'] as List<dynamic>;
          final minTemps = daily['temperature_2m_min'] as List<dynamic>;
          final maxTemps = daily['temperature_2m_max'] as List<dynamic>;

          return Expanded(
            child: ListView.builder(
              itemCount: weatherCodes.length,
              itemBuilder: (context, index) {
                final weatherCode = weatherCodes[index] as int;
                final weatherInfo = _getWeatherInfo(weatherCode);
                final date = DateTime.parse(times[index].toString());
                final formattedDate = '${date.year}-${date.month}-${date.day}';

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Center(
                    child: Text(
                      '$formattedDate - ${weatherInfo['description']} ${minTemps[index]}°C - ${maxTemps[index]}°C',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                );
              },
            ),
          );
        } else {
          return const Center(child: Text('Weekly forecast not available'));
        }
      default:
        return const Text('Unknown tab');
    }
  }
}
