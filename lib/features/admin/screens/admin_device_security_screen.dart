import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../app/atlas_academy_app.dart';

class AdminDeviceSecurityScreen extends StatelessWidget {
  const AdminDeviceSecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FF),
      appBar: AppBar(
        title: const Text('Device Security'),
        backgroundColor: AtlasColors.navy,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('device_security_events')
            .orderBy('createdAt', descending: true)
            .limit(100)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Unable to load security review events.'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          final pending = docs.where((d) =>
              (d.data()['reviewStatus'] ?? 'pending') == 'pending').length;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ONE DEVICE PER STUDENT',
                          style: TextStyle(fontWeight: FontWeight.w900,
                              color: AtlasColors.navy, letterSpacing: 1)),
                      const SizedBox(height: 7),
                      Text('$pending events awaiting review',
                          style: const TextStyle(color: AtlasColors.secondaryText)),
                      const SizedBox(height: 6),
                      const Text(
                        'Possible VPN/proxy connections are risk signals, not proof. Review the network and device-change history before taking action.',
                        style: TextStyle(fontSize: 12, height: 1.45,
                            color: AtlasColors.secondaryText)),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: docs.isEmpty
                    ? const Center(child: Text('No suspicious device activity recorded.'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: docs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data = doc.data();
                          final reviewed = data['reviewStatus'] == 'reviewed';
                          final event = (data['event'] ?? 'security_event').toString();
                          final isProxy = event == 'possible_vpn_or_proxy';
                          final title = isProxy ? 'Possible VPN / Proxy' :
                              (event == 'device_changed' ? 'Device changed' : 'Unusual sign-in location');
                          final created = data['createdAt'];
                          final when = created is Timestamp
                              ? created.toDate().toLocal().toString()
                              : (created ?? '').toString();
                          return Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: reviewed
                                  ? const Color(0xFFE0E8F2)
                                  : const Color(0xFFFFDDA6)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Icon(isProxy ? Icons.shield_outlined : Icons.devices_other_rounded,
                                      color: isProxy ? Colors.deepOrange : AtlasColors.royalBlue),
                                  const SizedBox(width: 9),
                                  Expanded(child: Text(title,
                                      style: const TextStyle(fontWeight: FontWeight.w900,
                                          color: AtlasColors.navy))),
                                  Text(reviewed ? 'Reviewed' : 'Pending',
                                      style: TextStyle(fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: reviewed ? Colors.green : Colors.deepOrange)),
                                ]),
                                const SizedBox(height: 9),
                                Text('Student UID: ${data['userId'] ?? '-'}',
                                    style: const TextStyle(fontSize: 11)),
                                Text('IP: ${data['ipAddress'] ?? '-'}  •  Country: ${data['country'] ?? '-'}',
                                    style: const TextStyle(fontSize: 11)),
                                Text('Network: ${data['networkOrganization'] ?? '-'}',
                                    style: const TextStyle(fontSize: 11)),
                                Text('Time: $when',
                                    style: const TextStyle(fontSize: 10,
                                        color: AtlasColors.secondaryText)),
                                if ((data['details'] ?? '').toString().isNotEmpty) ...[
                                  const SizedBox(height: 7),
                                  Text(data['details'].toString(),
                                      style: const TextStyle(fontSize: 12, height: 1.4)),
                                ],
                                if (!reviewed)
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      onPressed: () => doc.reference.update({
                                        'reviewStatus': 'reviewed',
                                        'reviewedAt': FieldValue.serverTimestamp(),
                                      }),
                                      icon: const Icon(Icons.done_rounded, size: 17),
                                      label: const Text('Mark reviewed'),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
