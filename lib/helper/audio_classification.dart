import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import '../spectrogram.dart';

class PredictionResults {
  final String theLabel;
  final double theValue;
  PredictionResults(this.theLabel, this.theValue);
}

class VoiceCommandRecognition {
  static const String _modelPath = 'assets/model.tflite';
  static const String _labelPath = 'assets/labels.txt';
  static const String _modelPathYamnet = 'assets/yamnet.tflite';
  static const String _labelPathYamnet = 'assets/yamnet.txt';

  Interpreter? _interpreter;
  Interpreter? _interpreteryamnet;
  List<String>? _labels;
  List<String>? _labelsyamnet;

  VoiceCommandRecognition() {
    _loadModel();
    _loadLabels();
    log('Done.');
  }

  Future<void> _loadModel() async {
    log('Loading yamnet interpreter...');
    _interpreteryamnet = await Interpreter.fromAsset(_modelPathYamnet);

    log('Loading interpreter options...');
    final interpreterOptions = InterpreterOptions();
    // Use XNNPACK Delegate
    if (Platform.isAndroid) interpreterOptions.addDelegate(XNNPackDelegate());
    // Use Metal Delegate
    if (Platform.isIOS) interpreterOptions.addDelegate(GpuDelegate());
    log('Loading interpreter...');
    _interpreter = await Interpreter.fromAsset(_modelPath, options: interpreterOptions);

  }

  Future<void> _loadLabels() async {
    log('Loading yamnet labels...');
    final labelsRawyamnet = await rootBundle.loadString(_labelPathYamnet);
    _labelsyamnet = labelsRawyamnet.split('\n');

    log('Loading labels...');
    final labelsRaw = await rootBundle.loadString(_labelPath);
    _labels = labelsRaw.split('\n');
  }

  Future<PredictionResults> analyseAudioBytes(Uint8List audiobytes) async {

    PredictionResults output = await _runInferenceBytes(audiobytes);

    log('Processing outputs...');

    return output;
  }

  Future<PredictionResults> analyseAudio(Float64List audio) async {
    PredictionResults output = await _runInference(audio);
    log('Processing outputs...');
    return output;
  }

  Future<PredictionResults> yamnetAudio(Float64List audio) async {
    PredictionResults output = await _runInferenceYamnet(audio);
    log('Processing outputs...');
    return output;
  }

  Future<PredictionResults> _runInferenceBytes(
    Uint8List audiobytes,
  ) async {
    log('Running inference...');
    List<List<List<double>>> input = await getSpectrogramByBytes(audiobytes);
    final output = [List<double>.filled(26, 0)];

    _interpreter!.run([input], output);

    MapEntry<int, double> entryWithLargestNumber = output[0].asMap().entries.reduce((prev, curr) {
      return curr.value > prev.value ? curr : prev;
    });
    
    int largestNumberIndex = entryWithLargestNumber.key;

    print(_labels![largestNumberIndex]);
    return PredictionResults(
      _labels![largestNumberIndex],
      output[0][largestNumberIndex]
    );
  }

  Future<PredictionResults> _runInference(Float64List audio) async {
    log('Running inference...');
    List<List<List<double>>> input = getSpectrogramByAudio(audio);
    List<List<double>> output = [List<double>.filled(8, 0)];

    _interpreter!.run([input], output);

    MapEntry<int, double> entryWithLargestNumber = output[0].asMap().entries.reduce((prev, curr) {
      return curr.value > prev.value ? curr : prev;
    });
    
    int largestNumberIndex = entryWithLargestNumber.key;

    print(_labels![largestNumberIndex]);
    return PredictionResults(
      _labels![largestNumberIndex],
      output[0][largestNumberIndex]
    );
  }

  Future<PredictionResults> _runInferenceYamnet(Float64List input) async {
    log('Running inference...');

    // slightly longer data shift the interpreter to double layers, so we cut it off for now
    if (input.length > 15000) input = input.sublist(0, 15000);

    List<List<double>> scoresOutput = [List<double>.filled(521, 0)];
    List<List<double>> embeddingsOutput = [List<double>.filled(1024, 0)];
    List<List<double>> spectrogramOutput = List.generate(96, (_) => List.from([List<double>.filled(64, 0)][0]));

    final output = {
      0: scoresOutput,
      1: embeddingsOutput,
      2: spectrogramOutput,
    };
    _interpreteryamnet!.runForMultipleInputs([input], output);

    List<double> theoutput = output[0]![0];

    MapEntry<int, double> entryWithLargestNumber = theoutput.asMap().entries.reduce((prev, curr) {
      return curr.value > prev.value ? curr : prev;
    });
    
    int largestNumberIndex = entryWithLargestNumber.key;

    print(_labelsyamnet![largestNumberIndex]);
    return PredictionResults(
      _labelsyamnet![largestNumberIndex],
      theoutput[largestNumberIndex]
    );
  }
}