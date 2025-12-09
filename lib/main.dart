import 'package:flutter/material.dart';

void main() {
  runApp(
    MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.orange,
        appBar: AppBar(
          title: const Text('Home'),
        ),
        body: const Center(
          child: Text("here is the body"),
        ),
      ),
    ),
  );
}
