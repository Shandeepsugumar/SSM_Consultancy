import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Helper class for binary password operations
class BinaryPasswordHelper {
  /// Convert a string password to hexadecimal hash format (matching your database)
  static String convertToHexHash(String password) {
    // Convert password to UTF-8 bytes
    var bytes = utf8.encode(password);

    // Create SHA-256 hash
    var digest = sha256.convert(bytes);

    // Return as hexadecimal string (matching your database format)
    return digest.toString();
  }

  /// Alternative: Convert to MD5 hash if that's what your database uses
  static String convertToMD5Hash(String password) {
    var bytes = utf8.encode(password);
    var digest = md5.convert(bytes);
    return digest.toString();
  }

  /// Verify if entered password matches stored hash (for your database format)
  static bool verifyPasswordHash(String enteredPassword, String storedHash) {
    try {
      // Try SHA-256 first
      String enteredSHA256 = convertToHexHash(enteredPassword);
      if (enteredSHA256 == storedHash) {
        print('Password verified with SHA-256');
        return true;
      }

      // Try MD5 if SHA-256 doesn't match
      String enteredMD5 = convertToMD5Hash(enteredPassword);
      if (enteredMD5 == storedHash) {
        print('Password verified with MD5');
        return true;
      }

      // Try pure binary if neither hash works
      String enteredBinary = convertToBinary(enteredPassword);
      if (enteredBinary == storedHash) {
        print('Password verified with binary');
        return true;
      }

      print('Password verification failed with all methods');
      return false;
    } catch (e) {
      print('Error verifying password: $e');
      return false;
    }
  }

  /// Generate hash password for storage (matching your database format)
  static String generateHashPassword(String plainPassword) {
    return convertToHexHash(plainPassword);
  }

  /// Test different hash formats to see which one matches your database
  static void testPasswordFormats(String testPassword) {
    print('Testing password: $testPassword');
    print('SHA-256: ${convertToHexHash(testPassword)}');
    print('MD5: ${convertToMD5Hash(testPassword)}');
    print('Binary: ${convertToBinary(testPassword)}');

    // Test against your database hash
    String yourDatabaseHash =
        "4ee7ffea047070f4f7faa5b54ef0ee8bbba2d0f644c2c6e5b58e";
    print('');
    print('Comparing against your database hash: $yourDatabaseHash');
    print(
        'SHA-256 Match: ${convertToHexHash(testPassword) == yourDatabaseHash}');
    print('MD5 Match: ${convertToMD5Hash(testPassword) == yourDatabaseHash}');
    print('Binary Match: ${convertToBinary(testPassword) == yourDatabaseHash}');
  }

  /// Convert a string password to binary representation
  static String convertToBinary(String password) {
    // Convert each character to its ASCII value, then to binary
    List<String> binaryChars = [];

    for (int i = 0; i < password.length; i++) {
      int ascii = password.codeUnitAt(i);
      String binary = ascii.toRadixString(2).padLeft(8, '0'); // 8-bit binary
      binaryChars.add(binary);
    }

    return binaryChars.join('');
  }

  /// Convert binary string back to original password (for verification purposes)
  static String convertFromBinary(String binaryString) {
    if (binaryString.length % 8 != 0) {
      throw ArgumentError('Binary string length must be multiple of 8');
    }

    List<String> chars = [];

    for (int i = 0; i < binaryString.length; i += 8) {
      String binaryChar = binaryString.substring(i, i + 8);
      int ascii = int.parse(binaryChar, radix: 2);
      chars.add(String.fromCharCode(ascii));
    }

    return chars.join('');
  }

  /// Verify if entered password matches stored binary password
  static bool verifyPassword(
      String enteredPassword, String storedBinaryPassword) {
    try {
      String enteredBinary = convertToBinary(enteredPassword);
      return enteredBinary == storedBinaryPassword;
    } catch (e) {
      print('Error verifying password: $e');
      return false;
    }
  }

  /// Generate binary password for storage (use this when creating/updating passwords)
  static String generateBinaryPassword(String plainPassword) {
    return convertToBinary(plainPassword);
  }

  /// Test function to verify conversion works correctly
  static void testConversion() {
    String testPassword = "password123";
    print('Original password: $testPassword');

    String binary = convertToBinary(testPassword);
    print('Binary representation: $binary');

    String converted = convertFromBinary(binary);
    print('Converted back: $converted');

    bool matches = verifyPassword(testPassword, binary);
    print('Verification matches: $matches');
  }
}
