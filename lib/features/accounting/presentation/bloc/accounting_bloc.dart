import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../backend/services/accounting_service.dart';
import 'accounting_event.dart';
import 'accounting_state.dart';

class AccountingBloc extends Bloc<AccountingEvent, AccountingState> {
  AccountingBloc() : super(AccountingInitial()) {
    on<FetchAccountingDataRequested>(_onFetchAccountingDataRequested);
    on<FetchDuesStatusRequested>(_onFetchDuesStatusRequested);
    on<AddFeePaymentSubmitted>(_onAddFeePaymentSubmitted);
    on<AddExpenseSubmitted>(_onAddExpenseSubmitted);
    on<UpdateFeePaymentSubmitted>(_onUpdateFeePaymentSubmitted);
    on<DeleteFeePaymentSubmitted>(_onDeleteFeePaymentSubmitted);
    on<UpdateExpenseSubmitted>(_onUpdateExpenseSubmitted);
    on<DeleteExpenseSubmitted>(_onDeleteExpenseSubmitted);
  }

  Future<void> _onFetchAccountingDataRequested(
    FetchAccountingDataRequested event,
    Emitter<AccountingState> emit,
  ) async {
    emit(AccountingLoading());
    try {
      final summary = await AccountingService.fetchAccountingSummary();
      emit(AccountingDataLoaded(summary));
    } catch (e) {
      emit(AccountingError(e.toString()));
    }
  }

  Future<void> _onFetchDuesStatusRequested(
    FetchDuesStatusRequested event,
    Emitter<AccountingState> emit,
  ) async {
    emit(AccountingLoading());
    try {
      final dues = await AccountingService.fetchDuesStatus(event.month);
      emit(AccountingDuesLoaded(month: event.month, dues: dues));
    } catch (e) {
      emit(AccountingError(e.toString()));
    }
  }

  Future<void> _onAddFeePaymentSubmitted(
    AddFeePaymentSubmitted event,
    Emitter<AccountingState> emit,
  ) async {
    emit(AccountingLoading());
    try {
      await AccountingService.addFeePayment(
        memberId: event.memberId,
        amount: event.amount,
        month: event.month,
        paymentType: event.paymentType,
        eventName: event.eventName,
        remarks: event.remarks,
        externalSource: event.externalSource,
      );
      emit(const AccountingActionSuccess('Fee payment recorded successfully!', isPaymentAdded: true));
    } catch (e) {
      emit(AccountingError(e.toString()));
    }
  }

  Future<void> _onAddExpenseSubmitted(
    AddExpenseSubmitted event,
    Emitter<AccountingState> emit,
  ) async {
    emit(AccountingLoading());
    try {
      await AccountingService.addExpense(
        amount: event.amount,
        category: event.category,
        description: event.description,
        eventName: event.eventName,
        remarks: event.remarks,
        expenseDate: event.expenseDate,
      );
      emit(const AccountingActionSuccess('Club expense logged successfully!', isExpenseAdded: true));
    } catch (e) {
      emit(AccountingError(e.toString()));
    }
  }

  Future<void> _onUpdateFeePaymentSubmitted(
    UpdateFeePaymentSubmitted event,
    Emitter<AccountingState> emit,
  ) async {
    emit(AccountingLoading());
    try {
      await AccountingService.updateFeePayment(
        paymentId: event.paymentId,
        amount: event.amount,
        month: event.month,
        paymentType: event.paymentType,
        eventName: event.eventName,
        remarks: event.remarks,
      );
      emit(const AccountingActionSuccess('Fee payment updated successfully!', isPaymentAdded: true));
    } catch (e) {
      emit(AccountingError(e.toString()));
    }
  }

  Future<void> _onDeleteFeePaymentSubmitted(
    DeleteFeePaymentSubmitted event,
    Emitter<AccountingState> emit,
  ) async {
    emit(AccountingLoading());
    try {
      await AccountingService.deleteFeePayment(event.paymentId);
      emit(const AccountingActionSuccess('Fee payment deleted successfully!', isPaymentAdded: true));
    } catch (e) {
      emit(AccountingError(e.toString()));
    }
  }

  Future<void> _onUpdateExpenseSubmitted(
    UpdateExpenseSubmitted event,
    Emitter<AccountingState> emit,
  ) async {
    emit(AccountingLoading());
    try {
      await AccountingService.updateExpense(
        expenseId: event.expenseId,
        amount: event.amount,
        category: event.category,
        description: event.description,
        expenseDate: event.expenseDate,
        eventName: event.eventName,
        remarks: event.remarks,
      );
      emit(const AccountingActionSuccess('Club expense updated successfully!', isExpenseAdded: true));
    } catch (e) {
      emit(AccountingError(e.toString()));
    }
  }

  Future<void> _onDeleteExpenseSubmitted(
    DeleteExpenseSubmitted event,
    Emitter<AccountingState> emit,
  ) async {
    emit(AccountingLoading());
    try {
      await AccountingService.deleteExpense(event.expenseId);
      emit(const AccountingActionSuccess('Club expense deleted successfully!', isExpenseAdded: true));
    } catch (e) {
      emit(AccountingError(e.toString()));
    }
  }
}
