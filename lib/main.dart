import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:http/http.dart' as http;

void main() {
  runApp(MaterialApp(
    home: MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  double temperatureValue = -1.0;
  double ntuValue = -1.0;
  double phValue = -1.0;
  late io.Socket socket;

  @override
  void initState() {
    super.initState();
    initializeSocket();

    // Start a periodic timer to fetch initial data every 5 seconds
    Timer.periodic(Duration(seconds: 5), (timer) {
      fetchDataFromAPI();
    });
  }

  void initializeSocket() {
    // Initialize Socket.IO and connect to the server
    socket = io.io('https://realm-admin.onrender.com', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    // Listen for 'temperature_update' events from the server
    socket.on('temperature_update', (data) {
      setState(() {
        temperatureValue = data['temperature_value'].toDouble();
      });
    });

    // Listen for 'ntu_update' events from the server
    socket.on('ntu_update', (data) {
      setState(() {
        ntuValue = data['ntu_value'].toDouble();
      });
    });

    // Listen for 'ph_update' events from the server
    socket.on('ph_update', (data) {
      setState(() {
        phValue = data['ph_value'].toDouble();
      });
    });

    // Connect to the server
    socket.connect();
  }

  Future<void> fetchDataFromAPI() async {
    try {
      final temperatureResponse = await http.get(Uri.parse('https://realm-admin.onrender.com/api/realm/gettemp'));
      final ntuResponse = await http.get(Uri.parse('https://realm-admin.onrender.com/api/realm/getturbidity'));
      final phResponse = await http.get(Uri.parse('https://realm-admin.onrender.com/api/realm/getph'));

      if (temperatureResponse.statusCode == 200 &&
          ntuResponse.statusCode == 200 &&
          phResponse.statusCode == 200) {
        final temperatureJson = jsonDecode(temperatureResponse.body);
        final ntuJson = jsonDecode(ntuResponse.body);
        final phJson = jsonDecode(phResponse.body);

        setState(() {
          temperatureValue = temperatureJson[0]['temperature_value'].toDouble();
          ntuValue = ntuJson[0]['ntu_value'].toDouble();
          phValue = phJson[0]['ph_value'].toDouble();
        });
      } else {
        print('HTTP Error');
      }
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  @override
  void dispose() {
    socket.disconnect(); // Close the Socket.IO connection when the widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Values Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Temperature Value: ${temperatureValue.toStringAsFixed(1)}',
            ),
            Text(
              'NTU Value: ${ntuValue.toStringAsFixed(1)}',
            ),
            Text(
              'pH Value: ${phValue.toStringAsFixed(1)}',
            ),
          ],
        ),
      ),
    );
  }
}
