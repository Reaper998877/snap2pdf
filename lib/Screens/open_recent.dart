import 'dart:io';

import 'package:flutter/material.dart';
import 'package:snap2pdf/Common/shared_preferences_helper.dart';
import 'package:snap2pdf/Screens/view_pdf.dart';

class OpenRecentScreen extends StatefulWidget {
  const OpenRecentScreen({super.key});

  @override
  State<OpenRecentScreen> createState() => _OpenRecentScreenState();
}

class _OpenRecentScreenState extends State<OpenRecentScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Recent PDFs"),
        actions: [
          IconButton(
            onPressed: () async {
              // Used to clear recent pdf history.
              await SharedPreferencesHelper().deleteAllPDF();
              setState(() {});
            },
            icon: Icon(Icons.delete),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: FutureBuilder(
            future: SharedPreferencesHelper().getPDFList(), // Retrieves/Fetches recent pdf history
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) { 
                return Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text("No recent PDFs"));
              }

              final pdfFilesList = snapshot.data!; // Fills the list

              return ListView.separated(
                itemCount: pdfFilesList.length,
                physics: BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  final pdf = pdfFilesList[index];
                  return Dismissible(
                    direction:
                        DismissDirection.endToStart, // swipe left to delete

                    background: Container(
                      decoration: BoxDecoration(color: Colors.redAccent),
                      margin: EdgeInsets.symmetric(vertical: 5),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Icon(
                        Icons.delete,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),

                    onDismissed: (direction) async {
                      // Removes from list
                      pdfFilesList.removeAt(index);

                      // Updates list in SharedPreferences
                      await SharedPreferencesHelper().deletePDFAtIndex(
                        pdfFilesList,
                      );
                    },
                    key: Key(pdf["lastOpened"]), // Unique key for each item in the list.
                    child: ListTile(
                      title: Text(
                        pdf["pdfName"],
                        style: TextStyle(fontSize: 16.0, color: Colors.black),
                      ),
                      subtitle: Text(
                        pdf["lastOpened"],
                        style: TextStyle(fontSize: 14.0, color: Colors.grey),
                      ),
                      onTap: () {
                        File pdfFile = File(pdf["pdfPath"]); // Get file from path.
                        if (pdfFile.existsSync()) { // Check if file exists
                          Navigator.pushNamed(
                            context,
                            '/viewPDF',
                            arguments: ViewPDFArgs(
                              pdfName: pdf["pdfName"],
                              file: pdfFile,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("File does not exist"),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                    ),
                  );
                },
                separatorBuilder: (context, index) { // Divider between two list items
                  return Divider(
                    color: Colors.grey,
                    thickness: 0.5,
                    height: 0.0,
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
