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

/// Constants for styling and dimensions
class _DialogConstants {
  static const double itemHeight = 48.0;
  static const double iconSize = 20.0;
  static const double fontSize = 15.0;
  static const double verticalSpacing = 15.0;
  static const double verticalContentPadding = 8.0;
  
  static const EdgeInsets itemMargin = EdgeInsets.symmetric(vertical: 2, horizontal: 0);
  static const EdgeInsets listPadding = EdgeInsets.symmetric(vertical: 4);
  
  static const BoxConstraints buttonConstraints = BoxConstraints(
    minWidth: 32,
    minHeight: 32,
  );
}

/// A dialog for editing encourage words with inline editing capabilities
class EditEncourageWordDialog extends StatefulWidget {
  const EditEncourageWordDialog({super.key});

  @override
  State<EditEncourageWordDialog> createState() => _EditEncourageWordDialogState();
}

class _EditEncourageWordDialogState extends State<EditEncourageWordDialog> {
  final TextEditingController _newWordController = TextEditingController();
  final TextEditingController _editingController = TextEditingController();
  final EncourageWordController _controller = Get.find<EncourageWordController>();
  
  late List<String> _words;
  int? _editingIndex;

  @override
  void initState() {
    super.initState();
    _words = List<String>.from(_controller.encourageWord.words);
  }

  @override
  void dispose() {
    _newWordController.dispose();
    _editingController.dispose();
    super.dispose();
  }

  void _addWord() {
    final word = _newWordController.text.trim();
    if (word.isNotEmpty) {
      setState(() {
        _words.add(word);
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
    final word = _editingController.text.trim();
    if (word.isNotEmpty) {
      setState(() {
        _words[index] = word;
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

  void _handleReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _words.removeAt(oldIndex);
      _words.insert(newIndex, item);
    });
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
              child: _buildWordList(context),
            ),
            const SizedBox(height: _DialogConstants.verticalSpacing),
            _buildAddWordRow(context),
          ],
        ),
      ),
      actions: _buildDialogActions(context),
    );
  }

  Widget _buildWordList(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.4,
      child: ReorderableListView.builder(
        padding: _DialogConstants.listPadding,
        buildDefaultDragHandles: false,
        itemCount: _words.length,
        proxyDecorator: (child, index, animation) => _buildDraggedItem(context, child),
        onReorder: _handleReorder,
        itemBuilder: (context, index) => EncourageWordItem(
          key: ValueKey('${index}_${_words[index]}_${TimeOfDay.now()}'),
          word: _words[index],
          index: index,
          isEditing: _editingIndex == index,
          editingController: _editingController,
          onStartEditing: _startEditing,
          onSaveEditing: _saveEditing,
          onCancelEditing: _cancelEditing,
          onDelete: _deleteWord,
        ),
      ),
    );
  }

  Widget _buildDraggedItem(BuildContext context, Widget child) {
    return Material(
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
    );
  }

  Widget _buildAddWordRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _newWordController,
            onSubmitted: (_) => _addWord(),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          icon: const Icon(Icons.add),
          onPressed: _addWord,
          tooltip: FlutterI18n.translate(context, "setting.add_encourage_word"),
        ),
      ],
    );
  }

  List<Widget> _buildDialogActions(BuildContext context) {
    return [
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
    ];
  }
}

/// A list item widget for displaying and editing an encourage word
class EncourageWordItem extends StatelessWidget {
  final String word;
  final int index;
  final bool isEditing;
  final TextEditingController editingController;
  final void Function(int) onStartEditing;
  final void Function(int) onSaveEditing;
  final VoidCallback onCancelEditing;
  final void Function(int) onDelete;

  const EncourageWordItem({
    super.key,
    required this.word,
    required this.index,
    required this.isEditing,
    required this.editingController,
    required this.onStartEditing,
    required this.onSaveEditing,
    required this.onCancelEditing,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _DialogConstants.itemHeight,
      child: Card(
        margin: _DialogConstants.itemMargin,
        child: ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          leading: ReorderableDragStartListener(
            index: index,
            child: const Icon(
              Icons.drag_handle,
              size: _DialogConstants.iconSize,
            ),
          ),
          title: _buildTitle(context),
          onTap: !isEditing ? () => onStartEditing(index) : null,
          trailing: _buildTrailingButtons(context),
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
      fontSize: _DialogConstants.fontSize,
      fontWeight: FontWeight.w500,
      height: 1.0,
    );

    if (isEditing) {
      return TextField(
        controller: editingController,
        autofocus: true,
        style: textStyle,
        onSubmitted: (_) => onSaveEditing(index),
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(
            vertical: _DialogConstants.verticalContentPadding,
          ),
          border: InputBorder.none,
        ),
      );
    }

    return Text(word, style: textStyle);
  }

  Widget _buildTrailingButtons(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isEditing) ...[
          _buildIconButton(
            context: context,
            icon: Icons.check,
            tooltip: "save",
            onPressed: () => onSaveEditing(index),
          ),
          _buildIconButton(
            context: context,
            icon: Icons.close,
            tooltip: "cancel",
            onPressed: onCancelEditing,
          ),
        ] else
          _buildIconButton(
            context: context,
            icon: Icons.delete_outline,
            tooltip: "delete",
            onPressed: () => onDelete(index),
          ),
      ],
    );
  }

  Widget _buildIconButton({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      icon: Icon(icon, size: _DialogConstants.iconSize),
      onPressed: onPressed,
      tooltip: FlutterI18n.translate(context, tooltip),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: _DialogConstants.buttonConstraints,
    );
  }
}
