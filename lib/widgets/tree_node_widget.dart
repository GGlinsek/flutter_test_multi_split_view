import 'package:flutter/widgets.dart';
import 'package:test_multi_split_view/data_types/tree.dart';

class TreeNodeWidget extends StatefulWidget {
  final TreeNode<Widget> node;

  const TreeNodeWidget({
    super.key,
    required this.node,
  });

  @override
  State<StatefulWidget> createState() => _TreeNodeWidgetState();
}

class _TreeNodeWidgetState extends State<TreeNodeWidget> {
  @override
  Widget build(BuildContext context) {
    return widget.node.item;
  }
}
