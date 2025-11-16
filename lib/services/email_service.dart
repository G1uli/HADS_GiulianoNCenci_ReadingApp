import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:flutter/foundation.dart';

class EmailService {
  static final EmailService _instance = EmailService._internal();
  factory EmailService() => _instance;
  EmailService._internal();

  // Gmail SMTP configuration
  static const String _smtpServer = 'smtp.gmail.com';
  static const int _smtpPort = 587;

  Future<bool> sendPasswordResetEmail(
    String recipientEmail,
    String newPassword,
  ) async {
    // REPLACE THESE WITH YOUR ACTUAL GMAIL CREDENTIALS
    final String senderEmail = 'giginigi743@gmail.com'; // Your Gmail address
    final String senderPassword = 'cmbf xzrz cssv csoe'; // Gmail App Password

    debugPrint('Attempting to send email to: $recipientEmail');
    debugPrint('Using sender: $senderEmail');

    try {
      // Create SMTP server
      final smtpServer = SmtpServer(
        _smtpServer,
        port: _smtpPort,
        username: senderEmail,
        password: senderPassword,
      );

      // Create the message
      final message = Message()
        ..from = Address(senderEmail, 'Reading App')
        ..recipients.add(recipientEmail)
        ..subject = 'Password Reset - Reading App'
        ..text =
            '''
Hello,

Your password has been reset successfully.

Your new temporary password is: $newPassword

Please log in with this new password and consider changing it to something more memorable.

If you didn't request this reset, please contact support immediately.

Best regards,
Reading App Team
''';

      debugPrint('Sending email...');

      // Send the message - removed unused variable
      await send(message, smtpServer);
      debugPrint('Message sent successfully!');
      return true;
    } catch (e) {
      debugPrint('Error sending email: $e');
      debugPrint('Error type: ${e.runtimeType}');
      return false;
    }
  }
}
