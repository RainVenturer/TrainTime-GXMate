// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';

@immutable
class DropdownButtonWidget extends StatelessWidget {
  const DropdownButtonWidget({
    super.key,
    required this.label,
    required this.items,
    required this.value,
    required this.onChanged,
    this.decoration,
    this.borderRadius = 8.0,
  });

  final String label;
  final List<String> items;
  final String value;
  final ValueChanged<String?> onChanged;
  final InputDecoration? decoration;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        decoration: decoration ?? InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
          ),
          filled: true,
          labelText: label,
        ),
        value: value,
        onChanged: onChanged,
        dropdownColor: Theme.of(context).colorScheme.surface,
        menuMaxHeight: 300, // 限制下拉菜单的最大高度，超出后可滚动
        borderRadius: BorderRadius.circular(borderRadius),
        items: items.map((String item) {
          return DropdownMenuItem(
            value: item,
            child: Text(item),
          );
        }).toList(),
      ),
    );
  }
}
