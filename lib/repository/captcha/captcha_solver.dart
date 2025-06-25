// Copyright 2023 BenderBlog Rodriguez and contributors.
// SPDX-License-Identifier: MPL-2.0

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:watermeter/page/public_widget/toast.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:styled_widget/styled_widget.dart';

enum DigitCaptchaType { cas }

class DigitCaptchaClientProvider {
  static const List<String> classes = [
    '0',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '+',
    'x',
  ];

  static String _getInterpreterAssetName(DigitCaptchaType type) {
    return 'assets/captcha-solver-${type.name.toLowerCase()}.tflite';
  }

  static img.Image? _getImage(DigitCaptchaType type, List<int> imageData) {
    img.Image image = img.decodeImage(Uint8List.fromList(imageData))!;
    image = img.grayscale(image);
    image = image.convert(format: img.Format.float32, numChannels: 1);

    // 二值化处理
    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final gray = pixel.r;
        final newPixel =
            gray > 0.94 ? img.ColorRgb8(255, 255, 255) : img.ColorRgb8(0, 0, 0);
        image.setPixel(x, y, newPixel);
      }
    }

    return image;
  }

  static int _argmax(List<double> list) {
    int result = 0;
    for (int i = 1; i < list.length; i++) {
      if (list[i] > list[result]) {
        result = i;
      }
    }
    return result;
  }

  static int _calculate(String operand1, String operator, String operand2) {
    int num1, num2;
    try {
      num1 = int.parse(operand1);
      num2 = int.parse(operand2);
    } catch (e) {
      return -1;
    }

    if (operator == "+") {
      return num1 + num2;
    } else if (operator == "x" || operator == "*") {
      return num1 * num2;
    } else {
      return -1;
    }
  }

  static Future<String?> solve(BuildContext? context, List<int>? imageData,
      DigitCaptchaType? type, bool? lastTry,
      {int retryCount = 5}) async {
    if (type != null && imageData != null && lastTry != null) {
      for (int i = 0; i < retryCount; i++) {
        int? result = await infer(type, imageData);
        if (result != null) {
          return result.toString();
        }
      }
    }

    // 如果自动识别失败，回退到手动输入
    if (context != null &&
        context.mounted &&
        imageData != null) {
      return await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (context) => CaptchaInputDialog(
            image: imageData,
          ),
        ),
      );
    }

    return "0000";
  }

  static Future<int?> infer(
    DigitCaptchaType type,
    List<int> imageData,
  ) async {
    img.Image? image = _getImage(type, imageData);
    if (image == null) {
      return null;
    }

    int dim2 = image.height;
    int dim3 = image.width ~/ 4;

    // 准备输入输出张量
    var input = List.generate(
      1,
      (_) => List.generate(
        dim2,
        (_) => List.generate(dim3, (_) => List<double>.filled(1, 0.0)),
      ),
    );
    var output = List.generate(
      1,
      (_) => List<double>.filled(classes.length, 0.0),
    );

    final interpreter = await Interpreter.fromAsset(
      _getInterpreterAssetName(type),
    );
    List<String> predictedValues = [];

    // Four numbers
    // 依次识别3个字符（两个数字和一个运算符）
    for (int i = 0; i < 3; i++) {
      // 填充输入张量
      for (int y = 0; y < dim2; y++) {
        for (int x = 0; x < dim3; x++) {
          final pixel = image.getPixel(x + dim3 * i, y);
          // 归一化到0-1范围
          input[0][y][x][0] = pixel.r / 255.0;
        }
      }

      // 执行推理
      interpreter.run(input, output);

      // 获取预测结果
      int predictedIndex = _argmax(output[0]);
      predictedValues.add(classes[predictedIndex]);
    }

    if (predictedValues.length == 3) {
      String operand1 = predictedValues[0];
      String operators = predictedValues[1];
      String operand2 = predictedValues[2];

      int result = _calculate(operand1, operators, operand2);
      return result == -1 ? null : result;
    } else {
      return null;
    }
  }
}

class CaptchaInputDialog extends StatefulWidget {
  final List<int> image;

  const CaptchaInputDialog({
    super.key,
    required this.image,
  });

  @override
  State<CaptchaInputDialog> createState() => _CaptchaInputDialogState();
}

class _CaptchaInputDialogState extends State<CaptchaInputDialog> {
  final TextEditingController _captchaController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(FlutterI18n.translate(
          context,
          "login.captcha_window.title",
        )),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.memory(
            Uint8List.fromList(widget.image),
            width: 280,
            height: 100,
            fit: BoxFit.contain,
          ).center(),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: TextField(
              autofocus: true,
              controller: _captchaController,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 8),
              maxLength: 4,
              decoration: InputDecoration(
                counterText: "",
                hintText: FlutterI18n.translate(
                  context,
                  "login.captcha_window.hint",
                ),
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(FlutterI18n.translate(context, "cancel")),
              ),
              const SizedBox(width: 20),
              ElevatedButton(
                onPressed: () {
                  if (_captchaController.text.isEmpty) {
                    showToast(
                      context: context,
                      msg: FlutterI18n.translate(
                        context,
                        "login.captcha_window.message_on_empty",
                      ),
                    );
                  } else if (_captchaController.text.length != 4) {
                    showToast(
                      context: context,
                      msg: FlutterI18n.translate(
                        context,
                        "login.captcha_window.message_on_invalid",
                      ),
                    );
                  } else {
                    Navigator.of(context).pop(_captchaController.text);
                  }
                },
                child: Text(FlutterI18n.translate(context, "confirm")),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CaptchaSolveFailedException implements Exception {}
