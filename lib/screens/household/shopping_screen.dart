import 'package:flutter/material.dart';

import '../../models/expense.dart';
import '../../models/shopping_item.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/common/app_scope.dart';
import '../../widgets/common/category_icons.dart';
import '../../widgets/common/dialogs.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/common/status_pill.dart';
import '../money/expense_form_screen.dart';
import 'shopping_item_sheet.dart';

class ShoppingScreen extends StatelessWidget {
  const ShoppingScreen({super.key});

  Future<void> _recordAsExpense(BuildContext context) async {
    final app = context.app;
    final s = context.s;
    final candidates = app.unrecordedPurchases;
    if (candidates.isEmpty) return;
    final selected = await showDialog<List<ShoppingItem>>(
      context: context,
      builder: (_) => _SelectItemsDialog(items: candidates),
    );
    if (selected == null || selected.isEmpty || !context.mounted) return;
    final names = selected.map((i) => i.name).join(', ');
    final foodCount = selected
        .where(
          (i) =>
              i.category == ShoppingCategory.food ||
              i.category == ShoppingCategory.drinks,
        )
        .length;
    final payer = selected.first.purchasedById ?? app.data.currentMemberId;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExpenseFormScreen(
          draft: ExpenseDraft(
            title: s.groceriesTitle(names).length > 80
                ? s.groceriesTitle(names).substring(0, 80)
                : s.groceriesTitle(names),
            category: foodCount * 2 >= selected.length
                ? ExpenseCategory.groceries
                : ExpenseCategory.household,
            payerId: app.member(payer)?.isActive == true
                ? payer
                : app.data.currentMemberId,
            shoppingItemIds: selected.map((i) => i.id).toList(),
          ),
        ),
      ),
    );
  }

  Future<void> _clearPurchased(BuildContext context) async {
    final app = context.app;
    final s = context.s;
    final ok = await confirmAction(
      context,
      title: s.clearPurchased,
      message: s.clearPurchasedBody,
      confirmLabel: s.clearPurchased,
      destructive: true,
    );
    if (ok) app.clearPurchased();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final s = context.s;
    final theme = Theme.of(context);
    final toBuy = app.itemsToBuy;
    final purchased = app.purchasedItems;
    final unrecorded = app.unrecordedPurchases;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.shoppingTitle),
        actions: [
          if (purchased.isNotEmpty)
            IconButton(
              tooltip: s.clearPurchased,
              icon: const Icon(Icons.playlist_remove),
              onPressed: () => _clearPurchased(context),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'shopping-fab',
        onPressed: () => showShoppingItemSheet(context),
        icon: const Icon(Icons.add),
        label: Text(s.addItem),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: s.quickAdd,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.page,
                    AppSpacing.lg,
                    AppSpacing.page,
                    AppSpacing.sm,
                  ),
                ),
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.page,
                    ),
                    children: [
                      for (final (name, category) in s.commonItems)
                        Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.sm),
                          child: ActionChip(
                            avatar: Icon(shoppingIcon(category), size: 18),
                            label: Text(name),
                            onPressed: () => addShoppingItemChecked(
                              context,
                              name: name,
                              category: category,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                SectionHeader(title: '${s.toBuy} (${toBuy.length})'),
              ],
            ),
          ),
          if (toBuy.isEmpty)
            SliverToBoxAdapter(
              child: EmptyState(
                icon: Icons.shopping_basket_outlined,
                title: s.emptyList,
                message: s.emptyListHint,
                compact: true,
              ),
            )
          else
            SliverList.builder(
              itemCount: toBuy.length,
              itemBuilder: (context, index) => _ToBuyTile(item: toBuy[index]),
            ),
          if (unrecorded.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.page,
                  AppSpacing.lg,
                  AppSpacing.page,
                  0,
                ),
                child: Card(
                  color: theme.colorScheme.secondaryContainer.withValues(
                    alpha: 0.6,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.receipt_outlined),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                s.unrecordedPurchases(unrecorded.length),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.tonalIcon(
                            onPressed: () => _recordAsExpense(context),
                            icon: const Icon(Icons.add_card),
                            label: Text(s.recordAsExpense),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (purchased.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: SectionHeader(
                title: '${s.purchased} (${purchased.length})',
              ),
            ),
            SliverList.builder(
              itemCount: purchased.length,
              itemBuilder: (context, index) =>
                  _PurchasedTile(item: purchased[index]),
            ),
          ],
          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.fabClearance),
          ),
        ],
      ),
    );
  }
}

class _ToBuyTile extends StatelessWidget {
  const _ToBuyTile({required this.item});

  final ShoppingItem item;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final s = context.s;
    final details = [
      s.shoppingCategory(item.category),
      if (item.buyerMemberId != null)
        s.willBuy(app.memberName(item.buyerMemberId)),
      if (item.notes.isNotEmpty) item.notes,
    ].join(' · ');

    return ListTile(
      leading: Checkbox(
        value: false,
        semanticLabel: s.purchased,
        onChanged: (_) => app.setPurchased(item.id, true),
      ),
      title: Text(
        item.quantity.isEmpty ? item.name : '${item.name} — ${item.quantity}',
      ),
      subtitle: Text(details),
      onTap: () => showShoppingItemSheet(context, existing: item),
      trailing: IconButton(
        tooltip: s.delete,
        icon: const Icon(Icons.close),
        onPressed: () {
          app.removeShoppingItem(item.id);
          showSnack(context, s.deleted);
        },
      ),
    );
  }
}

class _PurchasedTile extends StatelessWidget {
  const _PurchasedTile({required this.item});

  final ShoppingItem item;

  Future<void> _restore(BuildContext context) async {
    final app = context.app;
    final s = context.s;
    if (app.expenseForShoppingItem(item.id) != null) {
      final ok = await confirmAction(
        context,
        title: s.restore,
        message: s.restoreLinkedNote,
        confirmLabel: s.restore,
      );
      if (!ok) return;
    }
    app.setPurchased(item.id, false);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final s = context.s;
    final theme = Theme.of(context);
    final linked = app.expenseForShoppingItem(item.id) != null;
    return ListTile(
      leading: Icon(
        Icons.check_circle,
        color: context.colors.positive,
        semanticLabel: s.purchased,
      ),
      title: Text(
        item.quantity.isEmpty ? item.name : '${item.name} — ${item.quantity}',
        style: TextStyle(
          decoration: TextDecoration.lineThrough,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              s.boughtBy(
                app.memberName(item.purchasedById),
                s.dates.relativeDay(
                  item.purchasedAt ?? item.createdAt,
                  app.today,
                ),
              ),
            ),
            if (linked)
              StatusPill(
                label: s.inExpenses,
                icon: Icons.receipt_outlined,
                tone: PillTone.positive,
              ),
          ],
        ),
      ),
      trailing: TextButton(
        onPressed: () => _restore(context),
        child: Text(s.restore),
      ),
    );
  }
}

class _SelectItemsDialog extends StatefulWidget {
  const _SelectItemsDialog({required this.items});

  final List<ShoppingItem> items;

  @override
  State<_SelectItemsDialog> createState() => _SelectItemsDialogState();
}

class _SelectItemsDialogState extends State<_SelectItemsDialog> {
  late final Set<String> _selected = widget.items.map((i) => i.id).toSet();

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return AlertDialog(
      title: Text(s.selectItems),
      contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final item in widget.items)
              CheckboxListTile(
                value: _selected.contains(item.id),
                title: Text(item.name),
                subtitle: item.quantity.isEmpty ? null : Text(item.quantity),
                onChanged: (v) => setState(
                  () => v == true
                      ? _selected.add(item.id)
                      : _selected.remove(item.id),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(s.cancel),
        ),
        FilledButton(
          onPressed: _selected.isEmpty
              ? null
              : () => Navigator.pop(
                  context,
                  widget.items.where((i) => _selected.contains(i.id)).toList(),
                ),
          child: Text(s.recordAsExpense),
        ),
      ],
    );
  }
}
