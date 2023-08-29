import 'dart:core';
import 'dart:io';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:voice_command/spectrogram.dart';
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
  bool wasItPlaying = false;
  bool actionable = false;

  String theLabel = '';
  double theValue = 0.0;

  String yamnetTheLabel = '';
  double yamnetTheValue = 0.0;

  String validTheLabel = '';
  double validTheValue = 0.0;

  VoiceCommandRecognition? voiceCommandRecognition;
  RealtimeRecordingHandler realtimeRecordingHandler = RealtimeRecordingHandler();

  final _audioPlayer = ap.AudioPlayer()..setReleaseMode(ReleaseMode.stop);

  bool isMusicPlaying() {
    return false;
  }

  _callNumber() async{
    const number = '+989939443754'; //set the number here
    bool? res = await FlutterPhoneDirectCaller.callNumber(number);
  }

  void processCommand(String theLabel) {
    switch(theLabel) {
      case 'call' || 'tamas': _callNumber(); break;
      // case 'enable' || 'faal': enable(); break;
      // case 'disable' || 'qeir_faal': disable(); break;
    }
  }

  Future<void> predictRealtime(String realtimepath) async {
    await realtimeRecordingHandler.recordHandler();

    String audioCount = (realtimeRecordingHandler.getrecordedRealtimeCount-1).toString();
    String audioPath = "$realtimepath/tmp/$audioCount.wav";
    Float64List audio = await getWavData(audioPath);

    PredictionResults yamnetPrediction = await voiceCommandRecognition!.yamnetAudio(audio);
    PredictionResults prediction = await voiceCommandRecognition!.analyseAudio(audio);
    setState(() {
      validTheLabel = '';
      validTheValue = 0.0;
    });
    // is the audio speech at all and not noise?
    // then verify the high confidance in prediction
    if (yamnetPrediction.theLabel.contains("speech") == true && prediction.theLabel.contains("noise") == false && prediction.theValue == 1.0) {
      setState(() {
        validTheLabel = prediction.theLabel;
        validTheValue = prediction.theValue;
      });
      processCommand(prediction.theLabel);
      // if (actionable == true && prediction.theLabel != 'ava') {
      //   actionable = false;
      //   if (wasItPlaying == true) {
      //     processCommand(prediction.theLabel);
      //     print("DEACTIVATED");
      //   }
      // } else if (actionable == false && prediction.theLabel == 'ava') {
      //   print("ACTIVATED");
      //   wasItPlaying = isMusicPlaying();
      //   if (wasItPlaying == true) {
      //     actionable = true;
      //   }
      // }
    }

    setState(() {
      theLabel = prediction.theLabel;
      theValue = prediction.theValue;
      yamnetTheLabel = yamnetPrediction.theLabel;
      yamnetTheValue = yamnetPrediction.theValue;
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
            Text('valid label: $validTheLabel'),
            Text('valid confidence: $validTheValue'),
            Text('label: $theLabel'),
            Text('confidence: $theValue'),
            Text('label: $yamnetTheLabel'),
            Text('confidence: $yamnetTheValue'),
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
