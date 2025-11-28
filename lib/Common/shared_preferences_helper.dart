import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

// Why JSON is used?
// SharedPreferences can store only Strings →
// so you convert your list into JSON string before saving.

class SharedPreferencesHelper {
  List<Map<String, dynamic>> pdfFilesList =
      []; // Stores name, path and dateTime of pdf

  /// SAVE PDF INFO
  Future<void> savePDFInfo(String name, String path, String dateTime) async {
    final prefs =
        await SharedPreferences.getInstance(); // access SharedPreferences instance.

    // Load existing list first (to avoid overwriting)
    String? savedData = prefs.getString("pdfList"); // pdfList is the key
    if (savedData != null) {
      pdfFilesList = List<Map<String, dynamic>>.from(jsonDecode(savedData));
    }
    // jsonDecode converts the JSON string back into a List.
    // You convert it into a List<Map<String, dynamic>>.

    // Add new entry
    pdfFilesList.add({
      "pdfName": name,
      "pdfPath": path,
      "lastOpened": dateTime,
    });

    // Save back
    prefs.setString("pdfList", jsonEncode(pdfFilesList));
    // Save updated list back to SharedPreferences as a JSON string.
  }

  /// FETCH PDF LIST
  Future<List<Map<String, dynamic>>> getPDFList() async {
    final prefs =
        await SharedPreferences.getInstance(); // // access SharedPreferences instance.

    String? savedData = prefs.getString("pdfList"); // // Load existing list.

    if (savedData != null) {
      pdfFilesList = List<Map<String, dynamic>>.from(jsonDecode(savedData));
      return pdfFilesList;
    }

    return []; // If no data exists:
  }

  /// DELETE PDF AT SPECIFIC INDEX
  // This method doesn't delete an item itself.
  // Instead, you pass the already-updated list from outside.
  // Then you save the updated list again.
  Future<void> deletePDFAtIndex(
    List<Map<String, dynamic>> updatedList,
  ) async {
    final prefs =
        await SharedPreferences.getInstance(); // access SharedPreferences instance.

    prefs.setString("pdfList", jsonEncode(updatedList));
    // Save updated list back to SharedPreferences as a JSON string.
  }

  /// DELETE PDF AT SPECIFIC INDEX
  Future<void> deleteAllPDF() async {
    final prefs =
        await SharedPreferences.getInstance(); // access SharedPreferences instance.

    prefs.setString(
      "pdfList",
      jsonEncode([]),
    ); // Replace the list with an empty list
  }
}
