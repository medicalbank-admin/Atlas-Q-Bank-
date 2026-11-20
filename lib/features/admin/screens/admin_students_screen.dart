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
  static const Color navy = Color(0xFF123F46);
  static const Color teal = Color(0xFF28777B);
  static const Color ivory = Color(0xFFF7F8F5);

  final TextEditingController _searchController =
      TextEditingController();

  late final Future<bool> _authorizationFuture;

  String _search = '';

  @override
  void initState() {
    super.initState();
    _authorizationFuture = _isAdmin();
  }

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
      future: _authorizationFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: ivory,
            body: Center(
              child: CircularProgressIndicator(color: teal),
            ),
          );
        }

        if (snapshot.data != true) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Student Management'),
            ),
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
      backgroundColor: ivory,
      appBar: AppBar(
        title: const Text(
          'Student Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: navy,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _search = value.trim().toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search name, email, phone or ID',
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
                  return _message(
                    'Unable to load students. Check Firestore '
                    'permissions and administrator access.',
                    icon: Icons.cloud_off_rounded,
                  );
                }

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: teal),
                  );
                }

                final students = snapshot.data?.docs ?? [];

                final filtered = students.where((doc) {
                  final data = doc.data();

                  final searchable = [
                    data['fullName'],
                    data['email'],
                    data['whatsappNumber'],
                    data['nationalId'],
                    doc.id,
                  ].map((value) => (value ?? '')
                      .toString()
                      .toLowerCase())
                      .join(' ');

                  return searchable.contains(_search);
                }).toList();

                filtered.sort((a, b) {
                  final aDate = a.data()['createdAt'];
                  final bDate = b.data()['createdAt'];

                  final aMillis = aDate is Timestamp
                      ? aDate.millisecondsSinceEpoch
                      : 0;

                  final bMillis = bDate is Timestamp
                      ? bDate.millisecondsSinceEpoch
                      : 0;

                  return bMillis.compareTo(aMillis);
                });

                if (filtered.isEmpty) {
                  return _message(
                    _search.isEmpty
                        ? 'No registered students found.'
                        : 'No matching students found.',
                    icon: Icons.people_outline_rounded,
                  );
                }

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.people_alt_rounded,
                            color: teal,
                            size: 19,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${filtered.length} student(s)',
                            style: const TextStyle(
                              color: navy,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                          16, 0, 16, 24,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final doc = filtered[index];

                          return _studentCard(
                            context,
                            doc.id,
                            doc.data(),
                          );
                        },
                      ),
                    ),
                  ],
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
    final name =
        (data['fullName'] ?? 'Unnamed Student').toString();

    final email =
        (data['email'] ?? 'No email').toString();

    // Correct field used by student registration.
    final accountStatus =
        (data['accountStatus'] ?? 'pending').toString();

    final subscriptionStatus =
        (data['subscriptionStatus'] ?? 'inactive').toString();

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
              color: navy,
              fontWeight: FontWeight.bold,
              fontSize: 19,
            ),
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: navy,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(email),
              const SizedBox(height: 9),
              Wrap(
                spacing: 7,
                runSpacing: 6,
                children: [
                  _statusChip(
                    'Account: $accountStatus',
                    accountStatus,
                  ),
                  _statusChip(
                    'Subscription: $subscriptionStatus',
                    subscriptionStatus,
                  ),
                ],
              ),
            ],
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 15,
          color: teal,
        ),
        onTap: () {
          showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => _studentDetails(uid, data),
          );
        },
      ),
    );
  }

  Widget _statusChip(String label, String status) {
    final normalized = status.toLowerCase();

    final Color color;

    if (normalized == 'approved' ||
        normalized == 'active') {
      color = Colors.green;
    } else if (normalized == 'rejected' ||
        normalized == 'expired' ||
        normalized == 'cancelled') {
      color = Colors.redAccent;
    } else {
      color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _studentDetails(
    String uid,
    Map<String, dynamic> data,
  ) {
    final expiry = data['subscriptionExpiryAt'];

    String expiryText = 'Not provided';

    if (expiry is Timestamp) {
      expiryText = _formatDate(expiry.toDate());
    }

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
                  color: navy,
                ),
              ),
              const SizedBox(height: 20),

              _detail('Full Name', data['fullName']),
              _detail('Father Name', data['fatherName']),
              _detail('National ID / Passport', data['nationalId']),
              _detail('WhatsApp Number', data['whatsappNumber']),
              _detail('Email', data['email']),
              _detail('Country of Study', data['countryOfStudy']),
              _detail('University', data['university']),

              const Divider(height: 28),

              const Text(
                'Account & Membership',
                style: TextStyle(
                  color: navy,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),

              _detail('Account Status', data['accountStatus']),
              _detail(
                'Subscription Status',
                data['subscriptionStatus'],
              ),
              _detail(
                'Access Enabled',
                data['accessEnabled'] == true ? 'Yes' : 'No',
              ),
              _detail('Subscription Plan', data['subscriptionPlanName']),
              _detail('Subscription Expiry', expiryText),

              const Divider(height: 28),

              _detail('Student UID', uid),
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
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: navy,
            ),
          ),
        ],
      ),
    );
  }

  Widget _message(
    String message, {
    required IconData icon,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: teal),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black54,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day-$month-${date.year}';
  }
}
