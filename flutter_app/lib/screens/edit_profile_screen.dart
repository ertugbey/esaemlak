import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

/// Edit profile screen for updating name, phone, and photo
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _adController = TextEditingController();
  final _soyadController = TextEditingController();
  final _telefonController = TextEditingController();
  
  File? _selectedImage;
  bool _isLoading = false;
  bool _hasChanges = false;
  String? _currentPhotoUrl;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  void _loadCurrentUser() {
    final user = context.read<AuthProvider>().currentUser;
    if (user != null) {
      _adController.text = user.ad;
      _soyadController.text = user.soyad;
      _telefonController.text = user.telefon;
      _currentPhotoUrl = user.profilFotoUrl;
    }
    
    _adController.addListener(_onFieldChanged);
    _soyadController.addListener(_onFieldChanged);
    _telefonController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  @override
  void dispose() {
    _adController.dispose();
    _soyadController.dispose();
    _telefonController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Kamera ile çek'),
              onTap: () async {
                Navigator.pop(ctx);
                final picked = await picker.pickImage(
                  source: ImageSource.camera,
                  maxWidth: 800,
                  maxHeight: 800,
                  imageQuality: 85,
                );
                if (picked != null) {
                  setState(() {
                    _selectedImage = File(picked.path);
                    _hasChanges = true;
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeriden seç'),
              onTap: () async {
                Navigator.pop(ctx);
                final picked = await picker.pickImage(
                  source: ImageSource.gallery,
                  maxWidth: 800,
                  maxHeight: 800,
                  imageQuality: 85,
                );
                if (picked != null) {
                  setState(() {
                    _selectedImage = File(picked.path);
                    _hasChanges = true;
                  });
                }
              },
            ),
            if (_currentPhotoUrl != null || _selectedImage != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Fotoğrafı kaldır', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _selectedImage = null;
                    _currentPhotoUrl = null;
                    _hasChanges = true;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final api = ApiService();
      
      // If there's a selected image, upload it first
      String? photoUrl;
      if (_selectedImage != null) {
        try {
          final urls = await api.uploadPhotos([_selectedImage!.path]);
          if (urls.isNotEmpty) {
            photoUrl = urls.first;
          }
        } catch (e) {
          debugPrint('Photo upload failed: $e');
        }
      }
      
      // Build update data
      final updateData = <String, dynamic>{
        'ad': _adController.text.trim(),
        'soyad': _soyadController.text.trim(),
        'telefon': _telefonController.text.trim(),
      };
      if (photoUrl != null) {
        updateData['profilFoto'] = photoUrl;
      }
      
      final result = await api.updateProfile(updateData);
      
      if (mounted) {
        final hasError = result['error'] != null;
        if (hasError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error']),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          // Refresh user data in AuthProvider
          await context.read<AuthProvider>().checkAuth();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil güncellendi'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profili Düzenle'),
        centerTitle: true,
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _isLoading ? null : _saveProfile,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Kaydet'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Photo
              Center(
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
                        backgroundImage: _selectedImage != null
                            ? FileImage(_selectedImage!)
                            : (_currentPhotoUrl != null
                                ? NetworkImage(_currentPhotoUrl!)
                                : null) as ImageProvider?,
                        child: (_selectedImage == null && _currentPhotoUrl == null)
                            ? Icon(
                                Icons.person,
                                size: 48,
                                color: AppTheme.primaryBlue,
                              )
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 8),
              
              TextButton(
                onPressed: _pickImage,
                child: const Text('Fotoğrafı Değiştir'),
              ),
              
              const SizedBox(height: 24),
              
              // Name fields
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _adController,
                      decoration: const InputDecoration(
                        labelText: 'Ad',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (v) => v?.isEmpty == true ? 'Ad gerekli' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _soyadController,
                      decoration: const InputDecoration(
                        labelText: 'Soyad',
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (v) => v?.isEmpty == true ? 'Soyad gerekli' : null,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Phone
              TextFormField(
                controller: _telefonController,
                decoration: const InputDecoration(
                  labelText: 'Telefon',
                  prefixIcon: Icon(Icons.phone_outlined),
                  hintText: '05XX XXX XX XX',
                ),
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v?.isEmpty == true) return 'Telefon gerekli';
                  if (v!.length < 10) return 'Geçerli telefon girin';
                  return null;
                },
              ),
              
              const SizedBox(height: 32),
              
              // Info text
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'E-posta adresinizi değiştirmek için destek ekibiyle iletişime geçin.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
