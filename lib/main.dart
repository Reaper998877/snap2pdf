import 'dart:async';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:snap2pdf/Screens/splash.dart';
import 'package:snap2pdf/Screens/view_pdf.dart';
import 'package:snap2pdf/routes.dart';
import 'package:snap2pdf/theme.dart';
import 'package:uri_content/uri_content.dart';

// Global Key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
// This is a crucial Flutter concept. It allows you to access and control the Navigator (which manages your app's screen stack) from anywhere in the app, including outside the build method and even from the State class. It's used here to perform navigation commands (pushNamed, pushNamedAndRemoveUntil).

void main() {
  WidgetsFlutterBinding.ensureInitialized(); // Initializes the Flutter binding
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _appLinks =
      AppLinks(); // Used to detect and handle incoming links/URIs.
  StreamSubscription<Uri>?
  _linkSubscription; // Listens for incoming links while app is running
  Logger logger = Logger();

  bool _isCheckingInitialLink =
      true; // A boolean flag that tracks if the app is still determining if it was launched via a link. This is essential for controlling the initial splash screen behavior.

  // NEW: Variable to track the last file we opened
  String? _lastProcessedUri;
  // A new variable added for a Duplication Check. It prevents the app from processing the same deep link multiple times if the underlying OS triggers the link listener more than once.

  @override
  void initState() {
    super.initState();
    super.initState();
    // FIX: Schedule the deep link check to run AFTER the first frame is built
    // This ensures the Navigator is ready and unlocked.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initDeepLinks();
    });
    // To delay the execution of _initDeepLinks. This ensures the Flutter widget tree, and more importantly, the Navigator associated with the navigatorKey, is fully built and ready before attempting any navigation commands.
    // ⚠️ Why?
    // Because the navigatorKey is not ready before build(), and trying to push routes too early causes errors.
    // So you wait for the first frame → then initialize deep links safely.
  }

  @override
  void dispose() {
    _linkSubscription?.cancel(); // Cancel the subscription.
    super.dispose();
  }

  Future<void> _initDeepLinks() async {
    // 1. Check for initial link
    final initialUri = await _appLinks.getInitialLink();

    // There are TWO types of deep links:
    // ✔ Initial Link
    // When app launches from a PDF → you get the URI here.
    // ✔ Listener Link
    // While app is already running → triggers from stream listener.

    if (initialUri != null) {
      // Case A: PDF Found
      // CASE A → App launched from a PDF
      // Process it → open viewer directly → keep splash screen frozen in background.

      // CASE B → Normal launch
      // End splash waiting → Splash(navigate: true) → Goes to home.

      await _processPdfUri(initialUri);

      // CRITICAL CHANGE:
      // If we processed a PDF, we have already navigated to '/viewPDF'.
      // We do NOT want to trigger the Splash Screen's auto-navigation.
      // So we leave _isCheckingInitialLink = true (or set a different state),
      // but keeping it 'true' keeps the Splash(navigate: false) in the background,
      // which is exactly what we want behind the PDF view.
    } else {
      // Case B: No PDF. Tell UI to switch to "Active" Splash Screen
      if (mounted) {
        setState(() {
          _isCheckingInitialLink = false;
        });
      }
    }

    // 2. Background listener
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _processPdfUri(uri);
    });
    // If app is already open and you share a PDF → this runs.
  }

  Future<void> _processPdfUri(Uri uri) async {
    // 1. DUPLICATE CHECK
    // Prevents duplicate events
    // Sometimes Android/iOS triggers the listener twice for the same file.
    if (uri.toString() == _lastProcessedUri) {
      debugPrint("Duplicate URI ignored");
      return;
    }

    _lastProcessedUri = uri.toString();

    try {
      final bytes = await UriContent().from(
        uri,
      ); // Converts content-URI to raw bytes.

      // B. LOGIC TO GET FILE NAME
      String fileName = "shared_document.pdf"; // Default fallback
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$fileName');

      await tempFile.writeAsBytes(bytes);

      // LOGIC:
      // If we are currently checking the initial link, it means the app JUST started.
      // Therefore, we must manually put 'Home' in the history stack.
      // App starts on Splash screen
      // Splash cannot navigate by itself (because deep link overrides)
      // So you manually push /home as the first screen
      // (so back button works properly)

      if (_isCheckingInitialLink) {
        // Case A — App just launched via PDF
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/home',
          (route) => false, // Remove the Stuck Splash Screen
        );

        // First complete the navigation to Home and then open ViewPDF.
        // Simultaneous navigation causes error, to prevent it Future.microtask() is used.
        Future.microtask(() {
          navigatorKey.currentState?.pushNamed(
            '/viewPDF',
            arguments: ViewPDFArgs(pdfName: fileName, file: tempFile),
          );
        });
      } else {
        // Case B — App already running
        // If app is already running, just push the PDF on top
        // so we don't kill the user's current session.
        navigatorKey.currentState?.pushNamed(
          '/viewPDF',
          arguments: ViewPDFArgs(pdfName: "View PDF", file: tempFile),
        );
      }
    } catch (e) {
      debugPrint("Error processing PDF: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Snap2PDF',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      navigatorKey: navigatorKey,

      home: _isCheckingInitialLink
          ? const SplashScreen(
              navigate: false, // Splash → auto navigate to home
            )
          : const SplashScreen(
              navigate: true, // Show splash animation but DO NOT auto-navigate
            ),
      // This ensures that:
      // If deep link triggered, splash will NOT navigate automatically.
      // If normal launch, splash screen behaves normally.
      onGenerateRoute: (settings) => Routes.generateRoute(settings),
    );
  }
}

// Deep Link Example - On WhatsApp, when a pdf is clicked it shows options(Apps that open PDF) to open that PDF. When the user selects any app to open PDF, WhatsApp shares a link/content URI to that app. This link/content URI is called Deep Link.