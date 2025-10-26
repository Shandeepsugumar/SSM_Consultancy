import 'package:flutter/material.dart';
import 'binary_password_helper.dart';
import 'password_migration_helper.dart';

/// Test page to demonstrate binary password functionality
class BinaryPasswordTestPage extends StatefulWidget {
  @override
  _BinaryPasswordTestPageState createState() => _BinaryPasswordTestPageState();
}

class _BinaryPasswordTestPageState extends State<BinaryPasswordTestPage> {
  final TextEditingController _passwordController = TextEditingController();
  String _binaryOutput = '';
  String _verificationResult = '';

  void _testHashConversion() {
    String password = _passwordController.text;
    if (password.isNotEmpty) {
      setState(() {
        // Test all hash formats
        String sha256Hash = BinaryPasswordHelper.convertToHexHash(password);
        String md5Hash = BinaryPasswordHelper.convertToMD5Hash(password);
        String binaryOutput = BinaryPasswordHelper.convertToBinary(password);

        // Your database hash for SSM023
        String databaseHash =
            "4ee7ffea047070f4f7faa5b54ef0ee8bbba2d0f644c2c6e5b58e";

        _binaryOutput = 'Password: $password\n\n'
            'SHA-256: $sha256Hash\n\n'
            'MD5: $md5Hash\n\n'
            'Binary: $binaryOutput\n\n'
            'Database Hash: $databaseHash\n\n'
            'SHA-256 Match: ${sha256Hash == databaseHash}\n'
            'MD5 Match: ${md5Hash == databaseHash}\n'
            'Binary Match: ${binaryOutput == databaseHash}';

        // Test verification against database hash
        bool isValid =
            BinaryPasswordHelper.verifyPasswordHash(password, databaseHash);
        _verificationResult = isValid
            ? 'Database Verification: ✅ PASSED'
            : 'Database Verification: ❌ FAILED';
      });
    }
  }

  void _testBinaryConversion() {
    String password = _passwordController.text;
    if (password.isNotEmpty) {
      setState(() {
        _binaryOutput = BinaryPasswordHelper.convertToBinary(password);

        // Test verification
        bool isValid =
            BinaryPasswordHelper.verifyPassword(password, _binaryOutput);
        _verificationResult =
            isValid ? 'Verification: ✅ PASSED' : 'Verification: ❌ FAILED';
      });
    }
  }

  void _testSSM022Migration() async {
    try {
      // Test the migration for SSM022 user
      await PasswordMigrationHelper.checkUserPasswordFormat('SSM022');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Check console for SSM022 password format results')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Binary Password Test'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Binary Password Converter',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Enter Password',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _testBinaryConversion,
                  child: Text('Convert to Binary'),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _testHashConversion,
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: Text('Test Hash Formats'),
                ),
              ],
            ),
            SizedBox(height: 20),
            if (_binaryOutput.isNotEmpty) ...[
              Text(
                'Binary Output:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 5),
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: SelectableText(
                  _binaryOutput,
                  style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
              SizedBox(height: 10),
              Text(
                _verificationResult,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _verificationResult.contains('✅')
                      ? Colors.green
                      : Colors.red,
                ),
              ),
              SizedBox(height: 20),
            ],
            Divider(),
            SizedBox(height: 10),
            Text(
              'Database Operations:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _testSSM022Migration,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: Text('Check SSM022 Password Format'),
            ),
            SizedBox(height: 20),
            Text(
              'How Binary Password Works:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            Text(
              '1. User enters password\n'
              '2. Password converts to ASCII values\n'
              '3. ASCII values convert to 8-bit binary\n'
              '4. Binary strings concatenate\n'
              '5. Result stores in database\n'
              '6. Login verifies binary matches',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
