import 'dart:async';
import 'dart:core';
import 'audio_player.dart';
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
  bool showPlayer = false;
  String? audioPath;

  @override
  void initState() {
    super.initState();

    showPlayer = false;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Center(
          child: showPlayer
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: AudioPlayer(
                source: audioPath!,
                onDelete: () {
                  setState(() => showPlayer = false);
                },
              ),
            )
          : AudioRecorder(
              onStop: (path) {
                print('Recorded file path: $path');
                setState(() {
                  audioPath = path;
                  showPlayer = true;
                });
              },
            ),
        ),
      ),
    );
  }
}

class AudioRecorder extends StatefulWidget {
  final void Function(String path) onStop;

  const AudioRecorder({Key? key, required this.onStop}) : super(key: key);

  @override
  State<AudioRecorder> createState() => _AudioRecorderState();
}

class _AudioRecorderState extends State<AudioRecorder> {
  bool wasItPlaying = false;
  bool actionable = false;

  String theLabel = '';
  double theValue = 0.0;

  VoiceCommandRecognition? voiceCommandRecognition;
  RealtimeHandler realtimeHandler = RealtimeHandler();

  void updateDynamicText() async {
    //   PredictionResults prediction = await voiceCommandRecognition!.analyseAudio(audiopath!);
    //   // setState(() {
    //     // theLabel = "Updated Text at ${DateTime.now()}";
    //   theLabel = prediction.theLabel;
    //   theValue = prediction.theValue;
    //   // });
    await realtimeHandler.recordHandler();
    final files = await realtimeHandler.realtimeDirContent();
    print(files.length);
  }

  void startInterval() {
    const Duration initialDelay = Duration(seconds: 1); // Initial delay before first execution
    const Duration intervalDuration = Duration(seconds: 1); // Interval between executions

    Timer(initialDelay, () {
      // Start the interval
      updateDynamicText(); // Update the text immediately
      Timer.periodic(intervalDuration, (timer) {
        updateDynamicText(); // Update the text at each interval
      });
    });
  }

  @override
  void initState() {
    realtimeHandler.initState();
    voiceCommandRecognition = VoiceCommandRecognition();
    startInterval();

    super.initState();
  }

  

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('label: $theLabel'),
            Text('confidence: $theValue'),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    realtimeHandler.dispose();
    super.dispose();
  }
}