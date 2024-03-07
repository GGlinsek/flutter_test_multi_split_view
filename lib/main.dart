import 'dart:async';

import 'package:flutter/material.dart';
import 'package:test_multi_split_view/widgets/layout_widget.dart';

void main() => runApp(const MultiSplitViewExampleApp());

enum DragDirection {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  right,
  left,
  top,
  bottom
}

enum DragPosition { top, bottom, right, left }

class MultiSplitViewExampleApp extends StatelessWidget {
  const MultiSplitViewExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.orange,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(Colors.orange),
            foregroundColor: MaterialStateProperty.all(Colors.white),
          ),
        ),
      ),
      home: const MultiSplitViewExample(),
    );
  }
}

class MultiSplitViewExample extends StatefulWidget {
  const MultiSplitViewExample({super.key});

  @override
  MultiSplitViewExampleState createState() => MultiSplitViewExampleState();
}

class MultiSplitViewExampleState extends State<MultiSplitViewExample> {
  final _widgetInController = StreamController<Widget>();

  @override
  initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Multi Split View Example')),
      body: PageView(
        children: [
          LayoutWidget(
            axis: Axis.vertical,
            addWidgetController: _widgetInController,
          ),
          const ColoredBox(color: Colors.red),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        shape: const StadiumBorder(
          side: BorderSide(
            color: Colors.orange,
          ),
        ),
        onPressed: _onAddButtonClick,
        label: const Text('Add Control Widget'),
        icon: const Icon(
          Icons.add,
        ),
      ),
    );
  }

  int _widgetCounter = 0;

  _onAddButtonClick() {
    final controlWidget = Container(
      color: Colors.blue,
      child: Center(
        child: Text('Control Widget $_widgetCounter'),
      ),
    );
    _widgetCounter++;
    _widgetInController.add(controlWidget);
  }
}
