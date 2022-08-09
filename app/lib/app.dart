import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:vocab/language/language.dart';

import 'package:vocab/camera/camera_page.dart';
import 'package:vocab/translation/google_translation_languages.dart';
import 'package:vocab/user/user_preferences_storage.dart';

import 'deck/deck_page.dart';
import 'deck/deck_storage.dart';

class App extends StatefulWidget {
  const App({Key? key}) : super(key: key);

  @override
  State<App> createState() => AppState();
}

class AppState extends State<App> {
  int _selectedIndex = 0;
  final deckStorage = DeckStorage();
  final userPreferencesStorage = UserPreferencesStorage();

  List<GoogleTranslationLanguage> _googleTranslationLanguages = [];

  @override
  initState() {
    super.initState();

    GoogleTranslationLanguages.load().then((value) {
      setState(() {
        _googleTranslationLanguages = value;
      });
    });
  }

  List<Widget> _getPages() {
    return [
      CameraPage(
        deckStorage: deckStorage,
        userPreferencesStorage: userPreferencesStorage,
        googleTranslationLanguages: _googleTranslationLanguages,
      ),
      DeckPage(deckStorage: deckStorage),
    ];
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
            title: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                      margin: EdgeInsets.only(right: 4.0),
                      child: Icon(Icons.document_scanner)),
                  const Text('Vocab',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24.0,
                      )),
                ]),
            foregroundColor: Colors.black,
            backgroundColor: Colors.white,
          ),
          body: _getPages().elementAt(_selectedIndex),
          bottomNavigationBar: BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.camera_alt_outlined),
                activeIcon: Icon(Icons.camera_alt),
                label: 'Camera',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.style_outlined),
                activeIcon: Icon(Icons.style),
                label: 'Deck',
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
