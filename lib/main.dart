import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';
import 'package:t_h_m/Screens/add_beds/add_beds_screen.dart';
//import 'Screens/welcome/welcome_screen.dart';
import 'Providers/theme_provider.dart';
import 'package:t_h_m/Theme/app_theme.dart';
import 'theme/theme_helper.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:t_h_m/generated/l10n.dart';
import 'package:t_h_m/Providers/localization_provider.dart'; // استيراد الملف
import 'Screens/login/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await dotenv.load(fileName: ".env");

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(
            create: (context) => LocaleProvider()), // إضافة LocaleProvider
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  // final bool isFirstTime;
  // const MyApp({required this.isFirstTime, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    Provider.of<LocaleProvider>(context); // استخدام LocaleProvider
    ThemeHelper.setNavigationBarColor(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: AppTheme.lightTheme, // استخدام الثيم الفاتح
      darkTheme: AppTheme.darkTheme, // استخدام الثيم الداكن
      builder: (context, child) {
        ThemeHelper.setNavigationBarColor(context);
        return child!;
      },
      locale: Provider.of<LocaleProvider>(context)
          .locale, // هذا يجب أن يعمل الآن بدون أخطاء
      supportedLocales: [
        Locale('en', 'US'), // الإنجليزية
        Locale('ar', 'SA'), // العربية
      ],
      localizationsDelegates: [
        S.delegate, // إضافة محول اللغات
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      initialRoute:
          FirebaseAuth.instance.currentUser != null ? '/addBeds' : '/login',

      routes: {
        '/login': (context) => LoginScreen(),
        '/addBeds': (context) => AddBedsScreen(),
      },
      //: AddBedsScreen(),
    );
  }
}
