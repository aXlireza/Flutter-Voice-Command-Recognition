import 'dart:async';

import 'package:record/record.dart';

class AudioHalper {
  final _audioRecorder = Record();
  RecordState _recordState = RecordState.stop;
  int _recordDuration = 0;
  Timer? _timer;
  StreamSubscription<RecordState>? _recordSub;
  StreamSubscription<Amplitude>? _amplitudeSub;
  Amplitude? _amplitude;

  void initState() {
    _recordSub = _audioRecorder.onStateChanged().listen((newrecordState) {
      // setState(() => _recordState = recordState);
      recordState = newrecordState;
    });

    _amplitudeSub = _audioRecorder
        .onAmplitudeChanged(const Duration(milliseconds: 300))
        // .listen((amp) => setState(() => _amplitude = amp));
        .listen((amp) => amplitude = amp);
  }

  RecordState get recordState => _recordState;
  int get recordDuration => _recordDuration;
  Amplitude? get amplitude => _amplitude;

  set recordState(state) => _recordState = state;
  set recordDuration(time) => _recordDuration = time;
  set amplitude(amp) => _amplitude = amp;

  void startTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      // setState(() => _recordDuration++);
      recordDuration = recordDuration+1;
    });
  }

  Future<void> start(String path) async {
    try {
      if (await _audioRecorder.hasPermission()) {
        await _audioRecorder.start(
            path: path,
            encoder: AudioEncoder.wav,
            numChannels: 1,
            samplingRate: 16000);
        _recordDuration = 0;
        startTimer();
      }
    } catch (e) {
      print(e);
    }
  }

  Future<String?> stop() async {
    _timer?.cancel();
    _recordDuration = 0;

    final path = await _audioRecorder.stop();

    if (path != null) {
      // voiceCommandRecognition!.analyseAudio(path);
      // widget.onStop(path);
    }

    return path;
  }

  Future<void> pause() async {
    _timer?.cancel();
    await _audioRecorder.pause();
  }

  Future<void> resume() async {
    startTimer();
    await _audioRecorder.resume();
  }

  void dispose() {
    _timer?.cancel();
    _recordSub?.cancel();
    _amplitudeSub?.cancel();
    _audioRecorder.dispose();
  }
  
}