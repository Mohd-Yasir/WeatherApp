import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/weather_model.dart';
import '../services/api_service.dart';
import 'widgets/weather_card.dart';

class HomeScreen extends StatefulWidget {
  final ValueChanged<ThemeMode> onThemeChanged;
  final ThemeMode initialThemeMode;

  const HomeScreen({
    super.key,
    required this.onThemeChanged,
    required this.initialThemeMode,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _cityTextController = TextEditingController();
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  Weather? _weather;
  String? _errorMessage;
  List<String> _recentSearches = [];
  late ThemeMode _currentThemeMode;

  @override
  void initState() {
    super.initState();
    _currentThemeMode = widget.initialThemeMode;
    _loadRecentSearches();
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches = prefs.getStringList('recentSearches') ?? [];
    });
  }

  Future<void> _saveRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('recentSearches', _recentSearches);
  }

  Future<void> _searchWeather() async {
    final city = _cityTextController.text.trim();
    if (city.isEmpty) {
      setState(() {
        _errorMessage = "Please enter a city name.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _weather = null;
    });

    try {
      final weatherData = await _apiService.fetchWeather(city);
      setState(() {
        _weather = weatherData;
        _addRecentSearch(city);
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addRecentSearch(String city) {
    final normalizedCity = city.trim().toLowerCase();
    _recentSearches.removeWhere((item) => item.toLowerCase() == normalizedCity);
    _recentSearches.insert(0, city.trim());
    if (_recentSearches.length > 5) {
      _recentSearches.removeLast();
    }
    _saveRecentSearches();
  }

  void _removeRecentSearch(String city) {
    setState(() {
      _recentSearches.remove(city);
    });
    _saveRecentSearches();
  }

  @override
  void dispose() {
    _cityTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather App'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _currentThemeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: () {
              final newThemeMode = _currentThemeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
              setState(() {
                _currentThemeMode = newThemeMode;
              });
              widget.onThemeChanged(newThemeMode);
            },
            tooltip: 'Toggle theme',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _searchWeather,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSearchInput(),
              const SizedBox(height: 20),
              _buildContent(),
              const SizedBox(height: 20),
              _buildRecentSearches(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      );
    }
    if (_weather != null) {
      return WeatherCard(weather: _weather!);
    }
    return const Center(
      child: Text(
        'Search for a city to see the weather.',
        style: TextStyle(fontSize: 18, color: Colors.grey),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSearchInput() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _cityTextController,
            decoration: InputDecoration(
              labelText: 'Enter City Name',
              hintText: 'e.g., Tokyo',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onSubmitted: (value) => _searchWeather(),
          ),
        ),
        const SizedBox(width: 10),
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: _searchWeather,
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentSearches() {
    if (_recentSearches.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recent Searches', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: _recentSearches.map((city) {
            return GestureDetector(
              onLongPress: () {
                _confirmRemoveRecentSearch(context, city);
              },
              child: ActionChip(
                label: Text(city),
                onPressed: () {
                  _cityTextController.text = city;
                  _searchWeather();
                },
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _confirmRemoveRecentSearch(BuildContext context, String city) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Remove Recent Search?'),
          content: Text('Do you want to remove "$city" from recent searches?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Remove'),
              onPressed: () {
                _removeRecentSearch(city);
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }
}