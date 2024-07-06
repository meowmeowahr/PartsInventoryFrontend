import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:http/http.dart' as http;
import 'package:sorter_frontend/widgets.dart';

import 'sorters.dart';
import 'locations.dart';

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
      home: const MyHomePage(),
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

  String partsSortType = "creationTimeDesc";
  String partsSearchQuery = "";

  @override
  void initState() {
    super.initState();
    _fetchLocations();
    _fetchSorters();
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Column(
            children: [
              const Text(
                'Location fetch failed!',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                e.toString(),
              ),
            ],
          ),
        ),
      );
      _locations = [];
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Column(
            children: [
              const Text(
                'Sorter fetch failed!',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                e.toString(),
              ),
            ],
          ),
        ),
      );
      _sorters = [];
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
        sortedLocations.sort((a, b) =>
            a['name'].toLowerCase().compareTo(b['name'].toLowerCase()));
        break;
      case 'nameDesc':
        sortedLocations.sort((a, b) =>
            b['name'].toLowerCase().compareTo(a['name'].toLowerCase()));
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
        sortedSorters.sort((a, b) =>
            a['name'].toLowerCase().compareTo(b['name'].toLowerCase()));
        break;
      case 'nameDesc':
        sortedSorters.sort((a, b) =>
            b['name'].toLowerCase().compareTo(a['name'].toLowerCase()));
        break;
      default:
        // Handle invalid sorter case if needed
        break;
    }
    return sortedSorters;
  }

  List<dynamic> filterLocations(List<dynamic> locations, String searchEntry) {
    final query = searchEntry.toLowerCase().trim();

    return locations.where((location) {
      final name = (location['name'] as String).toLowerCase();
      final tags = (location['tags'] as String).toLowerCase().split(',');

      return name.contains(query) || tags.any((tag) => tag.contains(query));
    }).toList();
  }

  List<dynamic> filterSorters(List<dynamic> sorters, String searchEntry) {
    final query = searchEntry.toLowerCase().trim();

    return sorters.where((sorter) {
      final name = (sorter['name'] as String).toLowerCase();
      final tags = (sorter['tags'] as String).toLowerCase().split(',');

      return name.contains(query) || tags.any((tag) => tag.contains(query));
    }).toList();
  }

  String? getLocationName(String locationId, List<dynamic> locations) {
    try {
      final location = locations.firstWhere(
        (location) => location['id'].toString() == locationId,
        orElse: () => null,
      );
      if (location != null) {
        return location['name']
            .toString(); // Assuming the location contains a 'name' field
      } else {
        throw Exception('Location not found');
      }
    } catch (e) {
      SchedulerBinding.instance.addPostFrameCallback(
        (timeStamp) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Theme.of(context).colorScheme.error,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Failed to load location!',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    e.toString(),
                  ),
                ],
              ),
            ),
          );
        },
      );

      return null;
    }
  }

  int getSortersCountInLocation(String locationId, List<dynamic> sorters) {
    return sorters.where((sorter) => sorter['location'] == locationId).length;
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
        return SingleChildScrollView(
          child: Column(
            children: [
              const Icon(
                Icons.home,
                size: 240,
              ),
              Text(
                "Locations in Inventory: ${_locations.length}",
                style: TextStyle(
                    fontSize: 24, color: Theme.of(context).colorScheme.primary),
              ),
              Text(
                "Sorters in Inventory: ${_sorters.length}",
                style: TextStyle(
                    fontSize: 24, color: Theme.of(context).colorScheme.primary),
              ),
              Text(
                "Items in Inventory: XXX",
                style: TextStyle(
                    fontSize: 26, color: Theme.of(context).colorScheme.primary),
              ),
            ],
          ),
        );
      case 1:
        return Stack(
          children: [
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: CustomSearchBar(
                        onChanged: (value) {
                          setState(() {
                            locationsSearchQuery = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(
                      width: 4.0,
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
                    const SizedBox(
                      width: 4.0,
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
                Expanded(
                  child: ListView.builder(
                    itemCount: filterLocations(_locations, locationsSearchQuery)
                        .length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LocationInfoPage(
                                  locationId: _sortLocations(
                                      filterLocations(
                                          _locations, locationsSearchQuery),
                                      locationsSortType)[index]['id'],
                                  locations: _locations,
                                  onDelete: () {
                                    _fetchLocations();
                                    _fetchSorters();
                                  },
                                  onModify: () {
                                    _fetchLocations();
                                    _fetchSorters();
                                  },
                                ),
                              ),
                            );
                          },
                          style: ButtonStyle(
                            shape: MaterialStateProperty.all<
                                RoundedRectangleBorder>(
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
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        _sortLocations(
                                            filterLocations(_locations,
                                                locationsSearchQuery),
                                            locationsSortType)[index]['name'],
                                        style: const TextStyle(
                                          fontSize: 18,
                                        ),
                                      ),
                                      Text(
                                        "Contains ${getSortersCountInLocation(_sortLocations(filterLocations(_locations, locationsSearchQuery), locationsSortType)[index]['id'], _sorters)} sorter"
                                        "${getSortersCountInLocation(_sortLocations(filterLocations(_locations, locationsSearchQuery), locationsSortType)[index]['id'], _sorters) == 1 ? '' : 's'}",
                                        style: const TextStyle(
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        _sortLocations(
                                            filterLocations(_locations,
                                                locationsSearchQuery),
                                            locationsSortType)[index]['id'],
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 4.0,
                                      ),
                                      _sortLocations(
                                                      filterLocations(_locations,
                                                          locationsSearchQuery),
                                                      locationsSortType)[index]
                                                  ['tags'] !=
                                              ""
                                          ? Wrap(
                                              direction: Axis.horizontal,
                                              spacing:
                                                  4.0, // Space between adjacent widgets
                                              runSpacing:
                                                  4.0, // Space between lines of widgets
                                              children: [
                                                for (var tag in _sortLocations(
                                                            filterLocations(
                                                                _locations,
                                                                locationsSearchQuery),
                                                            locationsSortType)[
                                                        index]['tags']
                                                    .split(','))
                                                  Chip(
                                                    label: Text(
                                                      tag,
                                                      style: const TextStyle(
                                                          fontSize: 11),
                                                    ),
                                                    materialTapTargetSize:
                                                        MaterialTapTargetSize
                                                            .shrinkWrap,
                                                    labelPadding:
                                                        EdgeInsets.zero,
                                                    visualDensity:
                                                        const VisualDensity(
                                                            horizontal: 0.0,
                                                            vertical: -4),
                                                  ),
                                              ],
                                            )
                                          : Text(
                                              "No Tags",
                                              style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onBackground),
                                            )
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
                const SizedBox(height: 88.0),
              ],
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: FloatingActionButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreateLocationPage(
                            onCreated: () {
                              setState(() {
                                _fetchLocations();
                              });
                            },
                          ),
                        ));
                  },
                  child: const Icon(Icons.add),
                ),
              ),
            )
          ],
        );
      case 2:
        return Stack(
          children: [
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: CustomSearchBar(
                        onChanged: (value) {
                          setState(() {
                            sorterSearchQuery = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(
                      width: 4.0,
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
                    const SizedBox(
                      width: 4.0,
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
                Expanded(
                  child: ListView.builder(
                    itemCount:
                        filterSorters(_sorters, sorterSearchQuery).length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SorterInfoPage(
                                  sorterId: _sortSorters(
                                      filterSorters(
                                          _sorters, sorterSearchQuery),
                                      sortersSortType)[index]['id'],
                                  locations: _locations,
                                  sorters: _sorters,
                                  onDelete: () {
                                    _fetchSorters();
                                    _fetchLocations();
                                  },
                                  onModify: () {
                                    _fetchSorters();
                                    _fetchLocations();
                                  },
                                ),
                              ),
                            );
                          },
                          style: ButtonStyle(
                            shape: MaterialStateProperty.all<
                                RoundedRectangleBorder>(
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
                                        "In: ${getLocationName(_sortSorters(filterSorters(_sorters, sorterSearchQuery), sortersSortType)[index]['location'], _locations) ?? 'LOCATION MISSING'}",
                                        style: const TextStyle(
                                          fontSize: 14,
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
                                      const SizedBox(
                                        height: 4.0,
                                      ),
                                      _sortSorters(
                                                      filterSorters(_sorters,
                                                          sorterSearchQuery),
                                                      sortersSortType)[index]
                                                  ['tags'] !=
                                              ""
                                          ? Wrap(
                                              direction: Axis.horizontal,
                                              spacing:
                                                  4.0, // Space between adjacent widgets
                                              runSpacing:
                                                  4.0, // Space between lines of widgets
                                              children: [
                                                for (var tag in _sortSorters(
                                                            filterSorters(_sorters,
                                                                sorterSearchQuery),
                                                            sortersSortType)[
                                                        index]['tags']
                                                    .split(','))
                                                  Chip(
                                                    label: Text(
                                                      tag,
                                                      style: const TextStyle(
                                                          fontSize: 11),
                                                    ),
                                                    materialTapTargetSize:
                                                        MaterialTapTargetSize
                                                            .shrinkWrap,
                                                    labelPadding:
                                                        EdgeInsets.zero,
                                                    visualDensity:
                                                        const VisualDensity(
                                                            horizontal: 0.0,
                                                            vertical: -4),
                                                  ),
                                              ],
                                            )
                                          : Text("No Tags",
                                              style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onBackground))
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
                const SizedBox(height: 88.0),
              ],
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: FloatingActionButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateSorterPage(
                          locations: _locations,
                          onCreated: () {
                            setState(() {
                              _fetchSorters();
                            });
                          },
                        ),
                      ),
                    );
                  },
                  child: const Icon(Icons.add),
                ),
              ),
            ),
          ],
        );
      default:
        return const Text('Default Area');
    }
  }
}
