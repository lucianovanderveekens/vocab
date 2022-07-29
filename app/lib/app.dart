import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:language_picker/languages.dart';

import 'package:vocab/pages/camera_page.dart';
import 'package:vocab/pages/list_page.dart';
import 'package:vocab/storage/word_storage.dart';
import 'package:vocab/translate/google_translation_supported_languages.dart';

class App extends StatefulWidget {
  const App({Key? key}) : super(key: key);

  @override
  State<App> createState() => AppState();
}

class AppState extends State<App> {
  int _selectedIndex = 0;
  final wordStorage = WordStorage();
  List<Language> supportedLanguages = [];

  List<Widget> _getPages() {
    return [
      CameraPage(
          wordStorage: wordStorage, supportedLanguages: supportedLanguages),
      ListPage(wordStorage: wordStorage),
    ];
  }

  @override
  void initState() {
    super.initState();

    GoogleTranslationSupportedLanguages.load().then((value) {
      this.supportedLanguages = value;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: ThemeData(
          textTheme: ThemeData(
                  textTheme: TextTheme(
            bodyText1: TextStyle(fontSize: 16.0),
            bodyText2: TextStyle(fontSize: 16.0),
            button: TextStyle(fontSize: 16.0),
          )).textTheme.apply(
                bodyColor: Colors.black,
              ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              primary: Colors.black,
            ).copyWith(
              side: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.disabled)) {
                  return BorderSide(color: Colors.grey);
                }
                return BorderSide(color: Colors.black);
              }),
            ),
          ),
        ),
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Vocab',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24.0,
                )),
            foregroundColor: Colors.black,
            backgroundColor: Colors.white,
          ),
          body: _getPages().elementAt(_selectedIndex),
          bottomNavigationBar: BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.camera_alt),
                label: 'Camera',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.list),
                label: 'List',
              ),
            ],
            selectedLabelStyle: TextStyle(fontSize: 16.0),
            unselectedLabelStyle: TextStyle(fontSize: 16.0),
            currentIndex: _selectedIndex,
            selectedItemColor: Colors.black,
            onTap: _onItemTapped,
          ),
        ));
  }
}
