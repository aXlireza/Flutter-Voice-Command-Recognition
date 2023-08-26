import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:path_provider/path_provider.dart';

class FFmpeg {
  static Future<File> concatenate(List<String> assetPaths) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File("${directory.path}/realtime/realtime.wav");
    final ffm = FlutterFFmpeg();
    final cmd = ["-y"];
    for (var path in assetPaths) {
      final tmp = await copyToTemp(path);
      cmd.add("-i");
      cmd.add(tmp.path);
    }
    cmd.addAll([
      "-filter_complex",
      "[0:a] [1:a] concat=n=${assetPaths.length}:v=0:a=1 [a]",
      "-map",
      " [a]",
      "-c:a",
      "wav",
      file.path
    ]);
    await ffm.executeWithArguments(cmd);
    return file;
  }

  static Future<File> copyToTemp(String path) async {
    Directory tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/${path.split("/").last}');
    if (await tempFile.exists()) {
      return tempFile;
    }
    final bd = await rootBundle.load(path);
    await tempFile.writeAsBytes(bd.buffer.asUint8List(), flush: true);
    return tempFile;
  }
}
