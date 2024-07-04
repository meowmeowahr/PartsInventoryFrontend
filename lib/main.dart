import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:flutter/services.dart';
import 'package:material_tag_editor/tag_editor.dart';

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
                Icons.home_filled,
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
                      child: SearchBar(
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
                      child: SearchBar(
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

class SearchBar extends StatelessWidget {
  final Function(String) onChanged;

  const SearchBar({required this.onChanged, super.key});

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

class CreateSorterPage extends StatefulWidget {
  const CreateSorterPage({
    super.key,
    required this.locations,
    required this.onCreated,
  });

  final List<dynamic> locations;
  final Function onCreated;

  @override
  CreateSorterPageState createState() => CreateSorterPageState();
}

class CreateSorterPageState extends State<CreateSorterPage> {
  String sorterName = "";
  bool autoGenerateId = true;
  String uniqueId = '';
  String? selectedLocation;
  List<String> values = [];

  late TextEditingController _uniqueIdController;

  void _onTagDetete(int index) {
    setState(() {
      values.removeAt(index);
    });
  }

  @override
  void initState() {
    super.initState();
    uniqueId = const Uuid().v4(); // Initial unique ID
    _uniqueIdController = TextEditingController(text: uniqueId);
  }

  @override
  void dispose() {
    _uniqueIdController.dispose();
    super.dispose();
  }

  List<DropdownMenuItem<String>> buildLocationDropdownItems(
      List<dynamic> locations) {
    return locations.map<DropdownMenuItem<String>>((location) {
      return DropdownMenuItem<String>(
        value: location['id'].toString(),
        child: Text(location['name'].toString()),
      );
    }).toList();
  }

  String? getUniqueIdValidationError() {
    if (uniqueId.isEmpty) {
      return "Value can't be empty";
    }

    RegExp regex = RegExp(r'[^\w-]');
    if (regex.hasMatch(uniqueId)) {
      return "Special characters are not allowed";
    }
    return null;
  }

  Future<void> _createSorter() async {
    final url = Uri.parse(
        'http://localhost:8000/sorters/'); // Replace with your API endpoint
    try {
      final response = await http.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'name': sorterName,
          'id': uniqueId,
          'location': selectedLocation,
          'icon': 'blank',
          'tags': values.join(","),
          'attrs': {}
        }),
      );
      if (response.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sorter created successfully!'),
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pop();
        widget.onCreated();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Theme.of(context).colorScheme.error,
            content: Column(
              children: [
                const Text(
                  'Sorter creation failed!',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(response.body),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Column(
            children: [
              const Text(
                'Sorter creation failed!',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(e.toString()),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Sorter"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TextField(
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'Name for Sorter',
                errorText: sorterName.isEmpty ? "Value can't be empty" : null,
              ),
              onChanged: (value) {
                setState(() {
                  sorterName = value;
                });
              },
            ),
            const SizedBox(height: 8.0),
            Row(
              children: [
                Checkbox(
                  value: autoGenerateId,
                  onChanged: (value) {
                    setState(() {
                      autoGenerateId = value ?? false;
                      if (autoGenerateId) {
                        uniqueId = const Uuid().v4(); // Auto-generate unique ID
                        _uniqueIdController.text = uniqueId;
                      }
                    });
                  },
                ),
                const Text('Auto Generate Unique ID'),
              ],
            ),
            TextField(
              enabled: !autoGenerateId,
              controller: _uniqueIdController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'Unique ID for sorter',
                errorText: getUniqueIdValidationError(),
              ),
              onChanged: (value) {
                setState(() {
                  uniqueId = value;
                });
              },
            ),
            const SizedBox(height: 8.0),
            DropdownButtonFormField<String>(
              value: selectedLocation,
              onChanged: (value) {
                setState(() {
                  selectedLocation = value;
                });
              },
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'Select Location',
                errorText:
                    selectedLocation == null ? "Value can't be empty" : null,
              ),
              items: buildLocationDropdownItems(widget.locations),
            ),
            const SizedBox(height: 8.0),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(4.0),
              ),
              padding: const EdgeInsets.only(left: 8.0, right: 8.0),
              child: TagEditor(
                length: values.length,
                delimiters: const [',', ' ', ';'],
                hasAddButton: false,
                inputDecoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Add tags here...',
                ),
                onTagChanged: (newValue) {
                  setState(() {
                    values.add(newValue);
                  });
                },
                tagBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(top: 7.0),
                  child: Chip(
                    label: Text(values[index]),
                    onDeleted: () {
                      _onTagDetete(index);
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8.0),
            ElevatedButton(
              onPressed: () {
                _createSorter(); // Call function to create sorter
              },
              child: const Text('Create Sorter'),
            ),
          ],
        ),
      ),
    );
  }
}

class CreateLocationPage extends StatefulWidget {
  const CreateLocationPage({
    super.key,
    required this.onCreated,
  });

  final Function onCreated;

  @override
  CreateLocationPageState createState() => CreateLocationPageState();
}

class CreateLocationPageState extends State<CreateLocationPage> {
  String locationName = "";
  bool autoGenerateId = true;
  String uniqueId = '';
  String? selectedLocation;
  List<String> values = [];

  late TextEditingController _uniqueIdController;

  void _onTagDetete(int index) {
    setState(() {
      values.removeAt(index);
    });
  }

  @override
  void initState() {
    super.initState();
    uniqueId = const Uuid().v4(); // Initial unique ID
    _uniqueIdController = TextEditingController(text: uniqueId);
  }

  @override
  void dispose() {
    _uniqueIdController.dispose();
    super.dispose();
  }

  List<DropdownMenuItem<String>> buildLocationDropdownItems(
      List<dynamic> locations) {
    return locations.map<DropdownMenuItem<String>>((location) {
      return DropdownMenuItem<String>(
        value: location['id'].toString(),
        child: Text(location['name'].toString()),
      );
    }).toList();
  }

  String? getUniqueIdValidationError() {
    if (uniqueId.isEmpty) {
      return "Value can't be empty";
    }

    RegExp regex = RegExp(r'[^\w-]');
    if (regex.hasMatch(uniqueId)) {
      return "Special characters are not allowed";
    }
    return null;
  }

  Future<void> _createLocation() async {
    final url = Uri.parse(
        'http://localhost:8000/locations/'); // Replace with your API endpoint
    try {
      final response = await http.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'name': locationName,
          'id': uniqueId,
          'icon': 'blank',
          'tags': values.join(","),
          'attrs': {}
        }),
      );
      if (response.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location created successfully!'),
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pop();
        widget.onCreated();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Theme.of(context).colorScheme.error,
            content: Column(
              children: [
                const Text(
                  'Location creation failed!',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(response.body),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Column(
            children: [
              const Text(
                'Location creation failed!',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(e.toString()),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Location"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TextField(
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'Name for Location',
                errorText: locationName.isEmpty ? "Value can't be empty" : null,
              ),
              onChanged: (value) {
                setState(() {
                  locationName = value;
                });
              },
            ),
            const SizedBox(height: 8.0),
            Row(
              children: [
                Checkbox(
                  value: autoGenerateId,
                  onChanged: (value) {
                    setState(() {
                      autoGenerateId = value ?? false;
                      if (autoGenerateId) {
                        uniqueId = const Uuid().v4(); // Auto-generate unique ID
                        _uniqueIdController.text = uniqueId;
                      }
                    });
                  },
                ),
                const Text('Auto Generate Unique ID'),
              ],
            ),
            TextField(
              enabled: !autoGenerateId,
              controller: _uniqueIdController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'Unique ID for location',
                errorText: getUniqueIdValidationError(),
              ),
              onChanged: (value) {
                setState(() {
                  uniqueId = value;
                });
              },
            ),
            const SizedBox(height: 8.0),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(4.0),
              ),
              padding: const EdgeInsets.only(left: 8.0, right: 8.0),
              child: TagEditor(
                length: values.length,
                delimiters: const [',', ' ', ';'],
                hasAddButton: false,
                inputDecoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Add tags here...',
                ),
                onTagChanged: (newValue) {
                  setState(() {
                    values.add(newValue);
                  });
                },
                tagBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(top: 7.0),
                  child: Chip(
                    label: Text(values[index]),
                    onDeleted: () {
                      _onTagDetete(index);
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8.0),
            ElevatedButton(
              onPressed: () {
                _createLocation();
              },
              child: const Text('Create Location'),
            ),
          ],
        ),
      ),
    );
  }
}

class SorterInfoPage extends StatefulWidget {
  final String sorterId;
  final List<dynamic> locations;

  final Function onDelete;
  final Function onModify;

  const SorterInfoPage({
    super.key,
    required this.sorterId,
    required this.locations,
    required this.onDelete,
    required this.onModify,
  });

  @override
  SorterInfoPageState createState() => SorterInfoPageState();
}

class SorterInfoPageState extends State<SorterInfoPage> {
  late Future<Map<String, dynamic>> _sorterInfo;

  String _pageTitle = "Sorter Information";
  String? sorterName;
  String? sorterId;
  String? sorterLocation;
  String? sorterLocationName;
  List<String>? sorterTags;

  @override
  void initState() {
    super.initState();
    _sorterInfo = _fetchSorterInfo();
  }

  Future<Map<String, dynamic>> _fetchSorterInfo() async {
    final url = Uri.parse('http://localhost:8000/sorters/${widget.sorterId}');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _pageTitle = data["name"];
        sorterName = data["name"];
        sorterId = data["id"];
        sorterLocation = data["location"];
        sorterTags = data["tags"].split(",");
      });
      sorterLocationName = getLocationName(sorterLocation!, widget.locations);
      return data;
    } else {
      throw Exception('Failed to load sorter information');
    }
  }

  Future<void> deleteSorter(String sorterId) async {
    final url = Uri.parse(
        'http://localhost:8000/sorters/$sorterId'); // Replace with your API endpoint

    try {
      final response = await http.delete(url);
      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sorter deleted successfully!'),
          ),
        );
        widget.onDelete();
        Navigator.of(context).pop();
      } else {
        throw Exception('Failed to delete sorter');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Column(
            children: [
              const Text(
                'Sorter delete failed!',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                e.toString(),
              ),
            ],
          ),
        ),
      );
    }
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
      return null;
    }
  }

  Future<Object> _showDeleteConfirmation(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Sorter'),
          content: const Text(
              'Are you sure you want to delete this sorter? Parts will not be deleted, but be left as orphaned parts. To resolve that, delete them or create a new sorter with the same unique id is the one being deleted.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(context).pop(true);
                deleteSorter(sorterId!);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoPane() {
    return Column(
      children: [
        Icon(
          Icons.inventory_2_rounded,
          size: 240,
          color: Theme.of(context).colorScheme.primary,
        ),
        Text(
          "Located in: $sorterLocationName",
          style: const TextStyle(fontSize: 24),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                "ID: $sorterId",
                softWrap: true,
              ),
            ),
            const SizedBox(width: 4.0),
            IconButton(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: sorterId!))
                      .then((_) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(content: Text('Copied!')));
                  });
                  // copied successfully
                },
                icon: const Icon(Icons.copy, size: 18))
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Tags:"),
            const SizedBox(width: 4.0),
            sorterTags?.firstOrNull != ""
                ? Flexible(
                    child: Wrap(
                      spacing: 4.0,
                      runSpacing: 4.0,
                      children: [
                        for (var tag in sorterTags ?? [])
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
                          )
                      ],
                    ),
                  )
                : const Text("No Tags")
          ],
        ),
      ],
    );
  }

  Widget _buildPartsPane() {
    return const Placeholder();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitle),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FutureBuilder<Map<String, dynamic>>(
                    future: _sorterInfo,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasData) {
                        return ModifySorterPage(
                            sorter: snapshot.data!,
                            locations: widget.locations,
                            onModified: () {
                              widget.onModify();
                              Navigator.of(context).pop();
                            });
                      } else {
                        return Text('Error: ${snapshot.error}');
                      }
                    },
                  ),
                ),
              );
            },
            icon: const Icon(
              Icons.edit,
            ),
          ),
          IconButton(
            onPressed: () {
              _showDeleteConfirmation(context);
            },
            icon: const Icon(
              Icons.delete_forever,
              color: Colors.red,
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _sorterInfo,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else if (snapshot.hasData) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 600) {
                    // Two-column layout for larger screens
                    return Row(
                      children: [
                        Expanded(
                          child: _buildInfoPane(),
                        ),
                        Expanded(
                          child: ListView(
                            children: [_buildPartsPane()],
                          ),
                        ),
                      ],
                    );
                  } else {
                    // One-column layout for smaller screens
                    return ListView(
                      children: [
                        _buildInfoPane(),
                        const SizedBox(
                          height: 8.0,
                        ),
                        _buildPartsPane()
                      ],
                    );
                  }
                },
              );
            } else {
              return const Text('No data');
            }
          },
        ),
      ),
    );
  }
}

class ModifySorterPage extends StatefulWidget {
  const ModifySorterPage({
    super.key,
    required this.sorter,
    required this.locations,
    required this.onModified,
  });

  final Map<String, dynamic> sorter;
  final List<dynamic> locations;
  final Function onModified;

  @override
  ModifySorterPageState createState() => ModifySorterPageState();
}

class ModifySorterPageState extends State<ModifySorterPage> {
  late String uniqueId;
  String? selectedLocation;
  List<String> values = [];

  late TextEditingController _sorterNameController;

  void _onTagDetete(int index) {
    setState(() {
      values.removeAt(index);
    });
  }

  @override
  void initState() {
    super.initState();
    uniqueId = widget.sorter['id'];
    selectedLocation = widget.sorter['location'];
    values = widget.sorter['tags'].split(',');

    _sorterNameController = TextEditingController(text: widget.sorter['name']);
  }

  @override
  void dispose() {
    super.dispose();
  }

  List<DropdownMenuItem<String>> buildLocationDropdownItems(
      List<dynamic> locations) {
    return locations.map<DropdownMenuItem<String>>((location) {
      return DropdownMenuItem<String>(
        value: location['id'].toString(),
        child: Text(location['name'].toString()),
      );
    }).toList();
  }

  String? getUniqueIdValidationError() {
    if (uniqueId.isEmpty) {
      return "Value can't be empty";
    }

    RegExp regex = RegExp(r'[^\w-]');
    if (regex.hasMatch(uniqueId)) {
      return "Special characters are not allowed";
    }
    return null;
  }

  Future<void> _modifySorter() async {
    final url = Uri.parse(
        'http://localhost:8000/sorters/$uniqueId'); // Replace with your API endpoint
    try {
      final response = await http.put(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'name': _sorterNameController.text,
          'id': uniqueId,
          'location': selectedLocation,
          'icon': 'blank',
          'tags': values.join(","),
          'attrs': {}
        }),
      );
      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sorter modified successfully!'),
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pop();
        widget.onModified();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Theme.of(context).colorScheme.error,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sorter modification failed!',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(response.body),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sorter modification failed!',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(e.toString()),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Modify Sorter"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: [
            ValueListenableBuilder(
                // Note: pass _controller to the animation argument
                valueListenable: _sorterNameController,
                builder: (context, TextEditingValue value, __) {
                  return TextField(
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: 'Name for Sorter',
                      errorText: _sorterNameController.text.isEmpty
                          ? "Value can't be empty"
                          : null,
                    ),
                    controller: _sorterNameController,
                  );
                }),
            const SizedBox(height: 8.0),
            DropdownButtonFormField<String>(
              value: widget.locations
                      .any((location) => location['id'] == selectedLocation)
                  ? selectedLocation
                  : null,
              onChanged: (value) {
                setState(() {
                  selectedLocation = value;
                });
              },
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'Select Location',
                errorText:
                    selectedLocation == null ? "Value can't be empty" : null,
              ),
              items: buildLocationDropdownItems(widget.locations),
            ),
            const SizedBox(height: 8.0),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(4.0),
              ),
              padding: const EdgeInsets.only(left: 8.0, right: 8.0),
              child: TagEditor(
                length: values.length,
                delimiters: const [',', ' ', ';'],
                hasAddButton: false,
                inputDecoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Add tags here...',
                ),
                onTagChanged: (newValue) {
                  setState(() {
                    values.add(newValue);
                  });
                },
                tagBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(top: 7.0),
                  child: Chip(
                    label: Text(values[index]),
                    onDeleted: () {
                      _onTagDetete(index);
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8.0),
            ElevatedButton(
              onPressed: () {
                _modifySorter(); // Call function to modify sorter
              },
              child: const Text('Modify Sorter'),
            ),
          ],
        ),
      ),
    );
  }
}

class LocationInfoPage extends StatefulWidget {
  final String locationId;
  final List<dynamic> locations;

  final Function onDelete;
  final Function onModify;

  const LocationInfoPage({
    super.key,
    required this.locationId,
    required this.onDelete,
    required this.onModify,
    required this.locations,
  });

  @override
  LocationInfoPageState createState() => LocationInfoPageState();
}

class LocationInfoPageState extends State<LocationInfoPage> {
  late Future<Map<String, dynamic>> _locationInfo;

  String _pageTitle = "Location Information";
  String? locationName;
  String? locationId;
  List<String>? locationTags;

  List<dynamic> _sorters = [];
  String sorterSearchQuery = "";
  String sortersSortType = "creationTimeDesc";

  @override
  void initState() {
    super.initState();
    _locationInfo = _fetchLocationInfo();
    _fetchSorters();
  }

  Future<Map<String, dynamic>> _fetchLocationInfo() async {
    final url =
        Uri.parse('http://localhost:8000/locations/${widget.locationId}');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _pageTitle = data["name"];
        locationName = data["name"];
        locationId = data["id"];
        locationTags = data["tags"].split(",");
      });
      return data;
    } else {
      throw Exception('Failed to load location information');
    }
  }

  Future<void> deleteLocation(String locationId) async {
    final url = Uri.parse(
        'http://localhost:8000/locations/$locationId'); // Replace with your API endpoint

    try {
      final response = await http.delete(url);
      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location deleted successfully!'),
          ),
        );
        widget.onDelete();
        Navigator.of(context).pop();
      } else {
        throw Exception('Failed to delete location');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Column(
            children: [
              const Text(
                'Location delete failed!',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                e.toString(),
              ),
            ],
          ),
        ),
      );
    }
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
      return null;
    }
  }

  Future<Object> _showDeleteConfirmation(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Location'),
          content: const Text(
              'Are you sure you want to delete this location? Deleting a location that is in use will create errors when viewing all sorters. This will not prevent you from browsing or changing the location of sorters, however advanced filtering may not work.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(context).pop(true);
                deleteLocation(locationId!);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoPane() {
    return Column(
      children: [
        Icon(
          Icons.room_rounded,
          size: 240,
          color: Theme.of(context).colorScheme.primary,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                "ID: $locationId",
                softWrap: true,
              ),
            ),
            const SizedBox(width: 4.0),
            IconButton(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: locationId!))
                      .then((_) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(content: Text('Copied!')));
                  });
                  // copied successfully
                },
                icon: const Icon(Icons.copy, size: 18))
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Tags:"),
            const SizedBox(width: 4.0),
            locationTags?.firstOrNull != ""
                ? Flexible(
                    child: Wrap(
                      spacing: 4.0,
                      runSpacing: 4.0,
                      children: [
                        for (var tag in locationTags ?? [])
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
                          )
                      ],
                    ),
                  )
                : const Text("No Tags")
          ],
        ),
      ],
    );
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

  List<dynamic> filterSorters(List<dynamic> sorters, String searchEntry) {
    final query = searchEntry.toLowerCase().trim();

    return sorters.where((sorter) {
      final name = (sorter['name'] as String).toLowerCase();
      final tags = (sorter['tags'] as String).toLowerCase().split(',');

      return name.contains(query) || tags.any((tag) => tag.contains(query));
    }).toList();
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

  List<dynamic> filterSortersByLocationId(
      String locationId, List<dynamic> sorters) {
    return sorters.where((sorter) => sorter['location'] == locationId).toList();
  }

  Widget _buildSortersPane() {
    return Expanded(
      child: ListView.builder(
        itemCount: filterSorters(
                filterSortersByLocationId(locationId!, _sorters),
                sorterSearchQuery)
            .length,
        shrinkWrap: true,
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
                              filterSortersByLocationId(locationId!, _sorters),
                              sorterSearchQuery),
                          sortersSortType)[index]['id'],
                      locations: widget.locations,
                      onDelete: () {
                        _fetchSorters();
                        Navigator.of(context).pop();
                        widget.onModify();
                      },
                      onModify: () {
                        _fetchSorters();
                        Navigator.of(context).pop();
                        widget.onModify();
                      },
                    ),
                  ),
                );
              },
              style: ButtonStyle(
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
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
                                    filterSortersByLocationId(
                                        locationId!, _sorters),
                                    sorterSearchQuery),
                                sortersSortType)[index]['name'],
                            style: const TextStyle(
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            _sortSorters(
                                filterSorters(
                                    filterSortersByLocationId(
                                        locationId!, _sorters),
                                    sorterSearchQuery),
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
                                      filterSorters(
                                          filterSortersByLocationId(
                                              locationId!, _sorters),
                                          sorterSearchQuery),
                                      sortersSortType)[index]['tags'] !=
                                  ""
                              ? Wrap(
                                  direction: Axis.horizontal,
                                  spacing:
                                      4.0, // Space between adjacent widgets
                                  runSpacing:
                                      4.0, // Space between lines of widgets
                                  children: [
                                    for (var tag in _sortSorters(
                                            filterSorters(
                                                filterSortersByLocationId(
                                                    locationId!, _sorters),
                                                sorterSearchQuery),
                                            sortersSortType)[index]['tags']
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitle),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FutureBuilder<Map<String, dynamic>>(
                    future: _locationInfo,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasData) {
                        return ModifyLocationPage(
                            location: snapshot.data!,
                            onModified: () {
                              widget.onModify();
                              Navigator.of(context).pop();
                            });
                      } else {
                        return Text('Error: ${snapshot.error}');
                      }
                    },
                  ),
                ),
              );
            },
            icon: const Icon(
              Icons.edit,
            ),
          ),
          IconButton(
            onPressed: () {
              _showDeleteConfirmation(context);
            },
            icon: const Icon(
              Icons.delete_forever,
              color: Colors.red,
            ),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _locationInfo,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else if (snapshot.hasData) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 600) {
                    // Two-column layout for larger screens
                    return Row(
                      children: [
                        Expanded(
                          child: _buildInfoPane(),
                        ),
                        Expanded(
                          child: _buildSortersPane(),
                        ),
                      ],
                    );
                  } else {
                    // One-column layout for smaller screens
                    return Column(
                      children: [
                        _buildInfoPane(),
                        const SizedBox(
                          height: 8.0,
                        ),
                        _buildSortersPane()
                      ],
                    );
                  }
                },
              );
            } else {
              return const Text('No data');
            }
          },
        ),
      ),
    );
  }
}

class ModifyLocationPage extends StatefulWidget {
  const ModifyLocationPage({
    super.key,
    required this.location,
    required this.onModified,
  });

  final Map<String, dynamic> location;
  final Function onModified;

  @override
  ModifyLocationPageState createState() => ModifyLocationPageState();
}

class ModifyLocationPageState extends State<ModifyLocationPage> {
  late String uniqueId;
  String? selectedLocation;
  List<String> values = [];

  late TextEditingController _locationNameController;

  void _onTagDetete(int index) {
    setState(() {
      values.removeAt(index);
    });
  }

  @override
  void initState() {
    super.initState();
    uniqueId = widget.location['id'];
    selectedLocation = widget.location['location'];
    values = widget.location['tags'].split(',');

    _locationNameController =
        TextEditingController(text: widget.location['name']);
  }

  @override
  void dispose() {
    super.dispose();
  }

  List<DropdownMenuItem<String>> buildLocationDropdownItems(
      List<dynamic> locations) {
    return locations.map<DropdownMenuItem<String>>((location) {
      return DropdownMenuItem<String>(
        value: location['id'].toString(),
        child: Text(location['name'].toString()),
      );
    }).toList();
  }

  String? getUniqueIdValidationError() {
    if (uniqueId.isEmpty) {
      return "Value can't be empty";
    }

    RegExp regex = RegExp(r'[^\w-]');
    if (regex.hasMatch(uniqueId)) {
      return "Special characters are not allowed";
    }
    return null;
  }

  Future<void> _modifyLocation() async {
    final url = Uri.parse(
        'http://localhost:8000/locations/$uniqueId'); // Replace with your API endpoint
    try {
      final response = await http.put(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'name': _locationNameController.text,
          'id': uniqueId,
          'location': selectedLocation,
          'icon': 'blank',
          'tags': values.join(","),
          'attrs': {}
        }),
      );
      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location modified successfully!'),
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pop();
        widget.onModified();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Theme.of(context).colorScheme.error,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Location modification failed!',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(response.body),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Location modification failed!',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(e.toString()),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Modify Location"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: [
            ValueListenableBuilder(
                valueListenable: _locationNameController,
                builder: (context, TextEditingValue value, __) {
                  return TextField(
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: 'Name for Location',
                      errorText: _locationNameController.text.isEmpty
                          ? "Value can't be empty"
                          : null,
                    ),
                    controller: _locationNameController,
                  );
                }),
            const SizedBox(height: 8.0),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(4.0),
              ),
              padding: const EdgeInsets.only(left: 8.0, right: 8.0),
              child: TagEditor(
                length: values.length,
                delimiters: const [',', ' ', ';'],
                hasAddButton: false,
                inputDecoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Add tags here...',
                ),
                onTagChanged: (newValue) {
                  setState(() {
                    values.add(newValue);
                  });
                },
                tagBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(top: 7.0),
                  child: Chip(
                    label: Text(values[index]),
                    onDeleted: () {
                      _onTagDetete(index);
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8.0),
            ElevatedButton(
              onPressed: () {
                _modifyLocation(); // Call function to modify location
              },
              child: const Text('Modify Location'),
            ),
          ],
        ),
      ),
    );
  }
}
