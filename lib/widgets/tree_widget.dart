import 'package:flutter/widgets.dart';
import 'package:multi_split_view/multi_split_view.dart';

import '../data_types/tree.dart';

class TreeWidget extends StatefulWidget {
  final Axis rootAxis;
  final Tree<MultiSplitView> tree;

  const TreeWidget({
    super.key,
    required this.rootAxis,
    required this.tree,
  });

  static TreeWidget fromJson(Map<String, dynamic> json) {
    return Tree.fromJson<Widget>(json) as TreeWidget;
  }

  @override
  State<StatefulWidget> createState() => _TreeWidgetState();
}

class _TreeWidgetState extends State<TreeWidget> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MultiSplitViewTheme(
      data: MultiSplitViewThemeData(
        dividerPainter: DividerPainters.grooved1(),
        dividerThickness: 20,
      ),
      child: widget.tree.root.item,
    );
  }
}
