import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/gallery_state.dart';
import 'package:ShEC_CSE/core/utils/snackbar_utils.dart';

class GalleryDetailScreen extends StatefulWidget {
  final GalleryItem item;
  const GalleryDetailScreen({super.key, required this.item});

  @override
  State<GalleryDetailScreen> createState() => _GalleryDetailScreenState();
}

class _GalleryDetailScreenState extends State<GalleryDetailScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openFullScreenViewer(BuildContext context, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenImageViewer(
          imagePaths: widget.item.imagePaths.isNotEmpty
              ? widget.item.imagePaths
              : [widget.item.imagePath],
          initialPage: initialIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const defaultColor = Colors.blue;
    final hasMultipleImages = widget.item.imagePaths.length > 1;

    return Scaffold(
      backgroundColor: colors.surface,
      body: CustomScrollView(
        slivers: [
          // ── Animated Collapsible Image AppBar ──
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            stretch: true,
            backgroundColor: colors.surface,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (!hasMultipleImages) ...[
                    Hero(
                      tag: 'gallery_img_${widget.item.id}',
                      child: GestureDetector(
                        onTap: () => _openFullScreenViewer(context, 0),
                        child: widget.item.imagePath.isNotEmpty
                            ? Image.network(
                                widget.item.imagePath,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: defaultColor.withValues(alpha: 0.15),
                                  child: const Center(child: Icon(Icons.photo_library, size: 80, color: Colors.grey)),
                                ),
                              )
                            : Container(
                                color: defaultColor.withValues(alpha: 0.15),
                                child: const Center(child: Icon(Icons.photo_library, size: 80, color: Colors.grey)),
                              ),
                      ),
                    ),
                  ] else ...[
                    PageView.builder(
                      controller: _pageController,
                      onPageChanged: (page) {
                        setState(() {
                          _currentPage = page;
                        });
                      },
                      itemCount: widget.item.imagePaths.length,
                      itemBuilder: (context, index) {
                        final imagePath = widget.item.imagePaths[index];
                        return GestureDetector(
                          onTap: () => _openFullScreenViewer(context, index),
                          child: Hero(
                            // Only tag the first image with active hero to prevent duplicate Hero tags exception
                            tag: index == 0 ? 'gallery_img_${widget.item.id}' : 'gallery_img_${widget.item.id}_$index',
                            child: Image.network(
                              imagePath,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: defaultColor.withValues(alpha: 0.15),
                                child: const Center(child: Icon(Icons.photo_library, size: 80, color: Colors.grey)),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    // Paging micro-dots indicator
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white12, width: 0.8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(
                              widget.item.imagePaths.length,
                              (index) => AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeInOut,
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                width: _currentPage == index ? 16 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: _currentPage == index ? Colors.white : Colors.white.withValues(alpha: 0.45),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ── Title ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: defaultColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: defaultColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.photo_library, color: defaultColor, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          hasMultipleImages ? 'Gallery • ${widget.item.imagePaths.length} Photos' : 'Gallery',
                          style: const TextStyle(color: defaultColor, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Title
                  Text(widget.item.title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, height: 1.3)),
                  const SizedBox(height: 8),
                  if (widget.item.createdByName.isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.person_outline, size: 14, color: colors.onSurface.withValues(alpha: 0.5)),
                        const SizedBox(width: 4),
                        Text('Added by ${widget.item.createdByName}',
                            style: TextStyle(color: colors.onSurface.withValues(alpha: 0.5), fontSize: 13)),
                      ],
                    ),
                ],
              ),
            ),
          ),

          // ── Divider ──
          const SliverToBoxAdapter(
            child: Padding(padding: EdgeInsets.symmetric(horizontal: 24), child: Divider()),
          ),

          // ── Description ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
              child: widget.item.description.isNotEmpty
                  ? Text(widget.item.description,
                      style: TextStyle(fontSize: 16, height: 1.7, color: colors.onSurface.withValues(alpha: 0.8)))
                  : Text('No description available.',
                      style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: colors.onSurface.withValues(alpha: 0.4))),
            ),
          ),
        ],
      ),
    );
  }
}

class FullScreenImageViewer extends StatefulWidget {
  final List<String> imagePaths;
  final int initialPage;

  const FullScreenImageViewer({
    super.key,
    required this.imagePaths,
    required this.initialPage,
  });

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentPage;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _pageController = PageController(initialPage: widget.initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _downloadImage() async {
    if (_isDownloading) return;
    
    setState(() {
      _isDownloading = true;
    });

    try {
      // 1. Check and request gallery access permission
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        final granted = await Gal.requestAccess();
        if (!granted) {
          throw Exception('Storage/Photo access permission denied.');
        }
      }

      // 2. Fetch the current image URL
      final imageUrl = widget.imagePaths[_currentPage];
      if (imageUrl.isEmpty) {
        throw Exception('Invalid image path URL.');
      }

      // 3. Download image bytes
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to download image from server (Status: ${response.statusCode}).');
      }

      // 4. Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final uri = Uri.parse(imageUrl);
      final filename = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'photo.webp';
      final fileExtension = p.extension(filename);
      final extension = fileExtension.isNotEmpty ? fileExtension : '.webp';
      
      final tempFile = File(p.join(tempDir.path, 'download_${DateTime.now().millisecondsSinceEpoch}$extension'));
      await tempFile.writeAsBytes(response.bodyBytes);

      // 5. Save to Gallery in specific album 'ShEC CSE'
      await Gal.putImage(tempFile.path, album: 'ShEC CSE');

      // 6. Delete temporary file
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      if (!mounted) return;
      SnackBarUtils.showSuccess(context, 'Successfully saved to gallery folder "ShEC CSE"!');
    } catch (e) {
      if (!mounted) return;
      SnackBarUtils.showError(context, e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 600;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Interactive Swipe Viewer ──
          PageView.builder(
            controller: _pageController,
            onPageChanged: (page) {
              setState(() {
                _currentPage = page;
              });
            },
            itemCount: widget.imagePaths.length,
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 1.0,
                maxScale: 4.0,
                clipBehavior: Clip.none,
                child: Center(
                  child: Image.network(
                    widget.imagePaths[index],
                    fit: BoxFit.contain,
                    loadingBuilder: (ctx, child, progress) {
                      if (progress == null) return child;
                      return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white));
                    },
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.broken_image, size: 64, color: Colors.white30),
                    ),
                  ),
                ),
              );
            },
          ),

          // ── Floating Header Overlay ──
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Glassy close button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white12),
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 22),
                  ),
                ),
                // Dynamic Page indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Text(
                    '${_currentPage + 1} / ${widget.imagePaths.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
                // Empty placeholder to balance the row
                const SizedBox(width: 40),
              ],
            ),
          ),

          // ── Premium Side Navigation Arrows (Tablet & Desktop only) ──
          if (isWide && widget.imagePaths.length > 1) ...[
            if (_currentPage > 0)
              Positioned(
                left: 24,
                top: 0,
                bottom: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white12),
                      ),
                      child: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
                    ),
                  ),
                ),
              ),
            if (_currentPage < widget.imagePaths.length - 1)
              Positioned(
                right: 24,
                top: 0,
                bottom: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white12),
                      ),
                      child: const Icon(Icons.chevron_right, color: Colors.white, size: 28),
                    ),
                  ),
                ),
              ),
          ],
          
          // ── Premium Floating Download Button (Bottom Right Corner) ──
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 24,
            right: 24,
            child: Tooltip(
              message: 'Save to Device Gallery',
              child: GestureDetector(
                onTap: _downloadImage,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black38,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _isDownloading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.download_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
