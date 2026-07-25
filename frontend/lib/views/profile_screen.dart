// lib/views/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/app_localizations.dart';
import '../models/profile_data.dart';
import '../services/profile_service.dart';

/// Profile screen for entering baby, parent, and pediatrician data.
///
/// Three collapsible sections with form fields. All fields optional.
/// Saves to SharedPreferences via [ProfileService].
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  late TextEditingController _motherNameController;
  late TextEditingController _fatherNameController;
  late TextEditingController _babyNameController;
  late TextEditingController _birthWeightController;
  late TextEditingController _currentWeightController;
  late TextEditingController _birthHeightController;
  late TextEditingController _currentHeightController;
  late TextEditingController _gestationalWeeksController;
  late TextEditingController _pediatricianNameController;
  late TextEditingController _pediatricianPhoneController;
  late TextEditingController _clinicNameController;

  DateTime? _birthDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final profile = context.read<ProfileService>().profile;

    _motherNameController = TextEditingController(text: profile.motherName);
    _fatherNameController = TextEditingController(text: profile.fatherName);
    _babyNameController = TextEditingController(text: profile.babyName);
    _birthWeightController = TextEditingController(
      text: profile.birthWeightKg?.toString() ?? '',
    );
    _currentWeightController = TextEditingController(
      text: profile.currentWeightKg?.toString() ?? '',
    );
    _birthHeightController = TextEditingController(
      text: profile.birthHeightCm?.toString() ?? '',
    );
    _currentHeightController = TextEditingController(
      text: profile.currentHeightCm?.toString() ?? '',
    );
    _gestationalWeeksController = TextEditingController(
      text: profile.gestationalWeeks?.toString() ?? '',
    );
    _pediatricianNameController = TextEditingController(
      text: profile.pediatricianName,
    );
    _pediatricianPhoneController = TextEditingController(
      text: profile.pediatricianPhone,
    );
    _clinicNameController = TextEditingController(text: profile.clinicName);
    _birthDate = profile.birthDate;
  }

  @override
  void dispose() {
    _motherNameController.dispose();
    _fatherNameController.dispose();
    _babyNameController.dispose();
    _birthWeightController.dispose();
    _currentWeightController.dispose();
    _birthHeightController.dispose();
    _currentHeightController.dispose();
    _gestationalWeeksController.dispose();
    _pediatricianNameController.dispose();
    _pediatricianPhoneController.dispose();
    _clinicNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profile),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSection(
                title: l10n.parents,
                icon: Icons.family_restroom_rounded,
                children: [
                  _buildTextField(
                    controller: _motherNameController,
                    label: l10n.motherName,
                    icon: Icons.person_rounded,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _fatherNameController,
                    label: l10n.fatherName,
                    icon: Icons.person_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSection(
                title: l10n.baby,
                icon: Icons.child_care_rounded,
                children: [
                  _buildTextField(
                    controller: _babyNameController,
                    label: l10n.babyName,
                    icon: Icons.face_rounded,
                  ),
                  const SizedBox(height: 12),
                  _buildDatePicker(context),
                  const SizedBox(height: 12),
                  _buildResponsiveRow(
                    context,
                    first: _buildNumberField(
                      controller: _birthWeightController,
                      label: l10n.birthWeight,
                      icon: Icons.monitor_weight_outlined,
                    ),
                    second: _buildNumberField(
                      controller: _currentWeightController,
                      label: l10n.currentWeight,
                      icon: Icons.monitor_weight_rounded,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildResponsiveRow(
                    context,
                    first: _buildNumberField(
                      controller: _birthHeightController,
                      label: l10n.birthHeight,
                      icon: Icons.straighten_outlined,
                    ),
                    second: _buildNumberField(
                      controller: _currentHeightController,
                      label: l10n.currentHeight,
                      icon: Icons.straighten_rounded,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildNumberField(
                    controller: _gestationalWeeksController,
                    label: l10n.gestationalWeeks,
                    icon: Icons.calendar_month_rounded,
                    isInteger: true,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSection(
                title: l10n.pediatrician,
                icon: Icons.medical_services_rounded,
                children: [
                  _buildTextField(
                    controller: _pediatricianNameController,
                    label: l10n.pediatricianName,
                    icon: Icons.person_rounded,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _pediatricianPhoneController,
                    label: l10n.pediatricianPhone,
                    icon: Icons.phone_rounded,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _clinicNameController,
                    label: l10n.clinicName,
                    icon: Icons.local_hospital_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 56,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _saveProfile,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(
                    l10n.saveProfile,
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF389BB0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF389BB0), size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isInteger = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          isInteger ? RegExp(r'[0-9]') : RegExp(r'[0-9.]'),
        ),
      ],
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// Responsive row that shows fields side-by-side on wide screens,
  /// stacked vertically on narrow screens (< 400px).
  Widget _buildResponsiveRow(
    BuildContext context, {
    required Widget first,
    required Widget second,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Stack vertically on narrow screens
        if (constraints.maxWidth < 350) {
          return Column(
            children: [
              first,
              const SizedBox(height: 12),
              second,
            ],
          );
        }
        // Side-by-side on wider screens
        return Row(
          children: [
            Expanded(child: first),
            const SizedBox(width: 12),
            Expanded(child: second),
          ],
        );
      },
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    final l10n = context.l10n;

    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _birthDate ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (date != null) {
          setState(() => _birthDate = date);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: l10n.birthDate,
          prefixIcon: const Icon(Icons.calendar_today_rounded),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          _birthDate != null
              ? '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}'
              : l10n.selectDate,
          style: TextStyle(
            color: _birthDate != null
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);

    final profile = ProfileData(
      motherName: _motherNameController.text.isNotEmpty
          ? _motherNameController.text
          : null,
      fatherName: _fatherNameController.text.isNotEmpty
          ? _fatherNameController.text
          : null,
      babyName: _babyNameController.text.isNotEmpty
          ? _babyNameController.text
          : null,
      birthDate: _birthDate,
      birthWeightKg: double.tryParse(_birthWeightController.text),
      currentWeightKg: double.tryParse(_currentWeightController.text),
      birthHeightCm: double.tryParse(_birthHeightController.text),
      currentHeightCm: double.tryParse(_currentHeightController.text),
      gestationalWeeks: int.tryParse(_gestationalWeeksController.text),
      pediatricianName: _pediatricianNameController.text.isNotEmpty
          ? _pediatricianNameController.text
          : null,
      pediatricianPhone: _pediatricianPhoneController.text.isNotEmpty
          ? _pediatricianPhoneController.text
          : null,
      clinicName: _clinicNameController.text.isNotEmpty
          ? _clinicNameController.text
          : null,
    );

    await context.read<ProfileService>().save(profile);

    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.profileSaved),
          backgroundColor: const Color(0xFF389BB0),
        ),
      );
    }
  }
}
