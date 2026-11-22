import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
class AdminSubscriptionPlansScreen extends StatefulWidget {
  const AdminSubscriptionPlansScreen({super.key});

  @override
  State<AdminSubscriptionPlansScreen> createState() =>
      _AdminSubscriptionPlansScreenState();
}

class _AdminSubscriptionPlansScreenState
    extends State<AdminSubscriptionPlansScreen> {
  static const Color navy = Color(0xFF071B3D);
  static const Color teal = Color(0xFF174A91);
  static const Color gold = Color(0xFFE4BE68);
  static const Color ivory = Color(0xFFF5F7FC);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late final Future<bool> _authorizationFuture =
      _checkAdminAuthorization();

  Future<bool> _checkAdminAuthorization() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return false;

    try {
      final token = await user.getIdTokenResult(true);
      return token.claims?['admin'] == true;
    } catch (_) {
      return false;
    }
  }

  CollectionReference<Map<String, dynamic>> get _plans =>
      _firestore.collection('subscription_plans');

  static const Map<String, String> _permissionLabels = {
    'studyLibrary': 'Study Library & Learning Resources',
    'mcqPractice': 'MCQ Practice',
    'examinations': 'Examinations',
    'pastPapers': 'Past Papers',
    'clinicalCases': 'Clinical Case-Based Learning',
    'mistakesNotebook': 'Mistakes Notebook',
    'mockPredictions': 'Mock Exam Readiness & Predictions',
    'discussionForum': 'Student Discussion Forum',
    'askTeacher': 'Ask a Teacher',
  };

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _authorizationFuture,
      builder: (context, authorizationSnapshot) {
        if (authorizationSnapshot.connectionState ==
            ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: ivory,
            body: Center(
              child: CircularProgressIndicator(color: teal),
            ),
          );
        }

        if (authorizationSnapshot.data != true) {
          return _accessDenied();
        }

        return _buildScreen();
      },
    );
  }

  Widget _accessDenied() {
    return Scaffold(
      backgroundColor: ivory,
      appBar: AppBar(
        title: const Text('Subscription Plans'),
        backgroundColor: ivory,
        foregroundColor: navy,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                size: 60,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 18),
              const Text(
                'Administrator Access Required',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: navy,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Only authorized administrators can manage '
                'subscription plans.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                },
                child: const Text('Sign Out'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScreen() {
    return Scaffold(
      backgroundColor: ivory,
      appBar: AppBar(
        title: const Text(
          'Subscription Plans',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: ivory,
        foregroundColor: navy,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openPlanForm(),
        backgroundColor: navy,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Create Plan'),
      ),
      body: Column(
        children: [
          _header(),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _plans
                  .orderBy('sortOrder')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: teal),
                  );
                }

                if (snapshot.hasError) {
                  return _errorState(snapshot.error.toString());
                }

                final documents = snapshot.data?.docs ?? [];

                if (documents.isEmpty) {
                  return _emptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: documents.length,
                  itemBuilder: (context, index) {
                    return _planCard(documents[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [navy, teal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(21),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.workspace_premium_rounded,
            color: gold,
            size: 34,
          ),
          SizedBox(height: 12),
          Text(
            'Membership Management',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 7),
          Text(
            'Create membership plans, set prices and durations, '
            'and configure the learning permissions included '
            'with each plan.',
            style: TextStyle(
              color: Colors.white70,
              height: 1.5,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _planCard(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    final name = data['name']?.toString() ?? 'Unnamed Plan';
    final description = data['description']?.toString() ?? '';
    final duration = (data['durationDays'] as num?)?.toInt() ?? 0;
    final price = (data['price'] as num?)?.toDouble() ?? 0;
    final currency = data['currency']?.toString() ?? 'USD';
    final active = data['isActive'] == true;
    final features = List<String>.from(
      data['features'] ?? const [],
    );

    final permissions = Map<String, dynamic>.from(
      data['accessPermissions'] ?? const {},
    );

    final enabledPermissions = permissions.entries
        .where((entry) => entry.value == true)
        .map((entry) => _permissionLabels[entry.key] ?? entry.key)
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF1FC),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: teal,
                  size: 25,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: navy,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      active ? 'Active Plan' : 'Inactive Plan',
                      style: TextStyle(
                        color: active
                            ? Colors.green.shade700
                            : Colors.red.shade600,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _openPlanForm(
                      documentId: document.id,
                      existingData: data,
                    );
                  } else if (value == 'toggle') {
                    _togglePlan(document.id, active);
                  } else if (value == 'delete') {
                    _confirmDelete(document.id, name);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Edit Plan'),
                  ),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Text(
                      active ? 'Deactivate Plan' : 'Activate Plan',
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      'Delete Plan',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 17),
          Text(
            '$currency ${price.toStringAsFixed(2)}',
            style: const TextStyle(
              color: navy,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$duration days membership',
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 12,
            ),
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              description,
              style: const TextStyle(
                color: Colors.black87,
                height: 1.4,
                fontSize: 12,
              ),
            ),
          ],
          if (features.isNotEmpty) ...[
            const SizedBox(height: 15),
            const Text(
              'Plan Features',
              style: TextStyle(
                color: navy,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 7),
            ...features.map(
              (feature) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: teal,
                      size: 15,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        feature,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (enabledPermissions.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              'Configured Access',
              style: TextStyle(
                color: navy,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 7),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: enabledPermissions.map((permission) {
                return Chip(
                  label: Text(permission),
                  backgroundColor: const Color(0xFFEAF1FC),
                  side: BorderSide.none,
                  labelStyle: const TextStyle(
                    color: navy,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.workspace_premium_outlined,
              color: teal,
              size: 65,
            ),
            const SizedBox(height: 16),
            const Text(
              'No Subscription Plans Yet',
              style: TextStyle(
                color: navy,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create your first membership plan to allow '
              'students to request subscriptions.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () => _openPlanForm(),
              icon: const Icon(Icons.add),
              label: const Text('Create First Plan'),
              style: FilledButton.styleFrom(
                backgroundColor: navy,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.redAccent,
              size: 45,
            ),
            const SizedBox(height: 12),
            const Text(
              'Unable to load subscription plans',
              style: TextStyle(
                color: navy,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPlanForm({
    String? documentId,
    Map<String, dynamic>? existingData,
  }) async {
    final formKey = GlobalKey<FormState>();

    final nameController = TextEditingController(
      text: existingData?['name']?.toString() ?? '',
    );

    final descriptionController = TextEditingController(
      text: existingData?['description']?.toString() ?? '',
    );

    final durationController = TextEditingController(
      text: existingData?['durationDays']?.toString() ?? '30',
    );

    final priceController = TextEditingController(
      text: existingData?['price']?.toString() ?? '',
    );

    final featuresController = TextEditingController(
      text: List<String>.from(
        existingData?['features'] ?? const [],
      ).join('\n'),
    );

    final currencyController = TextEditingController(
      text: existingData?['currency']?.toString() ?? 'USD',
    );

    final existingPermissions = Map<String, dynamic>.from(
      existingData?['accessPermissions'] ?? const {},
    );

    final permissions = <String, bool>{
      for (final key in _permissionLabels.keys)
        key: existingPermissions[key] == true,
    };

    bool isActive = existingData?['isActive'] != false;

    final sortOrderController = TextEditingController(
      text: existingData?['sortOrder']?.toString() ?? '0',
    );

    bool saving = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: Text(
                documentId == null
                    ? 'Create Subscription Plan'
                    : 'Edit Subscription Plan',
                style: const TextStyle(
                  color: navy,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SizedBox(
                width: 480,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _field(
                          controller: nameController,
                          label: 'Plan Name',
                          hint: 'e.g. Premium Membership',
                          validator: _requiredValidator,
                        ),
                        _field(
                          controller: descriptionController,
                          label: 'Description',
                          hint: 'Describe this membership plan',
                          maxLines: 3,
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: _field(
                                controller: durationController,
                                label: 'Duration (Days)',
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  final number = int.tryParse(
                                    value?.trim() ?? '',
                                  );

                                  if (number == null ||
                                      number < 1 ||
                                      number > 3650) {
                                    return 'Enter 1–3650';
                                  }

                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _field(
                                controller: priceController,
                                label: 'Price',
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                validator: (value) {
                                  final number = double.tryParse(
                                    value?.trim() ?? '',
                                  );

                                  if (number == null ||
                                      number <= 0 ||
                                      !number.isFinite) {
                                    return 'Enter valid price';
                                  }

                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        _field(
                          controller: currencyController,
                          label: 'Currency Code',
                          hint: 'e.g. PKR, USD',
                          validator: (value) {
                            final text = value?.trim() ?? '';

                            if (!RegExp(r'^[A-Za-z]{3}$').hasMatch(text)) {
                              return 'Use a 3-letter currency code';
                            }

                            return null;
                          },
                        ),
                        _field(
                          controller: featuresController,
                          label: 'Plan Features',
                          hint: 'Enter one feature per line',
                          maxLines: 4,
                        ),
                        _field(
                          controller: sortOrderController,
                          label: 'Display Order',
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (int.tryParse(value?.trim() ?? '') == null) {
                              return 'Enter a valid number';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Learning Access Permissions',
                          style: TextStyle(
                            color: navy,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Select the learning areas included in this plan.',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 9),
                        ..._permissionLabels.entries.map((entry) {
                          return CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            activeColor: teal,
                            title: Text(
                              entry.value,
                              style: const TextStyle(fontSize: 13),
                            ),
                            value: permissions[entry.key] ?? false,
                            onChanged: (value) {
                              setDialogState(() {
                                permissions[entry.key] = value == true;
                              });
                            },
                          );
                        }),
                        const Divider(height: 24),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Plan is Active',
                            style: TextStyle(
                              color: navy,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          value: isActive,
                          activeThumbColor: teal,
                          onChanged: (value) {
                            setDialogState(() {
                              isActive = value;
                            });
                          },
                        ),
                        if (saving)
                          const Padding(
                            padding: EdgeInsets.only(top: 12),
                            child: LinearProgressIndicator(color: teal),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: saving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }

                          setDialogState(() => saving = true);

                          try {
                            final features = featuresController.text
                                .split('\n')
                                .map((item) => item.trim())
                                .where((item) => item.isNotEmpty)
                                .toList();

                            final planData = {
                              'name': nameController.text.trim(),
                              'description':
                                  descriptionController.text.trim(),
                              'durationDays': int.parse(
                                durationController.text.trim(),
                              ),
                              'price': double.parse(
                                priceController.text.trim(),
                              ),
                              'currency': currencyController.text
                                  .trim()
                                  .toUpperCase(),
                              'features': features,
                              'accessPermissions': permissions,
                              'isActive': isActive,
                              'sortOrder': int.parse(
                                sortOrderController.text.trim(),
                              ),
                              'updatedAt': FieldValue.serverTimestamp(),
                            };

                            if (documentId == null) {
                              planData['createdAt'] =
                                  FieldValue.serverTimestamp();

                              await _plans.add(planData);
                            } else {
                              await _plans.doc(documentId).update(planData);
                            }

                            if (!mounted) return;

                            Navigator.pop(dialogContext);

                            _showMessage(
                              documentId == null
                                  ? 'Subscription plan created.'
                                  : 'Subscription plan updated.',
                            );
                          } catch (error) {
                            setDialogState(() => saving = false);

                            _showMessage(
                              'Could not save the plan: $error',
                              isError: true,
                            );
                          }
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: navy,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    documentId == null ? 'Create Plan' : 'Save Changes',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    descriptionController.dispose();
    durationController.dispose();
    priceController.dispose();
    currencyController.dispose();
    featuresController.dispose();
    sortOrderController.dispose();
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: ivory,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: teal, width: 1.5),
          ),
        ),
      ),
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }

    return null;
  }

  Future<void> _togglePlan(String id, bool currentlyActive) async {
    try {
      await _plans.doc(id).update({
        'isActive': !currentlyActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _showMessage(
        currentlyActive ? 'Plan deactivated.' : 'Plan activated.',
      );
    } catch (error) {
      _showMessage(
        'Could not update plan: $error',
        isError: true,
      );
    }
  }

  Future<void> _confirmDelete(String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Subscription Plan?'),
        content: Text(
          'Are you sure you want to delete "$name"? '
          'Existing subscription requests may refer to this plan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _plans.doc(id).delete();
      _showMessage('Plan deleted.');
    } catch (error) {
      _showMessage(
        'Could not delete plan: $error',
        isError: true,
      );
    }
  }

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : navy,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
