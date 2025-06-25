import 'dart:convert';
import 'dart:io';
import 'package:watermeter/model/encourage_word/encourage_word.dart';
import 'package:get/get.dart';
import 'package:watermeter/repository/network_session.dart';
import 'package:watermeter/repository/logger.dart';

class EncourageWordController extends GetxController {
  static const String encourageWordsFileName = "encourage_words.json";

  late File encourageWordsFile;
  late EncourageWord encourageWord;

  @override
  void onInit() {
    super.onInit();
    log.info(
      "[EncourageWordController][onInit] "
      "Init encourage words file.",
    );
    encourageWordsFile = File("${supportPath.path}/$encourageWordsFileName");
    bool encourageWordsFileisExist = encourageWordsFile.existsSync();
    if (encourageWordsFileisExist) {
      log.info(
        "[EncourageWordController][onInit] "
        "Init from cache.",
      );
      encourageWord = EncourageWord.fromJson(
        jsonDecode(encourageWordsFile.readAsStringSync()),
      );
    } else {
      log.info(
        "[EncourageWordController][onInit] "
        "Init with empty list.",
      );
      encourageWord = EncourageWord(words: []);
    }

    log.info(
      "[EncourageWordController][onInit] "
      "Init encourage words file.",
    );
  }

  @override
  void onReady() async {
    await updateEncourageWords();
  }

  Future<void> editEncourageWords(List<String> words) async {
    encourageWord.words.clear();
    encourageWord.words.addAll(words);
    await encourageWordsFile.writeAsString(
      jsonEncode(encourageWord.toJson()),
    );
    await updateEncourageWords();
  }

  Future<void> deleteEncourageWords() async {
    encourageWord.words.clear();
    await encourageWordsFile.writeAsString(
      jsonEncode(encourageWord.toJson()),
    );
    await updateEncourageWords();
  }

  Future<void> updateEncourageWords() async {
    try {
      log.info(
        "[EncourageWordController][updateEncourageWords] "
        "Update encourage words.",
      );

      if (!encourageWordsFile.existsSync()) {
        log.info(
          "[EncourageWordController][updateEncourageWords] "
          "Cache file does not exist, creating empty list.",
        );
        encourageWord = EncourageWord(words: []);
        await encourageWordsFile.writeAsString(jsonEncode(encourageWord.toJson()));
        update();
        return;
      }

      try {
        final String fileContent = encourageWordsFile.readAsStringSync();
        final dynamic jsonData = jsonDecode(fileContent);
        encourageWord = EncourageWord.fromJson(jsonData);
      } catch (e, s) {
        log.warning(
          "[EncourageWordController][updateEncourageWords] "
          "Failed to parse encourage words file: $e",
          s,
        );
        // 文件损坏或格式错误时，重置为空列表
        encourageWord = EncourageWord(words: []);
        await encourageWordsFile.writeAsString(jsonEncode(encourageWord.toJson()));
      }

      update();
    } catch (e, s) {
      log.error(
        "[EncourageWordController][updateEncourageWords] "
        "Critical error while updating encourage words: $e",
        s,
      );
      // 确保即使在发生严重错误时也能正常工作
      encourageWord = EncourageWord(words: []);
      update();
    }
  }
}
