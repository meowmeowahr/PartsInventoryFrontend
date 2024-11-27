import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_tag_editor/tag_editor.dart';
import 'package:responsive_grid/responsive_grid.dart';

import 'sorters.dart';
import 'widgets.dart';

class CreateLocationPage extends StatefulWidget {
  const CreateLocationPage({
    super.key,
    required this.apiBaseAddress,
    required this.onCreated,
  });

  final Function onCreated;
  final String apiBaseAddress;

  @override
  CreateLocationPageState createState() => CreateLocationPageState();
}

class CreateLocationPageState extends State<CreateLocationPage> {
  String locationName = "";
  bool autoGenerateId = true;
  String uniqueId = '';
  String? selectedLocation;
  List<String> locationTags = [];

  late TextEditingController _uniqueIdController;

  void _onTagDetete(int index) {
    setState(() {
      locationTags.removeAt(index);
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
    final url = Uri.parse(p.join(
        widget.apiBaseAddress, "locations/")); // Replace with your API endpoint
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
          'tags': locationTags.join(","),
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
                length: locationTags.length,
                delimiters: const [',', ' ', ';'],
                hasAddButton: false,
                inputDecoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Add tags here...',
                ),
                onTagChanged: (newValue) {
                  setState(() {
                    locationTags.add(newValue);
                  });
                },
                tagBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(top: 7.0, bottom: 3.5),
                  child: Chip(
                    label: Text(locationTags[index]),
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

class LocationInfoPage extends StatefulWidget {
  final String apiBaseAddress;

  final String locationId;
  final List<dynamic> locations;

  final Function onDelete;
  final Function onModify;

  const LocationInfoPage({
    super.key,
    required this.apiBaseAddress,
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
    final url = Uri.parse(
        p.join(widget.apiBaseAddress, "locations/${widget.locationId}"));
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _pageTitle = data["name"];
        locationName = data["name"];
        locationId = data["id"];
        locationTags = data["tags"].split(",");
        locationTags?.remove("");
      });
      return data;
    } else {
      throw Exception('Failed to load location information');
    }
  }

  Future<void> deleteLocation(String locationId) async {
    final url = Uri.parse(p.join(widget.apiBaseAddress,
        "locations/$locationId")); // Replace with your API endpoint

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
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 4.0),
            IconButton(
              onPressed: () async {
                // Capture the ScaffoldMessengerState before the async operation
                final messenger = ScaffoldMessenger.of(context);

                await Clipboard.setData(ClipboardData(text: locationId!));

                // Use the messenger directly, avoiding BuildContext issues
                messenger.showSnackBar(
                  const SnackBar(content: Text('Copied!')),
                );
              },
              icon: const Icon(Icons.copy, size: 18),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Tags:"),
            const SizedBox(width: 4.0),
            (locationTags?.firstOrNull ?? "") != ""
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
    final url = Uri.parse(p.join(
        widget.apiBaseAddress, "sorters")); // Replace with your API endpoint
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
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
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
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
        ),
        ResponsiveStaggeredGridList(
          desiredItemWidth: 320,
          children: List.generate(
              filterSorters(filterSortersByLocationId(locationId!, _sorters),
                      sorterSearchQuery)
                  .length, (index) {
            return Padding(
              padding: const EdgeInsets.all(4.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      barrierDismissible: true,
                      builder: (context) => SorterInfoPage(
                        apiBaseAddress: widget.apiBaseAddress,
                        sorterId: _sortSorters(
                            filterSorters(
                                filterSortersByLocationId(
                                    locationId!, _sorters),
                                sorterSearchQuery),
                            sortersSortType)[index]['id'],
                        locations: widget.locations,
                        sorters: _sorters,
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
                  shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Icon(
                        iconMap[_sortSorters(
                                    filterSorters(
                                        filterSortersByLocationId(
                                            locationId!, _sorters),
                                        sorterSearchQuery),
                                    sortersSortType)[index]['icon']]
                                ?.data ??
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
                              textAlign: TextAlign.end,
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
                                  )
                                : Text("No Tags",
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface))
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
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
                  barrierDismissible: true,
                  builder: (context) => FutureBuilder<Map<String, dynamic>>(
                    future: _locationInfo,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasData) {
                        return ModifyLocationPage(
                            apiBaseAddress: widget.apiBaseAddress,
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
                    return Flex(
                      direction: Axis.horizontal,
                      children: [
                        Flexible(
                          flex: 1,
                          child: _buildInfoPane(),
                        ),
                        Flexible(
                          flex: 2,
                          child: _buildSortersPane(),
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
    required this.apiBaseAddress,
    required this.location,
    required this.onModified,
  });

  final String apiBaseAddress;

  final Map<String, dynamic> location;
  final Function onModified;

  @override
  ModifyLocationPageState createState() => ModifyLocationPageState();
}

class ModifyLocationPageState extends State<ModifyLocationPage> {
  late String uniqueId;
  String? selectedLocation;
  List<String> locationTags = [];

  late TextEditingController _locationNameController;

  void _onTagDetete(int index) {
    setState(() {
      locationTags.removeAt(index);
    });
  }

  @override
  void initState() {
    super.initState();
    uniqueId = widget.location['id'];
    selectedLocation = widget.location['location'];
    locationTags = widget.location['tags'].split(',');
    locationTags.remove("");

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
    final url = Uri.parse(p.join(widget.apiBaseAddress, "locations/$uniqueId"));
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
          'tags': locationTags.join(","),
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
                length: locationTags.length,
                delimiters: const [',', ' ', ';'],
                hasAddButton: false,
                inputDecoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Add tags here...',
                ),
                onTagChanged: (newValue) {
                  setState(() {
                    locationTags.add(newValue);
                  });
                },
                tagBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(top: 7.0, bottom: 3.5),
                  child: Chip(
                    label: Text(locationTags[index]),
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
