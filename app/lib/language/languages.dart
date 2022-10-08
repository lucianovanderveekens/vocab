import 'dart:async' show Future;
import 'dart:convert' show json;
import 'dart:developer';
import 'package:flutter/services.dart' show rootBundle;
import 'package:vocab/language/language.dart';

class Languages {
  static Languages? _instance;

  static Future<Languages> getInstance() async {
    if (_instance == null) {
      _instance = Languages(
        languageList: await loadLanguageList(),
      );
    }
    return _instance!;
  }

  static const String _pathToFile = "assets/languages.json";

  static Future<List<Language>> loadLanguageList() {
    return rootBundle.loadStructuredData<List<Language>>(_pathToFile,
        (jsonStr) async {
      var languagesJson = json.decode(jsonStr) as List;
      List<Language> languages = languagesJson
          .map((languageJson) => Language.fromJson(languageJson))
          .toList();

      languages.sort((a, b) => a.name.compareTo(b.name));

      return languages;
    });
  }

  List<Language> languageList;

  Languages({required this.languageList});

  Language findByCode(String code) {
    return languageList.firstWhere(
      (l) {
        // from simple to complex
        if (l.iso639_1 == code) {
          return true;
        }
        if (l.iso639_2b == code) {
          return true;
        }
        if (l.iso639_2t == code) {
          return true;
        }
        if (l.iso639_3 == code) {
          return true;
        }
        if (l.bcp47 == code) {
          return true;
        }
        return false;
      },
      orElse: () {
        throw ArgumentError("Language not found", code);
      },
    );
  }
}
