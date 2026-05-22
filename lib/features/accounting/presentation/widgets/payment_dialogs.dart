import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../backend/services/auth_service.dart';
import '../../../../core/utils/validation_rules.dart';
import '../../../profile/models/profile_state.dart';
import '../bloc/accounting_bloc.dart';
import '../bloc/accounting_event.dart';

// Helper lists
const List<String> _monthsList = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December'
];

List<String> _getYearsList() {
  final currentYear = DateTime.now().year;
  return [
    '${currentYear - 2}',
    '${currentYear - 1}',
    '$currentYear',
    '${currentYear + 1}',
    '${currentYear + 2}'
  ];
}

class AddPaymentDialog extends StatefulWidget {
  final ProfileData? preselectedMember; // Optional preset (e.g. from Dues page click)
  final String? preselectedMonth;       // Optional preset format 'YYYY-MM'

  const AddPaymentDialog({
    super.key,
    this.preselectedMember,
    this.preselectedMonth,
  });

  @override
  State<AddPaymentDialog> createState() => _AddPaymentDialogState();
}

class _AddPaymentDialogState extends State<AddPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _eventNameController = TextEditingController();
  final _remarksController = TextEditingController();
  final _memberSearchController = TextEditingController();

  List<ProfileData> _allMembers = [];
  ProfileData? _selectedMember;
  bool _isLoadingMembers = true;

  String _selectedMonthName = _monthsList[DateTime.now().month - 1];
  String _selectedYear = DateTime.now().year.toString();
  String _paymentType = 'monthly';

  @override
  void initState() {
    super.initState();
    _amountController.text = '50'; // Default standard dues fee amount
    
    if (widget.preselectedMember != null) {
      _selectedMember = widget.preselectedMember;
      _memberSearchController.text = widget.preselectedMember!.name;
    }

    if (widget.preselectedMonth != null && widget.preselectedMonth!.contains('-')) {
      final parts = widget.preselectedMonth!.split('-');
      if (parts.length == 2) {
        _selectedYear = parts[0];
        final monthInt = int.tryParse(parts[1]);
        if (monthInt != null && monthInt >= 1 && monthInt <= 12) {
          _selectedMonthName = _monthsList[monthInt - 1];
        }
      }
    }

    _loadMembers();
  }

  Future<void> _loadMembers() async {
    try {
      final members = await AuthService.fetchAllMembers();
      setState(() {
        _allMembers = members.where((m) => m.isApproved && !m.isAlumni).toList();
        _isLoadingMembers = false;
      });
    } catch (e) {
      setState(() => _isLoadingMembers = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load members: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _eventNameController.dispose();
    _remarksController.dispose();
    _memberSearchController.dispose();
    super.dispose();
  }

  String _getTargetMonthString() {
    final monthIndex = _monthsList.indexOf(_selectedMonthName) + 1;
    final monthStr = monthIndex < 10 ? '0$monthIndex' : '$monthIndex';
    return '$_selectedYear-$monthStr';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        padding: const EdgeInsets.all(20),
        child: _isLoadingMembers
            ? const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              )
            : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Record Fee Payment',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colors.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const Divider(thickness: 0.5, height: 16),
                      
                      // 1. Search Member
                      Text(
                        'Select Club Member *',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      widget.preselectedMember != null
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: colors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundImage: _selectedMember?.imagePath != null &&
                                            _selectedMember!.imagePath!.startsWith('http')
                                        ? NetworkImage(_selectedMember!.imagePath!) as ImageProvider
                                        : null,
                                    child: (_selectedMember?.imagePath == null ||
                                            !_selectedMember!.imagePath!.startsWith('http'))
                                        ? const Icon(Icons.person, size: 16)
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _selectedMember?.name ?? '',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                        Text(
                                          _selectedMember?.studentFullId ?? '',
                                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Autocomplete<ProfileData>(
                              displayStringForOption: (ProfileData option) => option.name,
                              fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
                                return TextFormField(
                                  controller: textController,
                                  focusNode: focusNode,
                                  decoration: InputDecoration(
                                    hintText: 'Search by name or roll...',
                                    prefixIcon: const Icon(Icons.search),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  validator: (v) {
                                    if (_selectedMember == null) {
                                      return 'Please select a valid member from the list';
                                    }
                                    return null;
                                  },
                                );
                              },
                              optionsBuilder: (TextEditingValue textEditingValue) {
                                if (textEditingValue.text.isEmpty) {
                                  return const Iterable<ProfileData>.empty();
                                }
                                return _allMembers.where((ProfileData option) {
                                  final term = textEditingValue.text.toLowerCase();
                                  return option.name.toLowerCase().contains(term) ||
                                      option.universityId.toLowerCase().contains(term) ||
                                      option.classRoll.toLowerCase().contains(term);
                                });
                              },
                              optionsViewBuilder: (context, onSelected, options) {
                                return Align(
                                  alignment: Alignment.topLeft,
                                  child: Material(
                                    elevation: 8,
                                    borderRadius: BorderRadius.circular(12),
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(maxHeight: 200),
                                      child: Container(
                                        width: MediaQuery.of(context).size.width * 0.76,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          color: colors.surfaceContainer,
                                        ),
                                        child: ListView.builder(
                                          shrinkWrap: true,
                                          padding: EdgeInsets.zero,
                                          itemCount: options.length,
                                          itemBuilder: (BuildContext context, int index) {
                                            final ProfileData option = options.elementAt(index);
                                            return ListTile(
                                              leading: CircleAvatar(
                                                radius: 16,
                                                backgroundImage: option.imagePath != null &&
                                                        option.imagePath!.startsWith('http')
                                                    ? NetworkImage(option.imagePath!) as ImageProvider
                                                    : null,
                                                child: (option.imagePath == null ||
                                                        !option.imagePath!.startsWith('http'))
                                                    ? const Icon(Icons.person, size: 16)
                                                    : null,
                                              ),
                                              title: Text(
                                                option.name,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                              ),
                                              subtitle: Text(
                                                option.studentFullId,
                                                style: const TextStyle(fontSize: 10),
                                              ),
                                              onTap: () {
                                                onSelected(option);
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                              onSelected: (ProfileData selection) {
                                setState(() {
                                  _selectedMember = selection;
                                });
                              },
                            ),
                      const SizedBox(height: 16),

                      // 2. Amount and Payment Type
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Amount (Taka) *',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.primary),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _amountController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    prefixText: '৳ ',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  validator: (v) => ValidationRules.validateRequired(v, 'Amount'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Payment Type *',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.primary),
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  initialValue: _paymentType,
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'monthly',
                                      child: Text(
                                        'Monthly Fee',
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'event',
                                      child: Text(
                                        'Event Fee',
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'admission',
                                      child: Text(
                                        'Admission Fee',
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'others',
                                      child: Text(
                                        'Others',
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  ],
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                  ),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _paymentType = val);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 3. Month & Year (Enabled always, critical for tracking month fees)
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Select Month *',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.primary),
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  initialValue: _selectedMonthName,
                                  items: _monthsList
                                      .map((m) => DropdownMenuItem(
                                            value: m,
                                            child: Text(
                                              m,
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ))
                                      .toList(),
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                  ),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _selectedMonthName = val);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Select Year *',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.primary),
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  initialValue: _selectedYear,
                                  items: _getYearsList()
                                      .map((y) => DropdownMenuItem(
                                            value: y,
                                            child: Text(
                                              y,
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ))
                                      .toList(),
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                  ),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _selectedYear = val);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 4. Conditional Event Name
                      if (_paymentType == 'event') ...[
                        Text(
                          'Event Name *',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.primary),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _eventNameController,
                          decoration: InputDecoration(
                            hintText: 'e.g. CSE Fest 2026',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          validator: (v) => _paymentType == 'event'
                              ? ValidationRules.validateRequired(v, 'Event name')
                              : null,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // 5. Remarks
                      Text(
                        'Remarks / Note',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.primary),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _remarksController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Optional instructions or receipts metadata...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Actions
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        alignment: WrapAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              if (_formKey.currentState!.validate() && _selectedMember != null) {
                                final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
                                context.read<AccountingBloc>().add(
                                      AddFeePaymentSubmitted(
                                        memberId: _selectedMember!.id,
                                        amount: amount,
                                        month: _getTargetMonthString(),
                                        paymentType: _paymentType,
                                        eventName: _paymentType == 'event' ? _eventNameController.text.trim() : null,
                                        remarks: _remarksController.text.trim().isNotEmpty
                                            ? _remarksController.text.trim()
                                            : null,
                                      ),
                                    );
                                Navigator.pop(context);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              backgroundColor: colors.primary,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Save Payment'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class AddExpenseDialog extends StatefulWidget {
  const AddExpenseDialog({super.key});

  @override
  State<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<AddExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _eventNameController = TextEditingController();
  final _remarksController = TextEditingController();

  String _category = 'monthly';
  DateTime _selectedDate = DateTime.now();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Theme.of(context).colorScheme.primary,
                  onPrimary: Colors.white,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _eventNameController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Log Club Expense',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colors.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(thickness: 0.5, height: 16),

                // Visual indicator of who is recording the expense
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.admin_panel_settings, size: 16, color: colors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Recorded By: ',
                        style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        currentProfile.value.name,
                        style: TextStyle(fontSize: 11, color: colors.primary, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 1. Amount
                Text(
                  'Amount (Taka) *',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.primary),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    prefixText: '৳ ',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  validator: (v) => ValidationRules.validateRequired(v, 'Amount'),
                ),
                const SizedBox(height: 16),

                // 2. Category & Date Row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Category *',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.primary),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: _category,
                            items: const [
                              DropdownMenuItem(
                                value: 'monthly',
                                child: Text(
                                  'Monthly Expenses',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'event',
                                child: Text(
                                  'Event Expenses',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'yearly',
                                child: Text(
                                  'Yearly Expenses',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'others',
                                child: Text(
                                  'Others',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            ),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _category = val);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Expense Date *',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.primary),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () => _selectDate(context),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: colors.outline.withValues(alpha: 0.5)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      DateFormat('d MMM, yyyy').format(_selectedDate),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: colors.onSurface,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Icon(
                                    Icons.calendar_today,
                                    size: 18,
                                    color: colors.primary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 3. Conditional Event Name
                if (_category == 'event') ...[
                  Text(
                    'Event Name *',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.primary),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _eventNameController,
                    decoration: InputDecoration(
                      hintText: 'e.g. CSE Iftar Party 2026',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    validator: (v) => _category == 'event'
                        ? ValidationRules.validateRequired(v, 'Event name')
                        : null,
                  ),
                  const SizedBox(height: 16),
                ],

                // 4. Description
                Text(
                  'Description / Purpose *',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.primary),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Describe where the money was spent...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  validator: (v) => ValidationRules.validateRequired(v, 'Description'),
                ),
                const SizedBox(height: 16),

                // 5. Remarks
                Text(
                  'Remarks / Note',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.primary),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _remarksController,
                  decoration: InputDecoration(
                    hintText: 'Optional notes, receipts info, etc.',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 24),

                // Actions
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
                          context.read<AccountingBloc>().add(
                                AddExpenseSubmitted(
                                  amount: amount,
                                  category: _category,
                                  description: _descriptionController.text.trim(),
                                  expenseDate: _selectedDate,
                                  eventName: _category == 'event' ? _eventNameController.text.trim() : null,
                                  remarks: _remarksController.text.trim().isNotEmpty
                                      ? _remarksController.text.trim()
                                      : null,
                                ),
                              );
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        backgroundColor: colors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Log Expense'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
