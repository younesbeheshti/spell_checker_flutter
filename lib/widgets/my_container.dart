import 'package:flutter/material.dart';

class MyContainer extends StatelessWidget {
  final String word;

  MyContainer({super.key, required this.word});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8,),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.yellow[300],
        ),
        child: Center(child: Text(word, style: TextStyle(fontSize: 15),)),
      ),
    );
  }
}
