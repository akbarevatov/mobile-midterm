import 'package:flutter/material.dart';

import '../../models/household_member.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/validators.dart';
import '../../widgets/common/app_scope.dart';
import '../../widgets/common/dialogs.dart';
import '../../widgets/common/info_banner.dart';
import '../../widgets/common/member_avatar.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/common/status_pill.dart';
import '../../widgets/forms/member_selectors.dart';

class MembersScreen extends StatelessWidget {
  const MembersScreen({super.key});

  Future<void> _rename(BuildContext context) async {
    final app = context.app;
    final s = context.s;
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _TextDialog(
        title: s.renameHousehold,
        label: s.householdName,
        initial: app.data.household.name,
      ),
    );
    if (name != null) app.renameHousehold(name);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final s = context.s;
    final active = app.activeMembers;
    final movedOut = app.members.where((m) => !m.isActive).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(s.roommates),
        actions: [
          IconButton(
            tooltip: s.renameHousehold,
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _rename(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'members-fab',
        onPressed: () => showMemberSheet(context),
        icon: const Icon(Icons.person_add_alt),
        label: Text(s.addMember),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.fabClearance),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.md,
              AppSpacing.page,
              AppSpacing.sm,
            ),
            child: InfoBanner(
              title: s.syncTitle,
              text: s.syncBody,
              icon: Icons.cloud_off_outlined,
            ),
          ),
          for (final m in active) _MemberTile(member: m),
          if (movedOut.isNotEmpty) ...[
            SectionHeader(title: s.movedOut),
            for (final m in movedOut) _MemberTile(member: m),
          ],
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.member});

  final HouseholdMember member;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final s = context.s;
    final isCurrent = member.id == app.data.currentMemberId;
    final open = app.pendingAssignments
        .where((a) => a.assigneeMemberId == member.id)
        .length;
    return ListTile(
      leading: MemberAvatar(member: member),
      title: Text(member.displayName),
      subtitle: Text(
        '${s.colOpenTasks}: $open · ${s.money(app.balanceOf(member.id), showPlus: true)}',
      ),
      trailing: isCurrent
          ? StatusPill(
              label: s.currentProfile,
              icon: Icons.person,
              tone: PillTone.personal,
            )
          : (member.isActive
                ? null
                : StatusPill(label: s.movedOut, icon: Icons.logout)),
      onTap: () => showMemberSheet(context, existing: member),
    );
  }
}

Future<void> showMemberSheet(
  BuildContext context, {
  HouseholdMember? existing,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _MemberForm(existing: existing),
  );
}

class _MemberForm extends StatefulWidget {
  const _MemberForm({this.existing});

  final HouseholdMember? existing;

  @override
  State<_MemberForm> createState() => _MemberFormState();
}

class _MemberFormState extends State<_MemberForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  int _color = 0;
  bool _joinRotations = true;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final existing = widget.existing;
    if (existing != null) {
      _name.text = existing.displayName;
      _color = existing.colorIndex;
    } else {
      _color = context.app.members.length % AppColors.memberPalette.length;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final app = context.app;
    final existing = widget.existing;
    if (existing == null) {
      app.addMember(_name.text, _color, joinChoreRotations: _joinRotations);
    } else {
      app.updateMember(existing.id, name: _name.text, colorIndex: _color);
    }
    Navigator.pop(context);
  }

  Future<void> _toggleMovedOut() async {
    final app = context.app;
    final s = context.s;
    final m = widget.existing!;
    if (!m.isActive) {
      app.setMemberActive(m.id, true);
      Navigator.pop(context);
      return;
    }
    final balance = app.balanceOf(m.id);
    final message = balance == 0
        ? s.moveOutBody
        : '${s.moveOutBody}\n\n${s.moveOutBalanceWarning(s.money(balance, showPlus: true))}';
    final ok = await confirmAction(
      context,
      title: s.moveOutTitle,
      message: message,
      confirmLabel: s.markMovedOut,
    );
    if (!ok || !mounted) return;
    app.setMemberActive(m.id, false);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final s = context.s;
    final existing = widget.existing;
    final preview = HouseholdMember(
      id: 'preview',
      householdId: '',
      displayName: _name.text.isEmpty ? '?' : _name.text,
      colorIndex: _color,
      createdAt: DateTime(2000),
    );

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            0,
            AppSpacing.page,
            AppSpacing.xl,
          ),
          children: [
            Row(
              children: [
                MemberAvatar(member: preview, radius: 24),
                const SizedBox(width: AppSpacing.md),
                Text(
                  existing == null ? s.addMember : s.editMember,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _name,
              autofocus: existing == null,
              decoration: InputDecoration(labelText: s.displayName),
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
              validator: (v) => s.textError(
                validateRequiredText(v, maxLength: 40),
                maxLength: 40,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FieldLabel(s.color),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (var i = 0; i < AppColors.memberPalette.length; i++)
                  Semantics(
                    button: true,
                    selected: i == _color,
                    label: '${s.color} ${i + 1}',
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => setState(() => _color = i),
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.member(i),
                        child: i == _color
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
            if (existing == null)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _joinRotations,
                onChanged: (v) => setState(() => _joinRotations = v ?? true),
                title: Text(s.joinRotations),
              ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(onPressed: _save, child: Text(s.save)),
            if (existing != null &&
                (app.canMoveOut(existing.id) || !existing.isActive)) ...[
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: _toggleMovedOut,
                icon: Icon(existing.isActive ? Icons.logout : Icons.login),
                label: Text(existing.isActive ? s.markMovedOut : s.markBack),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TextDialog extends StatefulWidget {
  const _TextDialog({
    required this.title,
    required this.label,
    required this.initial,
  });

  final String title;
  final String label;
  final String initial;

  @override
  State<_TextDialog> createState() => _TextDialogState();
}

class _TextDialogState extends State<_TextDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          decoration: InputDecoration(labelText: widget.label),
          validator: (v) => s.textError(
            validateRequiredText(v, maxLength: 40),
            maxLength: 40,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(s.cancel),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, _controller.text.trim());
            }
          },
          child: Text(s.save),
        ),
      ],
    );
  }
}
