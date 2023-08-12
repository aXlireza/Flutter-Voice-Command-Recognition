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

  void analyseAudio(String audioPath) {

    final output = _runInference(audioPath);

    log('Processing outputs...');


    // return img.encodeJpg(imageInput);
  }

  Future<List<Object>> _runInference(
    String path,
  ) async {
    log('Running inference...');
    late Tensor inputTensor;
    late Tensor outputTensor;
    List<List<List<double>>> input = await getSpectrogram(path);
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
    return ['a'];
  }
}