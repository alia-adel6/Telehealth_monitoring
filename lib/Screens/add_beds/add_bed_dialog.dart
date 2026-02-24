import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:t_h_m/generated/l10n.dart';
import 'add_beds_firebase.dart';
import 'custom_text_field.dart';
import 'dialogs.dart';

class AddBedDialog extends StatefulWidget {
  @override
  _AddBedDialogState createState() => _AddBedDialogState();
}

class _AddBedDialogState extends State<AddBedDialog> {
  static const int maxBeds = 10; // الحد الأقصى لعدد الأسرة
  List<String> doctorNames = []; // قائمة بأسماء الأطباء
  String? selectedDoctor; // الطبيب المختار
  final FirebaseService _firebaseService = FirebaseService(); // استدعاء الخدمة
  String? bedNumberErrorText;

  @override
  void initState() {
    super.initState();
    loadDoctors(); // تحميل أسماء الأطباء
  }

  Future<void> loadDoctors() async {
    List<String> names = await _firebaseService.fetchDoctorNames();
    setState(() {
      doctorNames = names;
    });
  }

  final _formKey = GlobalKey<FormState>();
  final TextEditingController bedNumberController = TextEditingController();
  final TextEditingController bedNameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController doctorNameController = TextEditingController();

  String gender = 'Male';

  Future<bool> validateBedCount() async {
    final bedCountSnapshot =
        await FirebaseFirestore.instance.collection('beds').get();
    return bedCountSnapshot.docs.length < maxBeds;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(S.of(context).add_patient),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              buildTextField(
                label: S.of(context).bed_number,
                controller: bedNumberController,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return S.of(context).please_bed_number;
                  }
                  if (bedNumberErrorText != null) {
                    return bedNumberErrorText;
                  }
                  return null;
                },
                context: context,
              ),
              buildTextField(
                label: S.of(context).name,
                controller: bedNameController,
                keyboardType: TextInputType.text,
                validator: (value) =>
                    value!.isEmpty ? S.of(context).please_name : null,
                context: context,
              ),
              buildTextField(
                label: S.of(context).age,
                controller: ageController,
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value!.isEmpty ? S.of(context).please_age : null,
                context: context,
              ),
              buildGenderSelection(),
              buildTextField(
                label: S.of(context).phone_number,
                controller: phoneNumberController,
                keyboardType: TextInputType.phone,
                validator: (value) =>
                    value!.isEmpty ? S.of(context).please_phone : null,
                context: context,
              ),
              DropdownButtonFormField<String>(
                value: selectedDoctor,
                dropdownColor: Theme.of(context)
                    .dialogTheme
                    .backgroundColor, // الطبيب المختار
                decoration: InputDecoration(
                  labelText: S.of(context).doctor_name,
                ),
                items: doctorNames.map((String doctor) {
                  return DropdownMenuItem<String>(
                    value: doctor,
                    child: Text(doctor),
                  );
                }).toList(),
                validator: (value) =>
                    value == null ? S.of(context).please_doctor_name : null,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedDoctor = newValue;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(S.of(context).cancel,
              style: TextStyle(color: Theme.of(context).colorScheme.primary)),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              bool canAdd = await validateBedCount();
              if (!canAdd) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(S.of(context).maximum_beds_reached),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
                return;
              }
              // التحقق من تكرار رقم السرير
              final existingBed = await FirebaseFirestore.instance
                  .collection('beds')
                  .where('bedNumber',
                      isEqualTo: bedNumberController.text.trim())
                  .get();

              if (existingBed.docs.isNotEmpty) {
                setState(() {
                  bedNumberErrorText = S.of(context).bed_exists;
                });
                // إعادة التحقق لتحديث الـ validator
                _formKey.currentState!.validate();
                return;
              }

              await FirebaseService.saveBedData(
                bedNumberController.text.trim(),
                bedNameController.text.trim(),
                int.tryParse(ageController.text.trim()) ?? 0,
                gender,
                phoneNumberController.text.trim(),
                selectedDoctor,
                context,
              );

              Navigator.of(context).pop();
              Dialogs.showSuccessAnimation(context);

              // تنظيف الحقول
              bedNumberController.clear();
              bedNameController.clear();
              ageController.clear();
              phoneNumberController.clear();
              doctorNameController.clear();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
          child: Text(S.of(context).add, style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget buildGenderSelection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(S.of(context).gender),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Radio<String>(
                value: 'Male',
                groupValue: gender,
                onChanged: (value) => setState(() => gender = value!),
                activeColor: Theme.of(context).colorScheme.primary,
              ),
              Text(S.of(context).male),
              SizedBox(width: 20),
              Radio<String>(
                value: 'Female',
                groupValue: gender,
                onChanged: (value) => setState(() => gender = value!),
                activeColor: Theme.of(context).colorScheme.primary,
              ),
              Text(S.of(context).female),
            ],
          ),
        ],
      ),
    );
  }
}
