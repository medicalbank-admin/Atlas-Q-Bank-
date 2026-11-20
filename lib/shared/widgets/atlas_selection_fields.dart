
import 'package:flutter/material.dart';

import '../../app/atlas_academy_app.dart';

const String _otherCountryOption = 'Other — Enter Country Manually';

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

  Future<void> _openSelector(
    BuildContext context,
    FormFieldState<String> field,
  ) async {
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
      field.didChange(selected);
      onChanged(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      key: ValueKey<String?>('$label-$value'),
      initialValue: value,
      validator: validator,
      builder: (field) {
        return InkWell(
          onTap: () => _openSelector(context, field),
          borderRadius: BorderRadius.circular(16),
          child: InputDecorator(
            isEmpty: value == null,
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

    return widget.items.where((item) {
      return item.toLowerCase().contains(
            _query.trim().toLowerCase(),
          );
    }).toList();
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
          height: MediaQuery.of(context).size.height * 0.75,
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
                    ?.copyWith(fontWeight: FontWeight.w800),
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
                    hintText: 'Search countries or universities...',
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
    'Albania',
    'Algeria',
    'Andorra',
    'Angola',
    'Antigua and Barbuda',
    'Argentina',
    'Armenia',
    'Australia',
    'Austria',
    'Azerbaijan',
    'Bahamas',
    'Bahrain',
    'Bangladesh',
    'Barbados',
    'Belarus',
    'Belgium',
    'Belize',
    'Benin',
    'Bhutan',
    'Bolivia',
    'Bosnia and Herzegovina',
    'Botswana',
    'Brazil',
    'Brunei',
    'Bulgaria',
    'Burkina Faso',
    'Burundi',
    'Cabo Verde',
    'Cambodia',
    'Cameroon',
    'Canada',
    'Central African Republic',
    'Chad',
    'Chile',
    'China',
    'Colombia',
    'Comoros',
    'Congo',
    'Costa Rica',
    'Croatia',
    'Cuba',
    'Cyprus',
    'Czechia',
    'Democratic Republic of the Congo',
    'Denmark',
    'Djibouti',
    'Dominica',
    'Dominican Republic',
    'Ecuador',
    'Egypt',
    'El Salvador',
    'Equatorial Guinea',
    'Eritrea',
    'Estonia',
    'Eswatini',
    'Ethiopia',
    'Fiji',
    'Finland',
    'France',
    'Gabon',
    'Gambia',
    'Georgia',
    'Germany',
    'Ghana',
    'Greece',
    'Grenada',
    'Guatemala',
    'Guinea',
    'Guinea-Bissau',
    'Guyana',
    'Haiti',
    'Honduras',
    'Hungary',
    'Iceland',
    'India',
    'Indonesia',
    'Iran',
    'Iraq',
    'Ireland',
    'Israel',
    'Italy',
    'Ivory Coast',
    'Jamaica',
    'Japan',
    'Jordan',
    'Kazakhstan',
    'Kenya',
    'Kiribati',
    'Kuwait',
    'Kyrgyzstan',
    'Laos',
    'Latvia',
    'Lebanon',
    'Lesotho',
    'Liberia',
    'Libya',
    'Liechtenstein',
    'Lithuania',
    'Luxembourg',
    'Madagascar',
    'Malawi',
    'Malaysia',
    'Maldives',
    'Mali',
    'Malta',
    'Marshall Islands',
    'Mauritania',
    'Mauritius',
    'Mexico',
    'Micronesia',
    'Moldova',
    'Monaco',
    'Mongolia',
    'Montenegro',
    'Morocco',
    'Mozambique',
    'Myanmar',
    'Namibia',
    'Nauru',
    'Nepal',
    'Netherlands',
    'New Zealand',
    'Nicaragua',
    'Niger',
    'Nigeria',
    'North Korea',
    'North Macedonia',
    'Norway',
    'Oman',
    'Pakistan',
    'Palau',
    'Palestine',
    'Panama',
    'Papua New Guinea',
    'Paraguay',
    'Peru',
    'Philippines',
    'Poland',
    'Portugal',
    'Qatar',
    'Romania',
    'Russia',
    'Rwanda',
    'Saint Kitts and Nevis',
    'Saint Lucia',
    'Saint Vincent and the Grenadines',
    'Samoa',
    'San Marino',
    'Sao Tome and Principe',
    'Saudi Arabia',
    'Senegal',
    'Serbia',
    'Seychelles',
    'Sierra Leone',
    'Singapore',
    'Slovakia',
    'Slovenia',
    'Solomon Islands',
    'Somalia',
    'South Africa',
    'South Korea',
    'South Sudan',
    'Spain',
    'Sri Lanka',
    'Sudan',
    'Suriname',
    'Sweden',
    'Switzerland',
    'Syria',
    'Tajikistan',
    'Tanzania',
    'Thailand',
    'Timor-Leste',
    'Togo',
    'Tonga',
    'Trinidad and Tobago',
    'Tunisia',
    'Turkey',
    'Turkmenistan',
    'Tuvalu',
    'Uganda',
    'Ukraine',
    'United Arab Emirates',
    'United Kingdom',
    'United States',
    'Uruguay',
    'Uzbekistan',
    'Vanuatu',
    'Vatican City (Holy See)',
    'Venezuela',
    'Vietnam',
    'Yemen',
    'Zambia',
    'Zimbabwe',
  ];

  Future<void> _selectCountry(BuildContext context) async {
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
          title: 'Country of Study',
          items: [...countries, _otherCountryOption],
          selectedValue: value,
          searchable: true,
        );
      },
    );

    if (selected == null) return;

    if (selected == _otherCountryOption) {
      final controller = TextEditingController();

      final customCountry = await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Enter Your Country'),
            content: TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Country name',
                hintText: 'Enter your country',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final country = controller.text.trim();

                  if (country.isNotEmpty) {
                    Navigator.pop(dialogContext, country);
                  }
                },
                child: const Text('Save Country'),
              ),
            ],
          );
        },
      );

      controller.dispose();

      if (customCountry == null || customCountry.trim().isEmpty) {
        return;
      }

      onChanged(customCountry.trim());
    } else {
      onChanged(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      key: ValueKey<String?>('country-$value'),
      initialValue: value,
      validator: validator,
      builder: (field) {
        return InkWell(
          onTap: () => _selectCountry(context),
          borderRadius: BorderRadius.circular(16),
          child: InputDecorator(
            isEmpty: value == null,
            decoration: InputDecoration(
              labelText: 'Country of Study *',
              errorText: field.errorText,
              prefixIcon: const Icon(
                Icons.public_rounded,
                color: AtlasColors.oceanTeal,
              ),
              suffixIcon: const Icon(
                Icons.keyboard_arrow_down_rounded,
              ),
            ),
            child: Text(
              value ?? 'Search and select your country',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: value == null
                    ? Theme.of(context).hintColor
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        );
      },
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
      label: 'University *',
      hint: 'Search and select your university',
      value: value,
      items: [
        ...universities,
        'Other — Enter University Manually',
      ],
      onChanged: onChanged,
      validator: validator,
      prefixIcon: Icons.account_balance_rounded,
    );
  }
}
