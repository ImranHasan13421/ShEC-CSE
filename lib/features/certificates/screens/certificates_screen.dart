import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ShEC_CSE/features/dashboard/presentation/widgets/ambient_background.dart';
import 'package:ShEC_CSE/features/profile/models/profile_state.dart';
import 'package:ShEC_CSE/backend/services/auth_service.dart';
import 'package:ShEC_CSE/backend/services/alumni_service.dart';
import 'package:ShEC_CSE/features/certificates/models/certificate_model.dart';
import 'package:ShEC_CSE/features/certificates/services/certificate_service.dart';
import 'package:ShEC_CSE/features/alumni/models/alumni_state.dart';
import 'package:ShEC_CSE/core/utils/snackbar_utils.dart';

class CertificatesScreen extends StatefulWidget {
  final ProfileData? preselectedMember;
  const CertificatesScreen({super.key, this.preselectedMember});

  @override
  State<CertificatesScreen> createState() => _CertificatesScreenState();
}

class _CertificatesScreenState extends State<CertificatesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<CertificateModel> _certificates = [];
  List<ProfileData> _allMembers = [];
  List<AlumniItem> _allAlumni = [];
  bool _isLoadingCerts = true;
  bool _isLoadingMembers = true;
  bool _isGenerating = false;

  // Search/filter states
  String _searchQuery = '';
  final Map<String, bool> _downloadingCerts = {};

  // Form states
  final _formKey = GlobalKey<FormState>();
  ProfileData? _selectedMember;
  AlumniItem? _selectedAlumni;
  bool _isAlumniMode = false;

  final _designationController = TextEditingController();
  final _batchController = TextEditingController();
  final _sessionController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedCertType = CertificateService.certificateTypes.first;
  DateTime _issuedDate = DateTime.now();

  // Lifetime serial lookup
  String? _existingSerial;
  bool _checkingSerial = false;

  bool get isIssuer {
    final profile = currentProfile.value;
    return profile.role == UserRole.superUser ||
        profile.designation == 'President' ||
        profile.designation == 'Vice President';
  }

  @override
  void initState() {
    super.initState();
    final tabCount = isIssuer ? 2 : 1;
    _tabController = TabController(length: tabCount, vsync: this);

    _loadCertificates();

    if (isIssuer) {
      _loadMembers();
      if (widget.preselectedMember != null) {
        _selectedMember = widget.preselectedMember;
        _designationController.text = widget.preselectedMember!.designation;
        _batchController.text = widget.preselectedMember!.batch;
        _sessionController.text = widget.preselectedMember!.session;
        _tabController.index = 1;
        _lookupExistingSerial();
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _designationController.dispose();
    _batchController.dispose();
    _sessionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadCertificates() async {
    setState(() => _isLoadingCerts = true);
    try {
      final certs = isIssuer
          ? await CertificateService.fetchAllCertificates()
          : await CertificateService.fetchCertificatesForUser(
              currentProfile.value.id);
      setState(() => _certificates = certs);
    } catch (e) {
      if (mounted) SnackBarUtils.showError(context, 'Failed to load certificates: $e');
    } finally {
      if (mounted) setState(() => _isLoadingCerts = false);
    }
  }

  Future<void> _loadMembers() async {
    setState(() => _isLoadingMembers = true);
    try {
      final members = await AuthService.fetchAllMembers();
      final alumniList = await AlumniService.fetchAlumni();
      setState(() {
        _allMembers = members.where((m) => m.isApproved).toList();
        _allAlumni = alumniList.where((a) => a.isApproved).toList();
      });
    } catch (e) {
      if (mounted) SnackBarUtils.showError(context, 'Failed to load members list: $e');
    } finally {
      if (mounted) setState(() => _isLoadingMembers = false);
    }
  }

  Future<void> _lookupExistingSerial() async {
    if (!mounted) return;
    setState(() {
      _existingSerial = null;
      _checkingSerial = true;
    });
    try {
      String? serial;
      if (_isAlumniMode && _selectedAlumni != null) {
        serial = await CertificateService.getExistingAlumniSerial(_selectedAlumni!.id);
      } else if (!_isAlumniMode && _selectedMember != null) {
        serial = await CertificateService.getExistingMemberSerial(_selectedMember!.id);
      }
      if (mounted) setState(() => _existingSerial = serial);
    } finally {
      if (mounted) setState(() => _checkingSerial = false);
    }
  }

  Future<void> _generateAndIssueCertificate() async {
    if (_isAlumniMode && _selectedAlumni == null) return;
    if (!_isAlumniMode && _selectedMember == null) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isGenerating = true);
    try {
      final cert = await CertificateService.generateCertificate(
        context: context,
        issuer: currentProfile.value,
        member: _isAlumniMode ? null : _selectedMember!.copyWith(
          designation: _designationController.text.trim(),
          batch: _batchController.text.trim(),
          session: _sessionController.text.trim(),
        ),
        alumni: _isAlumniMode ? _selectedAlumni : null,
        certificateType: _selectedCertType,
        issuedDate: _issuedDate,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        overrideDesignation: _isAlumniMode ? _designationController.text.trim() : null,
        overrideBatch: _isAlumniMode ? _batchController.text.trim() : null,
        overrideSession: _isAlumniMode ? _sessionController.text.trim() : null,
      );

      if (mounted) {
        SnackBarUtils.showSuccess(
          context,
          '✅ Certificate ${cert.serialNumber} issued for ${cert.memberName}!',
        );
        setState(() {
          _selectedMember = null;
          _selectedAlumni = null;
          _existingSerial = null;
          _designationController.clear();
          _batchController.clear();
          _sessionController.clear();
          _notesController.clear();
          _selectedCertType = CertificateService.certificateTypes.first;
          _issuedDate = DateTime.now();
        });
        await _loadCertificates();
        _tabController.animateTo(0);
      }
    } catch (e) {
      if (mounted) SnackBarUtils.showError(context, 'Generation failed: $e');
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _downloadPdf(CertificateModel cert) async {
    setState(() => _downloadingCerts[cert.id] = true);
    try {
      await CertificateService.downloadCertificate(context, cert);
    } catch (e) {
      if (mounted) SnackBarUtils.showError(context, 'Download failed: $e');
    } finally {
      if (mounted) setState(() => _downloadingCerts[cert.id] = false);
    }
  }

  Future<void> _deleteCertificate(CertificateModel cert) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Certificate?'),
        content: Text(
            'This will permanently delete the certificate for ${cert.memberName} (${cert.serialNumber}). This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await CertificateService.deleteCertificate(cert.id);
      if (mounted) {
        SnackBarUtils.showSuccess(context, 'Certificate deleted.');
        _loadCertificates();
      }
    } catch (e) {
      if (mounted) SnackBarUtils.showError(context, 'Delete failed: $e');
    }
  }

  Future<void> _pickIssuedDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _issuedDate,
      firstDate: DateTime(2015),
      lastDate: DateTime(2100),
      helpText: 'Select Certificate Issue Date',
    );
    if (picked != null && mounted) {
      setState(() => _issuedDate = picked);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return AmbientTimeBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          elevation: 0,
          title: const Text('Club Certificates'),
          bottom: isIssuer
              ? TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'All Certificates', icon: Icon(Icons.verified_user_outlined)),
                    Tab(text: 'Issue Certificate', icon: Icon(Icons.add_moderator_outlined)),
                  ],
                )
              : null,
        ),
        body: isIssuer
            ? TabBarView(
                controller: _tabController,
                children: [
                  _buildCertificatesTab(colors),
                  _buildIssueTab(colors),
                ],
              )
            : _buildCertificatesTab(colors),
      ),
    );
  }

  // ── Certificate list tab ──────────────────────────────────────────────────

  Widget _buildCertificatesTab(ColorScheme colors) {
    final filtered = _certificates.where((c) {
      final q = _searchQuery.toLowerCase();
      return c.memberName.toLowerCase().contains(q) ||
          c.serialNumber.toLowerCase().contains(q) ||
          (c.memberDesignation?.toLowerCase().contains(q) ?? false) ||
          (c.memberSession?.toLowerCase().contains(q) ?? false) ||
          c.certificateType.toLowerCase().contains(q);
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          const SizedBox(height: 12),
          TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: 'Search by name, serial, type...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.outline.withOpacity(0.2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.outline.withOpacity(0.1)),
              ),
              filled: true,
              fillColor: colors.surfaceContainerLowest.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadCertificates,
              child: _isLoadingCerts
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                      ? SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Container(
                            height: MediaQuery.of(context).size.height * 0.6,
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.military_tech_outlined,
                                    size: 64,
                                    color: colors.onSurface.withOpacity(0.3)),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isEmpty
                                      ? 'No certificates found.'
                                      : 'No matching certificates found.',
                                  style: TextStyle(
                                      fontSize: 16,
                                      color: colors.onSurface.withOpacity(0.6)),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final cert = filtered[index];
                            return _buildCertCard(cert, colors);
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertCard(CertificateModel cert, ColorScheme colors) {
    final isDownloading = _downloadingCerts[cert.id] ?? false;
    final typeColor = _certTypeColor(cert.certificateType);
    final effectiveDate = cert.effectiveIssueDate;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: colors.surface.withOpacity(0.7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outline.withOpacity(0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Gold medal icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.amber.withOpacity(0.2)),
                  ),
                  child: const Icon(Icons.military_tech,
                      color: Colors.amber, size: 28),
                ),
                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name row with alumni chip
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              cert.memberName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (cert.isAlumni)
                            Container(
                              margin: const EdgeInsets.only(left: 6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.teal.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: Colors.teal.withOpacity(0.4)),
                              ),
                              child: const Text('Alumni',
                                  style: TextStyle(
                                      fontSize: 9,
                                      color: Colors.teal,
                                      fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      // Serial number in monospace
                      Text(
                        cert.serialNumber,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Actions
                if (isDownloading)
                  const Padding(
                    padding: EdgeInsets.all(10.0),
                    child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.download_rounded,
                            color: colors.primary),
                        tooltip: 'Download Certificate',
                        onPressed: () => _downloadPdf(cert),
                        visualDensity: VisualDensity.compact,
                      ),
                      if (isIssuer)
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red),
                          tooltip: 'Delete Certificate',
                          onPressed: () => _deleteCertificate(cert),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
              ],
            ),

            const SizedBox(height: 10),

            // Tag row: cert type + designation + date
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                // Certificate type badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: typeColor.withOpacity(0.4)),
                  ),
                  child: Text(
                    cert.certificateType,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: typeColor),
                  ),
                ),
                // Designation
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    cert.memberDesignation ?? 'Member',
                    style: TextStyle(
                        fontSize: 10,
                        color: colors.onSurface.withOpacity(0.7)),
                  ),
                ),
                // Issue date
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today,
                          size: 10,
                          color: colors.onSurface.withOpacity(0.6)),
                      const SizedBox(width: 3),
                      Text(
                        DateFormat('dd MMM yyyy').format(effectiveDate),
                        style: TextStyle(
                            fontSize: 10,
                            color: colors.onSurface.withOpacity(0.7)),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Notes if present
            if (cert.notes != null && cert.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLowest.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: colors.outline.withOpacity(0.1)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.note_outlined,
                        size: 13,
                        color: colors.onSurface.withOpacity(0.5)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        cert.notes!,
                        style: TextStyle(
                            fontSize: 11,
                            color: colors.onSurface.withOpacity(0.7),
                            fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _certTypeColor(String type) {
    switch (type) {
      case 'Excellence':
        return Colors.purple;
      case 'Leadership':
        return Colors.blue;
      case 'Participation':
        return Colors.green;
      case 'Special Recognition':
        return Colors.deepOrange;
      default: // Appreciation
        return Colors.amber.shade700;
    }
  }

  // ── Issue Certificate tab ─────────────────────────────────────────────────

  Widget _buildIssueTab(ColorScheme colors) {
    return _isLoadingMembers
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Card(
              elevation: 0,
              color: colors.surface.withOpacity(0.7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: colors.outline.withOpacity(0.15)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Text(
                        'Issue Certificate',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Generates a formal PDF certificate and stores it securely.',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const Divider(height: 28),

                      // ── Member / Alumni toggle ──────────────────────────
                      _buildLabel('Recipient Type', colors),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _modeToggleButton(
                              label: '👤 Active Member',
                              selected: !_isAlumniMode,
                              colors: colors,
                              onTap: () {
                                if (_isAlumniMode) {
                                  setState(() {
                                    _isAlumniMode = false;
                                    _selectedAlumni = null;
                                    _existingSerial = null;
                                    _designationController.clear();
                                    _batchController.clear();
                                    _sessionController.clear();
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _modeToggleButton(
                              label: '🎓 Alumni',
                              selected: _isAlumniMode,
                              colors: colors,
                              onTap: () {
                                if (!_isAlumniMode) {
                                  setState(() {
                                    _isAlumniMode = true;
                                    _selectedMember = null;
                                    _existingSerial = null;
                                    _designationController.clear();
                                    _batchController.clear();
                                    _sessionController.clear();
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── Member / Alumni autocomplete ────────────────────
                      _buildLabel(
                          _isAlumniMode ? 'Select Alumni *' : 'Select Member *',
                          colors),
                      const SizedBox(height: 8),
                      _isAlumniMode
                          ? _buildAlumniAutocomplete(colors)
                          : _buildMemberAutocomplete(colors),
                      const SizedBox(height: 8),

                      // Existing serial warning / info
                      if (_checkingSerial)
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: LinearProgressIndicator(),
                        )
                      else if (_existingSerial != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.amber.withOpacity(0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline,
                                  size: 16, color: Colors.amber),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Lifetime Serial: $_existingSerial (will be reused for this certificate)',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.amber,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // ── Certificate details ─────────────────────────────
                      if ((_isAlumniMode && _selectedAlumni != null) ||
                          (!_isAlumniMode && _selectedMember != null)) ...[
                        const SizedBox(height: 20),

                        // Certificate Type
                        _buildLabel('Certificate Type *', colors),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedCertType,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                            prefixIcon: const Icon(Icons.military_tech_outlined),
                          ),
                          items: CertificateService.certificateTypes
                              .map((t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(t)))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedCertType = v!),
                        ),
                        const SizedBox(height: 16),

                        // Issue Date
                        _buildLabel('Issue Date *', colors),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _pickIssuedDate,
                          borderRadius: BorderRadius.circular(10),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              prefixIcon:
                                  const Icon(Icons.calendar_today_outlined),
                              suffixIcon: const Icon(Icons.arrow_drop_down),
                            ),
                            child: Text(
                              DateFormat('dd MMMM, yyyy').format(_issuedDate),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Designation
                        _buildLabel(
                            'Designation on Certificate *', colors),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _designationController,
                          decoration: InputDecoration(
                            hintText: 'e.g. Executive Member, Vice President',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                            prefixIcon: const Icon(Icons.badge_outlined),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Designation is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('Batch *', colors),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _batchController,
                                    decoration: InputDecoration(
                                      hintText: 'e.g. 15',
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) {
                                        return 'Required';
                                      }
                                      return null;
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
                                  _buildLabel('Session *', colors),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _sessionController,
                                    decoration: InputDecoration(
                                      hintText: 'e.g. 2021-2022',
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) {
                                        return 'Required';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Optional notes
                        _buildLabel('Notes / Special Reason (optional)', colors),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _notesController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText:
                                'Optional — will appear on the certificate instead of the default recognition text.',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                            prefixIcon: const Icon(Icons.notes_outlined),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Submit button
                        _isGenerating
                            ? const Center(
                                child: Column(
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(height: 12),
                                    Text('Compiling PDF & Uploading...'),
                                  ],
                                ),
                              )
                            : SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton.icon(
                                  onPressed: _generateAndIssueCertificate,
                                  icon: const Icon(Icons.verified,
                                      color: Colors.white),
                                  label: const Text(
                                    'Generate & Issue Certificate',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colors.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
  }

  Widget _buildLabel(String text, ColorScheme colors) {
    return Text(
      text,
      style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: colors.primary),
    );
  }

  Widget _modeToggleButton({
    required String label,
    required bool selected,
    required ColorScheme colors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: selected
              ? colors.primary.withOpacity(0.12)
              : colors.surfaceContainerLowest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? colors.primary
                : colors.outline.withOpacity(0.2),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight:
                  selected ? FontWeight.bold : FontWeight.normal,
              color: selected
                  ? colors.primary
                  : colors.onSurface.withOpacity(0.6),
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMemberAutocomplete(ColorScheme colors) {
    return Autocomplete<ProfileData>(
      displayStringForOption: (option) => option.name,
      initialValue: _selectedMember != null
          ? TextEditingValue(text: _selectedMember!.name)
          : null,
      fieldViewBuilder: (ctx, textCtrl, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: textCtrl,
          focusNode: focusNode,
          decoration: InputDecoration(
            hintText: 'Search by name or student ID...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          validator: (_) =>
              _selectedMember == null ? 'Please select a valid member' : null,
        );
      },
      optionsBuilder: (tv) {
        if (tv.text.isEmpty) return const Iterable<ProfileData>.empty();
        final term = tv.text.toLowerCase();
        return _allMembers.where((m) =>
            m.name.toLowerCase().contains(term) ||
            m.universityId.toLowerCase().contains(term) ||
            m.classRoll.toLowerCase().contains(term));
      },
      optionsViewBuilder: _memberOptionsViewBuilder,
      onSelected: (selection) {
        setState(() {
          _selectedMember = selection;
          _designationController.text = selection.designation;
          _batchController.text = selection.batch;
          _sessionController.text = selection.session;
        });
        _lookupExistingSerial();
      },
    );
  }

  Widget _buildAlumniAutocomplete(ColorScheme colors) {
    return Autocomplete<AlumniItem>(
      displayStringForOption: (option) => option.name,
      initialValue: _selectedAlumni != null
          ? TextEditingValue(text: _selectedAlumni!.name)
          : null,
      fieldViewBuilder: (ctx, textCtrl, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: textCtrl,
          focusNode: focusNode,
          decoration: InputDecoration(
            hintText: 'Search alumni by name...',
            prefixIcon: const Icon(Icons.school_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          validator: (_) =>
              _selectedAlumni == null ? 'Please select a valid alumni' : null,
        );
      },
      optionsBuilder: (tv) {
        if (tv.text.isEmpty) return const Iterable<AlumniItem>.empty();
        final term = tv.text.toLowerCase();
        return _allAlumni.where((a) => a.name.toLowerCase().contains(term));
      },
      optionsViewBuilder: _alumniOptionsViewBuilder,
      onSelected: (selection) {
        setState(() {
          _selectedAlumni = selection;
          _designationController.text = selection.currentPosition;
          _batchController.text = selection.batch;
          _sessionController.text = selection.session;
        });
        _lookupExistingSerial();
      },
    );
  }

  Widget Function(
          BuildContext, AutocompleteOnSelected<ProfileData>, Iterable<ProfileData>)
      get _memberOptionsViewBuilder => (ctx, onSelected, options) {
            return _optionsContainer(
              ctx,
              children: options
                  .map(
                    (option) => ListTile(
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
                      title: Text(option.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text(option.studentFullId,
                          style: const TextStyle(fontSize: 10)),
                      onTap: () => onSelected(option),
                    ),
                  )
                  .toList(),
            );
          };

  Widget Function(
          BuildContext, AutocompleteOnSelected<AlumniItem>, Iterable<AlumniItem>)
      get _alumniOptionsViewBuilder => (ctx, onSelected, options) {
            return _optionsContainer(
              ctx,
              children: options
                  .map(
                    (option) => ListTile(
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundImage: option.imagePath.startsWith('http')
                            ? NetworkImage(option.imagePath) as ImageProvider
                            : null,
                        child: !option.imagePath.startsWith('http')
                            ? const Icon(Icons.school, size: 16)
                            : null,
                      ),
                      title: Text(option.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text(
                          '${option.currentPosition} • Batch ${option.batch}',
                          style: const TextStyle(fontSize: 10)),
                      onTap: () => onSelected(option),
                    ),
                  )
                  .toList(),
            );
          };

  Widget _optionsContainer(BuildContext ctx,
      {required List<Widget> children}) {
    final colors = Theme.of(ctx).colorScheme;
    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 200),
          child: Container(
            width: MediaQuery.of(ctx).size.width * 0.72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: colors.surfaceContainer,
            ),
            child: ListView(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}
