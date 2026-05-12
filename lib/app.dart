import 'package:flutter/material.dart';
import 'screens/storage_picker_screen.dart';

class PhotoCopierApp extends StatelessWidget {
  const PhotoCopierApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Photo Copier',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const StoragePickerScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
