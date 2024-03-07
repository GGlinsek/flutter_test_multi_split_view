import 'dart:convert';

import 'package:flutter/widgets.dart';

class TreeNode<T> {
  /// The key of the node
  Key key;

  /// The item of the node
  final T item;

  /// The list of nodes
  final List<TreeNode<T>> nodes;

  /// The parent of the node
  TreeNode<T>? parent;

  TreeNode(this.key, {required this.item, this.parent, required this.nodes});

  /// Change the parent of the node
  changeParent(TreeNode<T> newParent) {
    parent = newParent;
  }

  /// Convert the node to a json object
  Map<String, dynamic> toJson() {
    return {
      'key': key.toString(),
      'item': jsonEncode(item),
      'parent_key': parent?.key.toString(),
      'nodes': nodes.map((node) => node.toJson()).toList(),
    };
  }

  /// Create a node from a json object
  factory TreeNode.fromJson(Map<String, dynamic> json) {
    return TreeNode<T>(
      Key(json['key']),
      item: jsonDecode(json['item']),
      nodes: json['nodes']
          .map((e) => TreeNode<T>.fromJson(e))
          .toList()
          .cast<TreeNode<T>>(),
    );
  }
}

class Tree<T> {
  final TreeNode<T> root;

  Tree(this.root);

  /// Insert a node into the tree
  insert(TreeNode<T> node, TreeNode<T> parent) {
    node.changeParent(parent);
    parent.nodes.add(node);
  }

  /// Remove a node from the tree
  remove(TreeNode<T> node, TreeNode<T> parent) {
    parent.nodes.remove(node);
  }

  /// Search for a node in the tree
  search(TreeNode<T> node, TreeNode<T> parent) {
    return parent.nodes.contains(node);
  }

  Map<String, dynamic> toJson() {
    return root.toJson();
  }

  /// Traverse the tree and fix the parent of each node
  traverseAndFixParent(TreeNode<T> node, TreeNode<T>? parent) {
    node.parent = parent;
    for (final n in node.nodes) {
      traverseAndFixParent(n, node);
    }
  }

  static Tree<T> fromJson<T>(Map<String, dynamic> json) {
    final tree = Tree<T>(
      TreeNode<T>(
        Key(json['key']),
        item: jsonDecode(json['item']),
        //parent: json.containsKey('parent') ? jsonDecode(json['parent']) : null,
        nodes: json['nodes']
            .map((e) => TreeNode<T>.fromJson(e))
            .toList()
            .cast<TreeNode<T>>(),
      ),
    );
    tree.traverseAndFixParent(tree.root, null);
    return tree;
  }

}


