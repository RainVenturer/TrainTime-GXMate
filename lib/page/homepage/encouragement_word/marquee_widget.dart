// Copyright 2023-2025 BenderBlog Rodriguez and contributors
// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0

// From https://blog.csdn.net/zl18603543572/article/details/125757856

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class MarqueeWidget extends StatefulWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final int loopSeconds;
  const MarqueeWidget({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.loopSeconds = 5,
  });

  @override
  State<MarqueeWidget> createState() => _MarqueeWidgetState();
}

class _MarqueeWidgetState extends State<MarqueeWidget> {
  late PageController _controller;
  late Timer _timer;
  late List<int> _randomOrder;
  final _random = Random();
  int _currentIndex = 0;

  void _generateRandomOrder() {
    _randomOrder = List.generate(widget.itemCount, (index) => index);
    _randomOrder.shuffle(_random);
  }

  @override
  void initState() {
    super.initState();
    _generateRandomOrder();
    _currentIndex = _random.nextInt(widget.itemCount);
    _controller = PageController(initialPage: _currentIndex);
    
    _timer = Timer.periodic(
      Duration(seconds: widget.loopSeconds),
      (timer) {
        if (_controller.page != null) {
          _currentIndex = (_currentIndex + 1) % widget.itemCount;
          _controller.animateToPage(
            _currentIndex,
            duration: const Duration(milliseconds: 500),
            curve: Curves.linear,
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      physics: const NeverScrollableScrollPhysics(),
      scrollDirection: Axis.vertical,
      controller: _controller,
      itemBuilder: (buildContext, index) {
        final actualIndex = _randomOrder[index % widget.itemCount];
        return widget.itemBuilder(buildContext, actualIndex);
      },
      itemCount: widget.itemCount,
    );
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
    _timer.cancel();
  }
}
