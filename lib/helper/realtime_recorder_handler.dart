import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'audio_handler.dart';

class RealtimeRecordingHandler {
  int recordedRealtimeCount = 0;
  AudioHalper audioHalper = AudioHalper();
  int CHUPLENGTH = 6;

  get getaudioHalper => audioHalper;

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
  }

  Future<void> recordHandler() async {
    print("recordHandler INIT");
    await recordChunk();
    await chunksController();
    await generateRealtimeWav();
    print("recordHandler DONE");
  }

  Future<void> recordChunk() async {
    Directory realtimeDir = await handleRealtimeDir(path:'tmp');
    int recordlength = 1000~/CHUPLENGTH;
    await audioHalper.start('${realtimeDir.path}/$recordedRealtimeCount.wav');
    await Future.delayed(Duration(milliseconds: recordlength));
    await audioHalper.stop();
    recordedRealtimeCount++;
  }

  Future<void> chunksController() async{
    // check the realtime_dir length and remove the overflows
    Directory realtimeDir = await handleRealtimeDir(path:'tmp');
    List<FileSystemEntity> files = realtimeDir.listSync();
    sortfiles(files);
    if (files.length >= CHUPLENGTH) {
      int overflowCount = files.length-CHUPLENGTH;
      for (var i = 0; i < overflowCount; i++) {
        await files[i].delete();
      }
    }
  }

  Future<List<FileSystemEntity>> realtimeDirContent() async {
    Directory realtimeDir = await handleRealtimeDir(path: 'tmp');
    List<FileSystemEntity> files = realtimeDir.listSync();
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

  Future<void> generateRealtimeWav() async {
    Directory realtimeDir = await handleRealtimeDir();
    List<FileSystemEntity> files = await realtimeDirContent();
    String outputPath = "${realtimeDir.path}/realtime.wav";
    if (files.length >= CHUPLENGTH) {
      List<List<int>> audioDataList = [];
      List<FileSystemEntity> inputFiles = files.sublist(files.length - CHUPLENGTH);
      
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
      print('realtime audio generated');
    } else {
      generateEmptyWavFile(outputPath);
    }
  }

  void generateEmptyWavFile(String outputPath) {
    // WAV header information
    int sampleRate = 44100; // Samples per second (44.1 kHz)
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
    audioHalper.initState();
  }
  
  void dispose() {
    audioHalper.dispose();
  }
}