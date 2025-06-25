import 'package:flutter/material.dart';
import 'package:watermeter/page/homepage/encouragement_word/marquee_widget.dart';
import 'package:watermeter/controller/encourage_word_controller.dart';
import 'package:get/get.dart';

class EncouragementCard extends StatelessWidget {
  // final _controller = Get.find<EncourageWordController>();
  const EncouragementCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<EncourageWordController>(
      builder: (controller) {
        if (controller.encourageWord.words.isEmpty) {
          return const Text('');
        }
        
        return SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          height: 20, // 设置固定高度
          child: ClipRect( // 添加裁剪
            child: MarqueeWidget(
              itemCount: controller.encourageWord.words.length,
              loopSeconds: 20,
              itemBuilder: (context, index) {
                return Text(
                  controller.encourageWord.words[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    height: 1.0, // 设置行高为1.0
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
