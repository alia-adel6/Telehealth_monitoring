import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:t_h_m/Providers/theme_provider.dart';
import 'package:t_h_m/generated/l10n.dart';
import 'theme_toggle.dart';
import 'language_selector.dart';
import 'about_dialog.dart';
import 'rating_dialog.dart';
import 'previous_patient.dart';
import 'log_out.dart';
import 'ai_chat_screen.dart';
import 'view_selected_patients.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double averageRating = 0.0;
  String userRole = '';

  @override
  void initState() {
    super.initState();
    _getAverageRating();
    _getUserRole();
  }

  Future<void> _getAverageRating() async {
    double avg = await getAverageRating();
    if (!mounted) return;

    setState(() {
      averageRating = avg;
    });
  }

  void updateAverageRating(double newAverage) {
    setState(() {
      averageRating = newAverage;
    });
  }

  void _getUserRole() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // استرجاع دور المستخدم من Firestore
      DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (docSnapshot.exists) {
        setState(() {
          userRole = docSnapshot['Role']; // تعيين دور المستخدم من Firestore
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).app_settings,
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ////////////////الوضع الداكن
              ThemeToggle(),
              Divider(color: isDarkMode ? Colors.grey : Colors.black),
              /////////////// اللغة
              LanguageSelector(),
              if (userRole == 'Doctor')
                Divider(color: isDarkMode ? Colors.grey : Colors.black),

              ///////////////////تخصيص عرض المرضى

              if (userRole == 'Doctor')
                ListTile(
                  leading: Icon(Icons.people,
                      color: Theme.of(context).colorScheme.primary),
                  title: Text(S.of(context).view_patients),
                  onTap: () => PatientChoiceScreen(context), // فتح Dialog
                ),
              /////////////////// المرضى السابقين
              Divider(color: isDarkMode ? Colors.grey : Colors.black),
              ListTile(
                leading: Icon(Icons.history,
                    color: Theme.of(context).colorScheme.primary),
                title: Text(S.of(context).show_pre_patients),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            PreviousPatientsScreen()), // ✅ الانتقال إلى شاشة المرضى السابقين
                  );
                },
              ),
              ////////////////// المساعد الذكي
              Divider(color: isDarkMode ? Colors.grey : Colors.black),
              ListTile(
                leading: Icon(Icons.smart_toy,
                    color: Theme.of(context).colorScheme.primary),
                title: Text(S.of(context).smart_assistant),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AIChatScreen()),
                  );
                },
              ),
              /////////////////////// حوول التطبيق
              Divider(color: isDarkMode ? Colors.grey : Colors.black),
              ListTile(
                leading: Icon(Icons.info,
                    color: Theme.of(context).colorScheme.primary),
                title: Text(S.of(context).about_app),
                onTap: () => showCustomAboutDialog(context),
              ),
              ////////////////////// تقييم التطبيق
              Divider(color: isDarkMode ? Colors.grey : Colors.black),
              ListTile(
                leading: Icon(Icons.star_rate,
                    color: Theme.of(context).colorScheme.primary),
                title: Text(S.of(context).rate_app),
                subtitle: Text(
                    "${S.of(context).average_rating}: ${averageRating.toStringAsFixed(1)}"),
                onTap: () => showRatingDialog(context, updateAverageRating),
              ),
              //////////////////////////// تسجيل الخروج
              Divider(color: isDarkMode ? Colors.grey : Colors.black),
              ListTile(
                  leading: Icon(Icons.exit_to_app,
                      color: Theme.of(context).colorScheme.primary),
                  title: Text(S.of(context).logout),
                  onTap: () => LogOut.confirmSignOut(context)),
            ],
          ),
        ),
      ),
    );
  }
}
