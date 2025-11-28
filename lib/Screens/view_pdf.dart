import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:snap2pdf/theme.dart';

class ViewPDFScreen extends StatefulWidget {
  final File file;
  final String pdfName;
  const ViewPDFScreen({super.key, required this.file, required this.pdfName});

  @override
  State<ViewPDFScreen> createState() => _ViewPDFScreenState();
}

class _ViewPDFScreenState extends State<ViewPDFScreen> {
  late PdfController pdfController; // PDF controller required for PdfView to show PDF.
  int noOfPages = 0;
  int currentPage = 1;

  @override
  void initState() {
    super.initState();
    pdfController = PdfController( // Initializing
      document: PdfDocument.openFile(widget.file.path),
    );
  }

  @override
  void dispose() {
    pdfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pdfName),
        centerTitle: false,
        actions: [
          IconButton( // Go to previous page in PDF
            onPressed: () { 
              if (currentPage == 1) return; // If user is on 1st page then return

              setState(() {
                currentPage -= 1;
              });

              pdfController.animateToPage( // Page navigation with animation
                currentPage,
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            icon: Icon(Icons.arrow_back_ios),
          ),
          Text( // Diplays current page no.
            currentPage.toString(),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          IconButton( // Go to next page in PDF
            onPressed: () {
              if (currentPage == noOfPages) return; // If user is on last page then return

              setState(() {
                currentPage += 1;
              });

              pdfController.animateToPage( // Page navigation with animation
                currentPage,
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            icon: Icon(Icons.arrow_forward_ios),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsetsGeometry.all(10.0),
          child: Stack(
            children: [
              PdfView( // Displays PDF
                controller: pdfController,
                scrollDirection: Axis.vertical,
                backgroundDecoration: BoxDecoration(color: AppColors.textGrey),
                physics: BouncingScrollPhysics(),
                onPageChanged: (page) { // Callback triggered when page is changed. 
                  setState(() {
                    currentPage = page;
                  });
                },
                onDocumentLoaded: (document) { // Callback triggered when PDF is loaded.
                  setState(() {
                    noOfPages = document.pagesCount;
                  });
                },
                builders: PdfViewBuilders<DefaultBuilderOptions>(
                  options: DefaultBuilderOptions(),
                  documentLoaderBuilder: (_) =>
                      const Center(child: CircularProgressIndicator()), 

                  pageLoaderBuilder: (_) =>
                      const Center(child: CircularProgressIndicator()),

                  errorBuilder: (_, error) =>
                      Center(child: Text("❌ Error: $error")),

                  pageBuilder: (context, pageImage, index, document) {
                    return PhotoViewGalleryPageOptions(
                      imageProvider: PdfPageImageProvider(
                        pageImage,
                        index + 1, // <-- page number (starts at 1)
                        document.id, // <-- required
                      ),
                      minScale: PhotoViewComputedScale
                          .contained, // This sets the minimum zoom level of the page.
                      maxScale:
                          PhotoViewComputedScale.covered *
                          3, // This sets the maximum zoom level allowed. // Allow up to 3× more zoom
                      // PhotoViewComputedScale.covered means: → Zoom until the page covers the entire screen (fills it)
                      heroAttributes: PhotoViewHeroAttributes(
                        tag: index,
                      ), // This enables a Hero animation when switching pages.
                    );
                  },
                ),
              ),
              Padding(
                padding: EdgeInsetsGeometry.only(bottom: 20.0),
                child: Align(
                  alignment: AlignmentGeometry.bottomCenter,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    padding: EdgeInsets.all(10.0),
                    child: Text(
                      "$currentPage/$noOfPages", // Shows Current page No. / Total page No.
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Class that is used to pass arguments when navigating to ViewPDF screen.
class ViewPDFArgs {
  final String pdfName;
  final File file;

  ViewPDFArgs({required this.pdfName, required this.file});
}
