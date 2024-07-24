import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:responsive_grid/responsive_grid.dart';

import 'widgets.dart';
import 'sorters.dart';
import 'locations.dart';
import 'api.dart';
import 'theme_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: 'Parts Sorter',
      themeMode: themeProvider.themeMode,
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
  String apiBaseAddress = "";

  int? _selectedIndex = 0;
  List _locations = [];
  List _sorters = [];
  List _parts = [];

  String sortersSortType = "creationTimeDesc";
  String sorterSearchQuery = "";

  String locationsSortType = "creationTimeDesc";
  String locationsSearchQuery = "";

  String partsSortType = "creationTimeDesc";
  String partsSearchQuery = "";

  PackageInfo? packageInfo;

  String apiError = "";
  bool waitingForData = true;

  @override
  void initState() {
    super.initState();
    WidgetsFlutterBinding.ensureInitialized();
    _loadPackageInfo();
    initStateAsync();
  }

  Future<void> initStateAsync() async {
    await _loadSettings();
    await apiErrorCatcher(() async {
      await fetchData();
    });
    setState(() {});
  }

  Future<void> fetchData() async {
    if (apiBaseAddress != "") {
      waitingForData = true;
      _locations = await fetchLocations(apiBaseAddress);
      _sorters = await fetchSorters(apiBaseAddress);
      _parts = await fetchAllParts(apiBaseAddress);
      waitingForData = false;
    }
  }

  Future<void> apiErrorCatcher(AsyncCallback apiAction) async {
    try {
      await apiAction().catchError((e) {
        setState(() {
          apiError = e.toString();
        });
      });
    } catch (e) {
      setState(() {
        apiError = e.toString();
      });
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    apiBaseAddress = prefs.getString("apiBaseUrl") ?? "";
  }

  Future<void> _loadPackageInfo() async {
    packageInfo = await PackageInfo.fromPlatform();
  }

  Future<void> _setApiBaseAddress(String value) async {
    apiBaseAddress = value;
    final prefs = await SharedPreferences.getInstance();
    prefs.setString("apiBaseUrl", value);
  }

  Future<List<dynamic>> fetchLocations(String apiBaseAddress) async {
    final url = Uri.parse(
        p.join(apiBaseAddress, "locations")); // Replace with your API endpoint
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final List<dynamic> locationsJson = jsonDecode(response.body);
      return locationsJson;
    } else {
      throw Exception('Failed to load locations');
    }
  }

  Future<List<dynamic>> fetchSorters(String apiBaseAddress) async {
    final url = Uri.parse(p.join(apiBaseAddress, "sorters"));
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final List<dynamic> sortersJson = jsonDecode(response.body);
      return sortersJson;
    } else {
      throw Exception('Failed to load sorters');
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
        return location['name'].toString();
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

  int getTotalQuantity() {
    int quantity = 0;
    for (final part in _parts) {
      quantity += part["quantity"] as int;
    }
    return quantity;
  }

  double getTotalValue() {
    double value = 0;
    for (final part in _parts) {
      value += part["price"] * part["quantity"] as double;
    }
    return value;
  }

  Future<void> _onItemTapped(int index) async {
    if (_selectedIndex == index) {
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
    if (index < 3) {
      await apiErrorCatcher(() async {
        await fetchData();
      });
    }
    setState(() {});
  }

  Widget _buildNavigationRail(BuildContext context) {
    return NavigationRail(
      selectedIndex: _selectedIndex!,
      onDestinationSelected: _onItemTapped,
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
        NavigationRailDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: Text('Settings'),
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return NavigationBar(
      selectedIndex: _selectedIndex!,
      onDestinationSelected: _onItemTapped,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.room_outlined),
          selectedIcon: Icon(Icons.room),
          label: 'Locations',
        ),
        NavigationDestination(
          icon: Icon(Icons.inventory_2_outlined),
          selectedIcon: Icon(Icons.inventory),
          label: 'Sorters',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Part Sorter"),
        actions: [
          if (_selectedIndex == 0)
            IconButton(
                onPressed: () {
                  showAboutDialog(
                      context: context,
                      applicationIcon: Image.asset("assets/icon-96.png"),
                      applicationVersion: packageInfo?.version,
                      applicationLegalese: "©️ 2024 Kevin Ahr",
                      children: [
                        ListTile(
                          leading: const Icon(Icons.public_rounded),
                          title: const Text("Application GitHub repo"),
                          subtitle:
                              const Text("meowmeowahr/PartsInventoryFrontend"),
                          onTap: () {
                            launchUrlString(
                                "https://github.com/meowmeowahr/PartsInventoryFrontend");
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.gavel_rounded),
                          title: const Text("Application License"),
                          subtitle:
                              const Text("GNU General Public License 3.0"),
                          onTap: () {
                            launchUrlString(
                                "https://www.gnu.org/licenses/gpl-3.0.en.html");
                          },
                        ),
                      ]);
                },
                icon: const Icon(Icons.info_outline))
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 600) {
            // Use BottomNavigationBar for small screens
            return Scaffold(
              body: Center(child: _buildContent()),
              bottomNavigationBar: _buildBottomNavigationBar(context),
            );
          } else {
            // Use NavigationRail for larger screens
            return Row(
              children: <Widget>[
                _buildNavigationRail(context),
                Expanded(
                  child: Center(child: _buildContent()),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildContent() {
    final settings = Provider.of<ThemeProvider>(context);
    final TextEditingController apiBaseUrlController =
        TextEditingController(text: apiBaseAddress);

    if (apiError != "") {
      return Column(
        children: [
          Icon(
            Icons.error,
            size: 180,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(
            height: 8.0,
          ),
          const Text(
            "An error occured!",
            style: TextStyle(fontSize: 28),
          ),
          const SizedBox(
            height: 8.0,
          ),
          TextField(
            readOnly: true,
            maxLines: 5,
            controller: TextEditingController(text: apiError),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(
            height: 8.0,
          ),
          FilledButton(
              onPressed: () {
                setState(() {
                  apiError = "";
                });
              },
              child: const Text("Clear Error"))
        ],
      );
    }

    if ((apiBaseAddress == "") && _selectedIndex != 3) {
      return Column(
        children: [
          const Spacer(),
          const Icon(Icons.settings, size: 180),
          const Text(
            "API Base URL is not set",
            style: TextStyle(fontSize: 22),
          ),
          const Spacer(),
          LayoutBuilder(builder: (context, constraints) {
            if (constraints.maxWidth < 600) {
              return const Row(
                children: [
                  Spacer(),
                  Padding(
                    padding: EdgeInsets.only(
                      right: 32,
                      bottom: 16,
                    ),
                    child: Icon(Icons.arrow_downward, size: 32),
                  ),
                ],
              );
            } else {
              return const SizedBox.shrink();
            }
          }),
        ],
      );
    }

    if (waitingForData && _selectedIndex != 3) {
      return const CircularProgressIndicator();
    }

    switch (_selectedIndex) {
      case 0:
        return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 670),
          child: ResponsiveStaggeredGridList(
            desiredItemWidth: 220,
            children: [
              const Card(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.home_rounded,
                      size: 200,
                    ),
                  ],
                ),
              ),
              Card(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.room_rounded,
                      size: 80,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    Row(
                      children: [
                        Text(
                          _locations.length.toString(),
                          style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary),
                        ),
                        Text(
                          "Locations",
                          style: TextStyle(
                            fontSize: 24,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Card(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inventory_2_rounded,
                      size: 80,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    Row(
                      children: [
                        Text(
                          _sorters.length.toString(),
                          style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary),
                        ),
                        Text(
                          "Sorters",
                          style: TextStyle(
                            fontSize: 24,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Card(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.category_rounded,
                      size: 80,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    Row(
                      children: [
                        Text(
                          _parts.length.toString(),
                          style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary),
                        ),
                        Text(
                          "Items",
                          style: TextStyle(
                            fontSize: 24,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Card(
                child: Text(
                  "Total Inventory Quantity: ${getTotalQuantity()}",
                  style: TextStyle(
                      fontSize: 26,
                      color: Theme.of(context).colorScheme.primary),
                ),
              ),
              Card(
                child: Text(
                  "Total Inventory Value: \$${getTotalValue().toStringAsFixed(2)}",
                  style: TextStyle(
                      fontSize: 26,
                      color: Theme.of(context).colorScheme.primary),
                ),
              ),
            ],
          ),
        );
      case 1:
        return Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
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
                    ],
                  ),
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
                                  apiBaseAddress: apiBaseAddress,
                                  locationId: _sortLocations(
                                      filterLocations(
                                          _locations, locationsSearchQuery),
                                      locationsSortType)[index]['id'],
                                  locations: _locations,
                                  onDelete: () async {
                                    await apiErrorCatcher(() async {
                                      _locations =
                                          await fetchLocations(apiBaseAddress);
                                      _sorters =
                                          await fetchSorters(apiBaseAddress);
                                    });
                                  },
                                  onModify: () async {
                                    await apiErrorCatcher(() async {
                                      _locations =
                                          await fetchLocations(apiBaseAddress);
                                      _sorters =
                                          await fetchSorters(apiBaseAddress);
                                    });
                                  },
                                ),
                              ),
                            );
                          },
                          style: ButtonStyle(
                            shape:
                                WidgetStateProperty.all<RoundedRectangleBorder>(
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
                                                      .onSurface),
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
                            apiBaseAddress: apiBaseAddress,
                            onCreated: () async {
                              await apiErrorCatcher(() async {
                                setState(() async {
                                  _locations =
                                      await fetchLocations(apiBaseAddress);
                                });
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
                                  apiBaseAddress: apiBaseAddress,
                                  sorterId: _sortSorters(
                                      filterSorters(
                                          _sorters, sorterSearchQuery),
                                      sortersSortType)[index]['id'],
                                  locations: _locations,
                                  sorters: _sorters,
                                  onDelete: () async {
                                    await apiErrorCatcher(() async {
                                      _locations =
                                          await fetchLocations(apiBaseAddress);
                                      _sorters =
                                          await fetchSorters(apiBaseAddress);
                                    });
                                  },
                                  onModify: () async {
                                    await apiErrorCatcher(() async {
                                      _locations =
                                          await fetchLocations(apiBaseAddress);
                                      _sorters =
                                          await fetchSorters(apiBaseAddress);
                                    });
                                  },
                                ),
                              ),
                            );
                          },
                          style: ButtonStyle(
                            shape:
                                WidgetStateProperty.all<RoundedRectangleBorder>(
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
                                                      .onSurface))
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
                          apiBaseAddress: apiBaseAddress,
                          locations: _locations,
                          onCreated: () async {
                            await apiErrorCatcher(() async {
                              setState(() async {
                                _sorters = await fetchSorters(apiBaseAddress);
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
      case 3:
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListView(
            children: [
              const Text(
                'Theme',
                style: TextStyle(fontSize: 22),
              ),
              const SizedBox(height: 8),
              SegmentedButton<ThemeModeOption>(
                segments: const [
                  ButtonSegment(
                    value: ThemeModeOption.system,
                    label: Text('System'),
                    icon: Icon(Icons.auto_awesome),
                  ),
                  ButtonSegment(
                    value: ThemeModeOption.light,
                    label: Text('Light'),
                    icon: Icon(Icons.light_mode),
                  ),
                  ButtonSegment(
                    value: ThemeModeOption.dark,
                    label: Text('Dark'),
                    icon: Icon(Icons.mode_night),
                  ),
                ],
                selected: <ThemeModeOption>{settings.themeModeOption},
                onSelectionChanged: (Set<ThemeModeOption> newSelection) {
                  if (newSelection.isNotEmpty) {
                    settings.updateThemeMode(newSelection.first);
                  }
                },
              ),
              const Divider(),
              const Text(
                'API Settings',
                style: TextStyle(fontSize: 22),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: apiBaseUrlController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'API Base URL',
                ),
                onChanged: (value) {
                  _setApiBaseAddress(value);
                },
              ),
              const Divider(),
            ],
          ),
        );
      default:
        return const Text('Something went wrong!');
    }
  }
}
