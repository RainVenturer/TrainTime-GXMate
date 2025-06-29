// Copyright 2025 RainVenturer and contributors
// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0

//@ai: generate this file
//Aes encrypt and decrypt for dataModel in gxmu_hwpt

import 'dart:convert';
import 'package:encrypt/encrypt.dart';
import 'package:watermeter/repository/logger.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:watermeter/repository/gxmu_hwpt/hwpt_provider.dart';

class Crypto {
  late final Key _key;
  late final Encrypter _encrypter;

  Crypto() {
    // First decrypt the desKey using constKey
    String constKey = 'CwACBQEGDAYLAgkEBQMPBAoJBg4OAgAK';
    // Assuming desKey is provided as a base64 string
    String desKey = HwptProvider().userData.deskey.isEmpty
        ? 'kLOwC2T2sOmQWz4GWn4BYHg0lnPCChWC1zAccxa2W0BHzOa2UIFfKo3X7AL5oBIf'
        : HwptProvider().userData.deskey;
    final constKeyBytes = Key.fromUtf8(constKey);
    final tempEncrypter = Encrypter(AES(constKeyBytes, mode: AESMode.ecb));

    try {
      final decryptedKey = tempEncrypter.decrypt64(desKey);
      _key = Key.fromUtf8(decryptedKey);
      _encrypter = Encrypter(AES(_key, mode: AESMode.ecb));
    } catch (e) {
      log.error('Error initializing crypto: $e');
      rethrow;
    }
  }

  String encrypt(String text) {
    try {
      final encrypted = _encrypter.encrypt(text);
      return encrypted.base64;
    } catch (e) {
      log.error('Error encrypting: $e');
      rethrow;
    }
  }

  String decrypt(String encryptedText) {
    try {
      return _encrypter.decrypt64(encryptedText);
    } catch (e) {
      log.error('Error decrypting: $e');
      rethrow;
    }
  }

  String md5(String text) {
    return crypto.md5.convert(utf8.encode(text)).toString();
  }
}
