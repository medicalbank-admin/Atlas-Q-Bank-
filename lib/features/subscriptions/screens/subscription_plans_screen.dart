import 'package:flutter/material.dart';

import '../../../app/atlas_academy_app.dart';
import '../models/subscription_plan_model.dart';
import '../services/subscription_plan_service.dart';

class SubscriptionPlansScreen extends StatefulWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  State<SubscriptionPlansScreen> createState() =>
      _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState
    extends State<SubscriptionPlansScreen> {
  final SubscriptionPlanService _service =
      SubscriptionPlanService();

  String _currencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'PKR':
        return 'Rs ';
      case 'USD':
        return '\$';
      case 'GBP':
        return '£';
      case 'EUR':
        return '€';
      case 'INR':
        return '₹';
      case 'AED':
        return 'AED ';
      case 'SAR':
        return 'SAR ';
      default:
        return '$currency ';
    }
  }

  String _durationLabel(int days) {
    if (days == 30) return 'Monthly';
    if (days == 90) return 'Quarterly';
    if (days == 180) return 'Half-Yearly';
    if (days == 365) return 'Yearly';

    return '$days Days';
  }

  void _showPlanDetails(SubscriptionPlanModel plan) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 30),
          decoration: const BoxDecoration(
            color: AtlasColors.ivory,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AtlasColors.secondaryText.withValues(
                          alpha: 0.3,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  Text(
                    plan.name,
                    style: const TextStyle(
                      color: AtlasColors.deepTeal,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    plan.description,
                    style: const TextStyle(
                      color: AtlasColors.secondaryText,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '${_currencySymbol(plan.currency)}'
                    '${plan.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AtlasColors.deepTeal,
                      fontSize: 29,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    _durationLabel(plan.durationDays),
                    style: const TextStyle(
                      color: AtlasColors.secondaryText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Plan Features',
                    style: TextStyle(
                      color: AtlasColors.deepTeal,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...plan.features.map(
                    (feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AtlasColors.success,
                            size: 19,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              feature,
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.of(this.context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => SubscriptionRequestPlaceholder(
                              plan: plan,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AtlasColors.deepTeal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text(
                        'Choose This Plan',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Membership Plans'),
      ),
      body: StreamBuilder<List<SubscriptionPlanModel>>(
        stream: _service.watchActivePlans(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: AtlasColors.deepTeal,
              ),
            );
          }

          if (snapshot.hasError) {
            return _MessageView(
              icon: Icons.cloud_off_rounded,
              title: 'Unable to load plans',
              message: 'Please check your connection and try again.',
              action: () => setState(() {}),
            );
          }

          final plans = snapshot.data ?? [];

          if (plans.isEmpty) {
            return const _MessageView(
              icon: Icons.card_membership_rounded,
              title: 'Plans Coming Soon',
              message: 'The academy has not published any membership '
                  'plans yet. Please check again later.',
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AtlasColors.deepTeal,
                      AtlasColors.oceanTeal,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(23),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'INVEST IN YOUR FUTURE',
                      style: TextStyle(
                        color: AtlasColors.champagne,
                        fontSize: 11,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Choose your learning membership',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        height: 1.3,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Compare available plans and find the '
                      'membership that suits your preparation.',
                      style: TextStyle(
                        color: Colors.white70,
                        height: 1.5,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              Text(
                '${plans.length} Available Plans',
                style: const TextStyle(
                  color: AtlasColors.deepTeal,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 15),
              ...plans.map(
                (plan) => _PlanCard(
                  plan: plan,
                  price: '${_currencySymbol(plan.currency)}'
                      '${plan.price.toStringAsFixed(2)}',
                  duration: _durationLabel(plan.durationDays),
                  onTap: () => _showPlanDetails(plan),
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                'Membership activation is subject to payment review '
                'and approval by the academy administration.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AtlasColors.secondaryText,
                  fontSize: 11,
                  height: 1.5,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.price,
    required this.duration,
    required this.onTap,
  });

  final SubscriptionPlanModel plan;
  final String price;
  final String duration;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: AtlasColors.softTeal,
        ),
        boxShadow: [
          BoxShadow(
            color: AtlasColors.deepTeal.withValues(alpha: 0.035),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  plan.name,
                  style: const TextStyle(
                    color: AtlasColors.deepTeal,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AtlasColors.softTeal,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  duration,
                  style: const TextStyle(
                    color: AtlasColors.deepTeal,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Text(
            price,
            style: const TextStyle(
              color: AtlasColors.deepTeal,
              fontSize: 27,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (plan.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              plan.description,
              style: const TextStyle(
                color: AtlasColors.secondaryText,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
          if (plan.features.isNotEmpty) ...[
            const SizedBox(height: 16),
            ...plan.features.take(3).map(
              (feature) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AtlasColors.success,
                      size: 17,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        feature,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            height: 47,
            child: OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: AtlasColors.deepTeal,
                side: const BorderSide(
                  color: AtlasColors.oceanTeal,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              child: const Text(
                'View Plan Details',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageView extends StatelessWidget {
  const _MessageView({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 52,
              color: AtlasColors.oceanTeal,
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: AtlasColors.deepTeal,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AtlasColors.secondaryText,
                height: 1.5,
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: action,
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Temporary destination until the real payment request screen is added.
class SubscriptionRequestPlaceholder extends StatelessWidget {
  const SubscriptionRequestPlaceholder({
    super.key,
    required this.plan,
  });

  final SubscriptionPlanModel plan;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Membership Request'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.receipt_long_rounded,
                color: AtlasColors.oceanTeal,
                size: 55,
              ),
              const SizedBox(height: 18),
              Text(
                plan.name,
                style: const TextStyle(
                  fontSize: 23,
                  color: AtlasColors.deepTeal,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'The payment request form will be connected here next.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
