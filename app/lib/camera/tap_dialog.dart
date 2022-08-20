import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:vocab/deck/deck_storage.dart';
import 'package:vocab/deck/deck.dart';
import 'package:vocab/secret/secrets.dart';
import 'package:vocab/translation/google_translation_languages.dart';
import 'package:vocab/translation/google_translation_response.dart';
import 'package:vocab/user/user_preferences.dart';
import 'package:vocab/user/user_preferences_storage.dart';

class TapDialog extends StatefulWidget {
  final VoidCallback onClose;
  final String? tappedOnWord;
  final bool translationEnabled;
  final DeckStorage deckStorage;
  final UserPreferencesStorage userPreferencesStorage;
  final List<GoogleTranslationLanguage> googleTranslationLanguages;

  const TapDialog({
    Key? key,
    required this.onClose,
    required this.tappedOnWord,
    required this.translationEnabled,
    required this.deckStorage,
    required this.userPreferencesStorage,
    required this.googleTranslationLanguages,
  }) : super(key: key);

  @override
  State<TapDialog> createState() => TapDialogState();
}

class TapDialogState extends State<TapDialog> {
  final ValueNotifier<bool> _showTranslatePage = ValueNotifier(false);
  bool _showChangeLanguagePage = false;

  late GoogleTranslationLanguage _translatePageSourceLanguage;
  late GoogleTranslationLanguage _translatePageTargetLanguage;
  String? _translation;

  late GoogleTranslationLanguage _changeLanguagePageSourceLanguage;
  late GoogleTranslationLanguage _changeLanguagePageTargetLanguage;

  UserPreferences? _userPreferences;

  @override
  initState() {
    super.initState();

    _translatePageSourceLanguage = getGoogleTranslationLanguageByCode("it");
    _translatePageTargetLanguage = getGoogleTranslationLanguageByCode("en");

    log("Loading user preferences...");
    widget.userPreferencesStorage.get().then((value) {
      _userPreferences = value;

      if (_userPreferences!.sourceLanguageCode != null) {
        _translatePageSourceLanguage = getGoogleTranslationLanguageByCode(
            _userPreferences!.sourceLanguageCode!);
      }
      if (_userPreferences!.targetLanguageCode != null) {
        _translatePageTargetLanguage = getGoogleTranslationLanguageByCode(
            _userPreferences!.targetLanguageCode!);
      }

      _showTranslatePage.addListener(() => _translate());
    });
  }

  void _setChangeLanguagePageSourceLanguage(
      GoogleTranslationLanguage sourceLanguage) {
    log("@>_setChangeLanguagePageSourceLanguage");

    var oldSourceLanguage = _changeLanguagePageSourceLanguage;

    setState(() {
      _changeLanguagePageSourceLanguage = sourceLanguage;
      if (_changeLanguagePageTargetLanguage == sourceLanguage) {
        _changeLanguagePageTargetLanguage = oldSourceLanguage;
      }
    });

    // TODO: do after apply
    // TODO: set translate languages
    // _saveLanguagesInUserPreferences();
    // _translate();
  }

  void _setChangeLanguagePageTargetLanguage(
      GoogleTranslationLanguage newTargetLanguage) {
    log("@>_setChangeLanguagePageTargetLanguage");

    var oldTargetLanguage = _translatePageTargetLanguage;

    setState(() {
      _changeLanguagePageTargetLanguage = newTargetLanguage;
      if (_changeLanguagePageSourceLanguage == newTargetLanguage) {
        _changeLanguagePageSourceLanguage = oldTargetLanguage;
      }
    });
  }

  GoogleTranslationLanguage getGoogleTranslationLanguageByCode(String code) {
    return widget.googleTranslationLanguages.firstWhere((gtl) {
      return gtl.language.hasCode(code);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        child: Container(
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              if (_showTranslatePage.value)
                if (_showChangeLanguagePage)
                  ..._buildChangeLanguagePage()
                else
                  ..._buildTranslatePage()
              else
                ..._buildTapPage()
            ])));
  }

  List<Widget> _buildTapPage() {
    return [
      _buildDialogHeader(title: "Tap"),
      _buildDialogContentWrapper(child: _buildTapDialogPageContent())
    ];
  }

  List<Widget> _buildTranslatePage() {
    log("@>_buildTranslatePage");

    return [
      _buildDialogHeader(
          title: "Translate",
          onBack: () {
            setState(() {
              this._showTranslatePage.value = false;
            });
          }),
      _buildDialogContentWrapper(child: _buildTranslatePageContent())
    ];
  }

  List<Widget> _buildChangeLanguagePage() {
    log("@>_buildChangeLanguagePage");
    var onBack = () => setState(() {
          _showChangeLanguagePage = false;
        });

    return [
      _buildDialogHeader(title: "Change language", onBack: onBack),
      _buildDialogContentWrapper(child: _buildChangeLanguagePageContent(onBack))
    ];
  }

  Widget _buildChangeLanguagePageContent(
    VoidCallback onBack,
  ) {
    log("@>_buildChangeLanguagePageContent");
    // _changeLanguagePageSourceLanguage = sourceLanguage;
    // _changeLanguagePageTargetLanguage = targetLanguage;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16.0),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text("Original"),
              DropdownButton(
                isExpanded: true,
                value: _changeLanguagePageSourceLanguage,
                icon: const Icon(Icons.keyboard_arrow_down),
                items: widget.googleTranslationLanguages
                    .map((GoogleTranslationLanguage gtl) {
                  return DropdownMenuItem(
                    value: gtl,
                    child: Text(gtl.language.name),
                  );
                }).toList(),
                onChanged: (GoogleTranslationLanguage? newValue) {
                  _setChangeLanguagePageSourceLanguage(newValue!);
                },
              )
            ])),
        Container(
            width: double.infinity,
            margin: EdgeInsets.only(bottom: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Translation"),
                DropdownButton(
                  isExpanded: true,
                  value: _changeLanguagePageTargetLanguage,
                  icon: const Icon(Icons.keyboard_arrow_down),
                  items: widget.googleTranslationLanguages
                      .map((GoogleTranslationLanguage gtl) {
                    return DropdownMenuItem(
                      value: gtl,
                      child: Text(gtl.language.name),
                    );
                  }).toList(),
                  onChanged: (GoogleTranslationLanguage? newValue) {
                    _setChangeLanguagePageTargetLanguage(newValue!);
                  },
                ),
              ],
            )),
        Container(
            width: double.infinity,
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              child: Text("Apply"),
              onPressed: _onApply(onBack),
            ))
      ],
    );
  }

  VoidCallback _onApply(VoidCallback onBack) {
    return () {
      log("Pressed on apply");
      setState(() {
        _translatePageSourceLanguage = _changeLanguagePageSourceLanguage;
        _translatePageTargetLanguage = _changeLanguagePageTargetLanguage;
      });
      _saveLanguagesInUserPreferences();
      _translate();
      onBack();
    };
  }

  void _saveLanguagesInUserPreferences() {
    if (_userPreferences != null) {
      _userPreferences!.sourceLanguageCode = _translatePageSourceLanguage.code;
      _userPreferences!.targetLanguageCode = _translatePageTargetLanguage.code;
      widget.userPreferencesStorage.save(_userPreferences!);
    }
  }

  Widget _buildDialogContentWrapper({required Widget child}) {
    return Container(
      margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
      width: double.infinity,
      child: child,
    );
  }

  Widget _buildTranslatePageContent() {
    // TODO: right place?
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        margin: const EdgeInsets.only(bottom: 32.0),
        decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 1.0),
            borderRadius: BorderRadius.circular(10.0)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
              margin: EdgeInsets.only(bottom: 8.0),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TODO: not null safe
                    Text(this._translatePageSourceLanguage.language.name,
                        style: TextStyle(
                            color: Color(0xFF00A3FF),
                            fontWeight: FontWeight.bold,
                            fontSize: 12.0)),
                    Text('${widget.tappedOnWord}',
                        style: TextStyle(fontSize: 24.0)),
                  ])),
          Divider(
            color: Colors.black,
            height: 1.0,
            thickness: 1.0,
          ),
          Container(
              margin: EdgeInsets.only(top: 8.0),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TODO: not null safe
                    Text(this._translatePageTargetLanguage.language.name,
                        style: TextStyle(
                            color: Color(0xFF00A3FF),
                            fontWeight: FontWeight.bold,
                            fontSize: 12.0)),
                    Text(_translation != null ? _translation! : "",
                        style: TextStyle(fontSize: 24.0)),
                  ])),
        ]),
      ),
      Container(
          margin: EdgeInsets.only(bottom: 8.0),
          child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.all(16.0),
                // side: BorderSide(color: Colors.black),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              child: Container(
                  width: double.infinity,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Add to deck'),
                      const Icon(Icons.list, size: 24.0),
                    ],
                  )),
              onPressed: _translation != null
                  ? () async {
                      Deck deck = await widget.deckStorage.get();

                      Flashcard addedCard = Flashcard(
                        id: const Uuid().v4(),
                        sourceLanguageCode: _translatePageSourceLanguage.code,
                        sourceWord: widget.tappedOnWord!,
                        targetLanguageCode: _translatePageTargetLanguage.code,
                        targetWord: _translation!,
                      );
                      deck.cards.add(addedCard);
                      widget.deckStorage.save(deck);

                      widget.onClose();

                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: const Text('Added to deck'),
                          action: SnackBarAction(
                            label: "Undo",
                            onPressed: () {
                              deck.cards.remove(addedCard);
                              widget.deckStorage.save(deck);
                            },
                          )));
                    }
                  : null)),
      Container(
          child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.all(16.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
        child: Container(
            width: double.infinity,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Change language'),
                const Icon(Icons.language, size: 24.0),
              ],
            )),
        onPressed: () {
          log("Pressed on 'Change language'");
          setState(() {
            _changeLanguagePageSourceLanguage = _translatePageSourceLanguage;
            _changeLanguagePageTargetLanguage = _translatePageTargetLanguage;
            this._showChangeLanguagePage = true;
          });
        },
      )),
    ]);
  }

  Widget _buildTapDialogPageContent() {
    if (widget.tappedOnWord == null) {
      return Text("No word found.");
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Tapped on word:",
        ),
        Container(
            margin: EdgeInsets.only(top: 32.0, bottom: 32.0),
            child: Center(
                child: Text(widget.tappedOnWord!,
                    style: TextStyle(
                      fontSize: 24.0,
                    )))),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.all(16.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
          child: Container(
              width: double.infinity,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Translate'),
                  const Icon(Icons.translate, size: 24.0),
                ],
              )),
          onPressed: () {
            log("Pressed on translate");
            setState(() {
              this._showTranslatePage.value = true;
            });
          },
        ),
      ],
    );
  }

  // TODO: convert to separate widget with properties
  Widget _buildDialogHeader({required String title, VoidCallback? onBack}) {
    return Row(children: [
      Expanded(
          child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                margin: EdgeInsets.only(top: 4.0, bottom: 4.0),
                child: onBack == null
                    ? Container()
                    : IconButton(
                        icon: Icon(Icons.arrow_back), onPressed: onBack),
              ))),
      Text(title,
          style:
              TextStyle(color: Color(0xFF00A3FF), fontWeight: FontWeight.bold)),
      Expanded(
          child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                  margin: EdgeInsets.only(top: 4.0, bottom: 4.0),
                  child: IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () {
                        if (widget.onClose != null) {
                          widget.onClose();
                        }
                      }))))
    ]);
  }

  void _translate() async {
    if (!widget.translationEnabled) {
      return;
    }
    log("Translating...");
    String? translation = await googleTranslate(widget.tappedOnWord!,
        _translatePageSourceLanguage.code, _translatePageTargetLanguage.code);
    log("Translation: $translation");
    setState(() {
      _translation = translation;
    });
  }

  Future<String> googleTranslate(
      String text, String sourceCode, String targetCode) async {
    final response = await http.get(
        Uri.parse('https://translation.googleapis.com/language/translate/v2')
            .replace(queryParameters: {
      'q': text,
      'source': sourceCode,
      'target': targetCode,
      'key': (await SecretsLoader().load()).apiKey,
    }));

    if (response.statusCode != 200) {
      throw Exception(
          'Failed to call Google Cloud Translation API: ${response.body}');
    }

    final googleTranslationResponse =
        GoogleTranslationResponse.fromJson(jsonDecode(response.body));

    return googleTranslationResponse.data.translations[0].translatedText;
  }
}
