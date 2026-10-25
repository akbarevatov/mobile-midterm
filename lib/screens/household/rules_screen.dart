import 'package:flutter/material.dart';

import '../../models/house_notes.dart';
import '../../theme/app_spacing.dart';
import '../../utils/id_generator.dart';
import '../../utils/validators.dart';
import '../../widgets/common/app_scope.dart';
import '../../widgets/common/dialogs.dart';
import '../../widgets/common/member_avatar.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/common/status_pill.dart';

class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  Future<void> _postAnnouncement(BuildContext context) async {
    final s = context.s;
    final app = context.app;
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (_) => _TwoFieldDialog(
        title: s.newAnnouncement,
        firstLabel: s.announcement,
        firstHint: s.announcementHint,
        maxFirst: 200,
      ),
    );
    if (result != null) app.postAnnouncement(result.$1);
  }

  Future<void> _editRule(BuildContext context, {HouseRule? existing}) async {
    final s = context.s;
    final app = context.app;
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (_) => _TwoFieldDialog(
        title: existing == null ? s.addRule : s.editRule,
        firstLabel: s.ruleTitle,
        secondLabel: s.ruleDetails,
        firstInitial: existing?.title ?? '',
        secondInitial: existing?.details ?? '',
        maxFirst: 60,
      ),
    );
    if (result == null) return;
    app.saveRule(
      HouseRule(
        id: existing?.id ?? newId('rule'),
        householdId: app.data.household.id,
        title: result.$1,
        details: result.$2,
        createdById: existing?.createdById ?? app.data.currentMemberId,
        createdAt: existing?.createdAt ?? app.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final s = context.s;
    final theme = Theme.of(context);
    final announcements = app.announcementsNewestFirst;

    return Scaffold(
      appBar: AppBar(title: Text(s.rulesTitle)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        children: [
          SectionHeader(
            title: s.announcements,
            action: s.newAnnouncement,
            onAction: () => _postAnnouncement(context),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              0,
              AppSpacing.page,
              AppSpacing.sm,
            ),
            child: Text(s.notAChat, style: theme.textTheme.bodySmall),
          ),
          if (announcements.isEmpty)
            ListTile(title: Text(s.emptyAnnouncements)),
          for (final a in announcements)
            ListTile(
              leading: MemberAvatar(member: app.member(a.authorId), radius: 16),
              title: Text(a.message),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Wrap(
                  spacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      s.postedBy(
                        app.memberName(a.authorId),
                        s.timeAgo(a.createdAt, app.now()),
                      ),
                    ),
                    if (a.isPinned)
                      StatusPill(
                        label: s.pinned,
                        icon: Icons.push_pin_outlined,
                        tone: PillTone.shared,
                      ),
                  ],
                ),
              ),
              trailing: PopupMenuButton<String>(
                tooltip: s.moreActions,
                onSelected: (value) async {
                  if (value == 'pin') {
                    app.setAnnouncementPinned(a.id, !a.isPinned);
                  }
                  if (value == 'delete') {
                    final ok = await confirmAction(
                      context,
                      title: s.deleteAnnouncementTitle,
                      message: a.message,
                      confirmLabel: s.delete,
                      destructive: true,
                    );
                    if (ok) app.deleteAnnouncement(a.id);
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'pin',
                    child: Text(a.isPinned ? s.unpin : s.pin),
                  ),
                  PopupMenuItem(value: 'delete', child: Text(s.delete)),
                ],
              ),
            ),
          SectionHeader(
            title: s.houseRules,
            action: s.addRule,
            onAction: () => _editRule(context),
          ),
          if (app.data.rules.isEmpty)
            ListTile(
              title: Text(s.emptyRules),
              subtitle: Text(s.emptyRulesHint),
            ),
          for (final (index, rule) in app.data.rules.indexed)
            ListTile(
              leading: CircleAvatar(
                radius: 14,
                child: Text('${index + 1}', style: theme.textTheme.labelMedium),
              ),
              title: Text(rule.title),
              subtitle: rule.details.isEmpty ? null : Text(rule.details),
              onTap: () => _editRule(context, existing: rule),
              trailing: IconButton(
                tooltip: s.delete,
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  final ok = await confirmAction(
                    context,
                    title: s.deleteRuleTitle,
                    message: rule.title,
                    confirmLabel: s.delete,
                    destructive: true,
                  );
                  if (ok) app.deleteRule(rule.id);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _TwoFieldDialog extends StatefulWidget {
  const _TwoFieldDialog({
    required this.title,
    required this.firstLabel,
    this.firstHint,
    this.secondLabel,
    this.firstInitial = '',
    this.secondInitial = '',
    this.maxFirst = 80,
  });

  final String title;
  final String firstLabel;
  final String? firstHint;
  final String? secondLabel;
  final String firstInitial;
  final String secondInitial;
  final int maxFirst;

  @override
  State<_TwoFieldDialog> createState() => _TwoFieldDialogState();
}

class _TwoFieldDialogState extends State<_TwoFieldDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _first = TextEditingController(text: widget.firstInitial);
  late final _second = TextEditingController(text: widget.secondInitial);

  @override
  void dispose() {
    _first.dispose();
    _second.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _first,
              autofocus: true,
              maxLines: widget.secondLabel == null ? 3 : 1,
              decoration: InputDecoration(
                labelText: widget.firstLabel,
                hintText: widget.firstHint,
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) => s.textError(
                validateRequiredText(v, maxLength: widget.maxFirst),
                maxLength: widget.maxFirst,
              ),
            ),
            if (widget.secondLabel != null) ...[
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _second,
                maxLines: 2,
                decoration: InputDecoration(labelText: widget.secondLabel),
                textCapitalization: TextCapitalization.sentences,
                validator: (v) =>
                    (v ?? '').length > 200 ? s.textTooLong(200) : null,
              ),
            ],
          ],
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
              Navigator.pop(context, (_first.text.trim(), _second.text.trim()));
            }
          },
          child: Text(s.save),
        ),
      ],
    );
  }
}
