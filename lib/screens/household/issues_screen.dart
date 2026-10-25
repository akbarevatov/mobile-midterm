import 'package:flutter/material.dart';

import '../../models/household_issue.dart';
import '../../models/priority.dart';
import '../../theme/app_spacing.dart';
import '../../utils/id_generator.dart';
import '../../utils/validators.dart';
import '../../widgets/common/app_scope.dart';
import '../../widgets/common/category_icons.dart';
import '../../widgets/common/dialogs.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/info_banner.dart';
import '../../widgets/common/member_avatar.dart';
import '../../widgets/common/missing_item_screen.dart';
import '../../widgets/common/status_pill.dart';
import '../../widgets/forms/member_selectors.dart';
import '../../widgets/forms/picker_fields.dart';

class IssuesScreen extends StatefulWidget {
  const IssuesScreen({super.key});

  @override
  State<IssuesScreen> createState() => _IssuesScreenState();
}

class _IssuesScreenState extends State<IssuesScreen> {
  IssueStatus? _status;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final s = context.s;
    final issues = List.of(app.data.issues)
      ..sort((a, b) {
        if (a.isOpen != b.isOpen) return a.isOpen ? -1 : 1;
        final byPriority = b.priority.index.compareTo(a.priority.index);
        return byPriority != 0
            ? byPriority
            : b.createdAt.compareTo(a.createdAt);
      });
    final visible = _status == null
        ? issues
        : issues.where((i) => i.status == _status).toList();

    return Scaffold(
      appBar: AppBar(title: Text(s.issuesTitle)),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'issues-fab',
        onPressed: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const IssueFormScreen())),
        icon: const Icon(Icons.add),
        label: Text(s.reportIssue),
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
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                ChoiceChip(
                  label: Text(s.all),
                  selected: _status == null,
                  onSelected: (_) => setState(() => _status = null),
                ),
                for (final st in IssueStatus.values)
                  ChoiceChip(
                    label: Text(
                      '${s.issueStatus(st)} (${issues.where((i) => i.status == st).length})',
                    ),
                    selected: _status == st,
                    onSelected: (_) => setState(() => _status = st),
                  ),
              ],
            ),
          ),
          if (visible.isEmpty)
            EmptyState(
              icon: Icons.handyman_outlined,
              title: s.emptyIssues,
              message: s.emptyIssuesHint,
            ),
          for (final issue in visible) _IssueTile(issue: issue),
        ],
      ),
    );
  }
}

PillTone issueTone(IssueStatus status) => switch (status) {
  IssueStatus.open => PillTone.soon,
  IssueStatus.inProgress => PillTone.shared,
  IssueStatus.resolved => PillTone.done,
};

IconData issueStatusIcon(IssueStatus status) => switch (status) {
  IssueStatus.open => Icons.report_gmailerrorred,
  IssueStatus.inProgress => Icons.construction,
  IssueStatus.resolved => Icons.check,
};

class _IssueTile extends StatelessWidget {
  const _IssueTile({required this.issue});

  final HouseholdIssue issue;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final s = context.s;
    return ListTile(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => IssueDetailScreen(issueId: issue.id)),
      ),
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
        child: Icon(issueIcon(issue.category), size: 20),
      ),
      title: Text(issue.title),
      subtitle: Text(
        [
          s.issueCategory(issue.category),
          s.priorityLabel(issue.priority),
          if (issue.assigneeMemberId != null)
            s.assignedTo(app.memberName(issue.assigneeMemberId)),
        ].join(' · '),
      ),
      trailing: StatusPill(
        label: s.issueStatus(issue.status),
        icon: issueStatusIcon(issue.status),
        tone: issueTone(issue.status),
      ),
    );
  }
}

class IssueDetailScreen extends StatefulWidget {
  const IssueDetailScreen({super.key, required this.issueId});

  final String issueId;

  @override
  State<IssueDetailScreen> createState() => _IssueDetailScreenState();
}

class _IssueDetailScreenState extends State<IssueDetailScreen> {
  final _resolution = TextEditingController();
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _resolution.text =
        context.app.issueById(widget.issueId)?.resolutionNotes ?? '';
  }

  @override
  void dispose() {
    _resolution.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final s = context.s;
    final theme = Theme.of(context);
    final issue = app.issueById(widget.issueId);
    if (issue == null) return const MissingItemScreen();
    return Scaffold(
      appBar: AppBar(
        title: Text(s.issuesTitle),
        actions: [
          IconButton(
            tooltip: s.edit,
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => IssueFormScreen(existing: issue),
              ),
            ),
          ),
          IconButton(
            tooltip: s.delete,
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final ok = await confirmAction(
                context,
                title: s.deleteIssueTitle,
                message: issue.title,
                confirmLabel: s.delete,
                destructive: true,
              );
              if (!ok || !context.mounted) return;
              Navigator.of(context).pop();
              app.deleteIssue(issue.id);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.page),
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              StatusPill(
                label: s.issueStatus(issue.status),
                icon: issueStatusIcon(issue.status),
                tone: issueTone(issue.status),
              ),
              StatusPill(
                label: s.issueCategory(issue.category),
                icon: issueIcon(issue.category),
              ),
              StatusPill(
                label: s.priorityLabel(issue.priority),
                icon: priorityIcon(issue.priority),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(issue.title, style: theme.textTheme.titleLarge),
          if (issue.description.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(issue.description),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(
            s.reportedBy(
              app.memberName(issue.reportedById),
              s.dates.day(issue.createdAt, now: app.today),
            ),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: MemberAvatar(member: app.member(issue.assigneeMemberId)),
            title: Text(
              issue.assigneeMemberId == null
                  ? s.unassigned
                  : s.assignedTo(app.memberName(issue.assigneeMemberId)),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _resolution,
            decoration: InputDecoration(
              labelText: s.resolution,
              hintText: s.resolutionHint,
            ),
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
          ),
          if (issue.resolvedAt != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              s.resolvedOn(s.dates.day(issue.resolvedAt!, now: app.today)),
              style: theme.textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              if (issue.status == IssueStatus.open)
                OutlinedButton.icon(
                  onPressed: () => app.setIssueStatus(
                    issue.id,
                    IssueStatus.inProgress,
                    resolutionNotes: _resolution.text,
                  ),
                  icon: const Icon(Icons.construction),
                  label: Text(s.startWork),
                ),
              if (issue.status != IssueStatus.resolved)
                FilledButton.icon(
                  onPressed: () {
                    app.setIssueStatus(
                      issue.id,
                      IssueStatus.resolved,
                      resolutionNotes: _resolution.text,
                    );
                    showSnack(context, s.markResolved);
                  },
                  icon: const Icon(Icons.check),
                  label: Text(s.markResolved),
                )
              else
                OutlinedButton.icon(
                  onPressed: () => app.setIssueStatus(
                    issue.id,
                    IssueStatus.open,
                    resolutionNotes: _resolution.text,
                  ),
                  icon: const Icon(Icons.replay),
                  label: Text(s.reopen),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          InfoBanner(text: s.photosLater, icon: Icons.photo_camera_outlined),
        ],
      ),
    );
  }
}

class IssueFormScreen extends StatefulWidget {
  const IssueFormScreen({super.key, this.existing});

  final HouseholdIssue? existing;

  @override
  State<IssueFormScreen> createState() => _IssueFormScreenState();
}

class _IssueFormScreenState extends State<IssueFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  IssueCategory _category = IssueCategory.plumbing;
  Priority _priority = Priority.medium;
  String? _assigneeId;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _title.text = e.title;
      _description.text = e.description;
      _category = e.category;
      _priority = e.priority;
      _assigneeId = e.assigneeMemberId;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final app = context.app;
    final e = widget.existing;
    app.saveIssue(
      HouseholdIssue(
        id: e?.id ?? newId('issue'),
        householdId: app.data.household.id,
        title: _title.text.trim(),
        description: _description.text.trim(),
        category: _category,
        priority: _priority,
        status: e?.status ?? IssueStatus.open,
        assigneeMemberId: _assigneeId,
        reportedById: e?.reportedById ?? app.data.currentMemberId,
        createdAt: e?.createdAt ?? app.now(),
        resolvedAt: e?.resolvedAt,
        resolutionNotes: e?.resolutionNotes ?? '',
      ),
    );
    Navigator.of(context).pop();
    showSnack(context, context.s.saved);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final s = context.s;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? s.newIssue : s.editIssue),
        actions: [TextButton(onPressed: _save, child: Text(s.save))],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.sm,
            AppSpacing.page,
            AppSpacing.xxl,
          ),
          children: [
            TextFormField(
              controller: _title,
              decoration: InputDecoration(
                labelText: s.issueTitle,
                hintText: s.issueTitleHint,
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  s.textError(validateRequiredText(v, maxLength: 80)),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _description,
              decoration: InputDecoration(labelText: s.descriptionOptional),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  (v ?? '').length > 400 ? s.textTooLong(400) : null,
            ),
            const SizedBox(height: AppSpacing.xl),
            FieldLabel(s.category),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final c in IssueCategory.values)
                  ChoiceChip(
                    avatar: Icon(issueIcon(c), size: 18),
                    label: Text(s.issueCategory(c)),
                    selected: _category == c,
                    onSelected: (_) => setState(() => _category = c),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            FieldLabel(s.priority),
            PriorityPicker(
              value: _priority,
              onChanged: (p) => setState(() => _priority = p),
            ),
            const SizedBox(height: AppSpacing.xl),
            FieldLabel(s.assigneeOptional),
            MemberChoiceChips(
              members: app.activeMembers,
              selectedId: _assigneeId,
              allowNone: true,
              noneLabel: s.unassigned,
              onSelected: (id) => setState(() => _assigneeId = id),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(onPressed: _save, child: Text(s.save)),
          ],
        ),
      ),
    );
  }
}
