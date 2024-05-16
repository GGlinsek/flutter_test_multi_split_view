import 'dart:async';

import 'package:flutter/material.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:test_multi_split_view/widgets/draggable_multi_list_view.dart';

import 'movable_box.dart';

class LayoutWidget extends StatefulWidget {
  final StreamController<Area>? addWidgetController;
  final Axis axis;

  const LayoutWidget({
    required this.axis,
    this.addWidgetController,
    super.key,
  });

  @override
  State<LayoutWidget> createState() => _LayoutWidgetState();
}

class _LayoutWidgetState extends State<LayoutWidget> with AutomaticKeepAliveClientMixin {
  final _widgetInController = StreamController<Area>();
  final _widgetMovedOutController =
      StreamController<(MovableBox, MoveDirection)>();

  @override
  void initState() {
    if (widget.addWidgetController?.hasListener != null) {
      widget.addWidgetController?.stream.listen((area) {
        _widgetInController.add(area);
      });
    }
    if (!_widgetMovedOutController.hasListener) {
      _widgetMovedOutController.stream.listen((data) {
        debugPrint("Widget moved out: ${data.$1}");
        setState(() {});
      });
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return MultiSplitViewTheme(
      data: MultiSplitViewThemeData(
        dividerPainter: DividerPainters.grooved1(),
        dividerThickness: 20,
      ),
      child: DraggableMultiListView(
        axis: widget.axis,
        onWidgetInController: _widgetInController,
        onWidgetMovedOutController: _widgetMovedOutController,
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
