import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/profile/models/profile_state.dart';
import '../../core/services/database_helper.dart';
import '../../core/services/connectivity_service.dart';

class FeePayment {
  final String id;
  final String memberId;
  final String memberName;
  final String? memberIdRoll; // Combines University ID and Class Roll
  final double amount;
  final String month;
  final String paymentType;
  final String? eventName;
  final DateTime paymentDate;
  final String receivedBy;
  final String? remarks;

  FeePayment({
    required this.id,
    required this.memberId,
    required this.memberName,
    this.memberIdRoll,
    required this.amount,
    required this.month,
    required this.paymentType,
    this.eventName,
    required this.paymentDate,
    required this.receivedBy,
    this.remarks,
  });

  factory FeePayment.fromMap(Map<String, dynamic> map) {
    if (map.containsKey('member_name_raw')) {
      return FeePayment(
        id: map['id'] ?? '',
        memberId: map['member_id'] ?? '',
        memberName: map['member_name_raw'] ?? 'Unknown Member',
        memberIdRoll: map['member_id_roll'],
        amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
        month: map['month'] ?? '',
        paymentType: map['payment_type'] ?? 'monthly',
        eventName: map['event_name'],
        paymentDate: DateTime.parse(map['payment_date'] ?? DateTime.now().toIso8601String()),
        receivedBy: map['received_by'] ?? '',
        remarks: map['remarks'],
      );
    }
    final memberProfile = map['profiles_member'] as Map<String, dynamic>?;
    final String firstName = memberProfile?['first_name'] ?? '';
    final String lastName = memberProfile?['last_name'] ?? '';
    final String uniId = memberProfile?['university_id'] ?? '';
    final String roll = memberProfile?['class_roll'] ?? '';
    
    String? idRoll;
    if (uniId.isNotEmpty && roll.isNotEmpty) {
      idRoll = '$uniId | $roll';
    } else if (uniId.isNotEmpty) {
      idRoll = uniId;
    } else if (roll.isNotEmpty) {
      idRoll = roll;
    }

    final String? extSource = map['external_source'];
    final String resolvedName = firstName.isNotEmpty || lastName.isNotEmpty 
        ? '$firstName $lastName'.trim()
        : (extSource != null && extSource.isNotEmpty 
            ? extSource 
            : (map['payment_type'] == 'sponsor' || map['payment_type'] == 'external' || map['member_id'] == null 
                ? 'Sponsor / External' 
                : 'Unknown Member'));

    return FeePayment(
      id: map['id'] ?? '',
      memberId: map['member_id'] ?? '',
      memberName: resolvedName,
      memberIdRoll: idRoll,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      month: map['month'] ?? '',
      paymentType: map['payment_type'] ?? 'monthly',
      eventName: map['event_name'],
      paymentDate: DateTime.parse(map['payment_date'] ?? DateTime.now().toIso8601String()),
      receivedBy: map['received_by'] ?? '',
      remarks: map['remarks'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'member_id': memberId,
      'member_name_raw': memberName,
      'member_id_roll': memberIdRoll,
      'amount': amount,
      'month': month,
      'payment_type': paymentType,
      'event_name': eventName,
      'payment_date': paymentDate.toIso8601String(),
      'received_by': receivedBy,
      'remarks': remarks,
    };
  }
}

class ClubExpense {
  final String id;
  final double amount;
  final String category;
  final DateTime expenseDate;
  final String description;
  final String? eventName;
  final String recordedBy;
  final String recordedByName;
  final String? remarks;

  ClubExpense({
    required this.id,
    required this.amount,
    required this.category,
    required this.expenseDate,
    required this.description,
    this.eventName,
    required this.recordedBy,
    required this.recordedByName,
    this.remarks,
  });

  factory ClubExpense.fromMap(Map<String, dynamic> map) {
    if (map.containsKey('recorded_by_name_raw')) {
      return ClubExpense(
        id: map['id'] ?? '',
        amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
        category: map['category'] ?? 'monthly',
        expenseDate: DateTime.parse(map['expense_date'] ?? DateTime.now().toIso8601String()),
        description: map['description'] ?? '',
        eventName: map['event_name'],
        recordedBy: map['recorded_by'] ?? '',
        recordedByName: map['recorded_by_name_raw'] ?? 'Unknown Admin',
        remarks: map['remarks'],
      );
    }
    final recorderProfile = map['profiles_recorder'] as Map<String, dynamic>?;
    final String firstName = recorderProfile?['first_name'] ?? '';
    final String lastName = recorderProfile?['last_name'] ?? '';

    return ClubExpense(
      id: map['id'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      category: map['category'] ?? 'monthly',
      expenseDate: DateTime.parse(map['expense_date'] ?? DateTime.now().toIso8601String()),
      description: map['description'] ?? '',
      eventName: map['event_name'],
      recordedBy: map['recorded_by'] ?? '',
      recordedByName: firstName.isNotEmpty || lastName.isNotEmpty 
          ? '$firstName $lastName'.trim()
          : 'Unknown Admin',
      remarks: map['remarks'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'category': category,
      'expense_date': expenseDate.toIso8601String(),
      'description': description,
      'event_name': eventName,
      'recorded_by': recordedBy,
      'recorded_by_name_raw': recordedByName,
      'remarks': remarks,
    };
  }
}

class MemberDuesStatus {
  final ProfileData profile;
  final bool isPaid;
  final double? paidAmount;
  final DateTime? paymentDate;

  MemberDuesStatus({
    required this.profile,
    required this.isPaid,
    this.paidAmount,
    this.paymentDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'profile': profile.toJson(),
      'is_paid': isPaid,
      'paid_amount': paidAmount,
      'payment_date': paymentDate?.toIso8601String(),
    };
  }

  factory MemberDuesStatus.fromMap(Map<String, dynamic> map) {
    return MemberDuesStatus(
      profile: ProfileData.fromJson(map['profile'] as Map<String, dynamic>),
      isPaid: map['is_paid'] ?? false,
      paidAmount: (map['paid_amount'] as num?)?.toDouble(),
      paymentDate: map['payment_date'] != null
          ? DateTime.parse(map['payment_date'] as String)
          : null,
    );
  }
}

class AccountingSummary {
  final double totalCollection;
  final double totalExpenses;
  final double currentBalance;
  final List<FeePayment> recentPayments;
  final List<ClubExpense> recentExpenses;

  AccountingSummary({
    required this.totalCollection,
    required this.totalExpenses,
    required this.currentBalance,
    required this.recentPayments,
    required this.recentExpenses,
  });

  Map<String, dynamic> toMap() {
    return {
      'total_collection': totalCollection,
      'total_expenses': totalExpenses,
      'current_balance': currentBalance,
      'recent_payments': recentPayments.map((e) => e.toMap()).toList(),
      'recent_expenses': recentExpenses.map((e) => e.toMap()).toList(),
    };
  }

  factory AccountingSummary.fromMap(Map<String, dynamic> map) {
    return AccountingSummary(
      totalCollection: (map['total_collection'] as num?)?.toDouble() ?? 0.0,
      totalExpenses: (map['total_expenses'] as num?)?.toDouble() ?? 0.0,
      currentBalance: (map['current_balance'] as num?)?.toDouble() ?? 0.0,
      recentPayments: ((map['recent_payments'] as List?) ?? [])
          .map((e) => FeePayment.fromMap(e as Map<String, dynamic>))
          .toList(),
      recentExpenses: ((map['recent_expenses'] as List?) ?? [])
          .map((e) => ClubExpense.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class AccountingService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Fetch full summary of collections and expenses
  static Future<AccountingSummary> fetchAccountingSummary() async {
    final isOnline = await ConnectivityService.hasInternet();
    if (!isOnline) {
      final cachedStr = await DatabaseHelper.instance.getCache('accounting_summary');
      if (cachedStr != null) {
        try {
          final map = json.decode(cachedStr) as Map<String, dynamic>;
          debugPrint('Successfully loaded accounting summary from local SQLite database.');
          return AccountingSummary.fromMap(map);
        } catch (e) {
          debugPrint('Error deserializing cached accounting summary: $e');
        }
      }
      return AccountingSummary(
        totalCollection: 0.0,
        totalExpenses: 0.0,
        currentBalance: 0.0,
        recentPayments: [],
        recentExpenses: [],
      );
    }

    try {
      // 1. Fetch all collections to sum up
      final feesRes = await _client.from('club_member_fees').select('amount');
      double totalCollection = 0.0;
      for (var row in feesRes) {
        totalCollection += (row['amount'] as num?)?.toDouble() ?? 0.0;
      }

      // 2. Fetch all expenses to sum up
      final expensesRes = await _client.from('club_expenses').select('amount');
      double totalExpenses = 0.0;
      for (var row in expensesRes) {
        totalExpenses += (row['amount'] as num?)?.toDouble() ?? 0.0;
      }

      // 3. Fetch recent payments (up to 20)
      final paymentsQuery = await _client
          .from('club_member_fees')
          .select('*, profiles_member:profiles!member_id(first_name, last_name, university_id, class_roll)')
          .order('payment_date', ascending: false)
          .limit(20);

      final List<FeePayment> recentPayments = (paymentsQuery as List)
          .map((data) => FeePayment.fromMap(data))
          .toList();

      // 4. Fetch recent expenses (up to 20)
      final expensesQuery = await _client
          .from('club_expenses')
          .select('*, profiles_recorder:profiles!recorded_by(first_name, last_name)')
          .order('expense_date', ascending: false)
          .limit(20);

      final List<ClubExpense> recentExpenses = (expensesQuery as List)
          .map((data) => ClubExpense.fromMap(data))
          .toList();

      final summary = AccountingSummary(
        totalCollection: totalCollection,
        totalExpenses: totalExpenses,
        currentBalance: totalCollection - totalExpenses,
        recentPayments: recentPayments,
        recentExpenses: recentExpenses,
      );

      // Save to SQLite Cache
      await DatabaseHelper.instance.saveCache('accounting_summary', json.encode(summary.toMap()));

      return summary;
    } catch (e) {
      debugPrint('Error fetching accounting summary: $e');
      rethrow;
    }
  }

  // Fetch paid vs unpaid dues status of all club members for a target month (format: 'YYYY-MM')
  static Future<List<MemberDuesStatus>> fetchDuesStatus(String targetMonth) async {
    final isOnline = await ConnectivityService.hasInternet();
    final cacheKey = 'accounting_dues_$targetMonth';
    
    if (!isOnline) {
      final cachedStr = await DatabaseHelper.instance.getCache(cacheKey);
      if (cachedStr != null) {
        try {
          final List decoded = json.decode(cachedStr);
          debugPrint('Successfully loaded dues status ($targetMonth) from local SQLite database.');
          return decoded.map((e) => MemberDuesStatus.fromMap(e as Map<String, dynamic>)).toList();
        } catch (e) {
          debugPrint('Error deserializing cached dues status ($targetMonth): $e');
        }
      }
      return [];
    }

    try {
      // 1. Fetch all approved active club profiles (exclude alumni)
      final profilesRes = await _client
          .from('profiles')
          .select()
          .eq('is_approved', true)
          .eq('is_alumni', false)
          .order('first_name', ascending: true);

      // Convert to ProfileData list
      final List<ProfileData> members = [];
      for (var data in profilesRes) {
        UserRole parsedRole;
        switch (data['role']) {
          case 'superuser': parsedRole = UserRole.superUser; break;
          case 'committee': parsedRole = UserRole.committeeMember; break;
          default: parsedRole = UserRole.student; break;
        }
        members.add(ProfileData(
          id: data['id'],
          firstName: data['first_name'] ?? '',
          lastName: data['last_name'] ?? '',
          name: '${data['first_name']} ${data['last_name']}',
          email: data['email'] ?? '', 
          universityId: data['university_id'] ?? '',
          classRoll: data['class_roll'] ?? '',
          duRegNo: data['du_reg'] ?? '',
          session: data['session'] ?? '',
          batch: data['batch'] ?? '',
          phone: data['phone'] ?? '',
          imagePath: data['profile_pic'],
          role: parsedRole,
          designation: data['designation'] ?? 'Student',
          isApproved: data['is_approved'] ?? false,
          isAlumni: data['is_alumni'] ?? false,
        ));
      }

      // 2. Fetch payments recorded for this target month
      final paymentsRes = await _client
          .from('club_member_fees')
          .select('member_id, amount, payment_date')
          .eq('month', targetMonth)
          .eq('payment_type', 'monthly');

      // Map member ID to payment info
      final Map<String, Map<String, dynamic>> paidMap = {};
      for (var payment in paymentsRes) {
        final String mId = payment['member_id'];
        paidMap[mId] = {
          'amount': (payment['amount'] as num?)?.toDouble() ?? 0.0,
          'date': DateTime.parse(payment['payment_date'] ?? DateTime.now().toIso8601String()),
        };
      }

      // 3. Build dues status list
      final List<MemberDuesStatus> result = [];
      for (var member in members) {
        final hasPaid = paidMap.containsKey(member.id);
        result.add(MemberDuesStatus(
          profile: member,
          isPaid: hasPaid,
          paidAmount: hasPaid ? paidMap[member.id]!['amount'] : null,
          paymentDate: hasPaid ? paidMap[member.id]!['date'] : null,
        ));
      }

      // Save to SQLite Cache
      final listToCache = result.map((e) => e.toMap()).toList();
      await DatabaseHelper.instance.saveCache(cacheKey, json.encode(listToCache));

      return result;
    } catch (e) {
      debugPrint('Error fetching dues status for month $targetMonth: $e');
      rethrow;
    }
  }

  // Record a payment
  static Future<void> addFeePayment({
    String? memberId,
    required double amount,
    required String month,
    required String paymentType,
    String? eventName,
    String? remarks,
    String? externalSource,
  }) async {
    final isOnline = await ConnectivityService.hasInternet();
    if (!isOnline) {
      ConnectivityService.showNoInternetToast(message: 'Internet connection required to record fee payments.');
      throw Exception('Network connection required');
    }

    try {
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('No authenticated admin found.');

      await _client.from('club_member_fees').insert({
        'member_id': memberId,
        'amount': amount,
        'month': month,
        'payment_type': paymentType,
        'event_name': eventName,
        'remarks': remarks,
        'received_by': currentUserId,
        'external_source': externalSource,
      });
    } catch (e) {
      debugPrint('Error adding fee payment: $e');
      rethrow;
    }
  }

  // Record an expense
  static Future<void> addExpense({
    required double amount,
    required String category,
    required String description,
    String? eventName,
    String? remarks,
    required DateTime expenseDate,
  }) async {
    final isOnline = await ConnectivityService.hasInternet();
    if (!isOnline) {
      ConnectivityService.showNoInternetToast(message: 'Internet connection required to record club expenses.');
      throw Exception('Network connection required');
    }

    try {
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('No authenticated admin found.');

      await _client.from('club_expenses').insert({
        'amount': amount,
        'category': category,
        'description': description,
        'event_name': eventName,
        'remarks': remarks,
        'recorded_by': currentUserId,
        'expense_date': expenseDate.toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error adding club expense: $e');
      rethrow;
    }
  }

  // Update a fee payment
  static Future<void> updateFeePayment({
    required String paymentId,
    required double amount,
    required String month,
    required String paymentType,
    String? eventName,
    String? remarks,
  }) async {
    final isOnline = await ConnectivityService.hasInternet();
    if (!isOnline) {
      ConnectivityService.showNoInternetToast(message: 'Internet connection required to edit fee payments.');
      throw Exception('Network connection required');
    }

    try {
      await _client.from('club_member_fees').update({
        'amount': amount,
        'month': month,
        'payment_type': paymentType,
        'event_name': eventName,
        'remarks': remarks,
      }).eq('id', paymentId);
    } catch (e) {
      debugPrint('Error updating fee payment: $e');
      rethrow;
    }
  }

  // Delete a fee payment
  static Future<void> deleteFeePayment(String paymentId) async {
    final isOnline = await ConnectivityService.hasInternet();
    if (!isOnline) {
      ConnectivityService.showNoInternetToast(message: 'Internet connection required to delete fee payments.');
      throw Exception('Network connection required');
    }

    try {
      await _client.from('club_member_fees').delete().eq('id', paymentId);
    } catch (e) {
      debugPrint('Error deleting fee payment: $e');
      rethrow;
    }
  }

  // Update an expense
  static Future<void> updateExpense({
    required String expenseId,
    required double amount,
    required String category,
    required String description,
    String? eventName,
    String? remarks,
    required DateTime expenseDate,
  }) async {
    final isOnline = await ConnectivityService.hasInternet();
    if (!isOnline) {
      ConnectivityService.showNoInternetToast(message: 'Internet connection required to edit club expenses.');
      throw Exception('Network connection required');
    }

    try {
      await _client.from('club_expenses').update({
        'amount': amount,
        'category': category,
        'description': description,
        'event_name': eventName,
        'remarks': remarks,
        'expense_date': expenseDate.toIso8601String(),
      }).eq('id', expenseId);
    } catch (e) {
      debugPrint('Error updating club expense: $e');
      rethrow;
    }
  }

  // Delete an expense
  static Future<void> deleteExpense(String expenseId) async {
    final isOnline = await ConnectivityService.hasInternet();
    if (!isOnline) {
      ConnectivityService.showNoInternetToast(message: 'Internet connection required to delete club expenses.');
      throw Exception('Network connection required');
    }

    try {
      await _client.from('club_expenses').delete().eq('id', expenseId);
    } catch (e) {
      debugPrint('Error deleting club expense: $e');
      rethrow;
    }
  }
}

