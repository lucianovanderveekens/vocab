import 'dart:convert';

class Deck {
  List<Flashcard> cards;

  Deck({required this.cards});

  factory Deck.fromJsonV1(Map<String, dynamic> json) {
    var cardsJson = json['cards'] as List;
    List<Flashcard> cards = cardsJson
        .map((cardJson) => Flashcard.fromJson(jsonDecode(cardJson)))
        .toList();

    return Deck(cards: cards);
  }

  factory Deck.fromJsonV2(Map<String, dynamic> json) {
    var cardsJson = json['cards'] as List;
    List<Flashcard> cards =
        cardsJson.map((cardJson) => Flashcard.fromJson(cardJson)).toList();

    return Deck(cards: cards);
  }

  Map<String, dynamic> toJson() {
    return {
      'cards': cards.map((c) => c.toJson()).toList(),
    };
  }
}

class Flashcard {
  final String id;

  final String sourceLanguageCode;
  final String sourceWord;

  final String targetLanguageCode;
  final String targetWord;

  Flashcard({
    required this.id,
    required this.sourceLanguageCode,
    required this.sourceWord,
    required this.targetLanguageCode,
    required this.targetWord,
  });

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      id: json['id'],
      sourceLanguageCode: json['sourceLanguageCode'],
      sourceWord: json['sourceWord'],
      targetLanguageCode: json['targetLanguageCode'],
      targetWord: json['targetWord'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sourceLanguageCode': sourceLanguageCode,
      'sourceWord': sourceWord,
      'targetLanguageCode': targetLanguageCode,
      'targetWord': targetWord,
    };
  }
}
