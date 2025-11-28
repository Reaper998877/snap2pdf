import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PDFHelper {
  static const platform = MethodChannel('com.sks.snap2pdf/pdf'); // MethodChannel for Android
  final MethodChannel _channel = const MethodChannel(
    'com.sks.snap2pdf/file',
  ); // // MethodChannel for iOS
  String pathOnIOS = "";

  Future<bool> savePDFonAndroid(pdfBytes, pdfName, context) async {
    // MediaStore APIs work seamlessly on Android 10+ when your targetSdkVersion is 29 or higher.
    try {
      // Call a platform-specific method to save the PDF file.
      final result = await platform.invokeMethod(
        'savePdf', // Key to invoke the method ( in MainActivity.java ) on the native platform.
        // Pass the PDF data (as bytes) and the filename to the native method.
        {'data': pdfBytes, 'filename': "$pdfName.pdf"},
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result)));

      return true;
    } on PlatformException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save PDF: ${e.message}')),
      );
      return false;
    }
  }

  Future<bool> savePDFonIOS(pdfBytes, pdfName, context) async {
    // User is allowed to choose the location for saving PDF file.
    // UIDocumentPickerViewController is used to save file.
    try {
      // Call the native method
      final result = await _channel.invokeMethod(
        'saveFileToPicker', // The method ( in AppDelegate.swift ) name to invoke on the native platform.
        {
          // Pass the PDF data (as bytes) and the filename to the native method.
          'fileName': "$pdfName.pdf", 'fileData': pdfBytes,
        },
      );

      // Set the pathOnIOS where the PDF is saved.
      pathOnIOS = result;
      debugPrint('File saved at: $result');

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('File saved at: $result')));
      return true;
    } on PlatformException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save PDF: ${e.message}')),
      );
      return false;
    }
  }
}
