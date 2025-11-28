import Flutter
import UIKit

// The main entry point for the iOS application.
@main
@objc class AppDelegate: FlutterAppDelegate {

  // Override the application's launch method to set up a custom FlutterMethodChannel.
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    // Get the root Flutter view controller.
    let controller = window?.rootViewController as! FlutterViewController

    // Create a method channel for communicating between Flutter and iOS native code.
    let channel = FlutterMethodChannel(name: "com.sks.snap2pdf/file", binaryMessenger: controller.binaryMessenger)

    // Set up a handler for method calls from Flutter.
    channel.setMethodCallHandler { [weak self] (call, result) in
        // Handle the "saveFileToPicker" method call from Flutter.
          if call.method == "saveFileToPicker" {
            // Extract arguments passed from Flutter.
            guard let args = call.arguments as? [String: Any],
                  let fileName = args["fileName"] as? String,
                  let fileData = args["fileData"] as? FlutterStandardTypedData else {
                // Return an error if arguments are invalid.
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
                return
            }
            // Call a helper function to handle file saving and exporting.
            self?.saveFileToPicker(fileName: fileName, fileData: fileData.data, result: result)
        }
          else {
            // Return "not implemented" for unsupported methods.
            result(FlutterMethodNotImplemented)
        }
    }

    // Continue with the default app launch process.
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)

  }

  // Helper method to save a file and present the iOS document picker for exporting the file.
    private func saveFileToPicker(fileName: String, fileData: Data, result: @escaping FlutterResult) {
        // Get the temporary directory for saving the file.
        let tempDirectory = FileManager.default.temporaryDirectory

        // Create a temporary file URL with the provided file name.
        let tempFileURL = tempDirectory.appendingPathComponent(fileName)

        // Save the file URL for later use (if needed).
        // lastSavedFileURL = tempFileURL

        do {
            // Write the file data to the temporary file.
            try fileData.write(to: tempFileURL)

            // Present the Document Picker
            // Create a document picker for exporting the file.
            let documentPicker = UIDocumentPickerViewController(forExporting: [tempFileURL])
            documentPicker.delegate = self  // Set the delegate to handle document picker actions.

            // Handle the completion of the document picker operation.
            documentPicker.completionHandler = { (urls) in
                if let savedURL = urls?.first {
                    // Return the saved file path back to Flutter.
                    result(savedURL.path)
                } else {
                    // Return an error if the file could not be saved.
                    result(FlutterError(code: "FILE_PICKER_ERROR", message: "Failed to save file", details: nil))
                }
            }
            // Present the document picker to the user.
            // Presents a UIDocumentPickerViewController to let the user export or save the file.
            self.window?.rootViewController?.present(documentPicker, animated: true, completion: nil)
        } catch {
            // Return an error if the file could not be saved temporarily.
            result(FlutterError(code: "FILE_SAVE_ERROR", message: "Failed to save file temporarily", details: error.localizedDescription))
        }
    }
}
