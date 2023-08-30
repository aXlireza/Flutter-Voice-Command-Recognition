import 'dart:core';
import 'dart:io';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:voice_command/spectrogram.dart';
import 'action.dart';
import 'audio_classification.dart';
import 'realtime_recorder_handler.dart';

class Realtime {
  bool wasItPlaying = false;
  bool actionable = false;

  VoiceCommandRecognition? voiceCommandRecognition;
  RealtimeRecordingHandler realtimeRecordingHandler = RealtimeRecordingHandler();

  final _audioPlayer = ap.AudioPlayer()..setReleaseMode(ReleaseMode.stop);

  bool isMusicPlaying() {
    return false;
  }

  Future<void> predictRealtime(String realtimepath) async {
    await realtimeRecordingHandler.recordHandler();

    String audioCount = (realtimeRecordingHandler.getrecordedRealtimeCount-1).toString();
    String audioPath = "$realtimepath/tmp/$audioCount.wav";
    Float64List audio = await getWavData(audioPath);

    PredictionResults yamnetPrediction = await voiceCommandRecognition!.yamnetAudio(audio);
    PredictionResults prediction = await voiceCommandRecognition!.analyseAudio(audio);
    
    print("prediction label: "+prediction.theLabel);
    print("prediction value: "+prediction.theValue.toString());
    // is the audio speech at all and not noise?
    // then verify the high confidance in prediction
    if (yamnetPrediction.theLabel.contains("speech") == true && prediction.theLabel.contains("noise") == false && prediction.theValue == 1.0) {
      print("VALID");
      if (actionable == true && prediction.theLabel != 'ava') {
        actionable = false;
        if (wasItPlaying == true) {
          processCommand(prediction.theLabel);
          print("DEACTIVATED");
        }
      } else if (actionable == false && prediction.theLabel == 'ava') {
        print("ACTIVATED");
        wasItPlaying = isMusicPlaying();
        if (wasItPlaying == true) {
          actionable = true;
        }
      }
    }
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
    List<FileSystemEntity> files = await realtimeRecordingHandler.realtimeDirContent();
    for (var file in files) {
      await _audioPlayer.play(ap.DeviceFileSource(file.path));
      await Future.delayed(const Duration(seconds: 1));

      print(file.path);
    }
  }

  void initState() {
    realtimeRecordingHandler.initState();
    voiceCommandRecognition = VoiceCommandRecognition();
  }

  void dispose() {
    realtimeRecordingHandler.dispose();
  }
}
