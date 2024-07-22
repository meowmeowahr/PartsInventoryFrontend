import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutBox extends StatefulWidget {
  const AboutBox({super.key});

  @override
  AboutBoxState createState() => AboutBoxState();
}

class AboutBoxState extends State<AboutBox> {
  String appName = '';
  String version = '';
  String buildNumber = '';

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      appName = info.appName;
      version = info.version;
      buildNumber = info.buildNumber;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('About'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.info, size: 50),
          SizedBox(height: 10),
          Text(
            appName,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text('Version: $version'),
          Text('Build: $buildNumber'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('OK'),
        ),
      ],
    );
  }
}
