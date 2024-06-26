import 'dart:collection';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;

// SpellChecker class to manage spell checking and dictionary operations
class SpellChecker {
  // Paths to the dictionaries
  String enPath = 'assets/dictionaries/English_Dictionary.txt';
  String farsiPath = 'assets/dictionaries/Persian_Dictionary.txt';

  // Flag to indicate if the text is in Farsi
  static bool isTextFarsi = false;

  // Flag to enable additional spell checking for ed = 3
  bool checkEd3 = false;

  // Edit distances used for spell checking
  int ed1 = 1;
  int ed2 = 2;
  int ed3 = 3;

  // Lists to store the dictionaries
  List<String> enDic = [];
  List<String> persianDic = [];

  // Constructor that initializes the dictionaries
  SpellChecker() {
    init();
  }

  // Initialize the dictionaries
  Future<void> init() async {
    enDic = await loadDictionary(enPath);
    persianDic = await loadDictionary(farsiPath);
    print('English Dictionary Loaded: ${enDic.length} words');
    print('Persian Dictionary Loaded: ${persianDic.length} words');
  }

  // Function to load a dictionary from a file
  Future<List<String>> loadDictionary(String filePath) async {
    final file = await rootBundle.loadString(filePath);
    List<String> lines = file.split('\n');
    return lines
        .map((line) => line.trim())
        .toList(); // Remove any extra whitespace
  }

  // Function to remove punctuation from a word
  String removePunctuation(String word) {
    // Use a regular expression to remove all non-alphanumeric characters
    return word.replaceAll(RegExp(r'[^\w\s]'), '');
  }

  // Function to check if a word is correctly spelled
  Future<bool> isCorrectlySpelled(String word) async {
    String cleanWord = removePunctuation(word);
    bool isCorrect =
        enDic.contains(cleanWord) || persianDic.contains(cleanWord);
    print('Checking if "$word" is correctly spelled: $isCorrect');
    return isCorrect;
  }

  // Levenshtein distance algorithm to calculate edit distance between two words
  int levenshtein(String word, String dictWord) {
    int len1 = word.length;
    int len2 = dictWord.length;

    // Create a 2D list to hold the distances
    List<List<int>> distance = List.generate(
      len1 + 1,
      (i) => List<int>.filled(len2 + 1, 0),
    );

    // Initialize the first row and column
    for (int i = 0; i <= len1; i++) {
      distance[i][0] = i;
    }
    for (int j = 0; j <= len2; j++) {
      distance[0][j] = j;
    }

    // Fill in the rest of the matrix
    for (int i = 1; i <= len1; i++) {
      for (int j = 1; j <= len2; j++) {
        int cost = (word[i - 1] == dictWord[j - 1]) ? 0 : 1;
        distance[i][j] = [
          distance[i - 1][j] + 1, // Deletion
          distance[i][j - 1] + 1, // Insertion
          distance[i - 1][j - 1] + cost, // Substitution
        ].reduce(min);
      }
    }

    return distance[len1][len2];
  }

  // Function to get spelling suggestions for an input word
  Future<List<String>> spellCheck(String inputWord) async {
    if (enDic.isEmpty || persianDic.isEmpty) {
      await init();
    }

    String word = removePunctuation(inputWord);
    print('Spell checking word: "$word"');
    Queue<String> suggestions = Queue<String>();

    // Choose the appropriate dictionary based on the text language
    List<String> dictionary = isTextFarsi ? persianDic : enDic;
    for (final dictWord in dictionary) {
      String cleanDictWord = removePunctuation(dictWord);
      // Skip words with length difference greater than 1
      if ((cleanDictWord.length - word.length).abs() > 1) {
        continue;
      }
      int ed = levenshtein(word, cleanDictWord);
      if (ed == ed1) {
        suggestions.addFirst(cleanDictWord);
      }
      if (ed == ed2) {
        suggestions.addLast(cleanDictWord);
      }
      if (checkEd3 && ed == ed3) {
        suggestions.addLast(cleanDictWord);
      }
    }

    // Limit the number of suggestions to 15
    List<String> finalList = [];
    for (int i = 0; i < suggestions.length && i < 15; i++) {
      finalList.add(suggestions.removeFirst());
    }

    print('Suggestions for "$word": ${finalList.join(', ')}');
    return finalList;
  }

  // Function to add a word to the appropriate dictionary
  void addToDictionary(String word, bool isFarsi) {
    if (isFarsi) {
      persianDic.add(word);
      print('Added "$word" to Persian dictionary');
    } else {
      enDic.add(word);
      print('Added "$word" to English dictionary');
    }
  }
}
