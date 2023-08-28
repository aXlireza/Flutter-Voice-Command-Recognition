/*
 * Copyright 2023 The TensorFlow Authors. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *             http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
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
  static const String _modelPath_yamnet = 'assets/yamnet.tflite';
  static const String _labelPath_yamnet = 'assets/yamnet.txt';

  Interpreter? _interpreter;
  Interpreter? _interpreter_yamnet;
  List<String>? _labels;
  List<String>? _labels_yamnet;

  VoiceCommandRecognition() {
    _loadModel();
    _loadLabels();
    log('Done.');
  }

  Future<void> _loadModel() async {
    log('Loading yamnet interpreter options...');
    final interpreterOptions_yamnet = InterpreterOptions();
    // Use XNNPACK Delegate
    if (Platform.isAndroid) interpreterOptions_yamnet.addDelegate(XNNPackDelegate());
    // Use Metal Delegate
    if (Platform.isIOS) interpreterOptions_yamnet.addDelegate(GpuDelegate());
    log('Loading yamnet interpreter...');
    _interpreter_yamnet = await Interpreter.fromAsset(_modelPath_yamnet);

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
    final labelsRaw_yamnet = await rootBundle.loadString(_labelPath_yamnet);
    _labels_yamnet = labelsRaw_yamnet.split('\n');

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

  Future<PredictionResults> yamnetAudio(String audiopath) async {

    PredictionResults output = await _runInference_yamnet(audiopath);

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

  Future<PredictionResults> _runInference(
    String audiopath,
  ) async {
    log('Running inference...');
    List<List<List<double>>> input = await getSpectrogram(audiopath);
    final output = [List<double>.filled(8, 0)];

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

  Future<PredictionResults> _runInference_yamnet(
    String audiopath,
  ) async {
    log('Running inference...');
    List<List<List<double>>> input = await getSpectrogram(audiopath);
    final output = [List<double>.filled(521, 0)];
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
}