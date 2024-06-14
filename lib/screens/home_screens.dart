import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:untitled1/logic/spell_checker.dart';
import 'package:untitled1/widgets/my_container.dart';

// Main entry point of the Note Taking App
class NoteTakingApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Note Taking App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: NotePage(),
    );
  }
}

// Stateful widget to handle note taking and spell checking
class NotePage extends StatefulWidget {
  @override
  _NotePageState createState() => _NotePageState();
}

class _NotePageState extends State<NotePage> {
  // Controller for text input
  TextEditingController _controller = TextEditingController();

  // Instance of the SpellChecker
  SpellChecker spellChecker = SpellChecker();

  // List to store the content of the notes
  List<String> _content = [];
  // List to store suggestions for incorrect words
  List<String> suggestions = [];
  // Map to store the index and value of incorrect words
  Map<int, String> incorrectWords = {};
  // Index of the current incorrect word
  int currentIncorrectIndex = -1;

  // Variables to store messages and text direction
  late String message;
  bool isCorrect = true;
  TextDirection _textDirection = TextDirection.ltr;

  @override
  void initState() {
    super.initState();
    // Initialize the spell checker
    initSpellChecker();
    // Add listener to text field to monitor text changes
    _controller.addListener(_onTextChanged);
  }

  // Asynchronous method to initialize spell checker
  Future<void> initSpellChecker() async {
    await spellChecker.init();
  }

  @override
  void dispose() {
    // Remove listener and dispose controller
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  // Method called when the text in the text field changes
  void _onTextChanged() {
    String text = _controller.text;

    // Change text direction based on the input language (Farsi or not)
    if (isFarsi(text)) {
      setState(() {
        _textDirection = TextDirection.rtl;
        SpellChecker.isTextFarsi = true;
      });
    } else {
      setState(() {
        _textDirection = TextDirection.ltr;
        SpellChecker.isTextFarsi = false;
      });
    }

    // Update the list of words and check for spelling errors
    updateList();
  }

  // Asynchronous method to update the list of words and check for spelling errors
  Future<void> updateList() async {
    // Get the text from the controller and split it into words
    String text = _controller.text.trim().toLowerCase();
    _content = text.split(RegExp(r'[\s,.]+'));

    // Create a new map for incorrect words
    Map<int, String> newIncorrectWords = {};
    for (int i = 0; i < _content.length; i++) {
      // Check if each word is correctly spelled
      if (!(await spellChecker.isCorrectlySpelled(_content[i]))) {
        // Add incorrect words to the map
        newIncorrectWords[i] = _content[i];
      }
    }

    // Update the state with the new map of incorrect words
    setState(() {
      incorrectWords = newIncorrectWords;
    });

    // If there are incorrect words, show suggestions for the first one
    if (incorrectWords.isNotEmpty) {
      int firstIncorrectIndex = incorrectWords.keys.first;
      await showSuggestions(firstIncorrectIndex);
    } else {
      // If all words are correct, clear suggestions and update the message
      setState(() {
        suggestions.clear();
        currentIncorrectIndex = -1;
        isCorrect = false;
        message = 'All words are corrected!';
      });
    }
  }

  // Asynchronous method to show suggestions for the incorrect word
  Future<void> showSuggestions(int index) async {
    // Check if there are incorrect words and the index is valid
    if (incorrectWords.isNotEmpty && index >= 0 && index < _content.length) {
      String word = _content[index];
      // Get suggestions for the incorrect word
      List<String> newSuggestions = await spellChecker.spellCheck(word);
      // Update the state with the new suggestions
      setState(() {
        suggestions = newSuggestions;
        currentIncorrectIndex = index;
        message = newSuggestions.isEmpty ? 'NO suggestions...' : '';
        isCorrect = newSuggestions.isEmpty;
      });
    }
  }

  // Method to check if the text contains Farsi characters
  bool isFarsi(String text) {
    final farsiRegex = RegExp(r'[\u0600-\u06FF]');
    return farsiRegex.hasMatch(text);
  }

  // Method to replace the incorrect word with the selected suggestion
  void replaceWord(String newWord, int index) {
    // Check if the index is valid
    if (index >= 0 && index < _content.length) {
      setState(() {
        // If no suggestions are available, remove the incorrect word
        if (newWord == "NO suggestions...") {
          incorrectWords.remove(index);
        } else {
          // Replace the incorrect word with the new word
          _content[index] = newWord;
          incorrectWords.remove(index);
        }
        suggestions.clear();
        currentIncorrectIndex = -1;

        // Update the text field with the new content
        String newText = _content.join(' ') + ' ';
        _controller.text = newText;
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length),
        );

        // If there are more incorrect words, show suggestions for the next one
        if (incorrectWords.isNotEmpty) {
          int nextIndex = incorrectWords.keys.first;
          showSuggestions(nextIndex);
        }
      });
    }
  }

  // Method to build a TextSpan for the RichText widget
  TextSpan buildTextSpan() {
    List<TextSpan> children = [];
    for (int i = 0; i < _content.length; i++) {
      String word = _content[i];
      // Create a TextSpan for each word with the appropriate style
      TextSpan span = TextSpan(
        text: word + ' ',
        style: TextStyle(
          color: incorrectWords.containsKey(i) ? Colors.red : Colors.black,
          decoration: incorrectWords.containsKey(i)
              ? TextDecoration.underline
              : TextDecoration.none,
        ),
      );
      children.add(span);
    }
    return TextSpan(children: children);
  }

  // Method to copy the content to clipBoard
  void _copyTextToClipBoard() {
    setState(() async {
      await Clipboard.setData(ClipboardData(text: _controller.text));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Text copied to clipboard!'),
        ),
      );
    });
    print("text copied!");
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.yellow.shade100,
      appBar: AppBar(
        title: Text('Spell Checker'),
        centerTitle: true,
        backgroundColor: Colors.yellow.shade200,
        actions: [
          Padding(
            padding: const EdgeInsets.only(top:8.0, right: 8),
            child: GestureDetector(
                onTap: _copyTextToClipBoard,
                child: Icon(Icons.copy)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Text input and display area
            Expanded(
              flex: 3,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Text input field
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _controller,
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      expands: false,
                      autocorrect: true,
                      textDirection: _textDirection,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Type your notes here...',
                      ),
                    ),
                  ),
                  // Divider between input field and display area
                  VerticalDivider(
                    thickness: 1,
                    color: Colors.grey[500],
                  ),
                  // Display area with highlighted incorrect words
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.yellow[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: SingleChildScrollView(
                          child: RichText(
                            textDirection: _textDirection,
                            text: buildTextSpan(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              color: Colors.grey[500],
            ),
            // Suggestions and actions area
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  // Suggestions list
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: 8.0,
                        bottom: 8,
                        right: 4,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12.0),
                          color: Colors.yellow[200],
                        ),
                        child: ListView.builder(
                          itemCount:
                          suggestions.isNotEmpty ? suggestions.length : 1,
                          itemBuilder: (context, index) {
                            if (suggestions.isNotEmpty) {
                              return GestureDetector(
                                onTap: () {
                                  replaceWord(suggestions[index],
                                      currentIncorrectIndex);
                                },
                                child: MyContainer(word: suggestions[index]),
                              );
                            } else if (!isCorrect) {
                              return GestureDetector(
                                onTap: () {
                                  replaceWord("NO suggestions...",
                                      currentIncorrectIndex);
                                },
                                child: MyContainer(word: message),
                              );
                            } else {
                              return GestureDetector(
                                onTap: () {
                                  replaceWord("NO suggestions...",
                                      currentIncorrectIndex);
                                },
                                child: MyContainer(word: "No Suggestion.."),
                              );
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                  // Actions area
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: 8.0,
                        left: 4,
                        bottom: 8,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12.0),
                          color: Colors.yellow[200],
                        ),
                        child: Column(
                          children: [
                            // Add to the dictionary button
                            Padding(
                              padding: const EdgeInsets.only(
                                  top: 4.0, left: 4, right: 4),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    // Add the incorrect word to the dictionary
                                    spellChecker.addToDictionary(
                                        incorrectWords[currentIncorrectIndex]!,
                                        SpellChecker.isTextFarsi);
                                    incorrectWords
                                        .remove(currentIncorrectIndex);
                                    // Show suggestions for the next incorrect word
                                    currentIncorrectIndex =
                                        incorrectWords.keys.first;
                                    updateList();
                                  });
                                },
                                child: MyContainer(
                                  word: "Add to the dictionary",
                                ),
                              ),
                            ),
                            // Next word button
                            Padding(
                              padding: const EdgeInsets.only(
                                  top: 4.0, left: 4, right: 4),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    // Remove the current incorrect word and show suggestions for the next one
                                    incorrectWords
                                        .remove(currentIncorrectIndex);
                                    currentIncorrectIndex =
                                        incorrectWords.keys.first;
                                    updateList();
                                  });
                                },
                                child: MyContainer(
                                  word: "Next Word..",
                                ),
                              ),
                            ),
                            // Check again button
                            Padding(
                              padding: const EdgeInsets.only(
                                  top: 4.0, left: 4, right: 4),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    // Toggle the checkEd3 flag and update the list
                                    spellChecker.checkEd3 = !spellChecker.checkEd3;
                                    updateList();
                                  });
                                },
                                child: MyContainer(
                                  word: "Check Again!",
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
