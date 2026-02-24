import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // دالة لحفظ بيانات السرير في Firebase
  static Future< // دالة لحفظ البيانات في Firebase
      void> saveBedData(
    String bedNumber,
    String bedName,
    int age,
    String gender,
    String phoneNumber,
    String? selectedDoctor,
    BuildContext context,
  ) async {
// الحصول على العداد الحالي من Firebase
    DocumentSnapshot counterSnapshot = await FirebaseFirestore.instance
        .collection('settings')
        .doc('counter')
        .get();
    int currentCounter =
        counterSnapshot.exists && counterSnapshot.data() != null
            ? (counterSnapshot['patientId'] ?? 0)
            : 0;
    // زيادة العداد للحصول على id تصاعدي جديد
    int newPatientId = currentCounter + 1;

    // تحديث العداد في Firebase ليكون الرقم التالي
    await FirebaseFirestore.instance.collection('settings').doc('counter').set({
      'patientId': newPatientId,
    }, SetOptions(merge: true));

    FirebaseFirestore.instance.collection('beds').add({
      'patientId': newPatientId,
      'bedNumber': bedNumber,
      'bedName': bedName,
      'age': age,
      'gender': gender,
      'phoneNumber': phoneNumber,
      'doctorName': selectedDoctor,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<String?> getUserRole() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        var snapshot = await _firestore.collection('users').doc(user.uid).get();
        if (snapshot.exists) {
          return snapshot.data()?['Role']; // إرجاع الدور مباشرة
        }
      } catch (e) {
        print("Error fetching user role: $e");
      }
    }
    return null; // إرجاع null إذا فشل الحصول على الدور
  }

  Future<List<String>> fetchDoctorNames() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('Role', isEqualTo: 'Doctor')
          .get();

      List<String> doctorNames = snapshot.docs
          .map((doc) => doc['Name'].toString()) // استخراج الأسماء
          .toList();

      return doctorNames;
    } catch (e) {
      print("❌ خطأ أثناء جلب أسماء الأطباء: $e");
      return [];
    }
  }
}
