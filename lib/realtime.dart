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

  String theLabel = '';
  double theValue = 0.0;

  VoiceCommandRecognition? voiceCommandRecognition;
  RealtimeRecordingHandler realtimeRecordingHandler = RealtimeRecordingHandler();

  final _audioPlayer = ap.AudioPlayer()..setReleaseMode(ReleaseMode.stop);

  Future<void> predictRealtime(String realtimepath) async {
    await realtimeRecordingHandler.recordHandler();

    String path = (realtimeRecordingHandler.getrecordedRealtimeCount-1).toString();

    PredictionResults prediction = await voiceCommandRecognition!.analyseAudio("$realtimepath/tmp/$path.wav");
    // PredictionResults prediction = await voiceCommandRecognition!.analyseAudio("$realtimepath/realtime.wav");
    // PredictionResults prediction = await voiceCommandRecognition!.analyseAudioBytes(realtimebytes);
    setState(() {
      theLabel = prediction.theLabel;
      theValue = prediction.theValue;
    });
  }

  Future<void> startRealtimeRecordInterval({int rounds=-1}) async{
    String realtimepath = await realtimeRecordingHandler.directoryPath();
    
    if (rounds > -1) {
      for (var i = 0; i < rounds; i++) {
        await predictRealtime(realtimepath);
      }
    } else {
      await predictRealtime(realtimepath);
    }
  }

  void playRealtimeAudio() async {
    String realtimepath = await realtimeRecordingHandler.directoryPath();
    
    List<FileSystemEntity> files = await realtimeRecordingHandler.realtimeDirContent();
    // await _audioPlayer.play(ap.DeviceFileSource(files[0].path));
    for (var file in files) {
      await _audioPlayer.play(ap.DeviceFileSource(file.path));
      await Future.delayed(Duration(milliseconds: 1000));

      print(file.path);
    }
    // await _audioPlayer.play(ap.DeviceFileSource("$realtimepath/realtime.wav"));
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
                    await startRealtimeRecordInterval(rounds: 10);
                  },
                ),
              ),
              Material(
                child: InkWell(
                  child: SizedBox(width: 200, height: 56, child: Text('record chunk')),
                  onTap: () async {
                    await realtimeRecordingHandler.recordChunk();
                  },
                ),
              ),
              Material(
                child: InkWell(
                  child: SizedBox(width: 200, height: 56, child: Text('chunks Controller')),
                  onTap: () async {
                    await realtimeRecordingHandler.chunksController();
                  },
                ),
              ),
              // Material(
              //   child: InkWell(
              //     child: SizedBox(width: 200, height: 56, child: Text('generate realtime')),
              //     onTap: () async {
              //       await realtimeRecordingHandler.generateRealtimeWav();
              //     },
              //   ),
              // ),
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
                    await startRealtimeRecordInterval(rounds: -1);
                  },
                ),
              ),
              Material(
                child: InkWell(
                  child: SizedBox(width: 200, height: 56, child: Text('play realtime')),
                  onTap: () {
                    playRealtimeAudio();
                  },
                ),
              ),
              Material(
                child: InkWell(
                  child: SizedBox(width: 200, height: 56, child: Text('get tmp files')),
                  onTap: () async {
                    List<FileSystemEntity> files = await realtimeRecordingHandler.realtimeDirContent();
                    print(files);
                  },
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
