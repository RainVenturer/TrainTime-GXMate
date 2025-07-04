// Copyright 2023-2025 BenderBlog Rodriguez and contributors
// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0

// Electricity password dialog.

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:watermeter/page/public_widget/toast.dart';
import 'package:watermeter/repository/preference.dart' as preference;

class SchoolCardPasswordDialog extends StatefulWidget {
  const SchoolCardPasswordDialog({super.key});

  @override
  State<SchoolCardPasswordDialog> createState() =>
      _SchoolCardPasswordDialogState();
}

class _SchoolCardPasswordDialogState extends State<SchoolCardPasswordDialog> {
  /// Sport Password Text Editing Controller
  final TextEditingController _sportPasswordController =
      TextEditingController.fromValue(TextEditingValue(
    text: preference.getString(preference.Preference.schoolCardPassword),
    selection: TextSelection.fromPosition(TextPosition(
      affinity: TextAffinity.downstream,
      offset: preference
          .getString(preference.Preference.schoolCardPassword)
          .length,
    )),
  ));

  bool _couldView = true;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(FlutterI18n.translate(
        context,
        "setting.schoolcard_password_setting",
      )),
      content: TextField(
        autofocus: true,
        controller: _sportPasswordController,
        obscureText: _couldView,
        decoration: InputDecoration(
          hintText: FlutterI18n.translate(
            context,
            "setting.change_password_dialog.input_hint",
          ),
          suffixIcon: IconButton(
            icon: Icon(_couldView ? Icons.visibility : Icons.visibility_off),
            onPressed: () => setState(() => _couldView = !_couldView),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text(
            FlutterI18n.translate(
              context,
              "cancel",
            ),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        TextButton(
          child: Text(
            FlutterI18n.translate(
              context,
              "confirm",
            ),
          ),
          onPressed: () async {
            if (_sportPasswordController.text.isEmpty) {
              showToast(
                context: context,
                msg: FlutterI18n.translate(
                  context,
                  "setting.change_password_dialog.blank_input",
                ),
              );
            }
            preference.setString(
              preference.Preference.schoolCardPassword,
              _sportPasswordController.text,
            );
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
