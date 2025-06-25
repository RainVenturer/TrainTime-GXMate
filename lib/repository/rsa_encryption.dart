import 'dart:math';

/// 懒加载工具类，只有在首次访问时才会初始化值。
class Lazy<T> {
  final T Function() _initializer;

  Lazy(this._initializer);

  T? _value;

  T get value => _value ??= _initializer();
}

// 内部类
class BigInt {
  late List<int> digits;
  late bool isNeg;

  BigInt({bool isOne = false}) {
    if (isOne) {
      digits = List<int>.filled(RSAEncryption.maxDigit, 0);
      digits[0] = 1;
    } else {
      digits = List<int>.filled(RSAEncryption.maxDigit, 0);
    }
    isNeg = false;
  }

  BigInt clone(BigInt bigNum) {
    var result = BigInt();
    result.digits = List<int>.from(bigNum.digits);
    result.isNeg = bigNum.isNeg;
    return result;
  }
}

class RSAKey {
  late BigInt e;
  late BigInt d;
  late BigInt m;
  late int chunkSize;
  late int radix;
  late BarrettModulus barrett;

  RSAKey(String encryptionExponent, String decryptionExponent, String modulus) {
    e = RSAEncryption._hexToBigInt(encryptionExponent);
    d = RSAEncryption._hexToBigInt(decryptionExponent);
    m = RSAEncryption._hexToBigInt(modulus);
    chunkSize = 2 * RSAEncryption._getHighIndex(m);
    radix = 16;
    barrett = BarrettModulus(m);
  }
}

class BarrettModulus {
  late BigInt modulus;
  late int k;
  late BigInt mu;
  late BigInt bkplus1;
  late BigInt Function(BigInt) modulo;
  late BigInt Function(BigInt, BigInt) powMod;
  late BigInt Function(BigInt, BigInt) multiplyMod;

  BarrettModulus(BigInt modulus) {
    this.modulus = modulus.clone(modulus);
    k = RSAEncryption._getHighIndex(this.modulus) + 1;

    var temp = BigInt();
    temp.digits[2 * k] = 1;
    mu = RSAEncryption._quotientBigInt(temp, this.modulus);
    bkplus1 = BigInt();
    bkplus1.digits[k + 1] = 1;

    // 初始化函数成员
    modulo = (BigInt x) {
      var q1 = RSAEncryption._rightShiftByChunks(x, k - 1);
      var q2 = RSAEncryption._multiplyBigInt(q1, mu);
      var q3 = RSAEncryption._rightShiftByChunks(q2, k + 1);
      var r1 = RSAEncryption._truncateBigInt(x, k + 1);
      var r2 = RSAEncryption._multiplyBigInt(q3, this.modulus);
      var r3 = RSAEncryption._truncateBigInt(r2, k + 1);
      var r = RSAEncryption._subtractBigInt(r1, r3);

      if (r.isNeg) {
        r = RSAEncryption._addBigInt(r, bkplus1);
      }
      while (RSAEncryption._compareBigInt(r, this.modulus) >= 0) {
        r = RSAEncryption._subtractBigInt(r, this.modulus);
      }
      return r;
    };

    multiplyMod = (BigInt x, BigInt y) {
      var xy = RSAEncryption._multiplyBigInt(x, y);
      return modulo(xy);
    };

    powMod = (BigInt x, BigInt y) {
      var result = BigInt();
      result.digits[0] = 1;
      var n = x;
      var r = y;
      while (true) {
        if ((r.digits[0] & 1) != 0) {
          result = multiplyMod(result, n);
        }
        r = RSAEncryption._rightShift(r, 1);
        if (r.digits[0] == 0 && RSAEncryption._getHighIndex(r) == 0) {
          break;
        }
        n = multiplyMod(n, n);
      }
      return result;
    };
  }
}

class RSAEncryption {
  // 静态常量
  static const int maxDigit = 131; // 最大位数
  static const int bitPerDigit = 16; // 每个数字的位数
  static const int maxDigitValue = 65536; // 每个数字的最大值 (2^16)
  static const int maxDigitValueHalf = maxDigitValue >>> 1; // 每个数字的一半最大值 (2^15)
  static const int maxDigitValueSquared =
      maxDigitValue * maxDigitValue; // 每个数字的平方最大值 (2^32)
  static const int maxDigitValueMinusOne =
      maxDigitValue - 1; // 每个数字的最大值减一 (2^16-1)

  static final BigInt digitsArray = BigInt(); // 数字数组
  static final BigInt bigZero = BigInt(); // 大数0
  static final BigInt bigOne = BigInt(isOne: true); // 大数1

  // 常量数组
  static final List<String> _digitsToChar = [
    "0",
    "1",
    "2",
    "3",
    "4",
    "5",
    "6",
    "7",
    "8",
    "9",
    "a",
    "b",
    "c",
    "d",
    "e",
    "f",
    "g",
    "h",
    "i",
    "j",
    "k",
    "l",
    "m",
    "n",
    "o",
    "p",
    "q",
    "r",
    "s",
    "t",
    "u",
    "v",
    "w",
    "x",
    "y",
    "z",
  ];

  static final List<String> _hexToChar = [
    "0",
    "1",
    "2",
    "3",
    "4",
    "5",
    "6",
    "7",
    "8",
    "9",
    "a",
    "b",
    "c",
    "d",
    "e",
    "f",
  ];

  static final List<int> _highBitMasks = [
    0,
    32768,
    49152,
    57344,
    61440,
    63488,
    64512,
    65024,
    65280,
    65408,
    65472,
    65504,
    65520,
    65528,
    65532,
    65534,
    65535,
  ];

  static final List<int> _lowBitMasks = [
    0,
    1,
    3,
    7,
    15,
    31,
    63,
    127,
    255,
    511,
    1023,
    2047,
    4095,
    8191,
    16383,
    32767,
    65535,
  ];

  // 静态工具函数
  static int _getHighIndex(BigInt bigNum) {
    var index = bigNum.digits.length - 1;
    for (; index > 0 && 0 == bigNum.digits[index];) {
      --index;
    }
    return index;
  }

  static BigInt _addBigInt(BigInt x, BigInt y) {
    late BigInt result;
    if (x.isNeg != y.isNeg) {
      y.isNeg = !y.isNeg;
      result = _subtractBigInt(x, y);
      y.isNeg = !y.isNeg;
    } else {
      result = BigInt();
      var carry = 0;
      for (var i = 0; i < x.digits.length; i++) {
        var sum = x.digits[i] + y.digits[i] + carry;
        result.digits[i] = sum % maxDigitValue;
        carry = (sum >= maxDigitValue) ? 1 : 0;
      }
      result.isNeg = x.isNeg;
    }
    return result;
  }

  static BigInt _subtractBigInt(BigInt x, BigInt y) {
    late BigInt result;
    if (x.isNeg != y.isNeg) {
      y.isNeg = !y.isNeg;
      result = _addBigInt(x, y);
      y.isNeg = !y.isNeg;
    } else {
      result = BigInt();
      var borrow = 0;
      for (var i = 0; i < x.digits.length; i++) {
        var sub = x.digits[i] - y.digits[i] + borrow;
        result.digits[i] = sub % maxDigitValue;
        if (result.digits[i] < 0) {
          result.digits[i] += maxDigitValue;
        }
        borrow = (sub < 0) ? -1 : 0;
      }
      if (borrow == -1) {
        borrow = 0;
        for (var i = 0; i < x.digits.length; i++) {
          var sub = 0 - result.digits[i] + borrow;
          result.digits[i] = sub % maxDigitValue;
          if (result.digits[i] < 0) {
            result.digits[i] += maxDigitValue;
          }
          borrow = (sub < 0) ? -1 : 0;
        }
        result.isNeg = !x.isNeg;
      } else {
        result.isNeg = x.isNeg;
      }
    }
    return result;
  }

  static BigInt _multiplyBigInt(BigInt x, BigInt y) {
    var result = BigInt();
    var highIndexX = _getHighIndex(x);
    var highIndexY = _getHighIndex(y);
    for (var i = 0; i <= highIndexY; i++) {
      var carry = 0;
      var digitIndex = i;
      for (var j = 0; j <= highIndexX; j++, digitIndex++) {
        var multiply =
            result.digits[digitIndex] + x.digits[j] * y.digits[i] + carry;
        result.digits[digitIndex] = multiply & maxDigitValueMinusOne;
        carry = multiply >>> bitPerDigit;
      }
      result.digits[i + highIndexX + 1] = carry;
    }
    result.isNeg = x.isNeg != y.isNeg;
    return result;
  }

  static List<BigInt> _divideBigInt(BigInt x, BigInt y) {
    var bitLengthX = _getBitLength(x);
    var bitLengthY = _getBitLength(y);
    late BigInt divide, remainder;
    var isNegY = y.isNeg;

    if (bitLengthX < bitLengthY) {
      if (x.isNeg) {
        divide = bigOne.clone(bigOne);
        divide.isNeg = !y.isNeg;
        x.isNeg = false;
        y.isNeg = false;
        remainder = _subtractBigInt(y, x);
        x.isNeg = true;
        y.isNeg = isNegY;
        return [divide, remainder];
      } else {
        divide = BigInt();
        remainder = x.clone(x);
        return [divide, remainder];
      }
    }

    divide = BigInt();
    remainder = x;

    var u = 0;
    var l = (bitLengthY / bitPerDigit).ceil() - 1;
    for (var l = (bitLengthY / bitPerDigit).ceil() - 1;
        y.digits[l] < maxDigitValueHalf;
        u++) {
      y = _leftShift(y, 1);
      bitLengthY++;
      l = (bitLengthY / bitPerDigit).ceil() - 1;
    }

    remainder = _leftShift(remainder, u);
    bitLengthX += u;

    var d = (bitLengthX / bitPerDigit).ceil() - 1;
    var p = _leftShiftByChunks(y, d - l);

    while (_compareBigInt(remainder, p) != -1) {
      divide.digits[d - l]++;
      remainder = _subtractBigInt(remainder, p);
    }

    for (var m = d; m > l; m--) {
      var f = m >= remainder.digits.length ? 0 : remainder.digits[m];
      var E = m - 1 >= remainder.digits.length ? 0 : remainder.digits[m - 1];
      var z = m - 2 >= remainder.digits.length ? 0 : remainder.digits[m - 2];

      var S = l >= y.digits.length ? 0 : y.digits[l];
      var O = l - 1 >= y.digits.length ? 0 : y.digits[l - 1];

      divide.digits[m - l - 1] = f == S
          ? maxDigitValueMinusOne
          : ((f * maxDigitValue + E) / S).floor();

      var k = divide.digits[m - l - 1] * (S * maxDigitValue + O);
      var N = f * maxDigitValueSquared + (E * maxDigitValue + z);

      while (k > N) {
        divide.digits[m - l - 1]--;
        k = divide.digits[m - l - 1] * (S * maxDigitValue | O);
        N = f * maxDigitValue * maxDigitValue + (E * maxDigitValue + z);
      }

      p = _leftShiftByChunks(y, m - l - 1);
      remainder = _subtractBigInt(
        remainder,
        _multiplyByDigit(p, divide.digits[m - l - 1]),
      );

      if (remainder.isNeg) {
        remainder = _addBigInt(remainder, p);
        divide.digits[m - l - 1]--;
      }
    }

    remainder = _rightShift(remainder, u);
    divide.isNeg = x.isNeg != isNegY;

    if (x.isNeg) {
      divide =
          isNegY ? _addBigInt(divide, bigOne) : _subtractBigInt(divide, bigOne);
      y = _rightShift(y, u);
      remainder = _subtractBigInt(y, remainder);
    }

    if (remainder.digits[0] == 0 && _getHighIndex(remainder) == 0) {
      remainder.isNeg = false;
    }

    return [divide, remainder];
  }

  static BigInt _quotientBigInt(BigInt x, BigInt y) {
    return _divideBigInt(x, y)[0];
  }

  static BigInt _leftShift(BigInt bigNum, int shift) {
    var digitCount = (shift / bitPerDigit).floor();
    var result = BigInt();
    _arrayCopy(
      bigNum.digits,
      0,
      result.digits,
      digitCount,
      result.digits.length - digitCount,
    );
    var remainingBits = shift % bitPerDigit;
    var bits1 = bitPerDigit - remainingBits;
    for (var i = result.digits.length - 1, j = i - 1; i > 0; i--, j--) {
      result.digits[i] =
          (result.digits[i] << remainingBits) & maxDigitValueMinusOne |
              (result.digits[j] & _highBitMasks[remainingBits]) >>> bits1;
    }
    result.digits[0] =
        (result.digits[0] << remainingBits) & maxDigitValueMinusOne;
    result.isNeg = bigNum.isNeg;
    return result;
  }

  static BigInt _rightShift(BigInt bigNum, int shift) {
    var digitCount = (shift / bitPerDigit).floor();
    var result = BigInt();
    _arrayCopy(
      bigNum.digits,
      digitCount,
      result.digits,
      0,
      bigNum.digits.length - digitCount,
    );
    var remainingBits = shift % bitPerDigit;
    var bits1 = bitPerDigit - remainingBits;
    for (var i = 0, j = i + 1; i < result.digits.length - 1; i++, j++) {
      result.digits[i] = result.digits[i] >>> remainingBits |
          (result.digits[j] & _lowBitMasks[remainingBits]) << bits1;
    }
    result.digits[result.digits.length - 1] >>>= remainingBits;
    result.isNeg = bigNum.isNeg;
    return result;
  }

  static BigInt _leftShiftByChunks(BigInt bigNum, int digitCount) {
    var result = BigInt();
    _arrayCopy(
      bigNum.digits,
      0,
      result.digits,
      digitCount,
      bigNum.digits.length - digitCount,
    );
    return result;
  }

  static BigInt _rightShiftByChunks(BigInt bigNum, int digitCount) {
    var result = BigInt();
    _arrayCopy(
      bigNum.digits,
      digitCount,
      result.digits,
      0,
      bigNum.digits.length - digitCount,
    );
    return result;
  }

  static BigInt _truncateBigInt(BigInt bigNum, int digitCount) {
    var result = BigInt();
    _arrayCopy(bigNum.digits, 0, result.digits, 0, digitCount);
    return result;
  }

  static int _compareBigInt(BigInt x, BigInt y) {
    if (x.isNeg != y.isNeg) {
      return 1 - 2 * (x.isNeg ? 1 : 0);
    }
    for (var i = x.digits.length - 1; i >= 0; i--) {
      if (x.digits[i] != y.digits[i]) {
        if (x.isNeg) {
          return 1 - 2 * (x.digits[i] > y.digits[i] ? 1 : 0);
        } else {
          return 1 - 2 * (x.digits[i] < y.digits[i] ? 1 : 0);
        }
      }
    }
    return 0;
  }

  static void _arrayCopy(
    List<int> src,
    int srcStart,
    List<int> dest,
    int destStart,
    int length,
  ) {
    var end = min(srcStart + length, src.length);
    for (var i = srcStart, j = destStart; i < end; i++, j++) {
      dest[j] = src[i];
    }
  }

  static BigInt _multiplyByDigit(BigInt bigNum, int intValue) {
    var result = BigInt();
    var highIndex = _getHighIndex(bigNum);
    var carry = 0;
    for (var i = 0; i <= highIndex; i++) {
      var multiply = result.digits[i] + bigNum.digits[i] * intValue + carry;
      result.digits[i] = multiply & maxDigitValueMinusOne;
      carry = multiply >>> bitPerDigit;
    }
    result.digits[1 + highIndex] = carry;
    return result;
  }

  static int _getBitLength(BigInt bigNum) {
    var highIndex = _getHighIndex(bigNum);
    var digit = bigNum.digits[highIndex];
    var bitLength = (highIndex + 1) * bitPerDigit;
    late int result;
    for (result = bitLength;
        result > bitLength - bitPerDigit && (32768 & digit) == 0;
        result--) {
      digit <<= 1;
    }
    return result;
  }

  static BigInt _hexToBigInt(String str) {
    var result = BigInt();
    for (var i = str.length, n = i, r = 0; n > 0; n -= 4, r++) {
      var start = max(n - 4, 0);
      // var end = min(n, str.length);
      result.digits[r] = _hexToDigit(str.substring(start, n));
    }
    return result;
  }

  static BigInt _strToBigInt(String str, int base) {
    bool isNeg = str.startsWith('-');
    int startIndex = isNeg ? 1 : 0;
    BigInt result = BigInt();
    BigInt power = BigInt(isOne: true);

    for (int i = str.length - 1; i >= startIndex; i--) {
      int digit = _charToDigit(str.codeUnitAt(i));
      result = _addBigInt(result, _multiplyByDigit(power, digit));
      power = _multiplyByDigit(power, base);
    }

    result.isNeg = isNeg;
    return result;
  }

  static int _hexToDigit(String str) {
    var result = 0;
    var len = min(str.length, 4);
    for (var i = 0; i < len; i++) {
      result <<= 4;
      result |= _charToDigit(str.codeUnitAt(i));
    }
    return result;
  }

  static int _charToDigit(int charCode) {
    if (charCode >= 48 && charCode <= 57) {
      return charCode - 48;
    } else if (charCode >= 65 && charCode <= 90) {
      return 10 + charCode - 65;
    } else if (charCode >= 97 && charCode <= 122) {
      return 10 + charCode - 97;
    }
    return 0;
  }

  // 加密方法
  static String encrypt(RSAKey rsa, String pwd) {
    var textArray = List<int>.from(pwd.codeUnits);
    for (var i = 0; i < pwd.length; i++) {
      textArray[i] = pwd.codeUnitAt(i);
    }
    while (textArray.length % rsa.chunkSize != 0) {
      textArray.add(0);
    }
    var encryptedPwd = "";
    var textArrayLength = textArray.length;
    for (var i = 0; i < textArrayLength; i += rsa.chunkSize) {
      var block = BigInt();
      for (var j = 0, k = i; k < i + rsa.chunkSize; j++) {
        block.digits[j] = textArray[k++];
        block.digits[j] += textArray[k++] << 8;
      }
      var m = rsa.barrett.powMod(block, rsa.e);
      if (rsa.radix == 16) {
        encryptedPwd += "${_bigIntToHex(m)} ";
      } else {
        encryptedPwd += "${_bigIntToBase(m, rsa.radix)} ";
      }
    }
    return encryptedPwd.substring(0, encryptedPwd.length - 1);
  }

  // 解密方法
  static String decrypt(RSAKey rsa, String encryptedPwd) {
    // 拆分加密字符串
    final chunks = encryptedPwd.split(" ");
    var decryptedText = "";

    for (final chunk in chunks) {
      // 根据基数转换加密块为大数
      final bigIntChunk = rsa.radix == 16
          ? _hexToBigInt(chunk)
          : _strToBigInt(chunk, rsa.radix);

      // 使用私钥解密
      final decryptedChunk = rsa.barrett.powMod(bigIntChunk, rsa.d);

      // 获取解密结果的最高有效位索引
      final highIndex = _getHighIndex(decryptedChunk);

      // 将解密结果转换为字符
      for (var n = 0; n <= highIndex; n++) {
        final lowByte = decryptedChunk.digits[n] & 255;
        decryptedText += String.fromCharCode(lowByte);
        final highByte = decryptedChunk.digits[n] >> 8;
        if (highByte != 0) {
          decryptedText += String.fromCharCode(highByte);
        }
      }
    }
    // 返回解密后的字符串
    return decryptedText;
  }

  static String _bigIntToHex(BigInt e) {
    var result = "";
    for (var i = _getHighIndex(e); i > -1; i--) {
      result += _digitToHex(e.digits[i]);
    }
    return result;
  }

  static String _digitToHex(int e) {
    var result = "";
    for (var i = 0; i < 4; i++) {
      result += _hexToChar[15 & e];
      e >>>= 4;
    }
    return _reverseString(result);
  }

  static String _reverseString(String str) {
    var result = "";
    for (var i = str.length - 1; i > -1; i--) {
      result += str[i];
    }
    return result;
  }

  static String _bigIntToBase(BigInt bigNum, int base) {
    var result = BigInt();
    result.digits[0] = base;
    var n = _divideBigInt(bigNum, result);
    var r = _digitsToChar[n[1].digits[0]];
    while (_compareBigInt(n[0], bigZero) == 1) {
      n = _divideBigInt(n[0], result);
      r += _digitsToChar[n[1].digits[0]];
    }
    if (bigNum.isNeg) {
      return "-${_reverseString(r)}";
    }
    return _reverseString(r);
  }

  // 构造函数（如有需要）
  RSAEncryption();
}
