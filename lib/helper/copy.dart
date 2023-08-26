import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<void> copytmpFiles() async {
  try {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String sourceDirPath = '${appDocDir.path}/realtime/tmp';

    // Get the external storage directory
    Directory? externalDirectory = await getExternalStorageDirectory();
    String destinationDirPath = '${externalDirectory?.path}';

    // // Create the destination directory
    // await Directory(destinationDirPath).create(recursive: true);

    // Copy the entire directory recursively
    await _copyDirectory(Directory(sourceDirPath), Directory(destinationDirPath));
    // await _copyDirectory(File(sourceDirPath), File(destinationDirPath));

    print('Directory copied to external storage: $destinationDirPath');
  } catch (e) {
    print('Error: $e');
  }
}

Future<void> copyRealtimeFile({String count="0"}) async {
  try {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String sourceDirPath = '${appDocDir.path}/realtime/realtime.wav';

    // Get the external storage directory
    Directory? externalDirectory = await getExternalStorageDirectory();
    String destinationDirPath = '${externalDirectory?.path}/realtime$count.wav';

    // // Delete the destination directory if it exists
    // if (await Directory(destinationDirPath).exists()) {
    //   await _deleteDirectory(Directory(destinationDirPath));
    // }

    // // Create the destination directory
    // await Directory(destinationDirPath).create(recursive: true);

    // Copy the entire directory recursively
    // await _copyDirectory(Directory(sourceDirPath), Directory(destinationDirPath));
    await _copyFile(File(sourceDirPath), File(destinationDirPath));

    print('Directory copied to external storage: $destinationDirPath');
  } catch (e) {
    print('Error: $e');
  }
}

Future<void> copySampleFile() async {
  try {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String sourceDirPath = '${appDocDir.path}/realtime/sample.wav';

    // Get the external storage directory
    Directory? externalDirectory = await getExternalStorageDirectory();
    String destinationDirPath = '${externalDirectory?.path}/sample.wav';

    // // Delete the destination directory if it exists
    // if (await Directory(destinationDirPath).exists()) {
    //   await _deleteDirectory(Directory(destinationDirPath));
    // }

    // // Create the destination directory
    // await Directory(destinationDirPath).create(recursive: true);

    // Copy the entire directory recursively
    // await _copyDirectory(Directory(sourceDirPath), Directory(destinationDirPath));
    await _copyFile(File(sourceDirPath), File(destinationDirPath));

    print('Directory copied to external storage: $destinationDirPath');
  } catch (e) {
    print('Error: $e');
  }
}

// Future<void> _deleteDirectory(Directory directory) async {
//   await for (var entity in directory.list(recursive: true)) {
//     if (entity is File) {
//       await entity.delete();
//     } else if (entity is Directory) {
//       await entity.delete(recursive: true);
//     }
//   }
// }

Future<void> _copyFile(File source, File destination) async {
  String newFilePath = destination.path;
  await source.copy(newFilePath);
}

Future<void> _copyDirectory(Directory source, Directory destination) async {
  await for (var entity in source.list()) {
    if (entity is File) {
      // Copy files
      String newFilePath = '${destination.path}/${entity.uri.pathSegments.last}';
      await entity.copy(newFilePath);
    } else if (entity is Directory) {
      // Recursively copy subdirectories
      String newDirPath = '${destination.path}/${entity.uri.pathSegments.last}';
      await _copyDirectory(entity, Directory(newDirPath));
    }
  }
}