import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

/// Agency/Store page screen showing corporate profile and their listings
class StorePageScreen extends StatefulWidget {
  final String agencyId;

  const StorePageScreen({super.key, required this.agencyId});

  @override
  State<StorePageScreen> createState() => _StorePageScreenState();
}

class _StorePageScreenState extends State<StorePageScreen> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _agency;
  List<Listing> _listings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAgency();
  }

  Future<void> _loadAgency() async {
    setState(() => _isLoading = true);
    try {
      // TODO: Implement API method
      // final agency = await _api.getAgency(widget.agencyId);
      // final listings = await _api.getAgencyListings(widget.agencyId);
      
      // Mock data for now
      _agency = {
        'id': widget.agencyId,
        'firmaAdi': 'Elite Gayrimenkul',
        'logo': 'https://images.unsplash.com/photo-1560518883-ce09059eeffa?w=200',
        'kapakFoto': 'https://images.unsplash.com/photo-1497366216548-37526070297c?w=800',
        'telefon': '+90 212 555 0123',
        'email': 'info@elitegayrimenkul.com',
        'website': 'www.elitegayrimenkul.com',
        'il': 'İstanbul',
        'ilce': 'Beşiktaş',
        'adres': 'Levent Mah. Nispetiye Cad. No:45',
        'hakkinda': 'Elite Gayrimenkul olarak 15 yıldır İstanbul\'un en prestijli bölgelerinde hizmet vermekteyiz. Güvenilir ve şeffaf hizmet anlayışımızla binlerce müşterimize hayallerindeki eve kavuşmalarında yardımcı olduk.',
        'kurulusYili': 2009,
        'onaylanmis': true,
        'calismaSaatleri': '09:00 - 19:00',
        'calismaGunleri': ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi'],
        'toplamIlan': 47,
        'aktifIlan': 32,
        'puan': 4.7,
        'yorumSayisi': 89,
      };
    } catch (e) {
      debugPrint('Error loading agency: $e');
    }
    setState(() => _isLoading = false);
  }

  void _makeCall(String phone) async {
    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _sendEmail(String email) async {
    final url = Uri.parse('mailto:$email');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _openWebsite(String website) async {
    final url = Uri.parse(website.startsWith('http') ? website : 'https://$website');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_agency == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Emlak Ofisi')),
        body: const Center(child: Text('Emlak ofisi bulunamadı')),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Cover photo and logo
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: _agency!['kapakFoto'] ?? '',
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: Colors.grey[300]),
                    errorWidget: (_, __, ___) => Container(color: Colors.grey[300]),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -40),
              child: Column(
                children: [
                  // Logo and Company Info
                  _buildHeader(),
                  
                  const SizedBox(height: 16),
                  
                  // Contact buttons
                  _buildContactButtons(),
                  
                  const SizedBox(height: 24),
                  
                  // Stats
                  _buildStats(),
                  
                  const SizedBox(height: 24),
                  
                  // About section
                  _buildAboutSection(),
                  
                  const SizedBox(height: 24),
                  
                  // Working hours
                  _buildWorkingHours(),
                  
                  const SizedBox(height: 24),
                  
                  // Listings section header
                  _buildListingsHeader(),
                ],
              ),
            ),
          ),
          
          // Listings grid
          // TODO: Add listings grid when API is ready
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('İlanlar yüklenecek...'),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildHeader() {
    final isVerified = _agency!['onaylanmis'] as bool? ?? false;
    
    return Column(
      children: [
        // Logo
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
              ),
            ],
            image: DecorationImage(
              image: CachedNetworkImageProvider(_agency!['logo'] ?? ''),
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        // Company name with verified badge
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _agency!['firmaAdi'] ?? '',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isVerified) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 14),
              ),
            ],
          ],
        ),
        
        const SizedBox(height: 4),
        
        // Location
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_on, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              '${_agency!['ilce']}, ${_agency!['il']}',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        
        // Rating
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 18),
            const SizedBox(width: 4),
            Text(
              '${_agency!['puan']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              ' (${_agency!['yorumSayisi']} yorum)',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContactButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _makeCall(_agency!['telefon']),
              icon: const Icon(Icons.phone),
              label: const Text('Ara'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: () => _sendEmail(_agency!['email'] ?? ''),
              icon: const Icon(Icons.email),
              label: const Text('E-posta'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: AppTheme.primaryBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('${_agency!['aktifIlan']}', 'Aktif İlan'),
            _buildStatDivider(),
            _buildStatItem('${_agency!['toplamIlan']}', 'Toplam İlan'),
            _buildStatDivider(),
            _buildStatItem('${_agency!['kurulusYili']}', 'Kuruluş'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryBlue,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(width: 1, height: 40, color: Colors.grey[300]);
  }

  Widget _buildAboutSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hakkımızda',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _agency!['hakkinda'] ?? '',
            style: const TextStyle(height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkingHours() {
    final hours = _agency!['calismaSaatleri'] ?? '';
    final days = (_agency!['calismaGunleri'] as List<dynamic>?)?.join(', ') ?? '';
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.access_time, color: AppTheme.primaryBlue),
                const SizedBox(width: 8),
                const Text(
                  'Çalışma Saatleri',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(hours, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 4),
            Text(days, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildListingsHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'İlanları',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          TextButton(
            onPressed: () {},
            child: const Text('Tümünü Gör'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_agency!['website'] != null)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _openWebsite(_agency!['website']),
                icon: const Icon(Icons.language),
                label: const Text('Web Sitesi'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          if (_agency!['website'] != null) const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: () => _makeCall(_agency!['telefon']),
              icon: const Icon(Icons.phone),
              label: const Text('Hemen Ara'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: AppTheme.accentTeal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
