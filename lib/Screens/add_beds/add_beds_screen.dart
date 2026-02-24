import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:t_h_m/Constants/colors.dart';
import 'package:t_h_m/Screens/add_beds/add_bed_dialog.dart';
import 'package:t_h_m/Screens/add_beds/bed_item.dart';
import 'package:t_h_m/Screens/settings/settings_screen.dart';
import 'package:t_h_m/generated/l10n.dart';
import 'dialogs.dart';
import 'add_beds_firebase.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddBedsScreen extends StatefulWidget {
  final String? doctorName;

  const AddBedsScreen({Key? key, this.doctorName}) : super(key: key);

  @override
  _AddBedsScreenState createState() => _AddBedsScreenState();
}

class _AddBedsScreenState extends State<AddBedsScreen> {
  String? userRole;
  bool isLoading = true;
  final FirebaseService _firebaseService = FirebaseService();
  bool _isSearching = false;
  TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  String selectedPatientType = 'all';
  String? doctorName;
  bool isGridView = false;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (userDoc.exists && userDoc.data() != null) {
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      setState(() {
        userRole = userData['Role'] ?? "Unknown";
        doctorName = userData['Name'] ?? "";
        selectedPatientType = userData['selectedOption'] ?? 'all';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return await Dialogs.showExitDialog(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: _isSearching
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  cursorColor: Colors.white,
                  decoration: InputDecoration(
                    hintText: S.of(context).search,
                    border: InputBorder.none,
                    hintStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value.toLowerCase();
                    });
                  },
                )
              : Text(
                  S.of(context).app_title,
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          actions: [
            IconButton(
              icon: Icon(isGridView ? Icons.view_list : Icons.grid_view),
              onPressed: () {
                setState(() {
                  isGridView = !isGridView;
                });
              },
            ),
            IconButton(
              icon: Icon(
                _isSearching ? Icons.close : Icons.search,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              onPressed: () {
                setState(() {
                  if (_isSearching) {
                    _searchController.clear();
                    searchQuery = '';
                  }
                  _isSearching = !_isSearching;
                });
              },
            ),
            IconButton(
              icon: Icon(
                Icons.settings,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsScreen()),
                );
              },
            ),
          ],
        ),
        body: isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
              )
            : StreamBuilder<QuerySnapshot>(
                stream: getBedsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        S.of(context).no_beds_yet,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                    );
                  }

                  var beds = snapshot.data!.docs.where((bed) {
                    var bedData = bed.data() as Map<String, dynamic>;
                    var patientName =
                        bedData['bedName']?.toString().toLowerCase() ?? "";
                    return searchQuery.isEmpty ||
                        patientName.contains(searchQuery);
                  }).toList();
// الترتيب حسب timestamp (إذا كان موجودًا)
                  beds.sort((a, b) {
                    var aData = a.data() as Map<String, dynamic>;
                    var bData = b.data() as Map<String, dynamic>;

                    var aTimestamp = aData['timestamp'] ?? Timestamp(0, 0);
                    var bTimestamp = bData['timestamp'] ?? Timestamp(0, 0);

                    return aTimestamp.compareTo(bTimestamp);
                  });

                  return isGridView
                      ? GridView.builder(
                          padding: const EdgeInsets.all(10),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2, // عنصرين في كل صف
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 0.85, // اضبطيه حسب شكل الكرت
                          ),
                          itemCount: beds.length,
                          itemBuilder: (context, index) {
                            var bed = beds[index];
                            var bedData = bed.data() as Map<String, dynamic>?;

                            return BedItem(
                              isGrid: true, // كأنه يقول "اعرض كل شي"

                              docId: bed.id,
                              bedNumber: bedData?['bedNumber'] ?? 'Unknown',
                              bedName: bedData?['bedName'] ?? 'Unknown',
                              age: bedData?['age'] ?? 0,
                              gender: bedData?['gender'] ?? 'Unknown',
                              phoneNumber: bedData?['phoneNumber'] ?? 'Unknown',
                              doctorName: bedData?['doctorName'] ?? 'Unknown',
                              userRole: userRole ?? "Unknown",
                              heartRate: bedData?['heart_rate'] ?? 'Unknown',
                              temperature: bedData?['temperature'] ?? 'Unknown',
                              spo2: bedData?['spo2'] ?? 'Unknown',
                              bloodPressure:
                                  bedData?['blood_pressure'] ?? 'Unknown',
                              glucose: bedData?['glucose'] ?? 'Unknown',
                            );
                          },
                        )
                      : ListView.builder(
                          itemCount: beds.length,
                          itemBuilder: (context, index) {
                            var bed = beds[index];
                            var bedData = bed.data() as Map<String, dynamic>?;

                            return BedItem(
                              isGrid: false,
                              docId: bed.id,
                              bedNumber: bedData?['bedNumber'] ?? 'Unknown',
                              bedName: bedData?['bedName'] ?? 'Unknown',
                              age: bedData?['age'] ?? 0,
                              gender: bedData?['gender'] ?? 'Unknown',
                              phoneNumber: bedData?['phoneNumber'] ?? 'Unknown',
                              doctorName: bedData?['doctorName'] ?? 'Unknown',
                              userRole: userRole ?? "Unknown",
                              heartRate: bedData?['heart_rate'] ?? 'Unknown',
                              temperature: bedData?['temperature'] ?? 'Unknown',
                              spo2: bedData?['spo2'] ?? 'Unknown',
                              bloodPressure:
                                  bedData?['blood_pressure'] ?? 'Unknown',
                              glucose: bedData?['glucose'] ?? 'Unknown',
                            );
                          },
                        );
                },
              ),
        floatingActionButton: (userRole == "Admin")
            ? FloatingActionButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) => AddBedDialog(),
                  );
                },
                backgroundColor: AppColors.primaryColor,
                child:
                    Icon(Icons.add, color: Theme.of(context).iconTheme.color),
              )
            : null,
      ),
    );
  }

  Stream<QuerySnapshot> getBedsStream() {
    Query query = FirebaseFirestore.instance.collection('beds');

    if (selectedPatientType == 'myPatients' && (doctorName ?? '').isNotEmpty) {
      query = query.where('doctorName', isEqualTo: doctorName);
    }

    return query.snapshots();
  }
}
