import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:multi_split_view/multi_split_view.dart';

class SerializableMultiSplitView extends MultiSplitView {
  SerializableMultiSplitView({
    super.axis,
    super.controller,
    super.onDividerDragUpdate,
    super.resizable,
    required super.key,
  });

  // toJson() {
  //   return {
  //     'key': key ?? UniqueKey(),
  //     'children': jsonEncode(children),
  //     'axis': axis,
  //   };
  // }
  //
  // static SerializableMultiSplitView fromJson(Map<String, dynamic> json) {
  //   return SerializableMultiSplitView(
  //     key: json.containsKey("key") ? json['key'] : UniqueKey(),
  //     children: json['children'],
  //     axis: json['axis'],
  //   );
  // }
}
