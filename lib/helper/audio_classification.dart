import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
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

  Interpreter? _interpreter;
  List<String>? _labels;

  VoiceCommandRecognition() {
    _loadModel();
    _loadLabels();
    log('Done.');
  }

  Future<void> _loadModel() async {
    log('Loading interpreter options...');
    final interpreterOptions = InterpreterOptions();

    // Use XNNPACK Delegate
    if (Platform.isAndroid) {
      interpreterOptions.addDelegate(XNNPackDelegate());
    }

    // Use Metal Delegate
    if (Platform.isIOS) {
      interpreterOptions.addDelegate(GpuDelegate());
    }

    log('Loading interpreter...');
    _interpreter =
        await Interpreter.fromAsset(_modelPath, options: interpreterOptions);
  }

  Future<void> _loadLabels() async {
    log('Loading labels...');
    final labelsRaw = await rootBundle.loadString(_labelPath);
    _labels = labelsRaw.split('\n');
  }

  Future<PredictionResults> analyseAudioBytes(Uint8List audiobytes) async {

    PredictionResults output = await _runInferenceBytes(audiobytes);

    log('Processing outputs...');

    return output;
  }

  Future<PredictionResults> analyseAudio(String audiopath) async {

    PredictionResults output = await _runInference(audiopath);

    log('Processing outputs...');

    return output;
  }

  Future<PredictionResults> _runInferenceBytes(
    Uint8List audiobytes,
  ) async {
    log('Running inference...');
    late Tensor inputTensor;
    late Tensor outputTensor;
    List<List<List<double>>> input = await getSpectrogramByBytes(audiobytes);
    final output = [List<double>.filled(26, 0)];

    inputTensor = _interpreter!.getInputTensors().first;
    outputTensor = _interpreter!.getOutputTensors().first;

    _interpreter!.run([input], output);

    MapEntry<int, double> entryWithLargestNumber = output[0].asMap().entries.reduce((prev, curr) {
      return curr.value > prev.value ? curr : prev;
    });
    
    int largestNumberIndex = entryWithLargestNumber.key;
    double largestNumber = entryWithLargestNumber.value;

    print(_labels![largestNumberIndex]);
    return PredictionResults(
      _labels![largestNumberIndex],
      output[0][largestNumberIndex]
    );
  }

  Future<PredictionResults> _runInference(
    String audiopath,
  ) async {
    log('Running inference...');
    late Tensor inputTensor;
    late Tensor outputTensor;
    List<List<List<double>>> input = await getSpectrogram(audiopath);
    final output = [List<double>.filled(8, 0)];

    inputTensor = _interpreter!.getInputTensors().first;
    outputTensor = _interpreter!.getOutputTensors().first;

    _interpreter!.run([input], output);

    MapEntry<int, double> entryWithLargestNumber = output[0].asMap().entries.reduce((prev, curr) {
      return curr.value > prev.value ? curr : prev;
    });
    
    int largestNumberIndex = entryWithLargestNumber.key;
    double largestNumber = entryWithLargestNumber.value;

    print(_labels![largestNumberIndex]);
    return PredictionResults(
      _labels![largestNumberIndex],
      output[0][largestNumberIndex]
    );
  }
}