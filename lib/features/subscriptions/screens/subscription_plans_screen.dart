import 'package:flutter/material.dart';

import '../../../app/atlas_academy_app.dart';
import '../models/subscription_plan_model.dart';
import '../services/subscription_plan_service.dart';
import 'my_subscription_requests_screen.dart';
import 'subscription_request_screen.dart';

class SubscriptionPlansScreen extends StatelessWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = SubscriptionPlanService();

    return Scaffold(
      backgroundColor: AtlasColors.ivory,
      appBar: AppBar(
        title: const Text('Membership Plans'),
        backgroundColor: AtlasColors.ivory,
        foregroundColor: AtlasColors.deepTeal,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'My subscription requests',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      const MySubscriptionRequestsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.receipt_long_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<SubscriptionPlanModel>>(
        stream: service.watchActivePlans(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: AtlasColors.oceanTeal,
              ),
            );
          }

          if (snapshot.hasError) {
            return _message(
              icon: Icons.error_outline,
              title: 'Unable to load plans',
              description: snapshot.error.toString(),
              action: 'Retry',
              onPressed: () {},
            );
          }

          final plans = snapshot.data ?? [];

          if (plans.isEmpty) {
            return _message(
              icon: Icons.workspace_premium_outlined,
              title: 'No Plans Available',
              description:
                  'There are currently no active membership plans. '
                  'Please check again later.',
            );
          }

          return RefreshIndicator(
            color: AtlasColors.oceanTeal,
            onRefresh: () async {
              await service.watchActivePlans().first;
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
              children: [
                _buildWelcomeHeader(),
                const SizedBox(height: 22),
                _buildHistoryButton(context),
                const SizedBox(height: 24),
                const Text(
                  'Choose Your Membership',
                  style: TextStyle(
                    color: AtlasColors.deepTeal,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Select a plan to continue your enrollment.',
                  style: TextStyle(
                    color: AtlasColors.secondaryText,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 18),
                ...plans.map(
                  (plan) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildPlanCard(context, plan),
                  ),
                ),
                const SizedBox(height: 12),
                _buildSecurityNote(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AtlasColors.deepTeal,
            AtlasColors.oceanTeal,
          ],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.school_rounded,
            color: AtlasColors.champagne,
            size: 32,
          ),
          SizedBox(height: 15),
          Text(
            'Invest in Your Medical Future',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Unlock your learning journey with The Atlas Academy '
            'membership plans.',
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

  Widget _buildHistoryButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                const MySubscriptionRequestsScreen(),
          ),
        );
      },
      icon: const Icon(Icons.history_rounded),
      label: const Text('View My Payment Requests'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AtlasColors.deepTeal,
        side: const BorderSide(
          color: AtlasColors.oceanTeal,
        ),
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  Widget _buildPlanCard(
    BuildContext context,
    SubscriptionPlanModel plan,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AtlasColors.oceanTeal.withValues(alpha: 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.workspace_premium_rounded,
                color: AtlasColors.gold,
                size: 25,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  plan.name,
                  style: const TextStyle(
                    color: AtlasColors.deepTeal,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (plan.description.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              plan.description,
              style: const TextStyle(
                color: AtlasColors.secondaryText,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 17),
          Text(
            '${plan.currency} ${plan.price.toStringAsFixed(2)}',
            style: const TextStyle(
              color: AtlasColors.oceanTeal,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${plan.durationDays} days membership',
            style: const TextStyle(
              color: AtlasColors.secondaryText,
              fontSize: 12,
            ),
          ),
          if (plan.features.isNotEmpty) ...[
            const SizedBox(height: 17),
            const Divider(),
            const SizedBox(height: 10),
            const Text(
              'Plan Benefits',
              style: TextStyle(
                color: AtlasColors.deepTeal,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 10),
            ...plan.features.map(
              (feature) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 17,
                      color: AtlasColors.success,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        feature,
                        style: const TextStyle(
                          color: AtlasColors.charcoal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 17),
          SizedBox(
            width: double.infinity,
            height: 49,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SubscriptionRequestScreen(
                      plan: plan,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AtlasColors.deepTeal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Choose This Plan',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityNote() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AtlasColors.softTeal,
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.verified_user_outlined,
            color: AtlasColors.deepTeal,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Membership access is granted only after '
              'administrator approval and payment verification.',
              style: TextStyle(
                color: AtlasColors.deepTeal,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _message({
    required IconData icon,
    required String title,
    required String description,
    String? action,
    VoidCallback? onPressed,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 48,
              color: AtlasColors.oceanTeal,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: AtlasColors.deepTeal,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AtlasColors.secondaryText,
                height: 1.5,
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: onPressed,
                child: Text(action),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
