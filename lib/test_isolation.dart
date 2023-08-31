import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/material.dart';

import 'helper/realtime_lib.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Isolate Example',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Realtime realtime = Realtime();
  Isolate? _isolate;
  bool _running = false;
  int counter = 0;

  void _startIsolate() async {
    if (_isolate == null) {
      final ReceivePort receivePort = ReceivePort();
        realtime.initState();
        String realtimepath = await realtime.realtimeRecordingHandler.directoryPath();
        _isolate = await Isolate.spawn(_isolateEntry, receivePort.sendPort);
        // _isolate = await Isolate.spawn(_isolateEntry, {
        //   'port': receivePort.sendPort,
        //   'path': realtimepath,
        //   'predictor': realtime.predictRealtime,
        // });
      receivePort.listen(_handleIsolateMessage);
      setState(() {
        _running = true;
      });
    }
  }

  void _handleIsolateMessage(dynamic message) {
    print(message.toString());
    setState(() {
      counter = message;
    });
  }

  void _stopIsolate() {
    if (_isolate != null) {
      realtime.dispose();
      _isolate!.kill(priority: Isolate.immediate);
      _isolate = null;
      setState(() {
        _running = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Isolate Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text("$counter"),
            if (_running)
              Text('Isolate is running...')
            else
              Text('Isolate is not running.'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _running ? _stopIsolate : _startIsolate,
              child: Text(_running ? 'Stop Isolate' : 'Start Isolate'),
            ),
          ],
        ),
      ),
    );
  }
}

// Future<void> _isolateEntry(Map<String, dynamic> args) async {
Future<void> _isolateEntry(SendPort sendPort) async {
  // {required SendPort sendPort, required String realtimepath,required predictfunc}
  // SendPort sendPort = args['port'];
  // String realtimepath = args['path'];
  // final predictfunc = args['predictor'];
  int counter = 0;
  while (true) {
    // predictfunc(realtimepath);
    counter++;
    sendPort.send(counter);
    await Future.delayed(Duration(seconds: 1));
  }
}
