import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'audio_handler.dart';

class RealtimeHandler {
  int recordedRealtimeCount = 0;
  AudioHalper audioHalper = AudioHalper();
  int CHUPLENGTH = 6;

  Future<Directory> handleRealtimeDir({String path=""}) async{
    // address to realtime dir, create if not found, drop any file in the directory
    final directory = await getApplicationDocumentsDirectory();
    String realtimeDirAddress = "${directory.path}/realtime";
    if (path.isNotEmpty) realtimeDirAddress+="/$path";
    Directory realtimeDir = Directory(realtimeDirAddress);

    if (realtimeDir.existsSync()) {
      // EMPTY THE FILES
    } else {
      realtimeDir.create()
      .then((Directory directory) {
        print('Directory created at ${directory.path}');
      })
      .catchError((error) {
        print('Error creating directory: $error');
      });
    }
    return realtimeDir;
  }

  Future<void> recordHandler() async {
    int recordlength = 1000~/CHUPLENGTH;

    Directory realtimeDir = await handleRealtimeDir(path:'tmp');
    print(recordlength);
    audioHalper.start('${realtimeDir.path}/$recordedRealtimeCount.wav');
    recordedRealtimeCount++;

    // check the realtime_dir length and remove the overflows
    List<FileSystemEntity> files = realtimeDir.listSync();
    files.sort((a, b) {
      String filenameA = a.uri.pathSegments.last;
      String filenameB = b.uri.pathSegments.last;
      int numericA = int.tryParse(filenameA.split('.').first) ?? 0;
      int numericB = int.tryParse(filenameB.split('.').first) ?? 0;
      return numericA.compareTo(numericB);
    });
    if (files.length >= CHUPLENGTH) {
      int overflowCount = files.length-CHUPLENGTH;
      for (var i = 0; i < overflowCount; i++) {
        await files[i].delete();
      }
    }
    // CHECKPOINT
    await generateRealtimeWav();
    print(files.length);
  }

  Future<List<FileSystemEntity>> realtimeDirContent() async {
    Directory realtimeDir = await handleRealtimeDir(path: 'tmp');
    return realtimeDir.listSync();
  }

  Future<void> generateRealtimeWav() async {
    Directory realtimeDir = await handleRealtimeDir();
    List<FileSystemEntity> files = await realtimeDirContent();
    List<List<int>> audioDataList = [];
    List<FileSystemEntity> inputFiles = files.sublist(files.length - 5);
    String outputPath = "${realtimeDir.path}realtime.wav";
    
    // Read audio data from each input file
    for (FileSystemEntity file in inputFiles) {
      
      List<int> audioData = File(file.path).readAsBytesSync();
      audioDataList.add(audioData);
    }

    // Write concatenated audio data to output file
    File outputFile = File(outputPath);
    var output = outputFile.openWrite(mode: FileMode.write);

    // Write the header from the first file
    output.add(audioDataList.first.sublist(0, 44));

    // Write the audio data from each file (excluding header)
    for (var audioData in audioDataList) {
      output.add(audioData.sublist(44)); // Exclude header
    }

    output.close();
  }

  Future<void> emptyRealtimeDir() async{
    Directory realtimeDir = await handleRealtimeDir(path:'tmp');
    List<FileSystemEntity> files = realtimeDir.listSync();

    for (FileSystemEntity file in files) {
      if (file is File) {
        file.deleteSync();
        print('Deleted file: ${file.path}');
      }
    }
  }

  get getaudioHalper => audioHalper;

  Future<void> initState() async {
    await emptyRealtimeDir();
    audioHalper.initState();
  }
  void dispose() {
    audioHalper.dispose();
  }
}