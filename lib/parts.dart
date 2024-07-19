import 'dart:convert';

import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import 'package:image/image.dart' as img;
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:material_tag_editor/tag_editor.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_linkify/flutter_linkify.dart';

import 'widgets.dart';

String convertUtcToLocal(BuildContext context, String utcTimestamp) {
  try {
    DateTime utcDateTime =
        DateFormat("yyyy-MM-dd HH:mm:ss").parse(utcTimestamp, true);
    DateTime localDateTime = utcDateTime.toLocal();
    String formattedDate = DateFormat.yMMMd().add_jms().format(localDateTime);
    return formattedDate;
  } catch (e) {
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Failed to convert utc timestamp!',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                e.toString(),
              ),
            ],
          ),
        ),
      );
    });
    return "UTC: $utcTimestamp";
  }
}

Future<Uint8List> resizeImageByWidth(XFile file, int targetWidth) async {
  Uint8List fileBytes = await file.readAsBytes();
  img.Image? originalImage = img.decodeImage(fileBytes);

  if (originalImage == null) {
    throw Exception('Failed to decode image.');
  }

  // Calculate the target height to maintain aspect ratio
  int targetHeight =
      (targetWidth * originalImage.height / originalImage.width).round();

  // Resize the image
  img.Image resizedImage =
      img.copyResize(originalImage, width: targetWidth, height: targetHeight);

  // Convert the resized image back to bytes
  Uint8List resizedBytes = Uint8List.fromList(img.encodeJpg(resizedImage));

  return resizedBytes;
}

class PartInfoPage extends StatefulWidget {
  final String apiBaseAddress;

  final String partId;
  final List<dynamic> locations;
  final List<dynamic> sorters;

  final Function onDelete;
  final Function onModify;

  const PartInfoPage({
    super.key,
    required this.apiBaseAddress,
    required this.partId,
    required this.locations,
    required this.sorters,
    required this.onDelete,
    required this.onModify,
  });

  @override
  PartInfoPageState createState() => PartInfoPageState();
}

class PartInfoPageState extends State<PartInfoPage> {
  late Future<Map<String, dynamic>> _partInfo;

  String _pageTitle = "Part Information";
  String? partName;
  String? partLocationName;
  String? partSorterId;
  Map<String, dynamic>? partPhysicalLocation;
  String? partSorterName;
  List<String>? partTags;
  int partQuantity = 0;
  String partQuantityType = "pcs";
  bool partQuantityEnabled = true;
  double partPrice = 0;
  String partNotes = "";
  String partLocation = "";
  Map partAttrs = {};
  bool partHasIdentify = false;
  String? partIdentifyApi;
  String partUpdatedTimestamp = "";
  String partCreatedTimestamp = "";
  Uint8List? partImage;

  bool fetchFailed = false;

  @override
  void initState() {
    super.initState();
    _partInfo = _fetchPartInfo();
  }

  Future<Map<String, dynamic>> _fetchPartInfo() async {
    try {
      final url = Uri.parse(
          p.join(widget.apiBaseAddress, 'parts_individual/${widget.partId}'));
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _pageTitle = data["name"];
        partName = data["name"];
        partSorterId = data["sorter"];
        partSorterName = getSorterName(data["sorter"], widget.sorters);
        partPhysicalLocation = getLocationBySorterId(
            widget.sorters, widget.locations, data["sorter"]);
        partLocationName = partPhysicalLocation?["name"];
        partTags = data["tags"].split(",");
        partTags?.remove("");
        partQuantity = data["quantity"];
        partQuantityType = data["quantity_type"];
        partQuantityEnabled = data["enable_quantity"].isOdd;
        partPrice = data["price"].toDouble();
        partLocation = data["location"];
        partNotes = data["notes"];
        partAttrs = data["attrs"];
        partUpdatedTimestamp = data["updated_at"];
        partCreatedTimestamp = data["created_at"];

        if (data["image"] != null) {
          partImage = base64Decode(data["image"]);
        } else {
          partImage = null;
        }

        final sorterAttrs = getSorterAttrs(data["sorter"], widget.sorters);
        if (sorterAttrs.containsKey("identify") &&
            sorterAttrs["identify"] != "") {
          partHasIdentify = true;
          partIdentifyApi = sorterAttrs["identify"];
        }
        if (!mounted) return data;
        setState(() {});
        return data;
      } else {
        throw Exception('Failed to load part information');
      }
    } catch (e) {
      if (!mounted) rethrow;
      fetchFailed = true;
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
    return {};
  }

  List<dynamic> filterParts(List<dynamic> parts, String searchEntry) {
    final query = searchEntry.toLowerCase().trim();

    return parts.where((sorter) {
      final name = (sorter['name'] as String).toLowerCase();
      final tags = (sorter['tags'] as String).toLowerCase().split(',');

      return name.contains(query) || tags.any((tag) => tag.contains(query));
    }).toList();
  }

  String? getSorterName(String sorterId, List<dynamic> sorters) {
    try {
      final sorter = sorters.firstWhere(
        (location) => location['id'].toString() == sorterId,
        orElse: () => null,
      );
      if (sorter != null) {
        return sorter['name']
            .toString(); // Assuming the location contains a 'name' field
      } else {
        throw Exception('Sorter not found');
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
                'Failed to load sorter!',
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

  Map getSorterAttrs(String sorterId, List<dynamic> sorters) {
    try {
      final sorter = sorters.firstWhere(
        (location) => location['id'].toString() == sorterId,
        orElse: () => null,
      );
      if (sorter != null) {
        return sorter['attrs']; // Assuming the location contains a 'name' field
      } else {
        throw Exception('Sorter not found');
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
                'Failed to load sorter!',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                e.toString(),
              ),
            ],
          ),
        ),
      );
      return {};
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

  Map<String, dynamic>? getLocationBySorterId(
      List<dynamic> sorters, List<dynamic> locations, String sorterId) {
    Map<String, dynamic> sorter = sorters
        .firstWhere((sorter) => sorter['id'] == sorterId, orElse: () => {});

    if (sorter.isNotEmpty) {
      String locationId = sorter['location'];
      return locations.firstWhere((location) => location['id'] == locationId,
          orElse: () => {});
    } else {
      return null;
    }
  }

  Future<void> _editImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) {
      return;
    }

    if (await image.length() > 1.049e+7) {
      // 10MB-ish limit
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.error,
          content: const Text(
            'Image size too large. Max size is 10MB',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
      return;
    }

    Uint8List fileBytes = await resizeImageByWidth(image, 480);
    String base64String = base64Encode(fileBytes);

    // Send image to api
    final url = Uri.parse(p.join(
        widget.apiBaseAddress, 'parts_individual/${widget.partId}/image'));
    try {
      final response = await http.put(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'id': widget.partId,
          'image': base64String,
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
                  'Part modification failed!',
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
                'Part modification failed!',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(e.toString()),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _removeImage() async {
    // Send image to api
    final url = Uri.parse(p.join(
        widget.apiBaseAddress, 'parts_individual/${widget.partId}/image'));
    try {
      final response = await http.put(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'id': widget.partId,
          'image': null,
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
                  'Part modification failed!',
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
                'Part modification failed!',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(e.toString()),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _updatePart() async {
    final url = Uri.parse(p.join(widget.apiBaseAddress,
        'parts_individual/${widget.partId}')); // Replace with your API endpoint
    try {
      final response = await http.put(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'name': partName,
          'id': widget.partId,
          'sorter': partSorterId,
          'quantity': partQuantity,
          'quantity_type': partQuantityType,
          'enable_quantity': partQuantityEnabled,
          'price': partPrice,
          'notes': partNotes,
          'location': partLocation,
          'image': null,
          'tags': partTags?.join(","),
          'attrs': partAttrs,
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
                  'Part modification failed!',
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
                'Part modification failed!',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(e.toString()),
            ],
          ),
        ),
      );
    }
  }

  Future<void> deletePart(String partId) async {
    final url = Uri.parse(p.join(widget.apiBaseAddress,
        'parts_individual/$partId')); // Replace with your API endpoint

    try {
      final response = await http.delete(url);
      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Part deleted successfully!'),
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

  Future<void> identifyPart() async {
    final url = Uri.parse(p.join(widget.apiBaseAddress, 'part_identify/'));
    try {
      final response = await http.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'api': partIdentifyApi!,
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

  Future<Object> _showDeleteConfirmation(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Part'),
          content: const Text(
              'Are you sure you want to delete this part? Deleted parts CANNOT be recovered.'),
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
                deletePart(widget.partId);
              },
            ),
          ],
        );
      },
    );
  }

  String getPriceString(
      double partPrice, int partQuantity, bool enableQuantity) {
    return enableQuantity
        ? "\$${(partPrice * partQuantity).toStringAsFixed(2)} (\$${partPrice.toString()} each)"
        : "\$${partPrice.toString()} each";
  }

  String? getLink(Map partAttrs) {
    if (!partAttrs.containsKey("link")) {
      // links is non-existent
      return null;
    }

    if (partAttrs["link"].runtimeType != String) {
      // links is empty, or not a String
      return null;
    }

    return partAttrs["link"];
  }

  Widget _buildInfoPane() {
    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                partImage != null
                    ? Image.memory(
                        partImage!,
                        width: 480,
                        alignment: Alignment.center,
                      )
                    : Icon(
                        Icons.broken_image,
                        size: 240,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                Align(
                  alignment: Alignment.bottomRight,
                  widthFactor: 12,
                  child: Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius:
                            const BorderRadius.all(Radius.circular(20)),
                      ),
                      child: PopupMenuButton(
                        itemBuilder: (BuildContext context) {
                          List<PopupMenuItem> options = [
                            const PopupMenuItem(
                              value: "edit",
                              child: Text("Edit Image"),
                            )
                          ];
                          if (partImage != null) {
                            options.add(
                              const PopupMenuItem(
                                value: "remove",
                                child: Text("Remove Image"),
                              ),
                            );
                          }
                          return options;
                        },
                        tooltip: "Image options",
                        onSelected: (value) {
                          if (value == "edit") {
                            _editImage().then((value) {
                              _fetchPartInfo().then((value) {
                                setState(() {});
                                return value;
                              });
                              return value;
                            });
                          } else if (value == "remove") {
                            _removeImage().then((value) {
                              _fetchPartInfo().then((value) {
                                setState(() {});
                                return value;
                              });
                              return value;
                            });
                          }
                        },
                        icon: Icon(
                          Icons.edit,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Text(
          "Located in: $partLocationName > $partSorterName",
          style: const TextStyle(fontSize: 24),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                "ID: ${widget.partId}",
                softWrap: true,
              ),
            ),
            const SizedBox(width: 4.0),
            IconButton(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: widget.partId))
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
            ["", null].contains(partTags?.firstOrNull)
                ? const Text("No Tags")
                : Flexible(
                    child: Wrap(
                      spacing: 4.0,
                      runSpacing: 4.0,
                      children: [
                        for (var tag in partTags ?? [])
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
          ],
        ),
        if (partHasIdentify) const SizedBox(height: 8.0),
        if (partHasIdentify)
          ElevatedButton.icon(
            onPressed: identifyPart,
            icon: const Icon(Icons.lightbulb_rounded),
            label: const Text("Identify"),
          ),
        const Divider(),
        NumberSpinner(
          value: partQuantity,
          title: "Quantity",
          suffix: " $partQuantityType",
          enabled: partQuantityEnabled,
          maxValue: 2147483647,
          onChanged: (value) {
            setState(() {
              partQuantity = value;
              _updatePart();
            });
          },
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              const Text("Price",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text(getPriceString(partPrice, partQuantity, partQuantityEnabled),
                  style: const TextStyle(fontSize: 18))
            ],
          ),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              const Text("Location",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text(partLocation == "" ? "Empty" : partLocation,
                  style: const TextStyle(fontSize: 18))
            ],
          ),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              const Text("Notes",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              Flexible(
                flex: 2,
                child: Text(partNotes == "" ? "Empty" : partNotes,
                    style: const TextStyle(fontSize: 18)),
              )
            ],
          ),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Link",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              Flexible(
                fit: FlexFit.tight,
                flex: 3,
                child: Linkify(
                  text: getLink(partAttrs) != null
                      ? getLink(partAttrs)!
                      : "No Link",
                  onOpen: (link) => launchUrl(Uri.parse(link.url)),
                  softWrap: false,
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              const Text("Updated at",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text(convertUtcToLocal(context, partUpdatedTimestamp),
                  style: const TextStyle(fontSize: 18))
            ],
          ),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              const Text("Created at",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text(convertUtcToLocal(context, partCreatedTimestamp),
                  style: const TextStyle(fontSize: 18))
            ],
          ),
        ),
        const Divider(),
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
                  builder: (context) => FutureBuilder<Map<String, dynamic>>(
                    future: _partInfo,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasData) {
                        return ModifyPartPage(
                            apiBaseAddress: widget.apiBaseAddress,
                            part: snapshot.data!,
                            sorters: widget.sorters,
                            onModified: () {
                              widget.onModify();
                              _partInfo = _fetchPartInfo().then((value) {
                                setState(() {});
                                return value;
                              });
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
          future: _partInfo,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else if (fetchFailed) {
              return const Center(
                child: Column(
                  children: [
                    Icon(Icons.sentiment_very_dissatisfied_sharp, size: 240),
                    Text(
                      "Unexpected error while loading part information!",
                      style: TextStyle(fontSize: 22),
                    ),
                  ],
                ),
              );
            } else if (snapshot.hasData) {
              return ListView(
                children: [
                  _buildInfoPane(),
                ],
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

class ModifyPartPage extends StatefulWidget {
  const ModifyPartPage({
    super.key,
    required this.apiBaseAddress,
    required this.part,
    required this.sorters,
    required this.onModified,
  });

  final String apiBaseAddress;

  final Map<String, dynamic> part;
  final List<dynamic> sorters;
  final Function onModified;

  @override
  ModifyPartPageState createState() => ModifyPartPageState();
}

class ModifyPartPageState extends State<ModifyPartPage> {
  late String uniqueId;
  String? selectedSorter;
  String? quantityType;
  int quantity = 1;
  bool enableQuantity = true;
  List<String> partTags = [];
  String partLocation = "Unknown";
  String? partNotes;
  Map<String, dynamic> partAttrs = {};

  late TextEditingController _partNameController;
  late TextEditingController _quantityController;
  late TextEditingController _priceController;
  late TextEditingController _locationController;
  late TextEditingController _notesController;
  late TextEditingController _linkController;

  void _onTagDetete(int index) {
    setState(() {
      partTags.removeAt(index);
    });
  }

  @override
  void initState() {
    super.initState();
    uniqueId = widget.part['id'];
    selectedSorter = widget.part['sorter'];
    quantity = widget.part['quantity'];
    quantityType = widget.part['quantity_type'];
    enableQuantity = widget.part["enable_quantity"].isOdd;
    partTags = widget.part['tags'].split(',');
    partTags.remove("");
    partAttrs = widget.part["attrs"];

    if (!partAttrs.containsKey("link")) {
      partAttrs["link"] = null;
    }

    _partNameController = TextEditingController(text: widget.part['name']);
    _quantityController =
        TextEditingController(text: widget.part['quantity'].toString());
    _priceController =
        TextEditingController(text: widget.part['price'].toString());
    _locationController = TextEditingController(text: widget.part['location']);
    _notesController = TextEditingController(text: widget.part['notes']);
    _linkController = TextEditingController(text: widget.part['attrs']["link"]);
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

  Future<void> _modifyPart() async {
    final url = Uri.parse(p.join(widget.apiBaseAddress,
        'parts_individual/$uniqueId')); // Replace with your API endpoint
    try {
      final response = await http.put(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'name': _partNameController.text,
          'id': uniqueId,
          'sorter': selectedSorter,
          'quantity': int.tryParse(_quantityController.text),
          'quantity_type': quantityType,
          'enable_quantity': enableQuantity,
          'price': double.tryParse(_priceController.text),
          'notes': _notesController.text,
          'location': _locationController.text,
          'tags': partTags.join(","),
          'attrs': partAttrs
        }),
      );
      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Part modified successfully!'),
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
                  'Part modification failed!',
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
                'Part modification failed!',
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
        title: const Text("Modify Part"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: [
            ValueListenableBuilder(
                valueListenable: _partNameController,
                builder: (context, TextEditingValue value, __) {
                  return TextField(
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: 'Name for Part',
                      errorText: _partNameController.text.isEmpty
                          ? "Value can't be empty"
                          : null,
                    ),
                    controller: _partNameController,
                  );
                }),
            const SizedBox(height: 8.0),
            DropdownButtonFormField<String>(
              value: widget.sorters
                      .any((location) => location['id'] == selectedSorter)
                  ? selectedSorter
                  : null,
              onChanged: (value) {
                setState(() {
                  selectedSorter = value;
                });
              },
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'Select Sorter',
                errorText:
                    selectedSorter == null ? "Value can't be empty" : null,
              ),
              items: buildLocationDropdownItems(widget.sorters),
            ),
            const SizedBox(height: 8.0),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(4.0),
              ),
              padding: const EdgeInsets.only(left: 8.0, right: 8.0),
              child: TagEditor(
                length: partTags.length,
                delimiters: const [',', ' ', ';'],
                hasAddButton: false,
                inputDecoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Add tags here...',
                ),
                onTagChanged: (newValue) {
                  setState(() {
                    partTags.add(newValue);
                  });
                },
                tagBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(top: 7.0),
                  child: Chip(
                    label: Text(partTags[index]),
                    onDeleted: () {
                      _onTagDetete(index);
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8.0),
            Row(
              children: [
                Checkbox(
                    value: enableQuantity,
                    onChanged: (value) {
                      setState(() {
                        enableQuantity = value!;
                      });
                    }),
                const Text("Enable Quantity Tracking")
              ],
            ),
            const SizedBox(height: 8.0),
            Row(
              children: [
                Expanded(
                  child: ValueListenableBuilder(
                      // Note: pass _controller to the animation argument
                      valueListenable: _quantityController,
                      builder: (context, TextEditingValue value, __) {
                        return TextField(
                          decoration: InputDecoration(
                              labelText: "Quantity",
                              errorText: _quantityController.text.isEmpty
                                  ? "Value can't be empty"
                                  : null,
                              border: const OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          controller: _quantityController,
                          enabled: enableQuantity,
                        );
                      }),
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: quantityType,
                    onChanged: enableQuantity
                        ? (value) {
                            setState(() {
                              quantityType = value;
                            });
                          }
                        : null,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: 'Quantity Type',
                      errorText: selectedSorter == null
                          ? "Value can't be empty"
                          : null,
                    ),
                    items: const [
                      DropdownMenuItem<String>(
                        value: "pcs",
                        child: Text("pcs"),
                      ),
                      DropdownMenuItem<String>(
                        value: "bags",
                        child: Text("bags"),
                      ),
                      DropdownMenuItem<String>(
                        value: "box",
                        child: Text("boxes"),
                      ),
                      DropdownMenuItem<String>(
                        value: "reels",
                        child: Text("reels"),
                      ),
                      DropdownMenuItem<String>(
                        value: "m",
                        child: Text("meters"),
                      ),
                      DropdownMenuItem<String>(
                        value: "cm",
                        child: Text("centimeters"),
                      ),
                      DropdownMenuItem<String>(
                        value: "ft",
                        child: Text("feet"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            ValueListenableBuilder(
                // Note: pass _controller to the animation argument
                valueListenable: _priceController,
                builder: (context, TextEditingValue value, __) {
                  return TextField(
                    decoration: InputDecoration(
                        prefixText: r"$",
                        labelText: "Price per Unit",
                        errorText: _priceController.text.isEmpty
                            ? "Value can't be empty"
                            : null,
                        border: const OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(RegExp(r"[0-9]|\."))
                    ],
                    controller: _priceController,
                  );
                }),
            const SizedBox(height: 8.0),
            ValueListenableBuilder(
                // Note: pass _controller to the animation argument
                valueListenable: _locationController,
                builder: (context, TextEditingValue value, __) {
                  return TextField(
                    decoration: InputDecoration(
                        labelText: "Location",
                        errorText: _locationController.text.isEmpty
                            ? "Value can't be empty"
                            : null,
                        border: const OutlineInputBorder()),
                    controller: _locationController,
                  );
                }),
            const SizedBox(height: 8.0),
            TextField(
              decoration: const InputDecoration(
                  labelText: "Link", border: OutlineInputBorder()),
              controller: _linkController,
              onChanged: (value) {
                partAttrs["link"] = value;
              },
            ),
            const SizedBox(height: 8.0),
            TextField(
              decoration: const InputDecoration(
                  labelText: "Notes", border: OutlineInputBorder()),
              controller: _notesController,
              maxLines: 4,
            ),
            const SizedBox(height: 8.0),
            ElevatedButton(
              onPressed: () {
                _modifyPart(); // Call function to modify sorter
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}

class CreatePartPage extends StatefulWidget {
  const CreatePartPage({
    super.key,
    required this.apiBaseAddress,
    required this.sorters,
    required this.onCreated,
  });

  final String apiBaseAddress;
  final List<dynamic> sorters;
  final Function onCreated;

  @override
  CreatePartPageState createState() => CreatePartPageState();
}

class CreatePartPageState extends State<CreatePartPage> {
  String uniqueId = "";
  String? selectedSorter;
  String quantityType = "pcs";
  int? quantity;
  bool enableQuantity = true;
  bool autoGenerateId = true;
  List<String> partTags = [];
  String partLocation = "Unknown";
  String? partNotes;
  Map<String, dynamic> partAttrs = {};

  late TextEditingController _partNameController;
  late TextEditingController _quantityController;
  late TextEditingController _priceController;
  late TextEditingController _locationController;
  late TextEditingController _notesController;
  late TextEditingController _linkController;
  late TextEditingController _uniqueIdController;

  void _onTagDelete(int index) {
    setState(() {
      partTags.removeAt(index);
    });
  }

  @override
  void initState() {
    super.initState();
    partAttrs["link"] = null;

    _partNameController = TextEditingController();
    _quantityController = TextEditingController();
    _priceController = TextEditingController();
    _locationController = TextEditingController();
    _notesController = TextEditingController();
    _linkController = TextEditingController();
    _uniqueIdController = TextEditingController();

    uniqueId = const Uuid().v4(); // Initial unique ID
    _uniqueIdController = TextEditingController(text: uniqueId);
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

  Future<void> _createPart() async {
    if (autoGenerateId) {
      uniqueId = const Uuid().v4();
    }

    final url = Uri.parse(p.join(widget.apiBaseAddress, 'parts_individual/'));
    try {
      final response = await http.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'name': _partNameController.text,
          'id': uniqueId,
          'sorter': selectedSorter,
          'quantity': int.tryParse(_quantityController.text),
          'quantity_type': quantityType,
          'enable_quantity': enableQuantity,
          'price': double.tryParse(_priceController.text),
          'notes': _notesController.text,
          'location': _locationController.text,
          'tags': partTags.join(","),
          'attrs': partAttrs
        }),
      );
      if (response.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Part created successfully!'),
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
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Part creation failed!',
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
                'Part creation failed!',
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
        title: const Text("Create Part"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: [
            ValueListenableBuilder(
              valueListenable: _partNameController,
              builder: (context, TextEditingValue value, __) {
                return TextField(
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: 'Name for Part',
                    errorText: _partNameController.text.isEmpty
                        ? "Value can't be empty"
                        : null,
                  ),
                  controller: _partNameController,
                );
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
            DropdownButtonFormField<String>(
              value: selectedSorter,
              onChanged: (value) {
                setState(() {
                  selectedSorter = value;
                });
              },
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'Select Sorter',
                errorText:
                    selectedSorter == null ? "Value can't be empty" : null,
              ),
              items: buildLocationDropdownItems(widget.sorters),
            ),
            const SizedBox(height: 8.0),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(4.0),
              ),
              padding: const EdgeInsets.only(left: 8.0, right: 8.0),
              child: TagEditor(
                length: partTags.length,
                delimiters: const [',', ' ', ';'],
                hasAddButton: false,
                inputDecoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Add tags here...',
                ),
                onTagChanged: (newValue) {
                  setState(() {
                    partTags.add(newValue);
                  });
                },
                tagBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(top: 7.0),
                  child: Chip(
                    label: Text(partTags[index]),
                    onDeleted: () {
                      _onTagDelete(index);
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8.0),
            Row(
              children: [
                Checkbox(
                  value: enableQuantity,
                  onChanged: (value) {
                    setState(() {
                      enableQuantity = value!;
                    });
                  },
                ),
                const Text("Enable Quantity Tracking")
              ],
            ),
            const SizedBox(height: 8.0),
            Row(
              children: [
                Expanded(
                  child: ValueListenableBuilder(
                    valueListenable: _quantityController,
                    builder: (context, TextEditingValue value, __) {
                      return TextField(
                        decoration: InputDecoration(
                          labelText: "Quantity",
                          errorText: _quantityController.text.isEmpty
                              ? "Value can't be empty"
                              : null,
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        controller: _quantityController,
                        enabled: enableQuantity,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: quantityType,
                    onChanged: enableQuantity
                        ? (value) {
                            setState(() {
                              quantityType = value!;
                            });
                          }
                        : null,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Quantity Type',
                    ),
                    items: const [
                      DropdownMenuItem<String>(
                        value: "pcs",
                        child: Text("pcs"),
                      ),
                      DropdownMenuItem<String>(
                        value: "bags",
                        child: Text("bags"),
                      ),
                      DropdownMenuItem<String>(
                        value: "box",
                        child: Text("boxes"),
                      ),
                      DropdownMenuItem<String>(
                        value: "reels",
                        child: Text("reels"),
                      ),
                      DropdownMenuItem<String>(
                        value: "m",
                        child: Text("meters"),
                      ),
                      DropdownMenuItem<String>(
                        value: "cm",
                        child: Text("centimeters"),
                      ),
                      DropdownMenuItem<String>(
                        value: "ft",
                        child: Text("feet"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            ValueListenableBuilder(
              valueListenable: _priceController,
              builder: (context, TextEditingValue value, __) {
                return TextField(
                  decoration: InputDecoration(
                    prefixText: r"$",
                    labelText: "Price per Unit",
                    errorText: _priceController.text.isEmpty
                        ? "Value can't be empty"
                        : null,
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp(r"[0-9]|\."))
                  ],
                  controller: _priceController,
                );
              },
            ),
            const SizedBox(height: 8.0),
            ValueListenableBuilder(
              valueListenable: _locationController,
              builder: (context, TextEditingValue value, __) {
                return TextField(
                  decoration: InputDecoration(
                    labelText: "Location",
                    errorText: _locationController.text.isEmpty
                        ? "Value can't be empty"
                        : null,
                    border: const OutlineInputBorder(),
                  ),
                  controller: _locationController,
                );
              },
            ),
            const SizedBox(height: 8.0),
            TextField(
              decoration: const InputDecoration(
                labelText: "Link",
                border: OutlineInputBorder(),
              ),
              controller: _linkController,
              onChanged: (value) {
                partAttrs["link"] = value;
              },
            ),
            const SizedBox(height: 8.0),
            TextField(
              decoration: const InputDecoration(
                labelText: "Notes",
                border: OutlineInputBorder(),
              ),
              controller: _notesController,
              maxLines: 4,
            ),
            const SizedBox(height: 8.0),
            ElevatedButton(
              onPressed: () {
                _createPart();
              },
              child: const Text('Create Part'),
            ),
          ],
        ),
      ),
    );
  }
}
