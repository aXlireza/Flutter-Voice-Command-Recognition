import 'dart:async';
import 'dart:core';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:audioplayers/audioplayers.dart' as ap;
import 'helper/audio_player.dart';
import 'package:flutter/material.dart';
import 'helper/audio_classification.dart';
import 'helper/realtime_recorder_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
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
  bool wasItPlaying = false;
  bool actionable = false;

  String theLabel = '';
  double theValue = 0.0;

  VoiceCommandRecognition? voiceCommandRecognition;
  RealtimeRecordingHandler realtimeRecordingHandler = RealtimeRecordingHandler();

  final _audioPlayer = ap.AudioPlayer()..setReleaseMode(ReleaseMode.stop);

  Future<void> updateDynamicText() async {
    await realtimeRecordingHandler.recordHandler();
    final realtimepath = await realtimeRecordingHandler.directoryPath();
    PredictionResults prediction = await voiceCommandRecognition!.analyseAudio("$realtimepath/realtime.wav");
    setState(() {
      theLabel = prediction.theLabel;
      theValue = prediction.theValue;
    });
  }

  void startInterval() {
    const Duration intervalDelay = Duration(seconds: 1);

    Timer(intervalDelay, () {
      updateDynamicText();
      Timer.periodic(intervalDelay, (timer) {
        updateDynamicText();
      });
    });
  }

  void startWhileLoop() async {
    // while (true) {
      // await updateDynamicText();
      final realtimepath = await realtimeRecordingHandler.directoryPath();
      // AudioPlayer(
      //   source: "$realtimepath/realtime.wav", onDelete: () {  },
      // );
    // }
  }

  void playRealtimeAudio() async {
    final realtimepath = await realtimeRecordingHandler.directoryPath();
    _audioPlayer.play(ap.DeviceFileSource("$realtimepath/realtime.wav"));
    // AudioPlayer(
    //   source: "$realtimepath/realtime.wav", onDelete: () {  },
    // );
  }

  @override
  void initState() {
    realtimeRecordingHandler.initState();
    voiceCommandRecognition = VoiceCommandRecognition();
    super.initState();
    // startWhileLoop();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipOval(
              child: Material(
                child: InkWell(
                  child: SizedBox(width: 56, height: 56, child: Text('record chunk')),
                  onTap: () async {
                    await realtimeRecordingHandler.recordHandler();
                  },
                ),
              ),
            ),
            ClipOval(
              child: Material(
                child: InkWell(
                  child: SizedBox(width: 56, height: 56, child: Text('play realtime')),
                  onTap: () {
                    playRealtimeAudio();
                  },
                ),
              ),
            ),
            ClipOval(
              child: Material(
                child: InkWell(
                  child: SizedBox(width: 56, height: 56, child: Text('get tmp files')),
                  onTap: () async {
                    List<FileSystemEntity> files = await realtimeRecordingHandler.realtimeDirContent();
                    print(files);
                  },
                ),
              ),
            ),
            Text('label: $theLabel'),
            Text('confidence: $theValue'),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    realtimeRecordingHandler.dispose();
    super.dispose();
  }
}
