package com.sks.snap2pdf;

import android.content.ContentValues;
import android.os.Build;
import android.os.Environment;
import android.provider.MediaStore;
import android.content.Intent;
import android.net.Uri;
import androidx.core.content.FileProvider;
import java.io.File;

import androidx.annotation.NonNull;

import java.io.OutputStream;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

// The MainActivity extends FlutterActivity to embed Flutter into the Android app.
public class MainActivity extends FlutterActivity {
    // Define the MethodChannel name for Flutter-to-Native communication.
    // The channel name ("com.sks.snap2pdf/pdf") matches the one used in Flutter.
    private static final String CHANNEL = "com.sks.snap2pdf/pdf";

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        // Set up the MethodChannel to handle method calls from Flutter.
        // Establishes a communication channel between Flutter (Dart) and native Android code.
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler((call, result) -> {
                    // Handle the "savePdf" method from Flutter.
                    // Checks if the incoming method call from Flutter is for saving a PDF.
                    if (call.method.equals("savePdf")) {
                        // Retrieve arguments passed from Flutter: the PDF data and filename.
                        byte[] bytes = call.argument("data");
                        String filename = call.argument("filename");

                        // Check if arguments are valid.
                        if (bytes != null && filename != null) {
                            // Attempt to save the PDF to the media store or filesystem.
                            boolean success = savePdfToMediaStore(bytes, filename);
                            if (success) {
                                result.success("PDF saved at /Documents/Snap2PDF"); // Inform Flutter of success.
                            } else {
                                result.error("SAVE_FAILED", "Failed to save PDF", null); // Inform Flutter of failure.
                            }
                        } else {
                            // Return an error if arguments are missing or invalid.
                            result.error("INVALID_ARGUMENTS", "Missing arguments", null);
                        }
                    }
                    else {
                        // Inform Flutter that the method is not implemented.
                        result.notImplemented();
                    }
                });
    }

    // Method to save a PDF file to the device's media store or filesystem.
    private boolean savePdfToMediaStore(byte[] data, String filename) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            // Android 10 and above: Use MediaStore with Scoped Storage
            // For Android 10 (API 29) and above: Use MediaStore with Scoped Storage.
            ContentValues contentValues = new ContentValues();
            contentValues.put(MediaStore.MediaColumns.DISPLAY_NAME, filename); // Set the file name.
            contentValues.put(MediaStore.MediaColumns.MIME_TYPE, "application/pdf"); // Set the MIME type.
            contentValues.put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOCUMENTS + "/Snap2PDF"); // Set the file path.

            try {
                // Create an OutputStream to write the file into the MediaStore.
                OutputStream outputStream = getApplicationContext().getContentResolver()
                        .openOutputStream(
                                getApplicationContext().getContentResolver()
                                        .insert(MediaStore.Files.getContentUri("external"), contentValues)
                        );
                if (outputStream != null) {
                    outputStream.write(data);  // Write the PDF data to the OutputStream.
                    outputStream.close(); // Close the stream.
                    return true; // Return true if the save is successful
                }
            } catch (Exception e) {
                e.printStackTrace();  // Print the exception for debugging purposes.
            }
        } else {
            // Android 7 to 9: Use legacy file paths
            // For Android 7 (API 24) to Android 9 (API 28): Use legacy file paths.
            try {
                // Define the directory path in the public "Documents/MyApp" folder.
                String directoryPath = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOCUMENTS) + "/PDF Saver";
                java.io.File directory = new java.io.File(directoryPath);

                // Create the directory if it doesn't exist.
                if (!directory.exists()) {
                    directory.mkdirs();
                }

                // Create the file within the directory.
                java.io.File file = new java.io.File(directory, filename);

                // Write the PDF data to the file.
                OutputStream outputStream = new java.io.FileOutputStream(file);
                outputStream.write(data);
                outputStream.close();
                return true;  // Return true if the save is successful.
            } catch (Exception e) {
                e.printStackTrace();  // Print the exception for debugging purposes.
            }
        }
        return false;  // Return false if the save operation fails.
    }
}
