import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

/// Listing action buttons for share, report, and favorite
class ListingActions extends StatefulWidget {
  final Listing listing;
  final bool showLabels;

  const ListingActions({
    super.key,
    required this.listing,
    this.showLabels = true,
  });

  @override
  State<ListingActions> createState() => _ListingActionsState();
}

class _ListingActionsState extends State<ListingActions> {
  bool _isReporting = false;

  void _shareListing() {
    final listing = widget.listing;
    final shareText = '''
🏠 ${listing.baslik}

💰 ${listing.formattedPrice}
📍 ${listing.location}
${listing.odaSayisi != null ? '🛏️ ${listing.odaSayisi}' : ''}
📐 ${listing.displayMetrekare} m²

🔗 EsaEmlak'ta görüntüle:
https://esaemlak.com/listings/${listing.id}
''';

    Share.share(shareText, subject: listing.baslik);
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (context) => _ReportDialog(
        listingId: widget.listing.id,
        listingTitle: widget.listing.baslik,
        onReported: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Şikayetiniz alındı. İncelenecektir.'),
                ],
              ),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.showLabels) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            icon: Icons.share,
            label: 'Paylaş',
            onTap: _shareListing,
            color: Colors.blue,
          ),
          _buildActionButton(
            icon: Icons.report_outlined,
            label: 'Şikayet',
            onTap: _showReportDialog,
            color: Colors.orange,
          ),
          _buildActionButton(
            icon: Icons.favorite_border,
            label: 'Favori',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Favorilere eklendi')),
              );
            },
            color: Colors.red,
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: _shareListing,
          tooltip: 'Paylaş',
        ),
        IconButton(
          icon: const Icon(Icons.report_outlined),
          onPressed: _showReportDialog,
          tooltip: 'Şikayet Et',
        ),
        IconButton(
          icon: const Icon(Icons.favorite_border),
          onPressed: () {},
          tooltip: 'Favorilere Ekle',
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Report dialog for listing complaints
class _ReportDialog extends StatefulWidget {
  final String listingId;
  final String listingTitle;
  final VoidCallback onReported;

  const _ReportDialog({
    required this.listingId,
    required this.listingTitle,
    required this.onReported,
  });

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  String? _selectedReason;
  final _detailsController = TextEditingController();
  bool _isSubmitting = false;

  static const _reportReasons = [
    'Yanlış / Yanıltıcı Bilgi',
    'Sahte İlan',
    'Fiyat Manipülasyonu',
    'Uygunsuz İçerik',
    'İlan Artık Geçerli Değil',
    'Kişisel Bilgi İhlali',
    'Diğer',
  ];

  Future<void> _submitReport() async {
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir şikayet nedeni seçin')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // TODO: Implement backend API call
      // await ApiService().reportListing(
      //   listingId: widget.listingId,
      //   reason: _selectedReason!,
      //   details: _detailsController.text,
      // );
      
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        Navigator.of(context).pop();
        widget.onReported();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }

    setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.report, color: Colors.orange[700]),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('İlanı Şikayet Et', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Listing title
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.home, size: 20, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.listingTitle,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Reason selection
            const Text(
              'Şikayet Nedeni',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ..._reportReasons.map((reason) => RadioListTile<String>(
              value: reason,
              groupValue: _selectedReason,
              onChanged: (v) => setState(() => _selectedReason = v),
              title: Text(reason, style: const TextStyle(fontSize: 14)),
              dense: true,
              contentPadding: EdgeInsets.zero,
            )),
            
            const SizedBox(height: 16),
            
            // Additional details
            const Text(
              'Ek Detaylar (Opsiyonel)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _detailsController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Şikayetinizle ilgili ek bilgi...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submitReport,
          style: FilledButton.styleFrom(backgroundColor: Colors.orange),
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Şikayet Gönder'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }
}
