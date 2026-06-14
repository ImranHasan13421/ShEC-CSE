import 'package:flutter/material.dart';
import 'package:ShEC_CSE/features/dashboard/presentation/widgets/ambient_background.dart';
import 'package:ShEC_CSE/features/profile/models/profile_state.dart';
import 'package:ShEC_CSE/backend/services/auth_service.dart';
import 'package:ShEC_CSE/features/certificates/models/certificate_model.dart';
import 'package:ShEC_CSE/features/certificates/services/certificate_service.dart';
import 'package:ShEC_CSE/core/utils/snackbar_utils.dart';

class CertificatesScreen extends StatefulWidget {
  final ProfileData? preselectedMember;
  const CertificatesScreen({super.key, this.preselectedMember});

  @override
  State<CertificatesScreen> createState() => _CertificatesScreenState();
}

class _CertificatesScreenState extends State<CertificatesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<CertificateModel> _certificates = [];
  List<ProfileData> _allMembers = [];
  bool _isLoadingCerts = true;
  bool _isLoadingMembers = true;
  bool _isGenerating = false;

  // Search/Filter states
  String _searchQuery = '';
  final Map<String, bool> _downloadingCerts = {};

  // Form states for certificate issuance
  final _formKey = GlobalKey<FormState>();
  ProfileData? _selectedMember;
  final _designationController = TextEditingController();
  final _batchController = TextEditingController();
  final _sessionController = TextEditingController();

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
        // Switch to the generate tab
        _tabController.index = 1;
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _designationController.dispose();
    _batchController.dispose();
    _sessionController.dispose();
    super.dispose();
  }

  Future<void> _loadCertificates() async {
    setState(() => _isLoadingCerts = true);
    try {
      final certs = isIssuer
          ? await CertificateService.fetchAllCertificates()
          : await CertificateService.fetchCertificatesForUser(currentProfile.value.id);
      setState(() => _certificates = certs);
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, 'Failed to load certificates: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoadingCerts = false);
    }
  }

  Future<void> _loadMembers() async {
    setState(() => _isLoadingMembers = true);
    try {
      final members = await AuthService.fetchAllMembers();
      // Filter only approved members
      setState(() {
        _allMembers = members.where((m) => m.isApproved).toList();
      });
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, 'Failed to load members list: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoadingMembers = false);
    }
  }

  Future<void> _generateAndIssueCertificate() async {
    if (_selectedMember == null) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isGenerating = true);
    try {
      // Create a custom ProfileData containing details confirmed in the form
      final customMemberProfile = _selectedMember!.copyWith(
        designation: _designationController.text.trim(),
        batch: _batchController.text.trim(),
        session: _sessionController.text.trim(),
      );

      final cert = await CertificateService.generateCertificate(
        context: context,
        issuer: currentProfile.value,
        member: customMemberProfile,
      );

      if (mounted) {
        SnackBarUtils.showSuccess(
          context,
          'Successfully generated certificate ${cert.serialNumber} for ${cert.memberName}!',
        );

        // Reset form
        setState(() {
          _selectedMember = null;
          _designationController.clear();
          _batchController.clear();
          _sessionController.clear();
        });

        // Refresh certificates list and switch tab
        await _loadCertificates();
        _tabController.animateTo(0);
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, 'Generation failed: $e');
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _downloadPdf(CertificateModel cert) async {
    setState(() => _downloadingCerts[cert.id] = true);
    try {
      await CertificateService.downloadCertificate(context, cert);
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, 'Download failed: $e');
      }
    } finally {
      if (mounted) setState(() => _downloadingCerts[cert.id] = false);
    }
  }

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

  Widget _buildCertificatesTab(ColorScheme colors) {
    final filtered = _certificates.where((c) {
      final q = _searchQuery.toLowerCase();
      return c.memberName.toLowerCase().contains(q) ||
          c.serialNumber.toLowerCase().contains(q) ||
          (c.memberDesignation?.toLowerCase().contains(q) ?? false) ||
          (c.memberSession?.toLowerCase().contains(q) ?? false);
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Search Bar
          TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: 'Search certificates by name, designation, or serial...',
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
                                Icon(Icons.military_tech_outlined, size: 64, color: colors.onSurface.withOpacity(0.3)),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isEmpty
                                      ? 'No certificates found.'
                                      : 'No matching certificates found.',
                                  style: TextStyle(fontSize: 16, color: colors.onSurface.withOpacity(0.6)),
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
                            final isDownloading = _downloadingCerts[cert.id] ?? false;
  
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 0,
                              color: colors.surface.withOpacity(0.7),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: colors.outline.withOpacity(0.15)),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    // Gold award medal icon
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withOpacity(0.12),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.amber.withOpacity(0.2)),
                                      ),
                                      child: const Icon(
                                        Icons.military_tech,
                                        color: Colors.amber,
                                        size: 32,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
  
                                    // Certificate Details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            cert.memberName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            cert.serialNumber,
                                            style: TextStyle(
                                              fontFamily: 'monospace',
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: colors.primary,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            '${cert.memberDesignation ?? "Member"} • Batch ${cert.memberBatch ?? ""}',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: colors.onSurface.withOpacity(0.7),
                                            ),
                                          ),
                                          Text(
                                            'Session ${cert.memberSession ?? ""}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: colors.onSurface.withOpacity(0.5),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
  
                                    // Download Button
                                    isDownloading
                                        ? const Padding(
                                            padding: EdgeInsets.all(12.0),
                                            child: SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            ),
                                          )
                                        : IconButton(
                                            icon: Icon(Icons.download_rounded, color: colors.primary),
                                            tooltip: 'Download Certificate PDF',
                                            onPressed: () => _downloadPdf(cert),
                                          ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

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
                        'This will generate a formal PDF certificate and store it securely for the member to download.',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const Divider(height: 32),

                      // Autocomplete Member Searcher
                      Text(
                        'Select Member *',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colors.primary),
                      ),
                      const SizedBox(height: 8),
                      Autocomplete<ProfileData>(
                        displayStringForOption: (ProfileData option) => option.name,
                        initialValue: _selectedMember != null
                            ? TextEditingValue(text: _selectedMember!.name)
                            : null,
                        fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
                          return TextFormField(
                            controller: textController,
                            focusNode: focusNode,
                            decoration: InputDecoration(
                              hintText: 'Search by name or student ID...',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            validator: (v) {
                              if (_selectedMember == null) {
                                return 'Please select a valid member';
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
                                  width: MediaQuery.of(context).size.width * 0.72,
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
                            _designationController.text = selection.designation;
                            _batchController.text = selection.batch;
                            _sessionController.text = selection.session;
                          });
                        },
                      ),
                      const SizedBox(height: 20),

                      // Confirmation of details
                      if (_selectedMember != null) ...[
                        Text(
                          'Confirm Designation on Certificate *',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colors.primary),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _designationController,
                          decoration: InputDecoration(
                            hintText: 'e.g. Executive Member, Vice President',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
                                  Text(
                                    'Batch *',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colors.primary),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _batchController,
                                    decoration: InputDecoration(
                                      hintText: 'e.g. 15',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) {
                                        return 'Batch is required';
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
                                  Text(
                                    'Session *',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colors.primary),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _sessionController,
                                    decoration: InputDecoration(
                                      hintText: 'e.g. 2021-2022',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) {
                                        return 'Session is required';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Action Buttons
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
                                height: 48,
                                child: ElevatedButton.icon(
                                  onPressed: _generateAndIssueCertificate,
                                  icon: const Icon(Icons.verified, color: Colors.white),
                                  label: const Text(
                                    'Generate & Save Certificate',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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
}
