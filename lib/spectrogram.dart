import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:fftea/fftea.dart';
import 'package:wav/wav.dart';

Float64List normalizeRmsVolume(List<double> a, double target) {
  final b = Float64List.fromList(a);
  double squareSum = 0;
  for (final x in b) {
    squareSum += x * x;
  }
  double factor = target * math.sqrt(b.length / squareSum);
  for (int i = 0; i < b.length; ++i) {
    b[i] *= factor;
  }
  return b;
}

Uint64List linSpace(int end, int steps) {
  final a = Uint64List(steps);
  for (int i = 1; i < steps; ++i) {
    a[i - 1] = (end * i) ~/ steps;
  }
  a[steps - 1] = end;
  return a;
}

String gradient(double power) {
  const scale = 2;
  const levels = [' ', '░', '▒', '▓', '█'];
  int index = math.log((power * levels.length) * scale).floor();
  if (index < 0) index = 0;
  if (index >= levels.length) index = levels.length - 1;
  return levels[index];
}

Future<Float64List> getWavData(String path) async {
  final wav = await Wav.readFile(path);
  return normalizeRmsVolume(wav.toMono(), 1);  
}

List<List<List<double>>> getSpectrogramByAudio(Float64List audio) {
  List<List<double>> spectrogramArrayTmp = [];
  List<List<List<double>>> spectrogramArray = [];
  const chunkSize = 2048;
  const buckets = 120;
  STFT stft = STFT(chunkSize, Window.hanning(chunkSize));
  Uint64List? logItr;
  stft.run(
    audio,
    (Float64x2List chunk) {
      final amp = chunk.discardConjugates().magnitudes();
      logItr ??= linSpace(amp.length, buckets);
      int i0 = 0;
      spectrogramArrayTmp = [];
      for (final i1 in logItr!) {
        double power = 0;
        if (i1 != i0) {
          for (int i = i0; i < i1; ++i) {
            power += amp[i];
          }
          power /= i1 - i0;
        }
        // stdout.write(gradient(power));
        spectrogramArrayTmp.add([power]);
        i0 = i1;
      }
      spectrogramArray.add(spectrogramArrayTmp);
      // stdout.write('\n');
    },
    chunkSize ~/ 2,
  );
  return spectrogramArray;
}

Future<List<List<List<double>>>> getSpectrogramByBytes(Uint8List audiobytes) async {
  List<List<double>> spectrogramArrayTmp = [];
  List<List<List<double>>> spectrogramArray = [];
  final wav = Wav.read(audiobytes);
  final audio = normalizeRmsVolume(wav.toMono(), 0.3);
  const chunkSize = 2048;
  const buckets = 120;
  final stft = STFT(chunkSize, Window.hanning(chunkSize));
  Uint64List? logItr;
  stft.run(
    audio,
    (Float64x2List chunk) {
      final amp = chunk.discardConjugates().magnitudes();
      logItr ??= linSpace(amp.length, buckets);
      int i0 = 0;
      spectrogramArrayTmp = [];
      for (final i1 in logItr!) {
        double power = 0;
        if (i1 != i0) {
          for (int i = i0; i < i1; ++i) {
            power += amp[i];
          }
          power /= i1 - i0;
        }
        // stdout.write(gradient(power));
        spectrogramArrayTmp.add([power]);
        i0 = i1;
      }
      spectrogramArray.add(spectrogramArrayTmp);
      // stdout.write('\n');
    },
    chunkSize ~/ 2,
  );
  return spectrogramArray;
}

void main(List<String> argv) async {
  if (argv.length != 1) {
    print('Wrong number of args. Usage:');
    print('  dart run spectrogram.dart test.wav');
    return;
  }
  final wav = await Wav.readFile(argv[0]);
  final audio = normalizeRmsVolume(wav.toMono(), 0.3);
  const chunkSize = 2048;
  const buckets = 120;
  final stft = STFT(chunkSize, Window.hanning(chunkSize));
  Uint64List? logItr;
  stft.run(
    audio,
    (Float64x2List chunk) {
      final amp = chunk.discardConjugates().magnitudes();
      logItr ??= linSpace(amp.length, buckets);
      int i0 = 0;
      for (final i1 in logItr!) {
        double power = 0;
        if (i1 != i0) {
          for (int i = i0; i < i1; ++i) {
            power += amp[i];
          }
          power /= i1 - i0;
        }
        stdout.write(gradient(power));
        i0 = i1;
      }
      stdout.write('\n');
    },
    chunkSize ~/ 2,
  );
}
