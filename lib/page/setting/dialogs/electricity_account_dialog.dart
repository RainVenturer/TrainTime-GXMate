// Copyright 2023-2025 BenderBlog Rodriguez and contributors
// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0

// Electricity account dialog.

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:styled_widget/styled_widget.dart';
import 'package:watermeter/page/public_widget/toast.dart';
import 'package:watermeter/repository/preference.dart' as preference;
import 'package:watermeter/page/public_widget/timeline_widget/dropdown_button.dart';
import 'package:watermeter/repository/gxmu_hwpt/electricitu_constant.dart';

class ElectricityAccountDialog extends StatefulWidget {
  const ElectricityAccountDialog({super.key});

  @override
  State<ElectricityAccountDialog> createState() =>
      _ElectricityAccountDialogState();
}

class _ElectricityAccountDialogState extends State<ElectricityAccountDialog> {
  final bool isInHeadquarters =
      preference.getBool(preference.Preference.isInHeadQuarters);

  final TextEditingController _controller =
      TextEditingController.fromValue(TextEditingValue(
    text: preference.getString(preference.Preference.location) == ""
        ? ""
        : preference.getString(preference.Preference.location).split("/")[1],
    selection: TextSelection.fromPosition(TextPosition(
      affinity: TextAffinity.downstream,
      offset: preference.getString(preference.Preference.location) == ""
          ? 0
          : preference
              .getString(preference.Preference.location)
              .split("/")[1]
              .length,
    )),
  ));

  final bool _isInHeadquarters =
      preference.getBool(preference.Preference.isInHeadQuarters);

  String _building = "";
  String _room = "";

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(FlutterI18n.translate(
        context,
        "setting.change_electricity_account.title",
      )),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Campus Selection using DropdownButtonWidget
          DropdownButtonWidget(
            label: FlutterI18n.translate(
              context,
              "setting.change_electricity_account.building_selection",
            ),
            items: _isInHeadquarters ? buildingListBB : buildingListWM,
            value: preference.getString(preference.Preference.location) == ""
                ? _isInHeadquarters
                    ? buildingListBB.first
                    : buildingListWM.first
                : preference
                    .getString(preference.Preference.location)
                    .split("/")[0],
            onChanged: (String? value) {
              if (value != null) {
                setState(() {
                  _building = value;
                });
              }
            },
          ),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: FlutterI18n.translate(
                context,
                _isInHeadquarters
                    ? "setting.change_electricity_account.benbu"
                    : "setting.change_electricity_account.wuming",
              ),
              hintText: FlutterI18n.translate(
                context,
                _isInHeadquarters
                    ? "setting.change_electricity_account.benbu_hint"
                    : "setting.change_electricity_account.wuming_hint",
              ),
            ),
            onChanged: (String? value) {
              if (value != null) {
                setState(() {
                  _room = value;
                });
              }
            },
          ),
          if (_isInHeadquarters)
            Text(
              FlutterI18n.translate(
                context,
                "setting.change_electricity_account.info",
              ),
              style: TextStyle(
                fontSize: 14,
                color: Colors.orange[800],
                height: 1.4,
              ),
            )
                .padding(all: 16)
                .decorated(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange[200]!),
                )
                .padding(all: 4),
        ],
      ),
      actions: <Widget>[
        TextButton(
          child: Text(FlutterI18n.translate(
            context,
            "cancel",
          )),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        TextButton(
          child: Text(FlutterI18n.translate(
            context,
            "confirm",
          )),
          onPressed: () async {
            _room = _room.trim();
            if (_building.isNotEmpty &&
                _room.isNotEmpty &&
                _room.length >= 3 &&
                _room.length <= 4) {
              // Save to general location preference for request
              await preference.setString(
                preference.Preference.location,
                "$_building/$_room",
              );
              if (!context.mounted) return;
              Navigator.pop(context);
            } else {
              showToast(
                context: context,
                msg: FlutterI18n.translate(
                  context,
                  "setting.change_electricity_account.invalid_input",
                ),
              );
            }
          },
        ),
      ],
    );
  }
}
