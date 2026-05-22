import 'package:equatable/equatable.dart';

abstract class AccountingEvent extends Equatable {
  const AccountingEvent();

  @override
  List<Object?> get props => [];
}

class FetchAccountingDataRequested extends AccountingEvent {}

class FetchDuesStatusRequested extends AccountingEvent {
  final String month; // Format: 'YYYY-MM'

  const FetchDuesStatusRequested(this.month);

  @override
  List<Object?> get props => [month];
}

class AddFeePaymentSubmitted extends AccountingEvent {
  final String memberId;
  final double amount;
  final String month;
  final String paymentType;
  final String? eventName;
  final String? remarks;

  const AddFeePaymentSubmitted({
    required this.memberId,
    required this.amount,
    required this.month,
    required this.paymentType,
    this.eventName,
    this.remarks,
  });

  @override
  List<Object?> get props => [memberId, amount, month, paymentType, eventName, remarks];
}

class AddExpenseSubmitted extends AccountingEvent {
  final double amount;
  final String category;
  final String description;
  final String? eventName;
  final String? remarks;
  final DateTime expenseDate;

  const AddExpenseSubmitted({
    required this.amount,
    required this.category,
    required this.description,
    required this.expenseDate,
    this.eventName,
    this.remarks,
  });

  @override
  List<Object?> get props => [amount, category, description, eventName, remarks, expenseDate];
}
