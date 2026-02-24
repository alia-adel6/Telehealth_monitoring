import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:t_h_m/Constants/colors.dart';
import 'package:t_h_m/Screens/add_beds/add_beds_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _obscureText = true;
  bool _isLoading = false; // لمعرفة إذا كان يتم التحميل

  String? _emailError;
  String? _passwordError;
  String? _roleError;
  String? _selectedRole;

  Future<void> _login() async {
    setState(() {
      _emailError = null;
      _passwordError = null;
      _roleError = null;
    });

    if (_emailController.text.isEmpty) {
      setState(() {
        _emailError = "Please enter your email";
      });
      return;
    }

    if (_passwordController.text.isEmpty) {
      setState(() {
        _passwordError = "Please enter your password";
      });
      return;
    }

    if (_selectedRole == null) {
      setState(() {
        _roleError = "Please select a role";
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // التحقق مما إذا كان البريد الإلكتروني موجودًا
      QuerySnapshot userQuery = await _firestore
          .collection("users")
          .where("Email", isEqualTo: _emailController.text.trim())
          .get();

      bool emailExists = userQuery.docs.isNotEmpty;

      if (!emailExists) {
        setState(() {
          _emailError = "User not found. Please check your email.";
        });
        return;
      }

      // محاولة تسجيل الدخول
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // التحقق من الدور بعد نجاح تسجيل الدخول
      DocumentSnapshot userDoc = await _firestore
          .collection("users")
          .doc(userQuery.docs.first.id)
          .get();

      if (userDoc.exists) {
        String roleInFirestore = userDoc["Role"] ?? "";

        if (roleInFirestore == _selectedRole) {
          Navigator.pushReplacementNamed(context, '/addBeds');
        } else {
          await _auth.signOut();
          setState(() {
            _roleError = "Selected role does not match.";
          });
        }
      } else {
        await _auth.signOut();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Access Denied! User not found.")),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          _passwordError = "Incorrect password. Please try again.";
        } else if (e.code == 'invalid-email') {
          _emailError = "Invalid email format. Please enter a valid email.";
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Login Failed: ${e.message}")),
          );
        }
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildTextField(
      String label, TextEditingController controller, String? errorText,
      {bool obscureText = false, bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          obscureText: isPassword ? _obscureText : obscureText,
          cursorColor: Colors.white,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: Colors.white),
            errorText: errorText,
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility : Icons.visibility_off,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  )
                : null,
          ),
          style: const TextStyle(color: Colors.white),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _selectedRole,
          decoration: InputDecoration(
            labelText: "Select Role",
            labelStyle: const TextStyle(color: Colors.white),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
            errorText: _roleError,
          ),
          dropdownColor: Colors.teal[900],
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
          items: ["Admin", "Doctor"].map((role) {
            return DropdownMenuItem<String>(
              value: role,
              child: Text(role, style: const TextStyle(color: Colors.white)),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedRole = value;
              _roleError = null; // إزالة الخطأ عند اختيار الدور
            });
          },
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          "Login to THM",
          style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
        ),
        backgroundColor: AppColors.darkPrimaryColor,
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.darkPrimaryColor, AppColors.primaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: SingleChildScrollView(
                //  هذا يسمح بالتمرير بدون إغلاق الكيبورد
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior
                    .manual, //  لا يغلق الكيبورد عند السحب
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    Image.asset(
                      "assets/images/logo.png",
                      height: 150,
                      width: 150,
                    ),
                    const SizedBox(height: 30),
                    _buildTextField("Email", _emailController, _emailError),
                    _buildTextField(
                        "Password", _passwordController, _passwordError,
                        obscureText: true, isPassword: true),
                    _buildDropdown(),
                    const SizedBox(height: 30),
                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : ElevatedButton(
                            onPressed: _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primaryColor,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 50, vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text(
                              "Login",
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> signIn(
      BuildContext context, String email, String password) async {
    try {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      // الانتقال إلى الصفحة الرئيسية بعد تسجيل الدخول
      Navigator.pushReplacementNamed(context, '/addBeds');
    } catch (e) {}
  }
}
