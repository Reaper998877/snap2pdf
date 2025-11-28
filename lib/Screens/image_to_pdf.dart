import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart'; // Required for 'compute'
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:snap2pdf/Common/pdf_helper.dart';
import 'package:snap2pdf/Common/shared_preferences_helper.dart';
import 'package:snap2pdf/Screens/view_pdf.dart';

// This class creates a custom aspect ratio for an image cropping tool
// (usually used with packages like image_cropper).
// It implements (implements) an interface CropAspectRatioPresetData.
// So this class must provide values required by that interface.
class CropAspectRatioPresetCustom implements CropAspectRatioPresetData {
  @override
  (int, int)? get data => (2, 3);
  // It returns a tuple (2, 3)
  // This represents aspect ratio width : height
  // So this cropping preset means:
  // 2 : 3 aspect ratio
  // For example:
  // 200px width × 300px height
  // 400px width × 600px height
  // Both follow 2:3 ratio.

  @override
  String get name => '2x3 (customized)'; // This is just the label shown in UI.
}

// 1. CAMERA INITIALIZATION
// Global camera list for cameras
List<CameraDescription> cameras =
    []; // Global list of available cameras on device
// ---------------------------------------------------------
// 2. BACKGROUND WORKER (ISOLATE)
// This runs on a separate thread to prevent UI freezing
// ---------------------------------------------------------
Future<Uint8List> generatePdfInBackground(List<String> imagePaths) async {
  // This function converts multiple images into a multi-page PDF, where each image becomes one page.

  // It is called inside compute() → meaning it runs on a background thread to avoid blocking the UI.

  // Creates an empty PDF container where pages will be added.
  final pdf = pw.Document();

  // imagePaths is a list of file paths (List<String>)
  // Process each image one by one
  for (final path in imagePaths) {
    final imageBytes = await File(
      path,
    ).readAsBytes(); // Loads the actual image file into memory as raw bytes (Uint8List)
    final pdfImage = pw.MemoryImage(imageBytes);
    // Converts regular image bytes → a format the PDF library can use.
    // Needed before placing image inside the PDF page.

    pdf.addPage(
      pw.Page(
        // Creates a new PDF page.
        pageFormat: PdfPageFormat.a4, // Uses A4 page size.
        margin: const pw.EdgeInsets.all(20), // Margin for cleaner print
        build: (pw.Context context) {
          return pw.Center(child: pw.Image(pdfImage, fit: pw.BoxFit.contain));
        },
        // Displays the image with:
        // BoxFit.contain = scale image to fit within page, keeping aspect ratio
        // → prevents distortion
        // → avoids cropping
        // Result: Each image is cleanly shown on its own page.
      ),
    );
  }

  return await pdf.save(); // This returns the final PDF as pdfBytes (Uint8List)
}

// ---------------------------------------------------------
// 3. HOME SCREEN (GRID & OPTIONS)
// ---------------------------------------------------------
class ImageToPDFScreen extends StatefulWidget {
  const ImageToPDFScreen({super.key});

  @override
  State<ImageToPDFScreen> createState() => _ImageToPDFScreenState();
}

class _ImageToPDFScreenState extends State<ImageToPDFScreen> {
  final ImagePicker _picker = ImagePicker(); // Allows to pick image
  final List<File> _images = []; // stores all captured / picked images
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    initializeCameraList(); // Calls function to initialize camera list
  }

  void initializeCameraList() async {
    try {
      cameras = await availableCameras(); // Returns all available cameras
    } on CameraException catch (e) {
      debugPrint('Error initializing camera: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("'Error initializing camera")));
      }
    }
  }

  Future<String?> askPdfName() async {
    final TextEditingController pdfNameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return await showDialog<String>(
      context: context,
      builder: (context) {
        return Dialog(
          child: Container(
            height: MediaQuery.sizeOf(context).height * 0.25,
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.0),
              color: Colors.white,
            ),
            child: Form(
              key: formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: pdfNameController,
                    keyboardType: TextInputType.name,
                    style: TextStyle(fontSize: 16, color: Colors.black),
                    decoration: const InputDecoration(
                      labelText: 'Enter PDF name',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter PDF name';
                      }
                      // Regex: Only letters, numbers, underscore
                      final regex = RegExp(r'^[a-zA-Z0-9_-\s]+$');

                      if (!regex.hasMatch(value)) {
                        // Checks if input matches the pattern.
                        return 'Alphabets, numbers, -, _ and space are allowed';
                      }
                      return null;
                    },
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () {
                      if (!formKey.currentState!.validate())
                        return; // Checks if all inputs are valid.

                      Navigator.pop(
                        context,
                        pdfNameController.text.trim(),
                      ); // Closes dialog and returns pdf name.
                    },
                    child: Text("Submit"),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Pick from Gallery
  Future<void> _pickFromGallery() async {
    final List<XFile> pickedFiles = await _picker
        .pickMultiImage(); // Allows user to pick multiple images from device storage and makes list of all those images.
    if (pickedFiles.isNotEmpty) {
      // if list is not empty
      setState(() {
        _images.addAll(pickedFiles.map((e) => File(e.path)));
        // pickedFiles is usually a list of XFile objects returned by: image_picker
        // Convert each XFile → File
        // Add all converted files into _images list
        // map is a iterative function. e is iterator.
      });
    }
  }

  // Open Custom Camera
  Future<void> _openCustomCamera() async {
    if (cameras.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No Camera Found")));
      return;
    }

    // Stores all images captured and returned by the ContinuousCamera screen
    final List<File>? capturedFiles = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ContinuousCameraScreen(
          camera: cameras.first,
        ), // Passes camera as argument
      ),
    );

    if (capturedFiles != null && capturedFiles.isNotEmpty) {
      // Checks if list capturedFiles has images
      setState(() {
        _images.addAll(capturedFiles); // Adds all images in _images list
      });
    }
  }

  // Create PDF Logic
  Future<void> _createPdf() async {
    if (_images.isEmpty) return;

    // show dialog to take pdf name
    final pdfName = await askPdfName();
    if (pdfName == null || pdfName.isEmpty) {
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final imagePaths = _images.map((e) => e.path).toList();
      // _images is a list of File objects.
      // Each File has a path property.
      // .map((e) => e.path) extracts the path of each image.
      // .toList() converts the mapped results into a normal list.

      // Store PDF bytes, which are returned by the function, runned on different thread.
      final pdfBytes = await compute(generatePdfInBackground, imagePaths);

      _showSaveOrShareSheet(pdfBytes, pdfName);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // Crop image based on index
  Future<void> cropSelectedImage(int index) async {
    final imageFile =
        _images[index]; // Finds the image selected by user to crop. Stores that image in imageFile.

    // Open the Image Cropper UI
    // The result (cropped) is a new image file
    final cropped = await ImageCropper().cropImage(
      sourcePath: imageFile.path, // pass the local file path of the image
      compressQuality:
          90, // Slight compression to reduce file size. Maintains good image quality
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: "Crop Image", // Title at the top
          toolbarColor: Colors.white, // White top bar
          toolbarWidgetColor: Colors.black, // Back button icon, text color
          hideBottomControls: false, // Show rotate/scale buttons
          initAspectRatio:
              CropAspectRatioPreset.original, // Start in original ratio
          lockAspectRatio: false, // User can freely resize crop box
          aspectRatioPresets: [
            CropAspectRatioPreset.original, // Original (freeform)
            CropAspectRatioPreset.square, // Square crop (1x1)
            CropAspectRatioPresetCustom(), // Custom 2x3 (Top most class in this file)
          ],
        ),
        IOSUiSettings(
          title: "Crop Image",
        ), // Adds a simple title for iOS crop UI.
      ],
    );

    if (cropped != null) {
      setState(() {
        _images[index] = File(cropped.path); // Replace old with new
      });
    }
    // If the user completes cropping:
    // Convert result path to a File
    // Replace the old image in _images
    // setState() updates UI immediately
  }

  void _showSourceSheet() {
    showModalBottomSheet(
      // A dialog like box comes from bottom of the screen to show options.
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              // Multiple images from gallery
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickFromGallery();
              },
            ),
            ListTile(
              // Multiple images from Camera
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _openCustomCamera();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSaveOrShareSheet(Uint8List pdfBytes, String pdfName) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Save'),
              onTap: () async {
                Navigator.pop(context);
                bool success;

                // Checking the operating system
                if (Platform.isAndroid) {
                  // Android
                  success = await PDFHelper().savePDFonAndroid(
                    pdfBytes,
                    pdfName,
                    context,
                  ); // To save PDF on android
                } else {
                  // iOS
                  success = await PDFHelper().savePDFonIOS(
                    pdfBytes,
                    pdfName,
                    context,
                  ); // To save PDF on iOS
                }

                // Create and write file so that it can be opened in ViewPDF screen.
                final directory =
                    await getApplicationDocumentsDirectory(); // Stores the application documents directory
                String path = directory.path; // Store the path of the directory
                final file = File(
                  '$path/$pdfName.pdf',
                ); // Creates a file on that path
                await file.writeAsBytes(
                  pdfBytes,
                ); // Writes pdfBytes in the file

                String openedDT = DateTime.now()
                    .toLocal()
                    .toString(); // 2025-11-19 12:34:56.789012 // Year-Month-Day Hour:Minute:Second.Millisecond

                await SharedPreferencesHelper().savePDFInfo(
                  pdfName,
                  file.path,
                  openedDT,
                ); // Save the pdf info in recent pdf history

                setState(() {
                  _isGenerating = false; // Removes CircularProgressIndicator
                });

                Future.delayed(Duration(microseconds: 500)); // Wait for 500 ms

                if (success) {
                  // If true navigate to ViewPDF screen.
                  Navigator.pushReplacementNamed(
                    context,
                    '/viewPDF',
                    arguments: ViewPDFArgs(pdfName: pdfName, file: file),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Share'),
              onTap: () async {
                Navigator.pop(context);
                await Printing.sharePdf(
                  // Allows to share pdf
                  bytes: pdfBytes,
                  filename: '$pdfName.pdf',
                );
                setState(() {
                  _isGenerating = false;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image to PDF'),
        actions: [
          if (_images.isNotEmpty)
            IconButton(
              // Clears all images from the list
              icon: const Icon(Icons.delete_sweep),
              onPressed: () => setState(() => _images.clear()),
              tooltip: "Clear All",
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Align(
              alignment: AlignmentGeometry.center,
              child: ElevatedButton.icon(
                onPressed: _showSourceSheet,
                label: Text("Start"),
                icon: const Icon(Icons.add_a_photo),
              ),
            ),
          ),
          Expanded(child: _images.isEmpty ? _buildEmptyState() : _buildGrid()),
          if (_images.isNotEmpty) _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.picture_as_pdf, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "No images selected",
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // 3 images in a row
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.8,
      ),
      itemCount: _images.length,
      itemBuilder: (ctx, i) {
        return InkWell(
          onDoubleTap: () {
            cropSelectedImage(i); // To crop image.
          },
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    // Displays image
                    _images[i],
                    fit: BoxFit
                        .cover, // Covers the entire box given for the image.
                    // CRITICAL FOR PERFORMANCE:
                    // Loads a small thumbnail into memory, not the full 4K image
                    cacheWidth: 250,
                  ),
                ),
              ),
              Align(
                alignment: AlignmentGeometry.topRight,
                child: GestureDetector(
                  onTap: () => setState(
                    () => _images.removeAt(i),
                  ), // To remove image from list.
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(4),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 10.0,
                      vertical: 4.0,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 4,
                left: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    // Shows no. on each image, so the user knows how many images will be there in pdf.
                    "${i + 1}",
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          onPressed: _isGenerating ? null : _createPdf,
          icon: _isGenerating
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.check_circle),
          label: Text(_isGenerating ? 'Generating PDF...' : 'Convert to PDF'),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// 4. CUSTOM CAMERA (CONTINUOUS SHOOTING + FLASH)
// ---------------------------------------------------------
class ContinuousCameraScreen extends StatefulWidget {
  final CameraDescription camera;
  const ContinuousCameraScreen({super.key, required this.camera});

  @override
  State<ContinuousCameraScreen> createState() => _ContinuousCameraScreenState();
}

class _ContinuousCameraScreenState extends State<ContinuousCameraScreen> {
  late CameraController
  _controller; // Required to initialize camera received as argument
  late Future<void> _initFuture;
  // A private variable (because it starts with _).
  // Stores the Future returned by: _initFuture = _controller.initialize();
  final List<File> _capturedImages = []; // Stores all captured images
  bool _isCapturing = false;

  FlashMode _flashMode = FlashMode.off; // Sets Default Flash Mode

  @override
  void initState() {
    super.initState();
    // This line creates the camera controller that manages the camera hardware.
    _controller = CameraController(
      widget
          .camera, // the selected camera (front/back) passed from parent widget.
      ResolutionPreset.medium, // controls output quality of the camera preview.
      enableAudio: false, // disables audio recording
    ); // This prepares the camera but doesn’t start it yet.

    _initFuture = _controller.initialize().then((_) {
      // Set initial flash mode to off to ensure UI matches hardware state
      _controller.setFlashMode(FlashMode.off);
    });
    // initialize() starts the actual camera hardware.
    // Returns a Future — the UI must wait until the camera is ready.
    // The returned Future is stored in _initFuture, used inside a FutureBuilder to show loading until ready.

    // Why do we use .then() instead of await?
    // You cannot use await inside initState() unless you make it async, which is not allowed because initState must remain synchronous.
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Logic to cycle Flash Modes: Off -> Auto -> Always -> Off
  Future<void> _toggleFlash() async {
    FlashMode newMode;
    if (_flashMode == FlashMode.off) {
      newMode = FlashMode.auto;
    } else if (_flashMode == FlashMode.auto) {
      newMode = FlashMode.always;
    } else {
      newMode = FlashMode.off;
    }

    try {
      await _controller.setFlashMode(newMode); // Sets flash on, off or auto
      setState(() {
        _flashMode = newMode;
      });
    } catch (e) {
      debugPrint("Error changing flash mode: $e");
    }
  }

  // Helper to get the correct icon
  IconData _getFlashIcon() {
    // Returns icon based on FlashMode
    switch (_flashMode) {
      case FlashMode.off:
        return Icons.flash_off;
      case FlashMode.auto:
        return Icons.flash_auto;
      case FlashMode.always:
        return Icons.flash_on;
      case FlashMode.torch:
        return Icons.highlight;
    }
  }

  Future<void> _takePicture() async {
    if (_isCapturing) return;
    // If the user taps the capture button multiple times quickly:
    // We avoid taking multiple pictures simultaneously.
    // This prevents camera crashes or errors.

    setState(() => _isCapturing = true); // Button disabled

    try {
      await _initFuture;
      // Ensures:
      // Camera is fully initialized
      // Preview is ready
      // Flash/focus modes are set
      // Without this, calling takePicture() too early may crash.

      // Ideally set focus mode to auto before snapping
      // await _controller.setFocusMode(FocusMode.auto);

      final XFile image = await _controller.takePicture();
      // Controller takes an actual photo.
      // Returns an XFile object (path + metadata).
      // This is async because taking a picture takes time.

      setState(() {
        // Converts XFile → File (easier to handle in Flutter)
        // Stores the image in list
        _capturedImages.add(File(image.path));
        _isCapturing = false; // Allows taking next picture. Button enabled
      });
    } catch (e) {
      debugPrint("Capture failed: $e");
      setState(() => _isCapturing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<void>(
        future: _initFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                // 1. Camera Preview
                Center(child: CameraPreview(_controller)),

                // 2. Top Bar (Flash Control)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            decoration: const BoxDecoration(
                              color: Colors.black45,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              // Button to Toggle flash
                              onPressed: _toggleFlash,
                              icon: Icon(_getFlashIcon(), color: Colors.white),
                              tooltip:
                                  "Flash Mode: ${_flashMode.name.toUpperCase()}",
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 3. Bottom UI Overlay
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.only(bottom: 30, top: 20),
                    color: Colors.black45,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Counter Bubble
                        if (_capturedImages.isNotEmpty)
                          Container(
                            // Shows total no. of images captured
                            margin: const EdgeInsets.only(bottom: 15),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.indigoAccent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_capturedImages.length} Captured',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                        // Buttons Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Close camera screen
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),

                            // SHUTTER BUTTON
                            GestureDetector(
                              // Button to take picture
                              onTap: _takePicture,
                              child: Container(
                                height: 80,
                                width: 80,
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 4,
                                  ),
                                ),
                                child: _isCapturing
                                    ? const CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                    : const Icon(
                                        Icons.camera,
                                        color: Colors.white,
                                        size: 40,
                                      ),
                              ),
                            ),

                            // Done / Confirm
                            IconButton(
                              onPressed: () {
                                // Return list of images to ImageToPDF screen
                                Navigator.pop(context, _capturedImages);
                              },
                              icon: const Icon(
                                Icons.check,
                                color: Colors.greenAccent,
                                size: 35,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }
          return const Center(
            child: CircularProgressIndicator(color: Colors.indigo),
          );
        },
      ),
    );
  }
}
