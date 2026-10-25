import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../../utils/validators.dart';
import '../../widgets/common/app_scope.dart';
import '../../widgets/common/info_banner.dart';

class CreateHouseholdScreen extends StatefulWidget {
  const CreateHouseholdScreen({super.key});

  @override
  State<CreateHouseholdScreen> createState() => _CreateHouseholdScreenState();
}

class _CreateHouseholdScreenState extends State<CreateHouseholdScreen> {
  static const int maxRoommates = 7;

  final _formKey = GlobalKey<FormState>();
  final _householdName = TextEditingController();
  final _yourName = TextEditingController();
  final List<TextEditingController> _roommates = [TextEditingController()];

  @override
  void dispose() {
    _householdName.dispose();
    _yourName.dispose();
    for (final c in _roommates) {
      c.dispose();
    }
    super.dispose();
  }

  void _addRoommate() {
    if (_roommates.length >= maxRoommates) return;
    setState(() => _roommates.add(TextEditingController()));
  }

  void _removeRoommate(int index) {
    final controller = _roommates.removeAt(index);
    setState(() {});
    controller.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.app.createHousehold(
      householdName: _householdName.text,
      yourName: _yourName.text,
      roommateNames: _roommates.map((c) => c.text).toList(),
    );
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    String? required(String? v) =>
        s.textError(validateRequiredText(v, maxLength: 40), maxLength: 40);

    return Scaffold(
      appBar: AppBar(title: Text(s.newHouseholdTitle)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.page),
          children: [
            TextFormField(
              controller: _householdName,
              decoration: InputDecoration(
                labelText: s.householdName,
                hintText: s.householdNameHint,
              ),
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              validator: required,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _yourName,
              decoration: InputDecoration(
                labelText: s.yourName,
                prefixIcon: const Icon(Icons.person_outline),
              ),
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              validator: required,
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(s.roommates, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              s.roommatesOptionalHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            for (var i = 0; i < _roommates.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _roommates[i],
                        decoration: InputDecoration(
                          labelText: '${s.roommateName} ${i + 1}',
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: (v) => (v ?? '').trim().length > 40
                            ? s.textTooLong(40)
                            : null,
                      ),
                    ),
                    IconButton(
                      tooltip: s.removeRoommate,
                      onPressed: () => _removeRoommate(i),
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                  ],
                ),
              ),
            if (_roommates.length < maxRoommates)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _addRoommate,
                  icon: const Icon(Icons.person_add_alt),
                  label: Text(s.addRoommate),
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
            InfoBanner(text: s.localOnlyNote, icon: Icons.phone_android),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(onPressed: _submit, child: Text(s.create)),
          ],
        ),
      ),
    );
  }
}
