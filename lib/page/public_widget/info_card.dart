// Copyright 2023-2025 BenderBlog Rodriguez and contributors
// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0
import 'package:flutter/material.dart';
import 'package:styled_widget/styled_widget.dart';
import 'package:marquee/marquee.dart';

class InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const InfoCard({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return [
      Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
      ),
      const SizedBox(height: 8),
      ...children,
    ]
        .toColumn(crossAxisAlignment: CrossAxisAlignment.start)
        .padding(all: 16)
        .card(elevation: 0);
  }
}

class InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const InfoItem({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            "$label：",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 4),
          /// @ai generated marquee widget
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // 创建一个 TextPainter 来测量文本宽度
                final textPainter = TextPainter(
                  text: TextSpan(
                    text: value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: valueColor ?? Theme.of(context).primaryColor,
                    ),
                  ),
                  maxLines: 1,
                  textDirection: TextDirection.ltr,
                )..layout(maxWidth: double.infinity);

                // 如果文本宽度超过可用宽度，使用 Marquee
                if (textPainter.width > constraints.maxWidth) {
                  return SizedBox(
                    height: 20,
                    child: Marquee(
                      text: value,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: valueColor ?? Theme.of(context).primaryColor,
                      ),
                      scrollAxis: Axis.horizontal,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      blankSpace: 20.0,
                      velocity: 30.0,
                      pauseAfterRound: const Duration(seconds: 1),
                      startPadding: 10.0,
                      accelerationDuration: const Duration(seconds: 1),
                      accelerationCurve: Curves.linear,
                      decelerationDuration: const Duration(milliseconds: 500),
                      decelerationCurve: Curves.easeOut,
                    ),
                  );
                }

                // 如果文本宽度不超过可用宽度，使用普通 Text
                return Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: valueColor ?? Theme.of(context).primaryColor,
                  ),
                  maxLines: 1,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
