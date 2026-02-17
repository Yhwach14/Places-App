import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:places_app/screens/places.dart';

void main() {
  runApp(ProviderScope(child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Great Places',
      home: PlacesScreen(),
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        textTheme: GoogleFonts.robotoFlexTextTheme().copyWith(
          titleSmall: GoogleFonts.robotoFlex(fontWeight: FontWeight.bold),
          titleMedium: GoogleFonts.robotoFlex(fontWeight: FontWeight.bold),
          titleLarge: GoogleFonts.robotoFlex(fontWeight: FontWeight.bold),
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 147, 229, 250),
          brightness: Brightness.light,
          surface: const Color.fromARGB(255, 211, 250, 255),
        ),
        scaffoldBackgroundColor: const Color.fromARGB(255, 255, 255, 255),
      ),
    );
  }
}
