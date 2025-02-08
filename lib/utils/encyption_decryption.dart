class ChatEncryption {
  static const double _charValue = 0.25;
  static const String _key = 'aswanth_ajmal_sagar';

  static String encrypt(String text) {
    String encryptedText = '';
    for (int i = 0; i < text.length; i++) {
      double charCode = text.codeUnitAt(i) * _charValue;
      double keyCharCode = _key.codeUnitAt(i % _key.length) * _charValue;
      int encryptedCharCode = (charCode + keyCharCode).toInt();
      encryptedText += String.fromCharCode(encryptedCharCode);
    }
    return encryptedText;
  }

  static String decrypt(String encryptedText) {
    String decryptedText = '';
    for (int i = 0; i < encryptedText.length; i++) {
      double encryptedCharCode = encryptedText.codeUnitAt(i).toDouble();
      double keyCharCode = _key.codeUnitAt(i % _key.length) * _charValue;
      int charCode = (encryptedCharCode - keyCharCode).toInt();
      decryptedText += String.fromCharCode(charCode);
    }
    return decryptedText;
  }
}

class AdditiveCipher {
  static const int key = 5; // Change this to any shift value

  static String encrypt(String text) {
    StringBuffer encryptedText = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      int charCode = text.codeUnitAt(i);
      int encryptedCharCode = (charCode + key) % 256; // Shift forward
      encryptedText.writeCharCode(encryptedCharCode);
    }
    return encryptedText.toString();
  }

  static String decrypt(String encryptedText) {
    StringBuffer decryptedText = StringBuffer();
    for (int i = 0; i < encryptedText.length; i++) {
      int encryptedCharCode = encryptedText.codeUnitAt(i);
      int charCode = (encryptedCharCode - key) % 256; // Shift backward
      if (charCode < 0) charCode += 256; // Ensure it's within ASCII range
      decryptedText.writeCharCode(charCode);
    }
    return decryptedText.toString();
  }
}

void main() {
  String original = "Hello, Dart!";
  String encrypted = AdditiveCipher.encrypt(original);
  String decrypted = AdditiveCipher.decrypt(encrypted);

  print("Original: $original");
  print("Encrypted: $encrypted");
  print("Decrypted: $decrypted");
}
