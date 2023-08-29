import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'audio_handler.dart';
import 'copy.dart';

class RealtimeRecordingHandler {
  int recordedRealtimeCount = 0;
  AudioHalper audioHalper = AudioHalper();
  int chupLength = 1;

  get chuplength => chupLength;
  get getaudioHalper => audioHalper;
  get getrecordedRealtimeCount => recordedRealtimeCount;

  Future<String> directoryPath({String path=""}) async{
    Directory directory = await getApplicationDocumentsDirectory();
    String address = "${directory.path}/realtime";
    if (path.isNotEmpty) address+="/$path";
    return address;
  }

  Future<Directory> handleRealtimeDir({String path=""}) async{
    String realtimeDirAddress = await directoryPath(path:path);
    Directory realtimeDir = Directory(realtimeDirAddress);
    return realtimeDir;
  }

  Future<void> setupRealtimeDir() async {
    String realtimeDirAddress = await directoryPath();
    Directory realtimeDir = Directory(realtimeDirAddress);

    if (!realtimeDir.existsSync()) {
      realtimeDir.create()
      .then((Directory directory) {
        print('Directory created at ${directory.path}');
      })
      .catchError((error) {
        print('Error creating directory: $error');
      });
    }

    String realtimeDirtmpAddress = await directoryPath(path: 'tmp');
    Directory realtimeTmpDir = Directory(realtimeDirtmpAddress);

    if (!realtimeTmpDir.existsSync()) {
      realtimeTmpDir.create()
      .then((Directory directory) {
        print('Directory created at ${directory.path}');
      })
      .catchError((error) {
        print('Error creating directory: $error');
      });
    }
  }

  Future<void> recordHandler() async {
    print("recordHandler INIT");
    await recordChunk();
    await chunksController();
    // await generateRealtimeWav();
    print("recordHandler DONE");
  }

  Future<void> recordChunk() async {
    Directory realtimeDir = await handleRealtimeDir(path:'tmp');
    int recordlength = 1000~/chupLength;
    print("record $recordedRealtimeCount init");
    await audioHalper.start('${realtimeDir.path}/$recordedRealtimeCount.wav');
    await Future.delayed(Duration(milliseconds: recordlength));
    print("record $recordedRealtimeCount end");
    await stopRecording();

    final DateTime now = DateTime.now();
    print('Current timestamp: $now');
  }

  Future<void> stopRecording() async {
    await audioHalper.stop();
    recordedRealtimeCount++;
  }

  Future<void> chunksController() async{
    // check the realtime_dir length and remove the overflows
    Directory realtimeDir = await handleRealtimeDir(path:'tmp');
    List<FileSystemEntity> files = realtimeDir.listSync();
    sortfiles(files);
    if (files.length >= chupLength) {
      int overflowCount = files.length-chupLength;
      for (var i = 0; i < overflowCount; i++) {
        await files[i].delete();
      }
    }
  }

  Future<List<FileSystemEntity>> realtimeDirContent() async {
    Directory realtimeDir = await handleRealtimeDir();
    
    String realtimeDirpath = realtimeDir.path;
    final checkrealtime = await File("$realtimeDirpath/realtime.wav").exists();
    if (checkrealtime) {
      File therealtimefile = File("$realtimeDirpath/realtime.wav");
      int filesize = await therealtimefile.length();
      print("Realtime file size: $filesize");
    }

    String actualrecordFilePath = recordedRealtimeCount.toString();
    print("The recordcounter: $actualrecordFilePath");

    Directory realtimeDirTmp = await handleRealtimeDir(path: 'tmp');
    List<FileSystemEntity> files = realtimeDirTmp.listSync();
    sortfiles(files);
    return files;
  }

  void sortfiles(List<FileSystemEntity> files) {
    files.sort((a, b) {
      String filenameA = a.uri.pathSegments.last;
      String filenameB = b.uri.pathSegments.last;
      int numericA = int.tryParse(filenameA.split('.').first) ?? 0;
      int numericB = int.tryParse(filenameB.split('.').first) ?? 0;
      return numericA.compareTo(numericB);
    });
  }

  Future<List<FileSystemEntity>> allRealtimeDirContent() async {
    Directory realtimeDir = await handleRealtimeDir();
    List<FileSystemEntity> files = realtimeDir.listSync();
    sortfiles(files);
    return files;
  }

  Future<void> generateSampleSingleSecondWav() async {
    Directory realtimeDir = await handleRealtimeDir();
    await audioHalper.start('${realtimeDir.path}/sample.wav');
    await Future.delayed(const Duration(seconds: 1));
    await stopRecording();
  }

  Future<void> generateRealtimeWav() async {
    Directory realtimeDir = await handleRealtimeDir();
    List<FileSystemEntity> files = await realtimeDirContent();
    String outputPath = "${realtimeDir.path}/realtime.wav";
    if (files.length >= chupLength) {
      List<List<int>> audioDataList = [];
      List<FileSystemEntity> inputFiles = files.sublist(files.length - chupLength);
      
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

      await copyWavHeader();
      print('realtime audio generated');
    } else {
      generateEmptyWavFile(outputPath);
    }

    await copyRealtimeFile(count: (recordedRealtimeCount-1).toString());
    await copySampleFile();
  }

  Future<void> copyWavHeader() async {
    Directory realtimeDir = await handleRealtimeDir();

    // Open the source file for reading in binary mode
    final sourceFile = File('${realtimeDir.path}/sample.wav');
    final sourceBytes = sourceFile.readAsBytesSync();

    // Read header information (first 44 bytes)
    final headerBytes = sourceBytes.sublist(0, 44);

    // Open the destination file for writing in binary mode
    final destinationFile = File('${realtimeDir.path}/realtime.wav');
    final destinationSink = destinationFile.openWrite();

    // Write the copied header to the destination file
    destinationSink.add(headerBytes);

    // Close the destination file
    destinationSink.close();
  }

  void generateEmptyWavFile(String outputPath) {
    // WAV header information
    int sampleRate = 16000;
    int numChannels = 1;    // Mono
    int bitsPerSample = 16; // 16-bit audio

    // Calculate audio data size and total file size
    int audioDataSize = (sampleRate * numChannels * bitsPerSample ~/ 8).toInt();
    int fileSize = 44 + audioDataSize;

    // Create a byte buffer for the WAV header
    Uint8List wavHeader = Uint8List(44);

    // RIFF chunk descriptor
    wavHeader.setAll(0, 'RIFF'.codeUnits);
    ByteData.view(wavHeader.buffer, 4, 4).setUint32(0, fileSize, Endian.little);
    wavHeader.setAll(8, 'WAVE'.codeUnits);

    // Format subchunk
    wavHeader.setAll(12, 'fmt '.codeUnits);
    ByteData.view(wavHeader.buffer, 16, 4).setUint32(0, 16, Endian.little); // Subchunk1Size
    ByteData.view(wavHeader.buffer, 20, 2).setUint16(0, 1, Endian.little); // AudioFormat
    ByteData.view(wavHeader.buffer, 22, 2).setUint16(0, numChannels, Endian.little); // NumChannels
    ByteData.view(wavHeader.buffer, 24, 4).setUint32(0, sampleRate, Endian.little); // SampleRate
    ByteData.view(wavHeader.buffer, 28, 4).setUint32(0, sampleRate * numChannels * bitsPerSample ~/ 8, Endian.little); // ByteRate
    ByteData.view(wavHeader.buffer, 32, 2).setUint16(0, numChannels * bitsPerSample ~/ 8, Endian.little); // BlockAlign
    ByteData.view(wavHeader.buffer, 34, 2).setUint16(0, bitsPerSample, Endian.little); // BitsPerSample

    // Data subchunk
    wavHeader.setAll(36, 'data'.codeUnits);
    ByteData.view(wavHeader.buffer, 40, 4).setUint32(0, audioDataSize, Endian.little); // Subchunk2Size

    // Write the WAV header to the output file
    File outputFile = File(outputPath);
    outputFile.writeAsBytesSync(wavHeader);
  }

  Future<void> emptyRealtimeDir() async{
    void removeFiles(List<FileSystemEntity> files) {
      for (FileSystemEntity file in files) {
        if (file is File) {
          file.deleteSync();
          print('Deleted file: ${file.path}');
        }
      }
    }
    List<FileSystemEntity> files = await allRealtimeDirContent();
    removeFiles(files);
    files = await realtimeDirContent();
    removeFiles(files);
  }

  Future<void> initState() async {
    await setupRealtimeDir();
    await emptyRealtimeDir();
    // await generateSampleSingleSecondWav();
    audioHalper.initState();
  }
  
  void dispose() {
    audioHalper.dispose();
  }
}