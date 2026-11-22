import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../app/atlas_academy_app.dart';

class AdminStudentsScreen extends StatefulWidget {
const AdminStudentsScreen({super.key});

@override
State createState() =>
_AdminStudentsScreenState();
}

class _AdminStudentsScreenState extends State {
final TextEditingController _searchController =
TextEditingController();

late final Future _authorizationFuture;

String _search = '';

@override
void initState() {
super.initState();
_authorizationFuture = _isAdmin();
}

Future _isAdmin() async {
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
return FutureBuilder(
future: _authorizationFuture,
builder: (context, snapshot) {
if (snapshot.connectionState == ConnectionState.waiting) {
return const Scaffold(
backgroundColor: const Color(0xFFF2F7FF),
body: Center(
child: CircularProgressIndicator(
color: AtlasColors.royalBlue,
),
),
);
}

    if (snapshot.data != true) {
      return Scaffold(
        backgroundColor: const Color(0xFFF2F7FF),
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
backgroundColor: const Color(0xFFF2F7FF),
appBar: AppBar(
title: const Text(
'Student Management',
style: TextStyle(fontWeight: FontWeight.w800),
),
backgroundColor: const Color(0xFFF2F7FF),
foregroundColor: AtlasColors.navy,
elevation: 0,
),
body: Column(
children: [
_buildHeader(),
_buildSearch(),
Expanded(
child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
stream: FirebaseFirestore.instance
.collection('users')
.where('role', isEqualTo: 'student')
.snapshots(),
builder: (context, snapshot) {
if (snapshot.hasError) {
return _message(
'Unable to load students. Check Firestore permissions.',
Icons.cloud_off_rounded,
);
}

            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AtlasColors.royalBlue,
                ),
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
              ].map((value) =>
                  (value ?? '').toString().toLowerCase()).join(' ');
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
                Icons.people_outline_rounded,
              );
            }
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.groups_rounded,
                        color: AtlasColors.royalBlue,
                      ),
                      const SizedBox(width: 9),
                      Text(
                        '${filtered.length} registered student(s)',
                        style: const TextStyle(
                          color: AtlasColors.navy,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
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

Widget _buildHeader() {
return Container(
width: double.infinity,
padding: const EdgeInsets.fromLTRB(22, 24, 22, 26),
decoration: const BoxDecoration(
gradient: LinearGradient(
colors: [
AtlasColors.navy,
AtlasColors.royalBlue,
],
begin: Alignment.topLeft,
end: Alignment.bottomRight,
),
borderRadius: BorderRadius.vertical(
bottom: Radius.circular(26),
),
),
child: const Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Icon(
Icons.school_rounded,
color: AtlasColors.royalBlue,
size: 30,
),
SizedBox(height: 13),
Text(
'Student Directory',
style: TextStyle(
color: Colors.white,
fontSize: 23,
fontWeight: FontWeight.w900,
),
),
SizedBox(height: 6),
Text(
'Review student profiles and membership information.',
style: TextStyle(
color: Colors.white70,
fontSize: 13,
height: 1.5,
),
),
],
),
);
}

Widget _buildSearch() {
return Padding(
padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
child: TextField(
controller: _searchController,
onChanged: (value) {
setState(() => _search = value.trim().toLowerCase());
},
decoration: InputDecoration(
hintText: 'Search name, email, phone or ID',
prefixIcon: const Icon(
Icons.search_rounded,
color: AtlasColors.royalBlue,
),
suffixIcon: IconButton(
icon: const Icon(Icons.close_rounded),
onPressed: () {
_searchController.clear();
setState(() => _search = '');
},
),
filled: true,
fillColor: Colors.white,
contentPadding: const EdgeInsets.symmetric(vertical: 16),
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(21),
borderSide: const BorderSide(color: AtlasColors.border),
),
enabledBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(17),
borderSide: const BorderSide(color: AtlasColors.border),
),
focusedBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(17),
borderSide: const BorderSide(
color: AtlasColors.royalBlue,
width: 1.5,
),
),
),
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
final accountStatus =
(data['accountStatus'] ?? 'pending').toString();
final subscriptionStatus =
(data['subscriptionStatus'] ?? 'inactive').toString();

return Container(
  margin: const EdgeInsets.only(bottom: 12),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(19),
    border: Border.all(color: const Color(0xFFE0EAF5)),
    boxShadow: [
      BoxShadow(
        color: AtlasColors.navy.withValues(alpha: 0.035),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  ),
  child: ListTile(
    contentPadding: const EdgeInsets.all(14),
    leading: CircleAvatar(
      radius: 25,
      backgroundColor: AtlasColors.paleBlue,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          color: AtlasColors.navy,
          fontSize: 19,
          fontWeight: FontWeight.w900,
        ),
      ),
    ),
    title: Text(
      name,
      style: const TextStyle(
        color: AtlasColors.navy,
        fontWeight: FontWeight.w800,
      ),
    ),
    subtitle: Padding(
      padding: const EdgeInsets.only(top: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            email,
            style: const TextStyle(
              color: AtlasColors.secondaryText,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _statusChip('Account: $accountStatus', accountStatus),
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
      color: AtlasColors.royalBlue,
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
if (normalized == 'approved' || normalized == 'active') {
  color = AtlasColors.success;
} else if (normalized == 'rejected' ||
    normalized == 'expired' ||
    normalized == 'cancelled') {
  color = AtlasColors.error;
} else {
  color = AtlasColors.gold;
}
return Container(
  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
  decoration: BoxDecoration(
    color: color.withValues(alpha: 0.10),
    borderRadius: BorderRadius.circular(20),
  ),
  child: Text(
    label,
    style: TextStyle(
      color: color,
      fontSize: 10,
      fontWeight: FontWeight.w800,
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
  constraints: BoxConstraints(
    maxHeight: MediaQuery.of(context).size.height * 0.88,
  ),
  padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
  decoration: const BoxDecoration(
    color: AtlasColors.ivory,
    borderRadius: BorderRadius.vertical(
      top: Radius.circular(27),
    ),
  ),
  child: SafeArea(
    child: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: AtlasColors.border,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Student Profile',
            style: TextStyle(
              color: AtlasColors.navy,
              fontSize: 23,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Personal and academic information',
            style: TextStyle(
              color: AtlasColors.secondaryText,
              fontSize: 12,
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
          const SizedBox(height: 8),
          _sectionHeading('Account & Membership'),
          const SizedBox(height: 15),
          _detail('Account Status', data['accountStatus']),
          _detail('Subscription Status', data['subscriptionStatus']),
          _detail(
            'Access Enabled',
            data['accessEnabled'] == true ? 'Yes' : 'No',
          ),
          _detail(
            'Subscription Plan',
            data['subscriptionPlanName'],
          ),
          _detail('Subscription Expiry', expiryText),
          const SizedBox(height: 8),
          _sectionHeading('Account Identifier'),
          const SizedBox(height: 15),
          _detail('Student UID', uid),
        ],
      ),
    ),
  ),
);

}

Widget _sectionHeading(String title) {
return Container(
width: double.infinity,
padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
decoration: BoxDecoration(
color: AtlasColors.paleBlue,
borderRadius: BorderRadius.circular(12),
),
child: Text(
title,
style: const TextStyle(
color: AtlasColors.navy,
fontSize: 14,
fontWeight: FontWeight.w900,
),
),
);
}

Widget _detail(String label, dynamic value) {
final text = value?.toString().isNotEmpty == true
? value.toString()
: 'Not provided';

return Padding(
  padding: const EdgeInsets.only(bottom: 15),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          color: AtlasColors.secondaryText,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 4),
      SelectableText(
        text,
        style: const TextStyle(
          color: AtlasColors.navy,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  ),
);

}

Widget _message(String message, IconData icon) {
return Center(
child: Padding(
padding: const EdgeInsets.all(28),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
Icon(icon, size: 52, color: AtlasColors.royalBlue),
const SizedBox(height: 14),
Text(
message,
textAlign: TextAlign.center,
style: const TextStyle(
color: AtlasColors.secondaryText,
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
