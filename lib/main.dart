import 'dart:async';
import 'package:flutter/foundation.dart';
import 'dart:core';
import 'package:flutter/material.dart';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;

import 'package:record/record.dart';
import 'audio_player.dart';



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
  late final tfl.Interpreter interpreter;
  late final List<String> labels;
  // late final IsolateInference isolateInference;
  late tfl.Tensor inputTensor;
  late tfl.Tensor outputTensor;

  bool showPlayer = false;
  String? audioPath;

  @override
  void initState() {
    super.initState();

    showPlayer = false;
    predict();
  }


  void predict() async {
    final options = tfl.InterpreterOptions();

    if (Platform.isAndroid) options.addDelegate(tfl.XNNPackDelegate());
    if (Platform.isIOS) options.addDelegate(tfl.GpuDelegate());

    final labelTxt = await rootBundle.loadString('assets/labels.txt');
    labels = labelTxt.split('\n');
    
    // Load model from assets
    // interpreter = await Interpreter.fromAsset('assets/model.tflite', options: options);
    interpreter = await tfl.Interpreter.fromAsset('assets/model.tflite');
    inputTensor = interpreter.getInputTensors().first;
    outputTensor = interpreter.getOutputTensors().first;
  }


  // def get_spectrogram(waveform):
  //   spectrogram = tf.signal.stft(waveform, frame_length=255, frame_step=128)
  //   spectrogram = tf.abs(spectrogram)
  //   spectrogram = spectrogram[..., tf.newaxis]
  //   return spectrogram


  // def processaudio(address, audiodata):
  //   x = tf.io.read_file(str(address)) if address else audiodata
  //   x, sample_rate = tf.audio.decode_wav(x, desired_channels=1, desired_samples=16000,)
  //   x = tf.squeeze(x, axis=-1)
  //   x = get_spectrogram(x)
  //   x = x[tf.newaxis,...]
  //   return x


void get_spectrogram(String path) async {
  // final wav = await Wav.readFile(path);
  // final audio = normalizeRmsVolume(wav.toMono(), 0.3);
  // const chunkSize = 2048;
  // const buckets = 120;

  // final FFT _fft;
  // final Float64List? _win;
  // final Float64x2List _chunk;
  
  // final chunkSize = _fft.size;
  // if (chunkStride <= 0) chunkStride = chunkSize;
  // for (int i = 0;; i += chunkStride) {
  //   final i2 = i + chunkSize;
  //   if (i2 > input.length) {
  //     int j = 0;
  //     final stop = input.length - i;
  //     for (; j < stop; ++j) {
  //       _chunk[j] = Float64x2(input[i + j], 0);
  //     }
  //     for (; j < chunkSize; ++j) {
  //       _chunk[j] = Float64x2.zero();
  //     }
  //   } else {
  //     for (int j = 0; j < chunkSize; ++j) {
  //       _chunk[j] = Float64x2(input[i + j], 0);
  //     }
  //   }
  //   _win?.inPlaceApplyWindow(_chunk);
  //   _fft.inPlaceFft(_chunk);
  //   reportChunk(_chunk);
  //   if (i2 >= input.length) {
  //     break;
  //   }
  // }
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
                // preprocess('assets/0.wav');

                // print(inputTensor);
                interpreter.run(inputTensor, outputTensor);
                print(outputTensor);
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
  int _recordDuration = 0;
  Timer? _timer;
  final _audioRecorder = Record();
  StreamSubscription<RecordState>? _recordSub;
  RecordState _recordState = RecordState.stop;
  StreamSubscription<Amplitude>? _amplitudeSub;
  Amplitude? _amplitude;

  @override
  void initState() {
    _recordSub = _audioRecorder.onStateChanged().listen((recordState) {
      setState(() => _recordState = recordState);
    });

    _amplitudeSub = _audioRecorder
        .onAmplitudeChanged(const Duration(milliseconds: 300))
        .listen((amp) => setState(() => _amplitude = amp));

    super.initState();
  }

  Future<void> _start() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        await _audioRecorder.start(
            encoder: AudioEncoder.wav,
            numChannels: 1);
        _recordDuration = 0;

        _startTimer();
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  Future<void> _stop() async {
    _timer?.cancel();
    _recordDuration = 0;

    final path = await _audioRecorder.stop();

    if (path != null) {
      widget.onStop(path);
    }
  }

  Future<void> _pause() async {
    _timer?.cancel();
    await _audioRecorder.pause();
  }

  Future<void> _resume() async {
    _startTimer();
    await _audioRecorder.resume();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                _buildRecordStopControl(),
                const SizedBox(width: 20),
                _buildPauseResumeControl(),
                const SizedBox(width: 20),
                _buildText(),
              ],
            ),
            if (_amplitude != null) ...[
              const SizedBox(height: 40),
              Text('Current: ${_amplitude?.current ?? 0.0}'),
              Text('Max: ${_amplitude?.max ?? 0.0}'),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recordSub?.cancel();
    _amplitudeSub?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  Widget _buildRecordStopControl() {
    late Icon icon;
    late Color color;

    if (_recordState != RecordState.stop) {
      icon = const Icon(Icons.stop, color: Colors.red, size: 30);
      color = Colors.red.withOpacity(0.1);
    } else {
      final theme = Theme.of(context);
      icon = Icon(Icons.mic, color: theme.primaryColor, size: 30);
      color = theme.primaryColor.withOpacity(0.1);
    }

    return ClipOval(
      child: Material(
        color: color,
        child: InkWell(
          child: SizedBox(width: 56, height: 56, child: icon),
          onTap: () {
            (_recordState != RecordState.stop) ? _stop() : _start();
          },
        ),
      ),
    );
  }

  Widget _buildPauseResumeControl() {
    if (_recordState == RecordState.stop) {
      return const SizedBox.shrink();
    }

    late Icon icon;
    late Color color;

    if (_recordState == RecordState.record) {
      icon = const Icon(Icons.pause, color: Colors.red, size: 30);
      color = Colors.red.withOpacity(0.1);
    } else {
      final theme = Theme.of(context);
      icon = const Icon(Icons.play_arrow, color: Colors.red, size: 30);
      color = theme.primaryColor.withOpacity(0.1);
    }

    return ClipOval(
      child: Material(
        color: color,
        child: InkWell(
          child: SizedBox(width: 56, height: 56, child: icon),
          onTap: () {
            (_recordState == RecordState.pause) ? _resume() : _pause();
          },
        ),
      ),
    );
  }

  Widget _buildText() {
    if (_recordState != RecordState.stop) {
      return _buildTimer();
    }

    return const Text("Waiting to record");
  }

  Widget _buildTimer() {
    final String minutes = _formatNumber(_recordDuration ~/ 60);
    final String seconds = _formatNumber(_recordDuration % 60);

    return Text(
      '$minutes : $seconds',
      style: const TextStyle(color: Colors.red),
    );
  }

  String _formatNumber(int number) {
    String numberStr = number.toString();
    if (number < 10) {
      numberStr = '0$numberStr';
    }

    return numberStr;
  }

  void _startTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      setState(() => _recordDuration++);
    });
  }
}