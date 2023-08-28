import 'dart:core';
import 'dart:io';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:flutter/material.dart';
import 'helper/audio_classification.dart';
import 'helper/copy.dart';
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

  VoiceCommandRecognition? voiceCommandRecognition;
  RealtimeRecordingHandler realtimeRecordingHandler = RealtimeRecordingHandler();

  final _audioPlayer = ap.AudioPlayer()..setReleaseMode(ReleaseMode.stop);

  Future<void> startRealtimeRecordInterval() async {
    for (var i = 0; i < 50; i++) {
      await realtimeRecordingHandler.recordChunk();
    }
  }

  void playRealtimeAudio() async {
    String realtimepath = await realtimeRecordingHandler.directoryPath();
    
    List<FileSystemEntity> files = await realtimeRecordingHandler.realtimeDirContent();
    await _audioPlayer.play(ap.DeviceFileSource(files[-1].path));
  }

  @override
  void initState() {
    realtimeRecordingHandler.initState();
    voiceCommandRecognition = VoiceCommandRecognition();
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
                    await startRealtimeRecordInterval();
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
