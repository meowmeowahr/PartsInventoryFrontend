import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Parts Sorter',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light, // Default to light theme
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  int? _selectedIndex = 0;
  List _locations = [];
  List _sorters = [];

  String sortersSortType = "creationTimeDesc";
  String sorterSearchQuery = "";

  String locationsSortType = "creationTimeDesc";
  String locationsSearchQuery = "";

  @override
  void initState() {
    super.initState();
    _fetchLocations();
  }

  Future<void> _fetchLocations() async {
    final url = Uri.parse(
        'http://localhost:8000/locations'); // Replace with your API endpoint
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> locationsJson = jsonDecode(response.body);
        setState(() {
          _locations = locationsJson;
        });
      } else {
        throw Exception('Failed to load locations');
      }
    } catch (e) {
      print('Error loading locations: $e');
      // Handle error as needed
    }
  }

  Future<void> _fetchSorters() async {
    final url = Uri.parse(
        'http://localhost:8000/sorters'); // Replace with your API endpoint
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> sortersJson = jsonDecode(response.body);
        setState(() {
          _sorters = sortersJson;
        });
      } else {
        throw Exception('Failed to load sorters');
      }
    } catch (e) {
      print('Error loading sorters: $e');
      // Handle error as needed
    }
  }

  List _sortLocations(List locations, String sorter) {
    List sortedLocations = List.from(locations);
    switch (sorter) {
      case 'creationTimeDesc':
        // Already in descending order
        break;
      case 'creationTimeAsc':
        sortedLocations = sortedLocations.reversed.toList();
        break;
      case 'nameAsc':
        sortedLocations.sort((a, b) => a['name'].compareTo(b['name']));
        break;
      case 'nameDesc':
        sortedLocations.sort((a, b) => b['name'].compareTo(a['name']));
        break;
      default:
        // Handle invalid sorter case if needed
        break;
    }
    return sortedLocations;
  }

  List _sortSorters(List sorters, String sorter) {
    List sortedSorters = List.from(sorters);
    switch (sorter) {
      case 'creationTimeDesc':
        // Already in descending order
        break;
      case 'creationTimeAsc':
        sortedSorters = sortedSorters.reversed.toList();
        break;
      case 'nameAsc':
        sortedSorters.sort((a, b) => a['name'].compareTo(b['name']));
        break;
      case 'nameDesc':
        sortedSorters.sort((a, b) => b['name'].compareTo(a['name']));
        break;
      default:
        // Handle invalid sorter case if needed
        break;
    }
    return sortedSorters;
  }

  List<dynamic> filterLocations(List<dynamic> locations, String searchEntry) {
    final query = searchEntry.toLowerCase();

    return locations.where((location) {
      final name = (location['name'] as String).toLowerCase();
      final tags = (location['tags'] as String).toLowerCase().split(',');

      return name.contains(query) || tags.any((tag) => tag.contains(query));
    }).toList();
  }

  List<dynamic> filterSorters(List<dynamic> sorters, String searchEntry) {
    final query = searchEntry.toLowerCase();

    return sorters.where((sorter) {
      final name = (sorter['name'] as String).toLowerCase();
      final tags = (sorter['tags'] as String).toLowerCase().split(',');

      return name.contains(query) || tags.any((tag) => tag.contains(query));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Part Sorter"),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            children: <Widget>[
              _buildNavigationRail(context),
              Expanded(
                child: Center(child: _buildContent()),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNavigationRail(BuildContext context) {
    return NavigationRail(
      selectedIndex: _selectedIndex!,
      onDestinationSelected: (int index) {
        _fetchSorters();
        _fetchLocations();
        setState(() {
          _selectedIndex = index;
        });
      },
      labelType: NavigationRailLabelType.selected,
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: Text('Home'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.room_outlined),
          selectedIcon: Icon(Icons.room),
          label: Text('Locations'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.inventory_2_outlined),
          selectedIcon: Icon(Icons.inventory),
          label: Text('Sorters'),
        ),
      ],
    );
  }

  Widget _buildContent() {
    // Simulate content based on selected index
    switch (_selectedIndex) {
      case 0:
        return const SingleChildScrollView(
          child: Column(
            children: [
              Icon(
                Icons.home_filled,
                size: 240,
              ),
              Text(
                "Total Items in Inventory: XXX",
                style: TextStyle(fontSize: 24),
              ),
            ],
          ),
        );
      case 1:
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: SearchBar(
                    onChanged: (value) {
                      setState(() {
                        locationsSearchQuery = value;
                      });
                    },
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.sort),
                  tooltip: "Sort",
                  onSelected: (String value) {
                    setState(() {
                      locationsSortType = value;
                    });
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'creationTimeDesc',
                      child: Text('Creation Time Descending'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'creationTimeAsc',
                      child: Text('Creation Time Ascending'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'nameAsc',
                      child: Text('Name Ascending'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'nameDesc',
                      child: Text('Name Descending'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            Expanded(
              child: ListView.builder(
                itemCount:
                    filterLocations(_locations, locationsSearchQuery).length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ButtonStyle(
                        shape:
                            MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            const Icon(
                              // String2Icon.getIconDataFromString(
                              //     _sorters[index]['icon']),
                              Icons.room,
                              size: 64,
                            ),
                            const Spacer(),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _sortLocations(
                                      filterLocations(
                                          _locations, locationsSearchQuery),
                                      locationsSortType)[index]['name'],
                                  style: const TextStyle(
                                    fontSize: 18,
                                  ),
                                ),
                                Text(
                                  _sortLocations(
                                      filterLocations(
                                          _locations, locationsSearchQuery),
                                      locationsSortType)[index]['id'],
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                                Wrap(
                                  direction: Axis.horizontal,
                                  spacing:
                                      4.0, // Space between adjacent widgets
                                  runSpacing:
                                      4.0, // Space between lines of widgets
                                  children: [
                                    for (var tag in _sortLocations(
                                            filterLocations(_locations,
                                                locationsSearchQuery),
                                            locationsSortType)[index]['tags']
                                        .split(','))
                                      Chip(
                                        label: Text(
                                          tag,
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        labelPadding: EdgeInsets.zero,
                                        visualDensity: const VisualDensity(
                                            horizontal: 0.0, vertical: -4),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );

      case 2:
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: SearchBar(
                    onChanged: (value) {
                      setState(() {
                        sorterSearchQuery = value;
                      });
                    },
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.sort),
                  tooltip: "Sort",
                  onSelected: (String value) {
                    setState(() {
                      sortersSortType = value;
                    });
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'creationTimeDesc',
                      child: Text('Creation Time Descending'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'creationTimeAsc',
                      child: Text('Creation Time Ascending'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'nameAsc',
                      child: Text('Name Ascending'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'nameDesc',
                      child: Text('Name Descending'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            Expanded(
              child: ListView.builder(
                itemCount: filterSorters(_sorters, sorterSearchQuery).length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ButtonStyle(
                        shape:
                            MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            const Icon(
                              // String2Icon.getIconDataFromString(
                              //     _sorters[index]['icon']),
                              Icons.inventory_2,
                              size: 64,
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _sortSorters(
                                        filterSorters(
                                            _sorters, sorterSearchQuery),
                                        sortersSortType)[index]['name'],
                                    style: const TextStyle(
                                      fontSize: 18,
                                    ),
                                  ),
                                  Text(
                                    _sortSorters(
                                        filterSorters(
                                            _sorters, sorterSearchQuery),
                                        sortersSortType)[index]['id'],
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Wrap(
                                    direction: Axis.horizontal,
                                    spacing:
                                        4.0, // Space between adjacent widgets
                                    runSpacing:
                                        4.0, // Space between lines of widgets
                                    children: [
                                      for (var tag in _sortSorters(
                                              filterSorters(
                                                  _sorters, sorterSearchQuery),
                                              sortersSortType)[index]['tags']
                                          .split(','))
                                        Chip(
                                          label: Text(
                                            tag,
                                            style:
                                                const TextStyle(fontSize: 11),
                                          ),
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          labelPadding: EdgeInsets.zero,
                                          visualDensity: const VisualDensity(
                                              horizontal: 0.0, vertical: -4),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      default:
        return Text('Default Area');
    }
  }
}

class SearchBar extends StatelessWidget {
  final Function(String) onChanged;

  const SearchBar({required this.onChanged, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        filled: true,
        hintText: 'Search',
        border: InputBorder.none,
        prefixIcon: const Icon(Icons.search),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
      ),
    );
  }
}
