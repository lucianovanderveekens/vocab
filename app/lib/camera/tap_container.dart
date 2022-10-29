import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:collection/collection.dart';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:vocab/deck/deck_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vocab/deck/deck.dart';
import 'package:vocab/secret/secrets.dart';
import 'package:vocab/text_to_speech/google_cloud_text_to_speech_client.dart';
import 'package:vocab/text_to_speech/google_cloud_text_to_speech_languages.dart';
import 'package:vocab/translation/google_cloud_translation_client.dart';
import 'package:vocab/translation/google_cloud_translation_languages.dart';
import 'package:vocab/translation/google_cloud_translation_dtos.dart';
import 'package:vocab/user/user_preferences.dart';
import 'package:vocab/user/user_preferences_storage.dart';

class TapContainer extends StatefulWidget {
  final VoidCallback onClose;
  final String tappedWord;
  final bool translationEnabled;
  final DeckStorage deckStorage;
  final UserPreferencesStorage userPreferencesStorage;
  final List<GoogleCloudTranslationLanguage> translationLanguages;
  final List<GoogleCloudTextToSpeechLanguage> textToSpeechLanguages;
  final UserPreferences? userPreferences;
  final GoogleCloudTranslationClient googleCloudTranslationClient;
  final GoogleCloudTextToSpeechClient googleCloudTextToSpeechClient;
  final double scaleFactor;

  const TapContainer({
    Key? key,
    required this.onClose,
    required this.tappedWord,
    required this.translationEnabled,
    required this.deckStorage,
    required this.userPreferencesStorage,
    required this.translationLanguages,
    required this.textToSpeechLanguages,
    required this.userPreferences,
    required this.googleCloudTranslationClient,
    required this.googleCloudTextToSpeechClient,
    required this.scaleFactor,
  }) : super(key: key);

  @override
  State<TapContainer> createState() => TapContainerState();
}

class TapContainerState extends State<TapContainer> {
  GoogleCloudTranslationLanguage? _translationSourceLanguage;
  GoogleCloudTranslationLanguage? _translationTargetLanguage;

  GoogleCloudTextToSpeechLanguage? _textToSpeechLanguage;

  String? _translation;

  @override
  Widget build(BuildContext context) {
    log("@>TapDialogState#build (widget.userPreferences=${widget.userPreferences})");

    if (widget.userPreferences != null &&
        _translationSourceLanguage == null &&
        _translationTargetLanguage == null) {
      log("setting source and target languages");
      setState(() {
        _translationSourceLanguage = getGoogleTranslationLanguageByCode(
            widget.userPreferences!.sourceLanguageCode);
        _translationTargetLanguage = getGoogleTranslationLanguageByCode(
            widget.userPreferences!.targetLanguageCode);
      });

      _setTextToSpeechLanguage();
      _translate();
    }

    return Container(
        decoration: BoxDecoration(
          borderRadius:
              BorderRadius.all(Radius.circular(10.0 * widget.scaleFactor)),
          color: Colors.white,
        ),
        child: Container(
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              _buildTapDialogPageContent(),
            ])));
  }

  void _setTranslateSourceLanguage(
      GoogleCloudTranslationLanguage newSourceLanguage) {
    log("@>_setTranslateSourceLanguage");

    var oldSourceLanguage = _translationSourceLanguage;

    setState(() {
      _translationSourceLanguage = newSourceLanguage;
      if (_translationTargetLanguage == newSourceLanguage) {
        _translationTargetLanguage = oldSourceLanguage;
      }
    });

    _setTextToSpeechLanguage();
    _saveLanguagesInUserPreferences();
    _translate();
  }

  void _setTextToSpeechLanguage() {
    setState(() {
      _textToSpeechLanguage = widget.textToSpeechLanguages.firstWhereOrNull(
          (ttsl) =>
              ttsl.language.name == _translationSourceLanguage!.language.name);
    });
  }

  void _setTranslateTargetLanguage(
      GoogleCloudTranslationLanguage newTargetLanguage) {
    log("@>_setTranslateTargetLanguage");

    var oldTargetLanguage = _translationTargetLanguage;

    setState(() {
      _translationTargetLanguage = newTargetLanguage;
      if (_translationSourceLanguage == newTargetLanguage) {
        _translationSourceLanguage = oldTargetLanguage;
      }
    });

    _saveLanguagesInUserPreferences();
    _translate();
  }

  GoogleCloudTranslationLanguage getGoogleTranslationLanguageByCode(
      String code) {
    return widget.translationLanguages.firstWhere((gtl) {
      return gtl.language.hasCode(code);
    });
  }

  void _saveLanguagesInUserPreferences() {
    if (widget.userPreferences != null) {
      widget.userPreferences!.sourceLanguageCode =
          _translationSourceLanguage!.code;
      widget.userPreferences!.targetLanguageCode =
          _translationTargetLanguage!.code;
      widget.userPreferencesStorage.save(widget.userPreferences!);
    }
  }

  Widget _buildTapDialogPageContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
            padding: EdgeInsets.only(
              top: 16.0 * widget.scaleFactor,
              left: 16.0 * widget.scaleFactor,
              right: 16.0 * widget.scaleFactor,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Center(
                      child: _translationSourceLanguage != null
                          ? DropdownButton(
                              underline: Container(),
                              iconSize: 0.0,
                              isDense: false,
                              isExpanded: true,
                              style: TextStyle(
                                  fontSize: 16.0 * widget.scaleFactor),
                              value: _translationSourceLanguage,
                              items: widget.translationLanguages
                                  .map((GoogleCloudTranslationLanguage gtl) {
                                return DropdownMenuItem(
                                  value: gtl,
                                  child: Text(
                                    gtl.language.name,
                                    style: TextStyle(
                                        color: gtl == _translationSourceLanguage
                                            ? Color(0xFF00A3FF)
                                            : Colors.black,
                                        fontSize: 16.0 /* no scaling needed */),
                                  ),
                                );
                              }).toList(),
                              onChanged:
                                  (GoogleCloudTranslationLanguage? newValue) {
                                _setTranslateSourceLanguage(newValue!);
                              },
                              selectedItemBuilder: (con) {
                                return widget.translationLanguages.map((gtl) {
                                  return Center(
                                      child: Text(
                                    gtl.language.name,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Color(0xFF00A3FF),
                                    ),
                                  ));
                                }).toList();
                              })
                          : null),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                  icon: Icon(Icons.swap_horiz),
                  iconSize: 24.0 * widget.scaleFactor,
                  onPressed: () async {
                    setState(() {
                      var oldTranslatePageSourceLanguage =
                          _translationSourceLanguage;

                      _translationSourceLanguage = _translationTargetLanguage;
                      _translationTargetLanguage =
                          oldTranslatePageSourceLanguage;
                    });
                    _setTextToSpeechLanguage();
                    _saveLanguagesInUserPreferences();
                    _translate();
                  },
                ),
                Expanded(
                  child: Center(
                      child: _translationTargetLanguage != null
                          ? DropdownButton(
                              underline: Container(),
                              iconSize: 0.0,
                              style: TextStyle(
                                  fontSize: 16.0 * widget.scaleFactor),
                              isDense: false,
                              isExpanded: true,
                              value: _translationTargetLanguage,
                              items: widget.translationLanguages
                                  .map((GoogleCloudTranslationLanguage gtl) {
                                return DropdownMenuItem(
                                  value: gtl,
                                  child: Text(
                                    gtl.language.name,
                                    style: TextStyle(
                                        fontSize: 16.0 /* no scaling needed */,
                                        color: gtl == _translationTargetLanguage
                                            ? Color(0xFF00A3FF)
                                            : Colors.black),
                                  ),
                                );
                              }).toList(),
                              onChanged:
                                  (GoogleCloudTranslationLanguage? newValue) {
                                _setTranslateTargetLanguage(newValue!);
                              },
                              selectedItemBuilder: (con) {
                                return widget.translationLanguages.map((gtl) {
                                  return Center(
                                      child: Text(
                                    gtl.language.name,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Color(0xFF00A3FF),
                                      // fontSize: 16.0 /* no scaling needed */,
                                    ),
                                  ));
                                }).toList();
                              })
                          : null),
                ),
              ],
            )),
        Container(
            padding: EdgeInsets.only(
              top: 32.0 * widget.scaleFactor,
              bottom: 32.0 * widget.scaleFactor,
            ),
            child: Column(children: [
              Container(
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                Expanded(
                  child: _textToSpeechLanguage != null
                      ? Container(
                          alignment: Alignment.centerRight,
                          margin:
                              EdgeInsets.only(right: 4.0 * widget.scaleFactor),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(Icons.volume_up),
                            iconSize: 24.0 * widget.scaleFactor,
                            onPressed: () async {
                              log("Pressed on speaker icon");
                              widget.googleCloudTextToSpeechClient
                                  .synthesize(
                                widget.tappedWord,
                                _textToSpeechLanguage!.code,
                              )
                                  .then((base64String) {
                                // log("base64 encoded" + base64String);

                                getTemporaryDirectory().then((dir) {
                                  var filePath =
                                      '${dir.path}/${widget.tappedWord}_${_textToSpeechLanguage!.code}.mp3';
                                  var file = File(filePath);

                                  var decoded = base64.decode(base64String);
                                  // log("Decoded: " + decoded.toString());

                                  file.writeAsBytes(decoded).then((value) {
                                    log("written to file: $filePath");
                                    final player = AudioPlayer();
                                    // player.setAudioContext(audioContext);

                                    // Cannot use BytesSource. It only works on Android...
                                    player
                                        .play(DeviceFileSource(filePath))
                                        .whenComplete(() {
                                      log("Deleting temp file again");
                                      file.deleteSync();
                                    });
                                  });
                                });
                              });
                            },
                          ))
                      : Container(),
                ),
                Container(
                    child: Text(
                  widget.tappedWord,
                  style: TextStyle(
                    fontSize: 24.0 * widget.scaleFactor,
                  ),
                )),
                Expanded(child: Container())
              ])),
              SizedBox(height: 16.0 * widget.scaleFactor),
              Text(
                _translation ?? '',
                style: TextStyle(
                  fontSize: 16.0 * widget.scaleFactor,
                ),
              )
            ])),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.all(16.0 * widget.scaleFactor),
            side: BorderSide.none,
            backgroundColor: const Color(0xFF00A3FF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(10.0 * widget.scaleFactor),
                bottomRight: Radius.circular(10.0 * widget.scaleFactor),
              ),
            ),
          ),
          child: Container(
            width: double.infinity,
            child: Center(
                child: Text('Add to deck',
                    style: TextStyle(
                        fontSize: 16.0 * widget.scaleFactor,
                        color: Colors.white,
                        fontWeight: FontWeight.bold))),
          ),
          onPressed: _translation != null
              ? () async {
                  Deck deck = await widget.deckStorage.get();

                  Flashcard addedCard = Flashcard(
                    id: const Uuid().v4(),
                    sourceLanguageCode: _translationSourceLanguage!.code,
                    sourceWord: widget.tappedWord,
                    targetLanguageCode: _translationTargetLanguage!.code,
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
              : null,
        ),
      ],
    );
  }

  void _translate() async {
    log("@>translate()");
    if (!widget.translationEnabled) {
      setState(() {
        _translation = "<translation disabled>";
      });
      return;
    }
    if (_translationSourceLanguage == null ||
        _translationTargetLanguage == null) {
      return;
    }

    log("Translating...");

    String? translation = await widget.googleCloudTranslationClient.translate(
      widget.tappedWord,
      _translationSourceLanguage!.code,
      _translationTargetLanguage!.code,
    );
    log("Translation: $translation");
    setState(() {
      _translation = translation;
    });
  }
}