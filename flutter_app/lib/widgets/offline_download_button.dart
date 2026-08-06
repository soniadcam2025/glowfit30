import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/media_downloader.dart';

const _pink = Color(0xFFFF136B);
const _darkText = Color(0xFF1A1A2E);

/// Downloads a set of media for offline use, and shows where it has got to.
///
/// Three states in one control, because they are the same idea at different
/// points: not saved, saving, saved. A separate button per state would make the
/// header jump as the download progresses.
class OfflineDownloadButton extends StatefulWidget {
  /// Identifies this bundle, so a download started here is distinguishable from
  /// one running for another workout.
  final String id;

  /// Everything needed to run offline. Use `offlineUrlsFor` to build it.
  final Iterable<String?> urls;

  final String label;

  const OfflineDownloadButton({
    super.key,
    required this.id,
    required this.urls,
    this.label = 'Workout',
  });

  @override
  State<OfflineDownloadButton> createState() => _OfflineDownloadButtonState();
}

class _OfflineDownloadButtonState extends State<OfflineDownloadButton> {
  bool _busy = false;

  bool get _saved => MediaDownloader.instance.hasAll(widget.urls);

  Future<void> _start() async {
    if (_busy) return;
    setState(() => _busy = true);
    // force: the user pressed a button, which is exactly the consent the
    // automatic Wi-Fi rule exists to stand in for when nobody has asked.
    final ok = await MediaDownloader.instance
        .download(widget.id, widget.urls, label: widget.label, force: true);
    if (!mounted) return;
    setState(() => _busy = false);
    _tell(ok
        ? 'Saved for offline. This workout now plays without a connection.'
        : 'Could not save everything. Check your connection and try again.');
  }

  Future<void> _remove() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove download?',
            style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w700, color: _darkText)),
        content: Text(
          'The files are deleted from this device. The workout still works '
          'with a connection.',
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Keep', style: GoogleFonts.poppins(color: Colors.grey[600])),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Remove', style: GoogleFonts.poppins(color: _pink)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await MediaDownloader.instance.remove(widget.urls);
    if (!mounted) return;
    setState(() {});
    _tell('Download removed.');
  }

  void _tell(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: GoogleFonts.poppins(fontSize: 12.5))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DownloadProgress?>(
      valueListenable: MediaDownloader.instance.progress,
      builder: (context, progress, _) {
        final mine = progress != null && progress.id == widget.id;
        final running = mine && progress.running;

        return GestureDetector(
          onTap: running
              ? MediaDownloader.instance.cancel
              : (_saved ? _remove : _start),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: _icon(running, progress)),
          ),
        );
      },
    );
  }

  Widget _icon(bool running, DownloadProgress? progress) {
    if (running || _busy) {
      return SizedBox(
        width: 20,
        height: 20,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              strokeWidth: 2,
              // Indeterminate until there is something real to show, so the
              // ring never sits frozen at zero looking broken.
              value: (progress != null && progress.total > 0 && progress.completed > 0)
                  ? progress.fraction
                  : null,
              backgroundColor: const Color(0xFFEDEDED),
              valueColor: const AlwaysStoppedAnimation(_pink),
            ),
            const Icon(Icons.close_rounded, size: 10, color: _darkText),
          ],
        ),
      );
    }
    if (_saved) {
      return const Icon(Icons.offline_pin_rounded, size: 20, color: _pink);
    }
    return const Icon(Icons.download_for_offline_outlined,
        size: 20, color: _darkText);
  }
}
