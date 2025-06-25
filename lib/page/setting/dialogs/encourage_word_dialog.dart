// Copyright 2025 RainVenturer and contributors
// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0 OR Apache-2.0

// import 'dart:io';
// import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
// import 'package:watermeter/model/encourage_word/encourage_word.dart';
// import 'package:watermeter/page/homepage/home.dart';
import 'package:get/get.dart';
import 'package:watermeter/controller/encourage_word_controller.dart';

class EditEncourageWordDialog extends StatefulWidget {
  const EditEncourageWordDialog({super.key});

  @override
  State<EditEncourageWordDialog> createState() => _EditEncourageWordDialogState();
}

class _EditEncourageWordDialogState extends State<EditEncourageWordDialog> {
  final TextEditingController _newWordController = TextEditingController();
  final EncourageWordController _controller = Get.find<EncourageWordController>();
  late List<String> _words;

  @override
  void initState() {
    super.initState();
    // 创建一个新的列表来存储编辑中的数据
    _words = List<String>.from(_controller.encourageWord.words);
  }

  void _addWord() {
    if (_newWordController.text.trim().isNotEmpty) {
      setState(() {
        _words.add(_newWordController.text.trim());
        _newWordController.clear();
      });
    }
  }

  void _deleteWord(int index) {
    setState(() {
      _words.removeAt(index);
    });
  }

  Future<void> _saveWords() async {
    await _controller.editEncourageWords(_words);
  }

  @override
  void dispose() {
    _newWordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(FlutterI18n.translate(context, "setting.edit_encourage_word")),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: ReorderableListView.builder(
                shrinkWrap: true,
                itemCount: _words.length,
                buildDefaultDragHandles: false,
                proxyDecorator: (child, index, animation) => Material(
                  elevation: 0,
                  color: Colors.transparent,
                  child: child,
                ),
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) {
                      newIndex -= 1;
                    }
                    final item = _words.removeAt(oldIndex);
                    _words.insert(newIndex, item);
                  });
                },
                itemBuilder: (context, index) {
                  return Card(
                    key: ValueKey(_words[index]),
                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 1),
                    child: ListTile(
                      leading: ReorderableDragStartListener(
                        index: index,
                        child: const Icon(Icons.drag_handle),
                      ),
                      title: Text(
                        _words[index],
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          height: 1.0,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _deleteWord(index),
                        tooltip: FlutterI18n.translate(context, "delete"),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newWordController,
                    // decoration: InputDecoration(
                    //   hintText: FlutterI18n.translate(
                    //     context,
                    //     "setting.new_encourage_word",
                    //   ),
                    //   border: const OutlineInputBorder(),
                    // ),
                    onSubmitted: (_) => _addWord(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.add),
                  onPressed: _addWord,
                  tooltip: FlutterI18n.translate(
                    context,
                    "setting.add_encourage_word",
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(FlutterI18n.translate(context, "cancel")),
        ),
        FilledButton(
          onPressed: () async {
            final navigator = Navigator.of(context);
            await _saveWords();
            if (mounted) {
              navigator.pop();
            }
          },
          child: Text(FlutterI18n.translate(context, "save")),
        ),
      ],
    );
  }
}
