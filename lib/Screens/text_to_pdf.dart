import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:logger/web.dart';
import 'package:snap2pdf/Common/pdf_helper.dart';
import 'package:snap2pdf/Common/shared_preferences_helper.dart';
import 'package:snap2pdf/Screens/view_pdf.dart';

class TextToPDFScreen extends StatefulWidget {
  const TextToPDFScreen({super.key});

  @override
  State<TextToPDFScreen> createState() => _TextToPDFScreenState();
}

class _TextToPDFScreenState extends State<TextToPDFScreen> {
  final TextEditingController textDataController = TextEditingController();
  final TextEditingController pdfNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  Logger logger = Logger();
  bool processing = false;

  Future<void> generatePDF() async {
    // First validate the Form fields
    if (!_formKey.currentState!.validate()) {
      // If any field input is invalid then return.
      return;
    }

    // To show CircularProgressIndicator make processing true
    setState(() {
      processing = true;
    });

    // Storing values of input fields
    String textData = textDataController.text.trim().toString();
    String pdfName = pdfNameController.text.trim().toString();
    logger.d("Text: $textData PDF Name: $pdfName");

    // Store PDF bytes, which are returned by the function, runned on different thread.
    final pdfBytes = await generatePdfBytesUsingCompute(textData);

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
    final file = File('$path/$pdfName.pdf'); // Creates a file on that path
    await file.writeAsBytes(pdfBytes); // Writes pdfBytes in the file

    String openedDT = DateTime.now()
        .toLocal()
        .toString(); // 2025-11-19 12:34:56.789012 // Year-Month-Day Hour:Minute:Second.Millisecond

    await SharedPreferencesHelper().savePDFInfo(
      pdfName,
      file.path,
      openedDT,
    ); // Save the pdf info in recent pdf history

    setState(() {
      processing = false; // Removes CircularProgressIndicator
    });

    Future.delayed(Duration(microseconds: 500)); // Wait for 500 ms

    if (success) { // If true navigate to ViewPDF screen.
      Navigator.pushReplacementNamed(
        context,
        '/viewPDF',
        arguments: ViewPDFArgs(pdfName: pdfName, file: file),
      );
    }
  }

  @override
  void dispose() {
    textDataController.dispose();
    pdfNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Text To PDF")),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    minLines: 6, // minimum height (6 lines tall)
                    maxLines: 12, // maximum height (12 lines tall)
                    keyboardType: TextInputType.multiline,
                    controller: textDataController,
                    style: TextStyle(fontSize: 16, color: Colors.black),
                    decoration: InputDecoration(
                      labelText: "Enter Text",
                      floatingLabelBehavior: FloatingLabelBehavior.auto,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter text';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20.0),
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
                        // Checks if input matches the validation pattern.
                        return 'Alphabets, numbers, -, _ and space are allowed';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20.0),
                  if (processing)
                    CircularProgressIndicator()
                  else
                    ElevatedButton(
                      onPressed: generatePDF,
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.save),
                          SizedBox(width: 10.0),
                          Text("Save PDF"),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Multithread
Future<List<int>> generatePdfBytesUsingCompute(String textData) {
  return compute(_buildPdfBytes, textData);
  // Asynchronously runs the given [callback] - with the provided [message] - in the background and completes with the result.
  // Runs a function on a new Dart Isolate (background thread)
  // Returns result (List<int> means pdf bytes)
}

Future<List<int>> _buildPdfBytes(String textData) {
  // This function gets executed inside compute().
  // Functions used inside compute() must be:
  // a top-level function
  // or a static function
  // NO class instance methods

  // Creating a pdf
  final pdf = pw.Document(
    compress: false,
  ); // compress: false → disables compression

  pdf.addPage(
    pw.MultiPage(
      // The layout builder for the page's content.
      build: (context) => [pw.Paragraph(text: textData)],
    ),
  );
  // MultiPage automatically:
  // ✔ handles long text
  // ✔ splits content into new pages
  // ✔ avoids overflow errors
  // ✔ repeats headers/footers
  // ✔ manages page breaks

  // pw.Paragraph(text: textData)
  // But if the text is long, it will create:
  // Page 1 2 3...
  // Automatically.

  return pdf.save(); // This returns a List<int> (binary PDF data)
}
