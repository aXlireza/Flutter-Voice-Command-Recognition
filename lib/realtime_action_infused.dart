import 'dart:core';
import 'dart:io';
import 'package:flutter/material.dart';
import 'helper/copy.dart';
import 'helper/realtime_lib.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Realtime',
      theme: ThemeData.dark(),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Realtime realtime = Realtime();

  @override
  void initState() {
    realtime.initState();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
              Material(
                child: InkWell(
                  child: SizedBox(width: 200, height: 56, child: Text('record one complete second')),
                  onTap: () async {
                    await realtime.startRealtimeRecordInterval(rounds: 10);
                  },
                ),
              ),
              Material(
                child: InkWell(
                  child: SizedBox(width: 200, height: 56, child: Text('record chunk')),
                  onTap: () async {
                    await realtime.realtimeRecordingHandler.recordChunk();
                  },
                ),
              ),
              Material(
                child: InkWell(
                  child: SizedBox(width: 200, height: 56, child: Text('chunks Controller')),
                  onTap: () async {
                    await realtime.realtimeRecordingHandler.chunksController();
                  },
                ),
              ),
              Material(
                child: InkWell(
                  child: SizedBox(width: 200, height: 56, child: Text('copy tmp files')),
                  onTap: () async {
                    await copytmpFiles();
                  },
                ),
              ),
              Material(
                child: InkWell(
                  child: SizedBox(width: 200, height: 56, child: Text('Predict')),
                  onTap: () async {
                    await realtime.startRealtimeRecordInterval(rounds: -1);
                  },
                ),
              ),
              Material(
                child: InkWell(
                  child: SizedBox(width: 200, height: 56, child: Text('play realtime')),
                  onTap: () {
                    realtime.playRealtimeAudio();
                  },
                ),
              ),
              Material(
                child: InkWell(
                  child: SizedBox(width: 200, height: 56, child: Text('get tmp files')),
                  onTap: () async {
                    List<FileSystemEntity> files = await realtime.realtimeRecordingHandler.realtimeDirContent();
                    print(files);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    realtime.dispose();
    super.dispose();
  }
}
