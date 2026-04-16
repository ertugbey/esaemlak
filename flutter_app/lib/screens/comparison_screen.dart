import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/models.dart';
import '../providers/comparison_provider.dart';
import '../theme/app_theme.dart';

/// Side-by-side comparison screen for up to 3 listings
class ComparisonScreen extends StatelessWidget {
  const ComparisonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İlan Karşılaştır'),
        actions: [
          TextButton(
            onPressed: () {
              context.read<ComparisonProvider>().clearAll();
              Navigator.pop(context);
            },
            child: const Text('Temizle'),
          ),
        ],
      ),
      body: Consumer<ComparisonProvider>(
        builder: (context, comparison, _) {
          if (comparison.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.compare_arrows, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Karşılaştırma listesi boş'),
                  SizedBox(height: 8),
                  Text(
                    'İlan detayından "Karşılaştır" butonuna tıklayın',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: _buildComparisonTable(context, comparison.listings),
            ),
          );
        },
      ),
    );
  }

  Widget _buildComparisonTable(BuildContext context, List<Listing> listings) {
    final columnWidth = MediaQuery.of(context).size.width / 
        (listings.length > 1 ? listings.length : 2);
    final clampedWidth = columnWidth.clamp(180.0, 250.0);

    return DataTable(
      columnSpacing: 12,
      columns: listings.map((listing) => DataColumn(
        label: SizedBox(
          width: clampedWidth - 24,
          child: Column(
            children: [
              // Remove button
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    context.read<ComparisonProvider>().removeFromComparison(listing.id);
                  },
                ),
              ),
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: listing.fotograflar.isNotEmpty 
                      ? listing.fotograflar.first 
                      : 'https://via.placeholder.com/100',
                  width: clampedWidth - 40,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 8),
              // Title
              Text(
                listing.baslik,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      )).toList(),
      rows: [
        _buildRow('Fiyat', listings.map((l) => Text(
          l.formattedPrice,
          style: TextStyle(
            color: AppTheme.primaryBlue,
            fontWeight: FontWeight.bold,
          ),
        )).toList()),
        _buildRow('Konum', listings.map((l) => Text(l.location, style: const TextStyle(fontSize: 12))).toList()),
        _buildRow('Kategori', listings.map((l) => Text(l.kategori)).toList()),
        _buildRow('İşlem', listings.map((l) => Text(l.islemTipiLabel)).toList()),
        _buildRow('Brüt m²', listings.map((l) => Text('${l.brutMetrekare ?? '-'}')).toList()),
        _buildRow('Net m²', listings.map((l) => Text('${l.netMetrekare ?? '-'}')).toList()),
        _buildRow('Oda', listings.map((l) => Text(l.odaSayisi ?? '-')).toList()),
        _buildRow('Bina Yaşı', listings.map((l) => Text(l.binaYasi ?? '-')).toList()),
        _buildRow('Kat', listings.map((l) => Text('${l.bulunduguKat ?? '-'}')).toList()),
        _buildRow('Isıtma', listings.map((l) => Text(l.isitmaTipi ?? '-')).toList()),
        _buildRow('Eşyalı', listings.map((l) => _buildCheckIcon(l.esyali)).toList()),
        _buildRow('Balkon', listings.map((l) => _buildCheckIcon(l.balkon)).toList()),
        _buildRow('Asansör', listings.map((l) => _buildCheckIcon(l.asansor)).toList()),
        _buildRow('Otopark', listings.map((l) => _buildCheckIcon(l.otopark)).toList()),
        _buildRow('Site', listings.map((l) => _buildCheckIcon(l.siteIcerisinde)).toList()),
        _buildRow('Havuz', listings.map((l) => _buildCheckIcon(l.havuz)).toList()),
        _buildRow('Güvenlik', listings.map((l) => _buildCheckIcon(l.guvenlik)).toList()),
        _buildRow('Krediye Uygun', listings.map((l) => _buildCheckIcon(l.krediyeUygun)).toList()),
        _buildRow('m² Fiyatı', listings.map((l) {
          final m2 = l.brutMetrekare ?? l.netMetrekare ?? 1;
          final pricePerM2 = l.fiyat / m2;
          return Text('${pricePerM2.toStringAsFixed(0)} TL/m²', style: const TextStyle(fontSize: 12));
        }).toList()),
      ],
    );
  }

  DataRow _buildRow(String label, List<Widget> cells) {
    return DataRow(
      cells: [
        DataCell(
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ),
        ...cells.map((c) => DataCell(SizedBox(width: 120, child: c))),
      ].skip(1).take(cells.length).toList(), // Skip label, take cells
    );
  }

  Widget _buildCheckIcon(bool value) {
    return Icon(
      value ? Icons.check_circle : Icons.cancel,
      color: value ? Colors.green : Colors.grey[400],
      size: 20,
    );
  }
}

/// Floating comparison bar that appears when items are added
class ComparisonBar extends StatelessWidget {
  const ComparisonBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ComparisonProvider>(
      builder: (context, comparison, _) {
        if (comparison.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Preview images
              ...comparison.listings.take(3).map((listing) => Container(
                margin: const EdgeInsets.only(right: 8),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white, width: 2),
                  image: DecorationImage(
                    image: CachedNetworkImageProvider(
                      listing.fotograflar.isNotEmpty 
                          ? listing.fotograflar.first 
                          : 'https://via.placeholder.com/36',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              )),
              const SizedBox(width: 8),
              Text(
                '${comparison.count} ilan',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ComparisonScreen()),
                  );
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.primaryBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('Karşılaştır'),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Button to add/remove listing from comparison
class CompareButton extends StatelessWidget {
  final Listing listing;
  final bool showText;

  const CompareButton({
    super.key,
    required this.listing,
    this.showText = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ComparisonProvider>(
      builder: (context, comparison, _) {
        final isInComparison = comparison.isInComparison(listing.id);
        final isFull = comparison.isFull;

        return IconButton(
          icon: Icon(
            isInComparison
                ? Icons.compare_arrows
                : Icons.add_circle_outline,
            color: isInComparison 
                ? AppTheme.primaryBlue 
                : isFull 
                    ? Colors.grey 
                    : null,
          ),
          tooltip: isInComparison
              ? 'Karşılaştırmadan Çıkar'
              : isFull
                  ? 'Maksimum 3 ilan karşılaştırabilirsiniz'
                  : 'Karşılaştırmaya Ekle',
          onPressed: () {
            final wasAdded = comparison.toggleComparison(listing);
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  wasAdded
                      ? comparison.isFull
                          ? 'Maksimum karşılaştırma sayısına ulaşıldı'
                          : 'Karşılaştırmaya eklendi'
                      : 'Karşılaştırmadan çıkarıldı',
                ),
                duration: const Duration(seconds: 2),
                action: wasAdded ? SnackBarAction(
                  label: 'Karşılaştır',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ComparisonScreen()),
                    );
                  },
                ) : null,
              ),
            );
          },
        );
      },
    );
  }
}
