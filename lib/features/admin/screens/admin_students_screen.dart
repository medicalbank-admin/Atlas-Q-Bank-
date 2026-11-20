
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminStudentsScreen extends StatefulWidget {
  const AdminStudentsScreen({super.key});

  @override
  State<AdminStudentsScreen> createState() =>
      _AdminStudentsScreenState();
}

class _AdminStudentsScreenState extends State<AdminStudentsScreen> {
  final TextEditingController _searchController =
      TextEditingController();

  String _search = '';

  Future<bool> _isAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final token = await user.getIdTokenResult(true);
      return token.claims?['admin'] == true;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isAdmin(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState ==
            ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (authSnapshot.data != true) {
          return Scaffold(
            appBar: AppBar(title: const Text('Student Management')),
            body: const Center(
              child: Text('Administrator access required.'),
            ),
          );
        }

        return _buildStudentList();
      },
    );
  }

  Widget _buildStudentList() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        title: const Text(
          'Student Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF123F46),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _search = value.trim().toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search students by name or email',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _search = '');
                  },
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'student')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Unable to load students. Check Firestore rules '
                        'and your administrator permissions.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final students = snapshot.data?.docs ?? [];

                final filtered = students.where((doc) {
                  final data = doc.data();
                  final name = (data['fullName'] ?? '')
                      .toString()
                      .toLowerCase();
                  final email = (data['email'] ?? '')
                      .toString()
                      .toLowerCase();

                  return name.contains(_search) ||
                      email.contains(_search);
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      _search.isEmpty
                          ? 'No registered students found.'
                          : 'No matching students found.',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 15,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final doc = filtered[index];
                    final data = doc.data();

                    return _studentCard(
                      context,
                      doc.id,
                      data,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _studentCard(
    BuildContext context,
    String uid,
    Map<String, dynamic> data,
  ) {
    final name = (data['fullName'] ?? 'Unnamed Student').toString();
    final email = (data['email'] ?? 'No email').toString();
    final status = (data['status'] ?? 'pending').toString();

    return Card(
      elevation: 1,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: const Color(0xFFE5F1EF),
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: const TextStyle(
              color: Color(0xFF123F46),
              fontWeight: FontWeight.bold,
              fontSize: 19,
            ),
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(email),
              const SizedBox(height: 5),
              Text(
                'Status: $status',
                style: const TextStyle(
                  color: Color(0xFF28777B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
        ),
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => _studentDetails(uid, data),
          );
        },
      ),
    );
  }

  Widget _studentDetails(
    String uid,
    Map<String, dynamic> data,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(26),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Student Profile',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF123F46),
                ),
              ),
              const SizedBox(height: 18),
              _detail('Full Name', data['fullName']),
              _detail('Father Name', data['fatherName']),
              _detail('National ID / Passport', data['nationalId']),
              _detail('WhatsApp', data['whatsappNumber']),
              _detail('Email', data['email']),
              _detail('Country of Study', data['countryOfStudy']),
              _detail('University', data['university']),
              _detail('Account Status', data['status']),
              _detail('Subscription Status', data['subscriptionStatus']),
              _detail('Student ID', uid),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detail(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 3),
          SelectableText(
            value?.toString().isNotEmpty == true
                ? value.toString()
                : 'Not provided',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
