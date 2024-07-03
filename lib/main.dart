import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
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
                          onPressed: () {},
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
                                                      locationsSortType)[index]
                                                  ['tags']
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
                                              labelPadding: EdgeInsets.zero,
                                              visualDensity:
                                                  const VisualDensity(
                                                      horizontal: 0.0,
                                                      vertical: -4),
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
                          onPressed: () {},
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
                                      Wrap(
                                        direction: Axis.horizontal,
                                        spacing:
                                            4.0, // Space between adjacent widgets
                                        runSpacing:
                                            4.0, // Space between lines of widgets
                                        children: [
                                          for (var tag in _sortSorters(
                                                      filterSorters(_sorters,
                                                          sorterSearchQuery),
                                                      sortersSortType)[index]
                                                  ['tags']
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
                                              labelPadding: EdgeInsets.zero,
                                              visualDensity:
                                                  const VisualDensity(
                                                      horizontal: 0.0,
                                                      vertical: -4),
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
                const SizedBox(height: 88.0),
              ],
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: FloatingActionButton(
                  onPressed: () {
                    onPressed:
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
                        ));
                  },
                  child: const Icon(Icons.add),
                ),
              ),
            )
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
    Key? key,
    required this.locations,
    required this.onCreated,
  }) : super(key: key);

  final List<dynamic> locations;
  final Function onCreated;

  @override
  _CreateSorterPageState createState() => _CreateSorterPageState();
}

class _CreateSorterPageState extends State<CreateSorterPage> {
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
    uniqueId = Uuid().v4(); // Initial unique ID
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
                        uniqueId = Uuid().v4(); // Auto-generate unique ID
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
    Key? key,
    required this.onCreated,
  }) : super(key: key);

  final Function onCreated;

  @override
  _CreateLocationPageState createState() => _CreateLocationPageState();
}

class _CreateLocationPageState extends State<CreateLocationPage> {
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
    uniqueId = Uuid().v4(); // Initial unique ID
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
                        uniqueId = Uuid().v4(); // Auto-generate unique ID
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
