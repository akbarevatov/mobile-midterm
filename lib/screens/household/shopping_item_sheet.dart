import 'package:flutter/material.dart';

import '../../models/shopping_item.dart';
import '../../theme/app_spacing.dart';
import '../../utils/validators.dart';
import '../../widgets/common/app_scope.dart';
import '../../widgets/common/category_icons.dart';
import '../../widgets/common/dialogs.dart';
import '../../widgets/forms/member_selectors.dart';

enum DuplicateChoice { updateQuantity, addSeparately }

Future<DuplicateChoice?> askAboutDuplicate(
  BuildContext context,
  ShoppingItem existing,
) {
  final s = context.s;
  return showDialog<DuplicateChoice>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: const Icon(Icons.content_copy_outlined),
      title: Text(s.duplicateTitle),
      content: Text(s.duplicateBody(existing.name, existing.quantity)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(s.cancel),
        ),
        TextButton(
          onPressed: () =>
              Navigator.pop(dialogContext, DuplicateChoice.addSeparately),
          child: Text(s.addSeparately),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.pop(dialogContext, DuplicateChoice.updateQuantity),
          child: Text(s.updateQuantity),
        ),
      ],
    ),
  );
}

Future<void> addShoppingItemChecked(
  BuildContext context, {
  required String name,
  required ShoppingCategory category,
  String quantity = '',
  String notes = '',
  String? buyerId,
}) async {
  final app = context.app;
  final s = context.s;
  final duplicate = app.findActiveDuplicate(name);
  if (duplicate != null) {
    final choice = await askAboutDuplicate(context, duplicate);
    if (choice == null || !context.mounted) return;
    if (choice == DuplicateChoice.updateQuantity && quantity.trim().isEmpty) {
      await showShoppingItemSheet(context, existing: duplicate);
      return;
    }
    if (choice == DuplicateChoice.updateQuantity) {
      app.updateShoppingItem(
        duplicate,
        name: duplicate.name,
        category: duplicate.category,
        quantity: quantity.isEmpty ? duplicate.quantity : quantity,
        notes: notes.isEmpty ? duplicate.notes : notes,
        buyerMemberId: buyerId ?? duplicate.buyerMemberId,
      );
      showSnack(context, s.quantityUpdated);
      return;
    }
  }
  app.addShoppingItem(
    name: name,
    category: category,
    quantity: quantity,
    notes: notes,
    buyerMemberId: buyerId,
  );
  if (context.mounted) showSnack(context, s.addedToList(name.trim()));
}

Future<void> showShoppingItemSheet(
  BuildContext context, {
  ShoppingItem? existing,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _ShoppingItemForm(existing: existing, hostContext: context),
  );
}

class _ShoppingItemForm extends StatefulWidget {
  const _ShoppingItemForm({this.existing, required this.hostContext});

  final ShoppingItem? existing;
  final BuildContext hostContext;

  @override
  State<_ShoppingItemForm> createState() => _ShoppingItemFormState();
}

class _ShoppingItemFormState extends State<_ShoppingItemForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _quantity = TextEditingController();
  final _notes = TextEditingController();
  ShoppingCategory _category = ShoppingCategory.food;
  String? _buyerId;

  @override
  void initState() {
    super.initState();
    final item = widget.existing;
    if (item != null) {
      _name.text = item.name;
      _quantity.text = item.quantity;
      _notes.text = item.notes;
      _category = item.category;
      _buyerId = item.buyerMemberId;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _quantity.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final app = context.app;
    final existing = widget.existing;
    if (existing != null) {
      app.updateShoppingItem(
        existing,
        name: _name.text,
        category: _category,
        quantity: _quantity.text,
        notes: _notes.text,
        buyerMemberId: _buyerId,
      );
      Navigator.pop(context);
      return;
    }
    Navigator.pop(context);
    final host = widget.hostContext;
    if (!host.mounted) return;
    await addShoppingItemChecked(
      host,
      name: _name.text,
      category: _category,
      quantity: _quantity.text,
      notes: _notes.text,
      buyerId: _buyerId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final s = context.s;
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
            Text(
              widget.existing == null ? s.addItem : s.editItem,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _name,
              autofocus: widget.existing == null,
              decoration: InputDecoration(labelText: s.itemName),
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              validator: (v) => s.textError(
                validateRequiredText(v, maxLength: 50),
                maxLength: 50,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _quantity,
              decoration: InputDecoration(
                labelText: s.quantityOptional,
                hintText: s.quantityHint,
              ),
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v ?? '').length > 30 ? s.textTooLong(30) : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            FieldLabel(s.category),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final c in ShoppingCategory.values)
                  ChoiceChip(
                    avatar: Icon(shoppingIcon(c), size: 18),
                    label: Text(s.shoppingCategory(c)),
                    selected: _category == c,
                    onSelected: (_) => setState(() => _category = c),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            FieldLabel(s.buyerOptional),
            MemberChoiceChips(
              members: app.activeMembers,
              selectedId: _buyerId,
              allowNone: true,
              noneLabel: s.unassigned,
              onSelected: (id) => setState(() => _buyerId = id),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _notes,
              decoration: InputDecoration(labelText: s.notesOptional),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  (v ?? '').length > 100 ? s.textTooLong(100) : null,
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(onPressed: _save, child: Text(s.save)),
          ],
        ),
      ),
    );
  }
}
