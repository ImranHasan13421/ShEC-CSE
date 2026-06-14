import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/job_state.dart';

class JobDetailScreen extends StatefulWidget {
  final JobItem? job;
  final String? jobId;

  const JobDetailScreen({super.key, this.job, this.jobId});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  JobItem? _job;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _job = widget.job;
    if (_job == null && widget.jobId != null) {
      _fetchJob();
    }
  }

  Future<void> _fetchJob() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('jobs')
          .select()
          .eq('id', widget.jobId!)
          .single();
      
      if (mounted) {
        setState(() {
          _job = JobItem.fromJson(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching job: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load job details.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _launchURL(String urlString) async {
    if (urlString.isEmpty) return;
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $urlString');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const iconColor = Colors.blue;
    const typeColor = Colors.teal;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: colors.surface,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: colors.onSurface),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _job == null) {
      return Scaffold(
        backgroundColor: colors.surface,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: colors.onSurface),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Text(_error ?? 'Job not found.', style: TextStyle(color: colors.error)),
        ),
      );
    }

    final job = _job!;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(job.company, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              background: Container(
                color: iconColor.withOpacity(0.1),
                child: const Center(
                  child: Icon(Icons.work, size: 80, color: iconColor),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(job.role, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(job.company, style: TextStyle(fontSize: 18, color: colors.primary, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: typeColor.withOpacity(0.3)),
                        ),
                        child: Text(job.jobType, style: const TextStyle(color: typeColor, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildInfoRow(context, Icons.location_on, 'Location', job.location),
                  _buildInfoRow(context, Icons.monetization_on, 'Salary', job.salary),
                  _buildInfoRow(context, Icons.calendar_today, 'Deadline', job.deadline),
                  const Divider(height: 40),
                  const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(
                    job.description.isNotEmpty ? job.description : 'No description provided.',
                    style: TextStyle(fontSize: 15, height: 1.6, color: colors.onSurface.withOpacity(0.8)),
                  ),
                  const SizedBox(height: 100), // Space for bottom button
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.surface,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _launchURL(job.applyUrl),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Apply Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colors.primary.withOpacity(0.7)),
          const SizedBox(width: 12),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(value.isNotEmpty ? value : 'Not specified', style: TextStyle(color: colors.onSurface.withOpacity(0.6))),
        ],
      ),
    );
  }
}
