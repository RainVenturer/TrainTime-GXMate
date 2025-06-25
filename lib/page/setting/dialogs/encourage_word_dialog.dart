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
  int? _editingIndex;
  final TextEditingController _editingController = TextEditingController();

  @override
  void initState() {
    super.initState();
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
      if (_editingIndex == index) {
        _editingIndex = null;
      }
      _words.removeAt(index);
    });
  }

  void _startEditing(int index) {
    setState(() {
      _editingIndex = index;
      _editingController.text = _words[index];
    });
  }

  void _saveEditing(int index) {
    if (_editingController.text.trim().isNotEmpty) {
      setState(() {
        _words[index] = _editingController.text.trim();
        _editingIndex = null;
      });
    }
  }

  void _cancelEditing() {
    setState(() {
      _editingIndex = null;
    });
  }

  Future<void> _saveWords() async {
    await _controller.editEncourageWords(_words);
  }

  @override
  void dispose() {
    _newWordController.dispose();
    _editingController.dispose();
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
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.4,
                child: ReorderableListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  buildDefaultDragHandles: false,
                  itemCount: _words.length,
                  proxyDecorator: (child, index, animation) => Material(
                    elevation: 2,
                    color: Colors.transparent,
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.7,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor.withAlpha(230),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: child,
                      ),
                    ),
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
                    return SizedBox(
                      key: ValueKey('${index}_${_words[index]}_${TimeOfDay.now()}'),
                      height: 48,
                      child: Card(
                        margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 0),
                        child: ListTile(
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          leading: ReorderableDragStartListener(
                            index: index,
                            child: const Icon(Icons.drag_handle, size: 20),
                          ),
                          title: _editingIndex == index
                              ? TextField(
                                  controller: _editingController,
                                  autofocus: true,
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    height: 1.0,
                                  ),
                                  onSubmitted: (_) => _saveEditing(index),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                                    border: InputBorder.none,
                                  ),
                                )
                              : Text(
                                  _words[index],
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    height: 1.0,
                                  ),
                                ),
                          onTap: _editingIndex == null ? () => _startEditing(index) : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_editingIndex == index) ...[
                                IconButton(
                                  icon: const Icon(Icons.check, size: 20),
                                  onPressed: () => _saveEditing(index),
                                  tooltip: FlutterI18n.translate(context, "save"),
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 20),
                                  onPressed: _cancelEditing,
                                  tooltip: FlutterI18n.translate(context, "cancel"),
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                ),
                              ] else
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 20),
                                  onPressed: () => _deleteWord(index),
                                  tooltip: FlutterI18n.translate(context, "delete"),
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
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
