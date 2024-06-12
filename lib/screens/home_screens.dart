import 'package:flutter/material.dart';
import 'package:untitled1/logic/spell_checker.dart';
import 'package:untitled1/widgets/my_container.dart';

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

class NotePage extends StatefulWidget {
  @override
  _NotePageState createState() => _NotePageState();
}

class _NotePageState extends State<NotePage> {
  TextEditingController _controller = TextEditingController();
  SpellChecker spellChecker = SpellChecker();

  List<String> _content = [];
  List<String> suggestions = [];
  Map<int, String> incorrectWords = {};
  int currentIncorrectIndex = -1;

  late String message;
  bool isCorrect = true;
  TextDirection _textDirection = TextDirection.ltr;

  @override
  void initState() {
    super.initState();
    initSpellChecker();
    _controller.addListener(_onTextChanged);
  }

  Future<void> initSpellChecker() async {
    await spellChecker.init();
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    String text = _controller.text;

    // Change text direction based on the input language
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

    updateList();
  }

  Future<void> updateList() async {
    String text = _controller.text.trim().toLowerCase();
    _content = text.split(RegExp(r'[\s,.]+'));

    Map<int, String> newIncorrectWords = {};
    for (int i = 0; i < _content.length; i++) {
      if (!(await spellChecker.isCorrectlySpelled(_content[i]))) {
        newIncorrectWords[i] = _content[i];
      }
    }

    setState(() {
      incorrectWords = newIncorrectWords;
    });

    if (incorrectWords.isNotEmpty) {
      int firstIncorrectIndex = incorrectWords.keys.first;
      await showSuggestions(firstIncorrectIndex);
    } else {
      setState(() {
        suggestions.clear();
        currentIncorrectIndex = -1;
        isCorrect = false;
        message = 'All words are corrected!';
      });
    }
  }

  Future<void> showSuggestions(int index) async {
    if (incorrectWords.isNotEmpty && index >= 0 && index < _content.length) {
      String word = _content[index];
      List<String> newSuggestions = await spellChecker.spellCheck(word);
      setState(() {
        suggestions = newSuggestions;
        currentIncorrectIndex = index;
        message = newSuggestions.isEmpty ? 'NO suggestions...' : '';
        isCorrect = newSuggestions.isEmpty;
      });
    }
  }

  bool isFarsi(String text) {
    final farsiRegex = RegExp(r'[\u0600-\u06FF]');
    return farsiRegex.hasMatch(text);
  }

  void replaceWord(String newWord, int index) {
    if (index >= 0 && index < _content.length) {
      setState(() {
        if (newWord == "NO suggestions...") {
          incorrectWords.remove(index);
        } else {
          _content[index] = newWord;
          incorrectWords.remove(index);
        }
        suggestions.clear();
        currentIncorrectIndex = -1;

        // Update the text field
        String newText = _content.join(' ') + ' ';
        _controller.text = newText;
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length),
        );

        if (incorrectWords.isNotEmpty) {
          int nextIndex = incorrectWords.keys.first;
          showSuggestions(nextIndex);
        }
      });
    }
  }

  TextSpan buildTextSpan() {
    List<TextSpan> children = [];
    for (int i = 0; i < _content.length; i++) {
      String word = _content[i];
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.yellow.shade100,
      appBar: AppBar(
        title: Text('Spell Checker'),
        centerTitle: true,
        backgroundColor: Colors.yellow.shade200,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  VerticalDivider(
                    thickness: 1,
                    color: Colors.grey[500],
                  ),
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
            Expanded(
              flex: 2,
              child: Row(
                children: [
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
                            Padding(
                              padding: const EdgeInsets.only(
                                  top: 4.0, left: 4, right: 4),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    spellChecker.addToDictionary(
                                        incorrectWords[currentIncorrectIndex]!,
                                        SpellChecker.isTextFarsi);
                                    incorrectWords
                                        .remove(currentIncorrectIndex);
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
                            Padding(
                              padding: const EdgeInsets.only(
                                  top: 4.0, left: 4, right: 4),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
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
                            Padding(
                              padding: const EdgeInsets.only(
                                  top: 4.0, left: 4, right: 4),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
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
