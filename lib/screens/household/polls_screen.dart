import 'package:flutter/material.dart';

import '../../models/household_poll.dart';
import '../../theme/app_spacing.dart';
import '../../utils/date_math.dart';
import '../../utils/validators.dart';
import '../../widgets/common/app_scope.dart';
import '../../widgets/common/dialogs.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/info_banner.dart';
import '../../widgets/common/member_avatar.dart';
import '../../widgets/common/missing_item_screen.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/common/status_pill.dart';
import '../../widgets/forms/picker_fields.dart';

class PollsScreen extends StatelessWidget {
  const PollsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final s = context.s;
    final now = app.now();
    final polls = List.of(app.data.polls)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final open = polls.where((p) => p.isOpen(now)).toList();
    final closed = polls.where((p) => !p.isOpen(now)).toList();

    return Scaffold(
      appBar: AppBar(title: Text(s.pollsTitle)),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'polls-fab',
        onPressed: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const PollFormScreen())),
        icon: const Icon(Icons.add),
        label: Text(s.newPoll),
      ),
      body: polls.isEmpty
          ? EmptyState(
              icon: Icons.how_to_vote_outlined,
              title: s.emptyPolls,
              message: s.emptyPollsHint,
            )
          : ListView(
              padding: const EdgeInsets.only(bottom: AppSpacing.fabClearance),
              children: [
                if (open.isNotEmpty) ...[
                  SectionHeader(title: s.openLabel),
                  for (final p in open) _PollTile(poll: p),
                ],
                if (closed.isNotEmpty) ...[
                  SectionHeader(title: s.closedLabel),
                  for (final p in closed) _PollTile(poll: p),
                ],
              ],
            ),
    );
  }
}

class _PollTile extends StatelessWidget {
  const _PollTile({required this.poll});

  final HouseholdPoll poll;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final s = context.s;
    final isOpen = poll.isOpen(app.now());
    final voted = poll.votesByMemberId.containsKey(app.data.currentMemberId);
    final leaders = poll.leadingOptions();
    final status = isOpen
        ? s.votedCount(poll.votesByMemberId.length, app.activeMembers.length)
        : (leaders.isEmpty
              ? s.noVotesYet
              : (leaders.length > 1 ? s.tie : s.result(leaders.first.text)));
    return ListTile(
      leading: Icon(isOpen ? Icons.how_to_vote_outlined : Icons.lock_outline),
      title: Text(poll.question),
      subtitle: Text(status),
      trailing: isOpen && voted
          ? StatusPill(
              label: s.yourVote,
              icon: Icons.check,
              tone: PillTone.positive,
            )
          : null,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PollDetailScreen(pollId: poll.id)),
      ),
    );
  }
}

class PollDetailScreen extends StatelessWidget {
  const PollDetailScreen({super.key, required this.pollId});

  final String pollId;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final s = context.s;
    final theme = Theme.of(context);
    final poll = app.pollById(pollId);
    if (poll == null) return const MissingItemScreen();
    final isOpen = poll.isOpen(app.now());
    final myVote = poll.votesByMemberId[app.data.currentMemberId];
    final total = poll.votesByMemberId.length;
    final leaders = poll.leadingOptions();

    return Scaffold(
      appBar: AppBar(
        title: Text(s.pollsTitle),
        actions: [
          IconButton(
            tooltip: s.delete,
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final ok = await confirmAction(
                context,
                title: s.deletePollTitle,
                message: poll.question,
                confirmLabel: s.delete,
                destructive: true,
              );
              if (!ok || !context.mounted) return;
              Navigator.of(context).pop();
              app.deletePoll(pollId);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.page),
        children: [
          Text(poll.question, style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(
            [
              s.addedBy(
                app.memberName(poll.createdById),
                s.dates.day(poll.createdAt, now: app.today),
              ),
              if (poll.closedAt != null)
                s.closedOn(s.dates.day(poll.closedAt!, now: app.today)),
              if (poll.closedAt == null && poll.deadline != null)
                s.endsOn(s.dates.dayAndTime(poll.deadline!, now: app.today)),
            ].join(' · '),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          InfoBanner(text: s.oneVoteRule, icon: Icons.rule),
          const SizedBox(height: AppSpacing.lg),
          if (isOpen)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(s.tapToVote, style: theme.textTheme.labelLarge),
            ),
          for (final option in poll.options)
            _OptionCard(
              option: option,
              votes: poll.votesFor(option.id),
              total: total,
              selected: option.id == myVote,
              leading:
                  !isOpen &&
                  leaders.length == 1 &&
                  leaders.first.id == option.id,
              voters: [
                for (final entry in poll.votesByMemberId.entries)
                  if (entry.value == option.id) entry.key,
              ],
              onTap: isOpen
                  ? () {
                      app.vote(poll.id, option.id);
                      showSnack(context, s.voteSaved);
                    }
                  : null,
            ),
          const SizedBox(height: AppSpacing.md),
          Text(
            s.votedCount(total, app.activeMembers.length),
            style: theme.textTheme.bodyMedium,
          ),
          if (isOpen) ...[
            const SizedBox(height: AppSpacing.xl),
            OutlinedButton.icon(
              onPressed: () async {
                final ok = await confirmAction(
                  context,
                  title: s.closePoll,
                  message: s.closePollBody,
                  confirmLabel: s.closePoll,
                );
                if (ok) app.closePoll(poll.id);
              },
              icon: const Icon(Icons.lock_outline),
              label: Text(s.closePoll),
            ),
          ] else ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              leaders.isEmpty
                  ? s.noVotesYet
                  : (leaders.length > 1 ? s.tie : s.result(leaders.first.text)),
              style: theme.textTheme.titleMedium,
            ),
          ],
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.option,
    required this.votes,
    required this.total,
    required this.selected,
    required this.leading,
    required this.voters,
    required this.onTap,
  });

  final PollOption option;
  final int votes;
  final int total;
  final bool selected;
  final bool leading;
  final List<String> voters;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final s = context.s;
    final theme = Theme.of(context);
    final share = total == 0 ? 0.0 : votes / total;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Card(
        color: selected ? theme.colorScheme.primaryContainer : null,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      size: 20,
                      color: selected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        option.text,
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                    if (leading)
                      const Icon(Icons.emoji_events_outlined, size: 20),
                    const SizedBox(width: AppSpacing.xs),
                    Text(s.votes(votes), style: theme.textTheme.labelLarge),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: share,
                    minHeight: 6,
                    semanticsLabel: s.votes(votes),
                  ),
                ),
                if (voters.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      for (final id in voters)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: MemberAvatar(
                            member: app.member(id),
                            radius: 10,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PollFormScreen extends StatefulWidget {
  const PollFormScreen({super.key});

  @override
  State<PollFormScreen> createState() => _PollFormScreenState();
}

class _PollFormScreenState extends State<PollFormScreen> {
  static const int maxOptions = 6;

  final _formKey = GlobalKey<FormState>();
  final _question = TextEditingController();
  final List<TextEditingController> _options = [
    TextEditingController(),
    TextEditingController(),
  ];
  DateTime? _deadline;
  bool _submitted = false;

  @override
  void dispose() {
    _question.dispose();
    for (final c in _options) {
      c.dispose();
    }
    super.dispose();
  }

  int get _filledOptions =>
      _options.where((c) => c.text.trim().isNotEmpty).length;

  void _save() {
    setState(() => _submitted = true);
    final s = context.s;
    if (!_formKey.currentState!.validate() || _filledOptions < 2) {
      showSnack(context, _filledOptions < 2 ? s.needTwoOptions : s.fixErrors);
      return;
    }
    context.app.createPoll(
      question: _question.text,
      options: _options.map((c) => c.text).toList(),
      deadline: _deadline,
    );
    Navigator.of(context).pop();
    showSnack(context, s.saved);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final s = context.s;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.newPoll),
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
              controller: _question,
              decoration: InputDecoration(labelText: s.question),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) => s.textError(
                validateRequiredText(v, maxLength: 120),
                maxLength: 120,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(s.pollOptions, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            for (var i = 0; i < _options.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _options[i],
                        decoration: InputDecoration(
                          labelText: s.optionN(i + 1),
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        onChanged: (_) => setState(() {}),
                        validator: (v) =>
                            (v ?? '').length > 80 ? s.textTooLong(80) : null,
                      ),
                    ),
                    if (_options.length > 2)
                      IconButton(
                        tooltip: s.delete,
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () {
                          final c = _options.removeAt(i);
                          setState(() {});
                          c.dispose();
                        },
                      ),
                  ],
                ),
              ),
            if (_submitted && _filledOptions < 2)
              Text(
                s.needTwoOptions,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            if (_options.length < maxOptions)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () =>
                      setState(() => _options.add(TextEditingController())),
                  icon: const Icon(Icons.add),
                  label: Text(s.addOption),
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
            PickerField(
              label: s.deadlineOptional,
              value: _deadline == null
                  ? s.noDeadline
                  : s.dates.dayAndTime(_deadline!, now: app.today),
              icon: Icons.timer_outlined,
              onClear: _deadline == null
                  ? null
                  : () => setState(() => _deadline = null),
              onTap: () async {
                final picked = await pickDate(
                  context,
                  _deadline ?? addDays(app.today, 2),
                  first: app.today,
                );
                if (picked != null) {
                  setState(() => _deadline = withTime(picked, 21, 0));
                }
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            InfoBanner(text: s.oneVoteRule, icon: Icons.rule),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(onPressed: _save, child: Text(s.save)),
          ],
        ),
      ),
    );
  }
}
