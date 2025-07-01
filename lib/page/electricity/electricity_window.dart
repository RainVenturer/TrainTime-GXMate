// Copyright 2023-2025 BenderBlog Rodriguez and contributors
// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:styled_widget/styled_widget.dart';
import 'package:watermeter/page/public_widget/info_card.dart';
import 'package:watermeter/repository/preference.dart' as preference;
import 'package:watermeter/repository/gxmu_hwpt/electricity_session.dart';

class ElectricityWindow extends StatelessWidget {
  const ElectricityWindow({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          FlutterI18n.translate(
            context,
            "electricity.title",
          ),
        ),
      ),
      body: Obx(() {
        if (isLoad.value) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        return [
          Text(
            FlutterI18n.translate(
              context,
              "electricity.info",
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
          InfoCard(
            title: FlutterI18n.translate(
              context,
              "electricity.power_title",
            ),
            children: [
              InfoItem(
                icon: Icons.account_balance,
                label: FlutterI18n.translate(
                  context,
                  "electricity.account",
                ),
                value: preference.getString(preference.Preference.dorm),
              ),
              InfoItem(
                icon: Icons.home,
                label: FlutterI18n.translate(
                  context,
                  "electricity.location",
                ),
                value: electricityInfo.value.location.contains("校区")
                    ? electricityInfo.value.location
                    : FlutterI18n.translate(
                        context,
                        "electricity.location_not_found",
                      ),
              ),
              InfoItem(
                icon: Icons.cached,
                label: FlutterI18n.translate(
                  context,
                  "electricity.cache_notice",
                ),
                value: DateFormat(
                  "yyyy-MM-dd HH:mm:ss",
                ).format(
                  electricityInfo.value.fetchDay,
                ),
              ),
              InfoItem(
                icon: Icons.electric_meter,
                label: FlutterI18n.translate(
                  context,
                  "electricity.remain_power",
                ),
                value: "${FlutterI18n.translate(
                  context,
                  electricityInfo.value.remain,
                )}${electricityInfo.value.remain.contains(RegExp(r'[0-9]')) ? " kWh" : ""}",
              ),
            ],
          ),
          const SizedBox(height: 4),
          InfoCard(
            title: FlutterI18n.translate(
              context,
              "electricity.history",
            ),
            children: [
              DataTable(
                columns: [
                  DataColumn(
                      label: Text(FlutterI18n.translate(
                    context,
                    "electricity.date",
                  ))),
                  DataColumn(
                      label: Text(FlutterI18n.translate(
                    context,
                    "electricity.power",
                  ))),
                ],
                rows: historyElectricityInfo.map((info) {
                  return DataRow(cells: [
                    DataCell(Text(
                      DateFormat("yyyy-MM-dd HH:mm").format(info.fetchDay),
                    )),
                    DataCell(Text(info.remain)),
                  ]);
                }).toList(),
              ).scrollable(
                scrollDirection: Axis.horizontal,
              )
            ],
          ),
          const SizedBox(height: 4),
          FilledButton(
            onPressed: () => update(force: true),
            child: Text(
              FlutterI18n.translate(
                context,
                "electricity.update",
              ),
            ),
          ).padding(all: 4),
        ]
            .toColumn(crossAxisAlignment: CrossAxisAlignment.stretch)
            .constrained(maxWidth: 480)
            .alignment(Alignment.topCenter)
            .padding(all: 12)
            .scrollable();
      }),
    );
  }
}
