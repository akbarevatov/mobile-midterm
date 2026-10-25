import 'package:flutter/material.dart';

import '../../models/expense.dart';
import '../../models/household_bill.dart';
import '../../models/household_event.dart';
import '../../models/household_issue.dart';
import '../../models/planner_item.dart';
import '../../models/shopping_item.dart';

IconData expenseIcon(ExpenseCategory c) => switch (c) {
  ExpenseCategory.groceries => Icons.shopping_basket_outlined,
  ExpenseCategory.household => Icons.cleaning_services_outlined,
  ExpenseCategory.utilities => Icons.bolt_outlined,
  ExpenseCategory.rent => Icons.key_outlined,
  ExpenseCategory.internet => Icons.wifi,
  ExpenseCategory.transport => Icons.local_taxi_outlined,
  ExpenseCategory.eatingOut => Icons.restaurant_outlined,
  ExpenseCategory.other => Icons.receipt_long_outlined,
};

IconData shoppingIcon(ShoppingCategory c) => switch (c) {
  ShoppingCategory.food => Icons.bakery_dining_outlined,
  ShoppingCategory.drinks => Icons.water_drop_outlined,
  ShoppingCategory.cleaning => Icons.soap_outlined,
  ShoppingCategory.hygiene => Icons.clean_hands_outlined,
  ShoppingCategory.household => Icons.home_repair_service_outlined,
  ShoppingCategory.other => Icons.category_outlined,
};

IconData plannerIcon(PlannerCategory c) => switch (c) {
  PlannerCategory.assignment => Icons.assignment_outlined,
  PlannerCategory.homework => Icons.edit_note,
  PlannerCategory.exam => Icons.quiz_outlined,
  PlannerCategory.project => Icons.groups_outlined,
  PlannerCategory.classSession => Icons.school_outlined,
  PlannerCategory.study => Icons.menu_book_outlined,
  PlannerCategory.personalTask => Icons.person_outline,
  PlannerCategory.event => Icons.event_outlined,
};

IconData billIcon(BillType t) => switch (t) {
  BillType.rent => Icons.key_outlined,
  BillType.electricity => Icons.bolt_outlined,
  BillType.water => Icons.water_drop_outlined,
  BillType.gas => Icons.local_fire_department_outlined,
  BillType.internet => Icons.wifi,
  BillType.maintenance => Icons.apartment_outlined,
  BillType.subscription => Icons.subscriptions_outlined,
  BillType.other => Icons.receipt_long_outlined,
};

IconData eventIcon(EventType t) => switch (t) {
  EventType.guests => Icons.people_outline,
  EventType.maintenance => Icons.handyman_outlined,
  EventType.meeting => Icons.forum_outlined,
  EventType.shopping => Icons.storefront_outlined,
  EventType.cleaning => Icons.cleaning_services_outlined,
  EventType.other => Icons.event_outlined,
};

IconData issueIcon(IssueCategory c) => switch (c) {
  IssueCategory.plumbing => Icons.plumbing,
  IssueCategory.electrical => Icons.electrical_services,
  IssueCategory.appliance => Icons.local_laundry_service_outlined,
  IssueCategory.internet => Icons.wifi_off,
  IssueCategory.furniture => Icons.chair_outlined,
  IssueCategory.supplies => Icons.inventory_2_outlined,
  IssueCategory.other => Icons.report_outlined,
};

const IconData choreIcon = Icons.cleaning_services_outlined;
