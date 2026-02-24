import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:t_h_m/Screens/Login/login_screen.dart';
import 'package:t_h_m/generated/l10n.dart';

class LogOut {
  static Future<void> confirmSignOut(BuildContext context) async {
    bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Text(S.of(context).logout_confirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false), // إغلاق بدون خروج
              child: Text(
                S.of(context).cancel,
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true), // تأكيد الخروج
              child: Text(
                S.of(context).yes,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      await signOut(context); // تنفيذ تسجيل الخروج إذا اختار "نعم"
    }
  }

  static Future<void> signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();

      // التأكد من أن `context` ما زال متاحًا قبل التنقل
      if (!context.mounted) return;

      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      print("Error signing out: $e");

      // التأكد من أن `context` ما زال متاحًا قبل عرض `SnackBar`
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Faild Log Out . please try again")),
      );
    }
  }
}
