import 'dart:async';

import 'package:flutter/material.dart';

enum MoveDirection { up, down, left, right, unknown }

typedef EdgeRecord = ({
  MovableBox targetBox,
  MovableBox movedBox,
  MoveDirection moveDirection
});

typedef MoveRecord = ({MovableBox targetBox, MovableBox movedBox});

class MovableBox extends StatefulWidget {
  final Widget child;
  final StreamController<bool> onMoveController;
  final StreamController<MoveRecord> onMovedController;
  final StreamController<Key> removedController;
  final StreamController<EdgeRecord> onEdgeController;

  const MovableBox({
    required this.child,
    required this.onMoveController,
    required this.onMovedController,
    required this.removedController,
    required this.onEdgeController,
    required super.key,
  });

  @override
  State<MovableBox> createState() => _MovableBoxState();
}

class _MovableBoxState extends State<MovableBox> {
  bool _showTopBorder = false;
  bool _showBottomBorder = false;
  bool _showLeftBorder = false;
  bool _showRightBorder = false;
  // static const barSize = 50.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double horizontalBarSize = constraints.maxHeight / 4;
        double verticalBarSize = constraints.maxWidth / 4;
        return LongPressDraggable<MovableBox>(
          data: widget,
          feedback: Material(
            elevation: 4,
            color: Colors.grey.withAlpha(150),
            type: MaterialType.canvas,
            child: SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              // decoration: BoxDecoration(
              //   border: Border.all(
              //     color: Colors.black,
              //     width: 2,
              //   ),
              // ),
              //child: widget.child,
            ),
          ),
          child: SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: Stack(
              children: [
                SizedBox.expand(
                  child: DragTarget<MovableBox>(
                    onWillAcceptWithDetails: (details) {
                      return true;
                    },
                    onAcceptWithDetails: (details) {
                      MoveRecord record =
                          (movedBox: details.data, targetBox: widget);
                      widget.onMovedController.add(record);
                    },
                    builder: (_, candidateData, ___) {
                      return widget.child;
                    },
                  ),
                ),
                Positioned(
                  top: 0,
                  width: constraints.maxWidth,
                  child: DragTarget<MovableBox>(
                    onMove: (details) {
                      setState(() {
                        _showTopBorder = true;
                      });
                    },
                    onLeave: (details) {
                      setState(() {
                        _showTopBorder = false;
                      });
                    },
                    onAcceptWithDetails: (details) {
                      setState(() {
                        _showTopBorder = false;
                      });
                      EdgeRecord r = (
                        moveDirection: MoveDirection.up,
                        targetBox: widget,
                        movedBox: details.data
                      );
                      widget.onEdgeController.add(r);
                    },
                    builder: (_, candidateData, ___) {
                      Color color = Colors.black.withAlpha(100);
                      if (!_showTopBorder) {
                        color = Colors.transparent;
                      }
                      return IgnorePointer(
                        ignoring: !_showTopBorder,
                        child: Container(
                          color: color,
                          height: horizontalBarSize,
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  bottom: 0,
                  width: constraints.maxWidth,
                  child: DragTarget<MovableBox>(
                    onMove: (details) {
                      setState(() {
                        _showBottomBorder = true;
                      });
                    },
                    onLeave: (details) {
                      setState(() {
                        _showBottomBorder = false;
                      });
                    },
                    onAcceptWithDetails: (details) {
                      setState(() {
                        _showBottomBorder = false;
                      });
                      EdgeRecord e = (
                        moveDirection: MoveDirection.down,
                        targetBox: widget,
                        movedBox: details.data
                      );
                      widget.onEdgeController.add(e);
                    },
                    builder: (_, candidateData, ___) {
                      Color color = Colors.black.withAlpha(100);
                      if (!_showBottomBorder) {
                        color = Colors.transparent;
                      }
                      return IgnorePointer(
                        ignoring: !_showBottomBorder,
                        child: Container(
                          color: color,
                          height: horizontalBarSize,
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  left: 0,
                  height: constraints.maxHeight,
                  child: DragTarget<MovableBox>(
                    onMove: (details) {
                      setState(() {
                        _showLeftBorder = true;
                      });
                    },
                    onLeave: (details) {
                      setState(() {
                        _showLeftBorder = false;
                      });
                    },
                    onAcceptWithDetails: (details) {
                      setState(() {
                        _showLeftBorder = false;
                      });
                      EdgeRecord e = (
                        moveDirection: MoveDirection.left,
                        targetBox: widget,
                        movedBox: details.data
                      );
                      widget.onEdgeController.add(e);
                    },
                    builder: (_, candidateData, ___) {
                      Color color = Colors.black.withAlpha(100);
                      if (!_showLeftBorder) {
                        color = Colors.transparent;
                      }
                      return IgnorePointer(
                        ignoring: !_showLeftBorder,
                        child: Container(
                          color: color,
                          width: verticalBarSize,
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  right: 0,
                  height: constraints.maxHeight,
                  child: DragTarget<MovableBox>(
                    onMove: (details) {
                      setState(() {
                        _showRightBorder = true;
                      });
                    },
                    onLeave: (details) {
                      setState(() {
                        _showRightBorder = false;
                      });
                    },
                    onAcceptWithDetails: (details) {
                      setState(() {
                        _showRightBorder = false;
                      });
                      EdgeRecord e = (
                        moveDirection: MoveDirection.right,
                        targetBox: widget,
                        movedBox: details.data
                      );
                      widget.onEdgeController.add(e);
                    },
                    builder: (_, candidateData, ___) {
                      Color color = Colors.black.withAlpha(100);
                      if (!_showRightBorder) {
                        color = Colors.transparent;
                      }
                      return IgnorePointer(
                        ignoring: !_showRightBorder,
                        child: Container(
                          color: color,
                          width: verticalBarSize,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
