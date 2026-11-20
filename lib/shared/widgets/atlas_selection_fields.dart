import 'package:flutter/material.dart';

import '../../app/atlas_academy_app.dart';

class AtlasSelectionField extends StatelessWidget {
  const AtlasSelectionField({
    super.key,
    required this.label,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
    this.prefixIcon,
    this.validator,
    this.searchable = true,
  });

  final String label;
  final String hint;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final IconData? prefixIcon;
  final String? Function(String?)? validator;
  final bool searchable;

  Future<void> _openSelector(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(26),
        ),
      ),
      builder: (context) {
        return _AtlasSelectionSheet(
          title: label,
          items: items,
          selectedValue: value,
          searchable: searchable,
        );
      },
    );

    if (selected != null) {
      onChanged(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      initialValue: value,
      validator: validator,
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => _openSelector(context),
              borderRadius: BorderRadius.circular(16),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: label,
                  errorText: field.errorText,
                  prefixIcon: prefixIcon == null
                      ? null
                      : Icon(
                          prefixIcon,
                          color: AtlasColors.oceanTeal,
                        ),
                  suffixIcon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                  ),
                ),
                child: Text(
                  value ?? hint,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: value == null
                        ? Theme.of(context).hintColor
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AtlasSelectionSheet extends StatefulWidget {
  const _AtlasSelectionSheet({
    required this.title,
    required this.items,
    required this.selectedValue,
    required this.searchable,
  });

  final String title;
  final List<String> items;
  final String? selectedValue;
  final bool searchable;

  @override
  State<_AtlasSelectionSheet> createState() =>
      _AtlasSelectionSheetState();
}

class _AtlasSelectionSheetState
    extends State<_AtlasSelectionSheet> {
  final TextEditingController _searchController =
      TextEditingController();

  String _query = '';

  List<String> get filteredItems {
    if (_query.trim().isEmpty) return widget.items;

    return widget.items
        .where(
          (item) => item.toLowerCase().contains(
                _query.toLowerCase().trim(),
              ),
        )
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = filteredItems;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 22,
          right: 22,
          top: 22,
          bottom: MediaQuery.of(context).viewInsets.bottom + 22,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.68,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'Select ${widget.title}',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 18),
              if (widget.searchable)
                TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _query = value;
                    });
                  },
                  decoration: const InputDecoration(
                    hintText: 'Search...',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
              const SizedBox(height: 14),
              Expanded(
                child: items.isEmpty
                    ? const Center(
                        child: Text('No matching results found.'),
                      )
                    : ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final selected =
                              item == widget.selectedValue;

                          return ListTile(
                            title: Text(
                              item,
                              style: TextStyle(
                                fontWeight: selected
                                    ? FontWeight.w800
                                    : FontWeight.w500,
                              ),
                            ),
                            trailing: selected
                                ? const Icon(
                                    Icons.check_circle_rounded,
                                    color: AtlasColors.oceanTeal,
                                  )
                                : null,
                            onTap: () {
                              Navigator.pop(context, item);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AtlasCountryField extends StatelessWidget {
  const AtlasCountryField({
    super.key,
    required this.value,
    required this.onChanged,
    this.validator,
  });

  final String? value;
  final ValueChanged<String?> onChanged;
  final String? Function(String?)? validator;

  static const List<String> countries = [
    'Afghanistan',
    'Australia',
    'Bangladesh',
    'Canada',
    'China',
    'Egypt',
    'Germany',
    'India',
    'Ireland',
    'Malaysia',
    'Nepal',
    'Pakistan',
    'Russia',
    'Saudi Arabia',
    'South Africa',
    'Turkey',
    'United Arab Emirates',
    'United Kingdom',
    'United States',
  ];

  @override
  Widget build(BuildContext context) {
    return AtlasSelectionField(
      label: 'Country of Study',
      hint: 'Select your country',
      value: value,
      items: countries,
      onChanged: onChanged,
      validator: validator,
      prefixIcon: Icons.public_rounded,
    );
  }
}

class AtlasUniversityField extends StatelessWidget {
  const AtlasUniversityField({
    super.key,
    required this.value,
    required this.onChanged,
    required this.universities,
    this.validator,
  });

  final String? value;
  final ValueChanged<String?> onChanged;
  final List<String> universities;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return AtlasSelectionField(
      label: 'University',
      hint: 'Select your university',
      value: value,
      items: universities,
      onChanged: onChanged,
      validator: validator,
      prefixIcon: Icons.account_balance_rounded,
    );
  }
}
