import 'dart:convert';

import 'package:flutter_iconpicker/Models/configuration.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:responsive_grid/responsive_grid.dart';
import 'package:uuid/uuid.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_tag_editor/tag_editor.dart';
import 'package:flutter_iconpicker/flutter_iconpicker.dart';

import 'parts.dart';
import 'widgets.dart';

Map<String, IconPickerIcon> iconMap = {
  "blank": IconPickerIcon(
      name: "blank", data: Icons.inventory_2_rounded, pack: IconPack.custom),
  "spaces": IconPickerIcon(
      name: "space", data: Icons.space_dashboard, pack: IconPack.custom),
  "computer": IconPickerIcon(
      name: "computer", data: Icons.computer_rounded, pack: IconPack.custom),
  "bolt": IconPickerIcon(
      name: "bolt", data: Icons.bolt_rounded, pack: IconPack.custom),
  "light": IconPickerIcon(
      name: "light", data: Icons.lightbulb_rounded, pack: IconPack.custom),
  "cable": IconPickerIcon(
      name: "cable", data: Icons.cable_rounded, pack: IconPack.custom),
  "sensors": IconPickerIcon(
      name: "sensors", data: Icons.sensors_rounded, pack: IconPack.custom),
  "build": IconPickerIcon(
      name: "build", data: Icons.build_rounded, pack: IconPack.custom),
  "hardware": IconPickerIcon(
      name: "hardware", data: Icons.hardware_rounded, pack: IconPack.custom),
  "construction": IconPickerIcon(
      name: "construction",
      data: Icons.construction_rounded,
      pack: IconPack.custom),
  "dashboard": IconPickerIcon(
      name: "dashboard", data: Icons.dashboard_rounded, pack: IconPack.custom),
  "svideo": IconPickerIcon(
      name: "svideo",
      data: Icons.settings_input_svideo_rounded,
      pack: IconPack.custom),
  "hdmi": IconPickerIcon(
      name: "hdmi",
      data: Icons.settings_input_hdmi_rounded,
      pack: IconPack.custom),
  "composite": IconPickerIcon(
      name: "composite",
      data: Icons.settings_input_composite_rounded,
      pack: IconPack.custom),
  "antenna": IconPickerIcon(
      name: "antenna",
      data: Icons.settings_input_antenna_rounded,
      pack: IconPack.custom),
  "robot": IconPickerIcon(
      name: "robot", data: Icons.smart_toy_rounded, pack: IconPack.custom),
  "chip": IconPickerIcon(
      name: "chip", data: Icons.memory_rounded, pack: IconPack.custom),
  "devboard": IconPickerIcon(
      name: "devboard",
      data: Icons.developer_board_rounded,
      pack: IconPack.custom),
};

Uint8List resizeImage(Uint8List imageBytes, int maxWidth, int maxHeight) {
  // Decode the image from Uint8List
  img.Image? originalImage = img.decodeImage(imageBytes);

  if (originalImage == null) {
    throw Exception('Failed to decode image.');
  }

  // Calculate the aspect ratio
  double aspectRatio = originalImage.width / originalImage.height;

  // Determine the target width and height based on the max constraints
  int targetWidth = originalImage.width;
  int targetHeight = originalImage.height;

  if (targetWidth > maxWidth || targetHeight > maxHeight) {
    if (aspectRatio > 1) {
      // Wider than tall, constrain by maxWidth
      targetWidth = maxWidth;
      targetHeight = (maxWidth / aspectRatio).round();
    } else {
      // Taller than wide, constrain by maxHeight
      targetHeight = maxHeight;
      targetWidth = (maxHeight * aspectRatio).round();
    }
  }

  // Resize the image
  img.Image resizedImage =
      img.copyResize(originalImage, width: targetWidth, height: targetHeight);

  // Convert the resized image back to Uint8List
  Uint8List resizedBytes = Uint8List.fromList(img.encodeJpg(resizedImage));

  return resizedBytes;
}

class CreateSorterPage extends StatefulWidget {
  const CreateSorterPage({
    super.key,
    required this.apiBaseAddress,
    required this.locations,
    required this.onCreated,
  });

  final String apiBaseAddress;

  final List<dynamic> locations;
  final Function onCreated;

  @override
  CreateSorterPageState createState() => CreateSorterPageState();
}

class CreateSorterPageState extends State<CreateSorterPage> {
  String sorterName = "";
  bool autoGenerateId = true;
  String? selectedLocation;
  String selectedIcon = "blank";
  List<String> sorterTags = [];
  bool enableIdentifyApi = false;

  late TextEditingController _uniqueIdController;
  late TextEditingController _identifyApiController;

  void _onTagDetete(int index) {
    setState(() {
      sorterTags.removeAt(index);
    });
  }

  @override
  void initState() {
    super.initState();
    _uniqueIdController =
        TextEditingController(text: const Uuid().v4().toString());
    _identifyApiController = TextEditingController(text: "localhost:4300");
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
    if (_uniqueIdController.text.isEmpty) {
      return "Value can't be empty";
    }

    RegExp regex = RegExp(r'[^\w-]');
    if (regex.hasMatch(_uniqueIdController.text)) {
      return "Special characters are not allowed";
    }
    return null;
  }

  String? getIdentifyApiValidationError() {
    if (_identifyApiController.text.isEmpty && enableIdentifyApi) {
      return "Value can't be empty";
    }

    return null;
  }

  Future<void> _createSorter() async {
    final url = Uri.parse(p.join(
        widget.apiBaseAddress, "sorters/")); // Replace with your API endpoint
    try {
      final response = await http.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'name': sorterName,
          'id': _uniqueIdController.text,
          'location': selectedLocation,
          'icon': selectedIcon,
          'tags': sorterTags.join(","),
          'attrs': {
            "identity": enableIdentifyApi ? _identifyApiController.text : ""
          }
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

  Future<void> _pickIcon() async {
    IconPickerIcon? icon = await showIconPicker(context,
        configuration: SinglePickerConfiguration(
            adaptiveDialog: true,
            iconPackModes: [IconPack.custom],
            customIconPack: iconMap));

    selectedIcon = iconMap.keys
        .firstWhere((k) => iconMap[k] == icon, orElse: () => "blank");
    setState(() {});

    debugPrint('Picked Icon:  $icon');
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
          crossAxisAlignment: CrossAxisAlignment.start,
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
                      autoGenerateId = value!;
                      if (autoGenerateId) {
                        // Auto-generate unique ID
                        _uniqueIdController.text = const Uuid().v4().toString();
                      }
                    });
                  },
                ),
                const Text('Auto Generate Unique ID'),
              ],
            ),
            ValueListenableBuilder(
                valueListenable: _uniqueIdController,
                builder: (context, TextEditingValue value, __) {
                  return TextField(
                    enabled: !autoGenerateId,
                    controller: _uniqueIdController,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: 'Unique ID for sorter',
                      errorText: getUniqueIdValidationError(),
                    ),
                  );
                }),
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
                length: sorterTags.length,
                delimiters: const [',', ' ', ';'],
                hasAddButton: false,
                inputDecoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Add tags here...',
                ),
                onTagChanged: (newValue) {
                  setState(() {
                    sorterTags.add(newValue);
                  });
                },
                tagBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(top: 7.0, bottom: 3.5),
                  child: Chip(
                    label: Text(sorterTags[index]),
                    onDeleted: () {
                      _onTagDetete(index);
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8.0),
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                ),
                borderRadius: const BorderRadius.all(
                  Radius.circular(5.0),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Current Sorter Icon",
                      style: TextStyle(fontSize: 15),
                    ),
                    // const Spacer(),
                    Icon(
                      iconMap[selectedIcon]?.data ?? Icons.inventory_2_rounded,
                      size: 48,
                    ),
                    // const Spacer(),
                    ElevatedButton(
                      onPressed: () {
                        _pickIcon();
                      },
                      child: const Text("Pick icon"),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(),
            const Text(
              "Identify API",
              textAlign: TextAlign.start,
              style: TextStyle(fontSize: 24),
            ),
            const Text(
                "The optional identify API is used for part identification systems. This includes led-illuminated part bins and other similar systems. All API requests are called from the backend.\n"
                "If the API is enabled, each part will have an identify button. Clicking this button will submit a GET request to [API ENDPOINT]/identify/[PART LOCATION]"),
            const SizedBox(height: 8.0),
            Row(
              children: [
                Checkbox(
                  value: enableIdentifyApi,
                  onChanged: ((value) {
                    setState(() {
                      enableIdentifyApi = value!;
                    });
                  }),
                ),
                const Text("Enable Identify API"),
              ],
            ),
            ValueListenableBuilder(
                valueListenable: _identifyApiController,
                builder: (context, TextEditingValue value, __) {
                  return TextField(
                    enabled: enableIdentifyApi,
                    controller: _identifyApiController,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: 'API Endpoint',
                      errorText: getIdentifyApiValidationError(),
                    ),
                  );
                }),
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

class SorterInfoPage extends StatefulWidget {
  final String apiBaseAddress;

  final String sorterId;
  final List<dynamic> locations;
  final List<dynamic> sorters;

  final Function onDelete;
  final Function onModify;

  final bool loadImages;

  const SorterInfoPage({
    super.key,
    required this.apiBaseAddress,
    required this.sorterId,
    required this.locations,
    required this.sorters,
    required this.onDelete,
    required this.onModify,
    required this.loadImages,
  });

  @override
  SorterInfoPageState createState() => SorterInfoPageState();
}

class SorterInfoPageState extends State<SorterInfoPage> {
  late Future<Map<String, dynamic>> _sorterInfo;
  late Future<List<dynamic>> parts;

  String _pageTitle = "Sorter Information";
  String? sorterName;
  String? sorterIcon;
  String? sorterId;
  String? sorterLocation;
  String? sorterLocationName;
  List<String>? sorterTags;
  Map? sorterAttrs;

  String partsSearchQuery = "";
  String partsSortType = "locAsc";

  @override
  void initState() {
    super.initState();
    _sorterInfo = _fetchSorterInfo().then((value) {
      parts = _fetchParts(value['id']);
      return value;
    });
  }

  Future<Map<String, dynamic>> _fetchSorterInfo() async {
    final url =
        Uri.parse(p.join(widget.apiBaseAddress, "sorters/${widget.sorterId}"));
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _pageTitle = data["name"];
        sorterName = data["name"];
        sorterIcon = data["icon"];
        sorterId = data["id"];
        sorterAttrs = data["attrs"];
        sorterLocation = data["location"];
        sorterTags = data["tags"].split(",");
        sorterTags?.remove("");
      });
      sorterLocationName = getLocationName(sorterLocation!, widget.locations);
      return data;
    } else {
      throw Exception('Failed to load sorter information');
    }
  }

  Future<List> _fetchParts(String sorter) async {
    final url = Uri.parse(p.join(widget.apiBaseAddress,
        "parts/$sorter")); // Replace with your API endpoint
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> partsJson = jsonDecode(response.body);
        return partsJson;
      } else {
        throw Exception('Failed to load parts');
      }
    } catch (e) {
      if (!mounted) return [];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Column(
            children: [
              const Text(
                'Parts fetch failed!',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                e.toString(),
              ),
            ],
          ),
        ),
      );
      return [];
    }
  }

  List<dynamic> filterParts(List<dynamic> parts, String searchEntry) {
    final query = searchEntry.toLowerCase().trim();

    return parts.where((sorter) {
      final name = (sorter['name'] as String).toLowerCase();
      final tags = (sorter['tags'] as String).toLowerCase().split(',');

      return name.contains(query) || tags.any((tag) => tag.contains(query));
    }).toList();
  }

  List _sortParts(List parts, String sorter) {
    List sortedParts = List.from(parts);
    switch (sorter) {
      case 'creationTimeDesc':
        // Already in descending order
        break;
      case 'creationTimeAsc':
        sortedParts = sortedParts.reversed.toList();
        break;
      case 'nameAsc':
        sortedParts.sort((a, b) =>
            a['name'].toLowerCase().compareTo(b['name'].toLowerCase()));
        break;
      case 'nameDesc':
        sortedParts.sort((a, b) =>
            b['name'].toLowerCase().compareTo(a['name'].toLowerCase()));
        break;
      case 'locDesc':
        sortedParts.sort((a, b) =>
            b['location'].toLowerCase().compareTo(a['location'].toLowerCase()));
        break;
      case 'locAsc':
        sortedParts.sort((a, b) =>
            a['location'].toLowerCase().compareTo(b['location'].toLowerCase()));
        break;
      default:
        // Handle invalid sorter case if needed
        break;
    }
    return sortedParts;
  }

  Future<void> deleteSorter(String sorterId) async {
    final url = Uri.parse(p.join(widget.apiBaseAddress,
        "sorters/$sorterId")); // Replace with your API endpoint

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
          iconMap[sorterIcon]?.data ?? Icons.inventory_2_rounded,
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
                  // Capture the ScaffoldMessengerState before the async operation
                  final messenger = ScaffoldMessenger.of(context);

                  await Clipboard.setData(ClipboardData(text: sorterId!));

                  // Use the messenger directly, avoiding BuildContext issues
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Copied!')),
                  );
                },
                icon: const Icon(Icons.copy, size: 18))
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Tags:"),
            const SizedBox(width: 4.0),
            (sorterTags?.firstOrNull ?? "") != ""
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

  Future<void> identifyPart(String partIdentifyApi, String partLocation) async {
    final url = Uri.parse(p.join(widget.apiBaseAddress, "part_identify/"));
    try {
      final response = await http.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'api': partIdentifyApi,
          'location': partLocation
        }),
      );
      if (response.statusCode != 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Theme.of(context).colorScheme.error,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Part identification failed!',
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
                'Part identification failed!',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(e.toString()),
            ],
          ),
        ),
      );
    }
  }

  Future<Uint8List?> _loadPartImage(String id) async {
    try {
      final url =
          Uri.parse(p.join(widget.apiBaseAddress, 'parts_individual/$id'));
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["image"] != null) {
          return base64Decode(data["image"]);
        } else {
          return null;
        }
      } else {
        throw Exception('Failed to load part information');
      }
    } catch (e) {
      if (!mounted) rethrow;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Column(
            children: [
              const Text(
                'Part info fetch failed!',
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
    return null;
  }

  Widget _buildPartsPane() {
    return FutureBuilder<List<dynamic>>(
      future: parts,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if ((snapshot.hasData) && (snapshot.data != null)) {
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
                            partsSearchQuery = value;
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
                          partsSortType = value;
                        });
                      },
                      itemBuilder: (BuildContext context) =>
                          <PopupMenuEntry<String>>[
                        CheckedPopupMenuItem<String>(
                          checked: partsSortType == 'creationTimeDesc',
                          value: 'creationTimeDesc',
                          child: const Text('Creation Time Descending'),
                        ),
                        CheckedPopupMenuItem<String>(
                          checked: partsSortType == 'creationTimeAsc',
                          value: 'creationTimeAsc',
                          child: const Text('Creation Time Ascending'),
                        ),
                        CheckedPopupMenuItem<String>(
                          checked: partsSortType == 'nameAsc',
                          value: 'nameAsc',
                          child: const Text('Name Ascending'),
                        ),
                        CheckedPopupMenuItem<String>(
                          checked: partsSortType == 'nameDesc',
                          value: 'nameDesc',
                          child: const Text('Name Descending'),
                        ),
                        CheckedPopupMenuItem<String>(
                          checked: partsSortType == 'locAsc',
                          value: 'locAsc',
                          child: const Text('Location Name Ascending'),
                        ),
                        CheckedPopupMenuItem<String>(
                          checked: partsSortType == 'locDesc',
                          value: 'locDesc',
                          child: const Text('Location Name Descending'),
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
                    filterParts(snapshot.data!, partsSearchQuery).length,
                    (index) {
                  return Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            barrierDismissible: true,
                            builder: (context) => PartInfoPage(
                              apiBaseAddress: widget.apiBaseAddress,
                              partId: _sortParts(
                                  filterParts(snapshot.data!, partsSearchQuery),
                                  partsSortType)[index]['id'],
                              locations: widget.locations,
                              sorters: widget.sorters,
                              onDelete: () {
                                parts = _fetchParts(sorterId!).then((value) {
                                  setState(
                                      () {}); // Force state update to show modified parts in list
                                  return value;
                                });
                                widget.onModify();
                              },
                              onModify: () {
                                parts = _fetchParts(sorterId!).then((value) {
                                  setState(
                                      () {}); // Force state update to show modified parts in list
                                  return value;
                                });
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
                            if (![null, ""].contains(sorterAttrs?["identify"]))
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: IconButton.filledTonal(
                                  onPressed: () {
                                    identifyPart(
                                        sorterAttrs?["identify"],
                                        _sortParts(
                                            filterParts(snapshot.data!,
                                                partsSearchQuery),
                                            partsSortType)[index]['location']);
                                  },
                                  icon: const Icon(
                                    Icons.lightbulb,
                                    size: 64,
                                  ),
                                ),
                              ),
                            if ([null, ""].contains(sorterAttrs?["identify"]))
                              if (widget.loadImages)
                                FutureBuilder(
                                  future: _loadPartImage(_sortParts(
                                      filterParts(
                                          snapshot.data!, partsSearchQuery),
                                      partsSortType)[index]['id']),
                                  builder: (BuildContext context,
                                      AsyncSnapshot<Uint8List?> image) {
                                    print(image.hasData);
                                    if (image.hasData) {
                                      return Image.memory(
                                        resizeImage(image.data!, 64, 64),
                                      ); // image is ready
                                    } else {
                                      return const Icon(
                                        // String2Icon.getIconDataFromString(
                                        //     _sorters[index]['icon']),
                                        Icons.category_rounded,
                                        size: 64,
                                      ); // placeholder
                                    }
                                  },
                                )
                              else
                                const Icon(
                                  // String2Icon.getIconDataFromString(
                                  //     _sorters[index]['icon']),
                                  Icons.category_rounded,
                                  size: 64,
                                ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _sortParts(
                                        filterParts(
                                            snapshot.data!, partsSearchQuery),
                                        partsSortType)[index]['name'],
                                    style: const TextStyle(
                                      fontSize: 18,
                                    ),
                                  ),
                                  Text(
                                    "Quantity: ${_sortParts(filterParts(snapshot.data!, partsSearchQuery), partsSortType)[index]['enable_quantity'] ? '${_sortParts(filterParts(snapshot.data!, partsSearchQuery), partsSortType)[index]['quantity'].toString()}${_sortParts(filterParts(snapshot.data!, partsSearchQuery), partsSortType)[index]['quantity_type'].toString()}' : 'Disabled'}",
                                    style: const TextStyle(
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    "Location: ${_sortParts(filterParts(snapshot.data!, partsSearchQuery), partsSortType)[index]['location']}",
                                    style: const TextStyle(
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    _sortParts(
                                        filterParts(
                                            snapshot.data!, partsSearchQuery),
                                        partsSortType)[index]['id'],
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 4.0,
                                  ),
                                  _sortParts(
                                              filterParts(snapshot.data!,
                                                  partsSearchQuery),
                                              partsSortType)[index]['tags'] !=
                                          ""
                                      ? Wrap(
                                          direction: Axis.horizontal,
                                          spacing:
                                              4.0, // Space between adjacent widgets
                                          runSpacing:
                                              4.0, // Space between lines of widgets
                                          children: [
                                            for (var tag in _sortParts(
                                                        filterParts(
                                                            snapshot.data!,
                                                            partsSearchQuery),
                                                        partsSortType)[index]
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
              const SizedBox(
                height: 88,
              ),
            ],
          );
        } else {
          return Text('Error: ${snapshot.error}');
        }
      },
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
                    future: _sorterInfo,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasData) {
                        return ModifySorterPage(
                            apiBaseAddress: widget.apiBaseAddress,
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
                    return Stack(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: ListView(
                                children: [
                                  _buildInfoPane(),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: ListView(
                                children: [_buildPartsPane()],
                              ),
                            ),
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
                                    barrierDismissible: true,
                                    builder: (context) => CreatePartPage(
                                      apiBaseAddress: widget.apiBaseAddress,
                                      sorters: widget.sorters,
                                      onCreated: () {
                                        setState(() {
                                          parts = _fetchParts(widget.sorterId)
                                              .then((value) {
                                            setState(() {});
                                            return value;
                                          });
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
                  } else {
                    // One-column layout for smaller screens
                    return Stack(children: [
                      ListView(
                        children: [
                          _buildInfoPane(),
                          const SizedBox(
                            height: 8.0,
                          ),
                          _buildPartsPane()
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
                                  barrierDismissible: true,
                                  builder: (context) => CreatePartPage(
                                    apiBaseAddress: widget.apiBaseAddress,
                                    sorters: widget.sorters,
                                    onCreated: () {
                                      setState(() {
                                        parts = _fetchParts(widget.sorterId)
                                            .then((value) {
                                          setState(() {});
                                          return value;
                                        });
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
                    ]);
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
    required this.apiBaseAddress,
    required this.sorter,
    required this.locations,
    required this.onModified,
  });

  final String apiBaseAddress;

  final Map<String, dynamic> sorter;
  final List<dynamic> locations;
  final Function onModified;

  @override
  ModifySorterPageState createState() => ModifySorterPageState();
}

class ModifySorterPageState extends State<ModifySorterPage> {
  late String uniqueId;
  String? selectedLocation;
  String? selectedIcon;
  List<String> sorterTags = [];
  bool enableIdentifyApi = false;

  late TextEditingController _sorterNameController;
  late TextEditingController _identifyApiController;

  void _onTagDetete(int index) {
    setState(() {
      sorterTags.removeAt(index);
    });
  }

  @override
  void initState() {
    super.initState();
    uniqueId = widget.sorter['id'];
    selectedLocation = widget.sorter['location'];
    selectedIcon = widget.sorter['icon'];
    sorterTags = widget.sorter['tags'].split(',');
    sorterTags.remove("");

    _sorterNameController = TextEditingController(text: widget.sorter['name']);
    _identifyApiController = TextEditingController(
        text: widget.sorter['attrs'].containsKey("identify")
            ? widget.sorter['attrs']['identify']
            : "");

    enableIdentifyApi = widget.sorter['attrs'].containsKey("identify")
        ? widget.sorter['attrs']['identify'] != ""
        : false;
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

  String? getIdentifyApiValidationError() {
    if (_identifyApiController.text.isEmpty && enableIdentifyApi) {
      return "Value can't be empty";
    }

    return null;
  }

  Future<void> _modifySorter() async {
    final url = Uri.parse(p.join(widget.apiBaseAddress, "sorters/$uniqueId"));
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
          'icon': selectedIcon,
          'tags': sorterTags.join(","),
          'attrs': {
            "identify": enableIdentifyApi ? _identifyApiController.text : ""
          }
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

  Future<void> _pickIcon() async {
    IconPickerIcon? icon = await showIconPicker(context,
        configuration: SinglePickerConfiguration(
            adaptiveDialog: true,
            iconPackModes: [IconPack.custom],
            customIconPack: iconMap));

    selectedIcon = iconMap.keys.firstWhere(
        (k) => iconMap[k]?.data == icon?.data, // Use ?. to check for null
        orElse: () => "blank");
    setState(() {});

    debugPrint('Picked Icon:  $icon');
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
                length: sorterTags.length,
                delimiters: const [',', ' ', ';'],
                hasAddButton: false,
                inputDecoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Add tags here...',
                ),
                onTagChanged: (newValue) {
                  setState(() {
                    sorterTags.add(newValue);
                  });
                },
                tagBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(top: 7.0, bottom: 3.5),
                  child: Chip(
                    label: Text(sorterTags[index]),
                    onDeleted: () {
                      _onTagDetete(index);
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8.0),
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                ),
                borderRadius: const BorderRadius.all(
                  Radius.circular(5.0),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Current Sorter Icon",
                      style: TextStyle(fontSize: 15),
                    ),
                    // const Spacer(),
                    Icon(
                      iconMap[selectedIcon]?.data ?? Icons.inventory_2_rounded,
                      size: 48,
                    ),
                    // const Spacer(),
                    ElevatedButton(
                      onPressed: () {
                        _pickIcon();
                      },
                      child: const Text("Pick icon"),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(),
            const Text(
              "Identify API",
              textAlign: TextAlign.start,
              style: TextStyle(fontSize: 24),
            ),
            const Text(
                "The optional identify API is used for part identification systems. This includes led-illuminated part bins and other similar systems. All API requests are called from the backend.\n"
                "If the API is enabled, each part will have an identify button. Clicking this button will submit a GET request to [API ENDPOINT]/identify/[PART LOCATION]"),
            const SizedBox(height: 8.0),
            Row(
              children: [
                Checkbox(
                  value: enableIdentifyApi,
                  onChanged: ((value) {
                    setState(() {
                      enableIdentifyApi = value!;
                    });
                  }),
                ),
                const Text("Enable Identify API"),
              ],
            ),
            ValueListenableBuilder(
                valueListenable: _identifyApiController,
                builder: (context, TextEditingValue value, __) {
                  return TextField(
                    enabled: enableIdentifyApi,
                    controller: _identifyApiController,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: 'API Endpoint',
                      errorText: getIdentifyApiValidationError(),
                    ),
                  );
                }),
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
