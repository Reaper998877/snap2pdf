import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:logger/web.dart';
import 'package:snap2pdf/Common/shared_preferences_helper.dart';
import 'package:snap2pdf/Common/stateless_widgets.dart';
import 'package:snap2pdf/Screens/image_to_pdf.dart';
import 'package:snap2pdf/Screens/view_pdf.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? selectedPdfFile; // PDF File selected by user to view.
  Logger logger = Logger();

  Future<void> pickPdf() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'], // Only .pdf file is allowed
    ); // Allows user to select a single PDF from device storage.
    
    // Checks if user has selected any PDF or not.
    if (result != null && result.files.single.path != null) {
      setState(() {
        selectedPdfFile = File(result.files.single.path!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    selectedPdfFile = null;
    return Scaffold(
      appBar: AppBar(title: Text("Snap2PDF")),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: GridView.count(
            shrinkWrap: true,
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: [
              CardButton(
                icon: Icons.text_fields,
                label: 'Text to PDF',
                onPressed: () {
                  Navigator.pushNamed(context, '/textToPDF');
                },
              ),
              CardButton(
                icon: Icons.text_fields,
                label: 'Image to PDF',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ImageToPDFScreen()),
                  );
                },
              ),
              CardButton(
                icon: Icons.text_fields,
                label: 'Open PDF',
                onPressed: () async {
                  await pickPdf();

                  if (selectedPdfFile == null) { // Checks if pdf file is selected or not
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("No PDF selected."),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );

                    return; // If not selected show snackbar and return.
                  }

                  // Correct way to extract file name
                  String fileName = selectedPdfFile!.path.split('/').last; // Finds last / and extracts text after it.
                  String pdfName = fileName.replaceAll('.pdf', ''); // From extracted text remove .pdf
                  String openedDT = DateTime.now()
                      .toLocal()
                      .toString(); // 2025-11-19 12:34:56.789012 // Year-Month-Day Hour:Minute:Second.Millisecond

                  logger.d("PDF name is $pdfName");

                  // Adds to SharedPreference
                  await SharedPreferencesHelper().savePDFInfo(
                    pdfName,
                    selectedPdfFile!.path,
                    openedDT,
                  );

                  Navigator.pushNamed(
                    context,
                    '/viewPDF',
                    arguments: ViewPDFArgs(
                      pdfName: pdfName,
                      file: selectedPdfFile!,
                    ),
                  );
                },
              ),
              CardButton(
                icon: Icons.text_fields,
                label: 'Open Recent',
                onPressed: () {
                  Navigator.pushNamed(context, '/openRecent');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
