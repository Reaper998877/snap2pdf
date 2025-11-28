import 'package:flutter/material.dart';
import 'package:snap2pdf/Screens/home.dart';
import 'package:snap2pdf/Screens/image_to_pdf.dart';
import 'package:snap2pdf/Screens/open_recent.dart';
import 'package:snap2pdf/Screens/text_to_pdf.dart';
import 'package:snap2pdf/Screens/view_pdf.dart';

class Routes {
  static SlideTransition slideTransition(
    Animation<double> animation,
    Widget child,
  ) {
    final slideAnimation = Tween<Offset>(
      begin: const Offset(1, 0), // slide from right
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut));

    return SlideTransition(position: slideAnimation, child: child);
  }

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/home':
        return PageRouteBuilder(
          pageBuilder: (_, _, _) => const HomeScreen(),
          transitionsBuilder: (_, animation, _, child) {
            return slideTransition(animation, child);
          },
          transitionDuration: const Duration(milliseconds: 600),
        );

      case '/textToPDF':
        return PageRouteBuilder(
          pageBuilder: (_, _, _) => const TextToPDFScreen(),
          transitionsBuilder: (_, animation, _, child) {
            return slideTransition(animation, child);
          },
          transitionDuration: const Duration(milliseconds: 600),
        );

      case '/imageToPDF':
        return PageRouteBuilder(
          pageBuilder: (_, _, _) => const ImageToPDFScreen(),
          transitionsBuilder: (_, animation, _, child) {
            return slideTransition(animation, child);
          },
          transitionDuration: const Duration(milliseconds: 600),
        );

      case '/viewPDF':
        final args = settings
            .arguments; // This retrieves whatever data you sent using the arguments: parameter.

        if (args is! ViewPDFArgs) {
          throw Exception('Invalid or missing ViewPDFArgs!');
        }
        // The navigation must provide a ViewPDFArgs object.
        // If arguments are missing OR wrong type → throw an exception.

        // PageRouteBuilder allows:

        // ✔ full control over animations
        // ✔ custom transition duration
        // ✔ custom slide, fade, scale, etc.
        return PageRouteBuilder(
          pageBuilder: (_, __, ___) =>
              ViewPDFScreen(pdfName: args.pdfName, file: args.file),
          transitionsBuilder: (_, animation, __, child) {
            return slideTransition(animation, child);
          },
          transitionDuration: const Duration(milliseconds: 600),
        );

      case '/openRecent':
        return PageRouteBuilder(
          pageBuilder: (_, _, _) => const OpenRecentScreen(),
          transitionsBuilder: (_, animation, _, child) {
            return slideTransition(animation, child);
          },
          transitionDuration: const Duration(milliseconds: 600),
        );

      default:
        return PageRouteBuilder(
          pageBuilder: (_, _, _) => const HomeScreen(),
          transitionsBuilder: (_, animation, _, child) {
            return slideTransition(animation, child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        );
    }
  }
}
