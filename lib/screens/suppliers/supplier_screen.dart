import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../models/supplier_model.dart';
import '../../providers/supplier_provider.dart';
import '../../utils/theme.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/contact_actions.dart';
import '../../widgets/profile_avatar_icon.dart';

class SupplierScreen extends ConsumerStatefulWidget {
  const SupplierScreen({super.key});

  @override
  ConsumerState<SupplierScreen> createState() => _SupplierScreenState();
}

class _SupplierScreenState extends ConsumerState<SupplierScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final suppliers = ref.watch(supplierProvider);

    final filteredSuppliers = suppliers.where((supplier) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return supplier.name.toLowerCase().contains(q) ||
          supplier.contactPerson.toLowerCase().contains(q) ||
          supplier.phone.toLowerCase().contains(q) ||
          supplier.email.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFA),
      drawer: const AppDrawer(),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.black87),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Row(
          children: const [
            Text(
              'PharmaLogic',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: AppTheme.primaryGreen,
              ),
            ),
          ],
        ),
        actions: const [
          ProfileAvatarIcon(radius: 20),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Title
            const Text(
              'Suppliers Directory',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Manage and contact your authorized medical distributors.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),

            // Onboard Supplier Card (Add Supplier) - Prominent Top Position
            _buildOnboardSupplierCard(),
            const SizedBox(height: 20),

            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
                decoration: InputDecoration(
                  hintText: 'Search by supplier name, contact, phone...',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                  suffixIcon: Icon(Icons.tune_rounded, color: Colors.grey[500]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Supplier Cards List
            ...filteredSuppliers.map((supplier) => _buildSupplierCard(supplier)),

            const SizedBox(height: 20),

            // Network Health Card
            _buildNetworkHealthCard(suppliers.length),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSupplierCard(Supplier supplier) {
    IconData iconData;
    Color iconBgColor;
    Color iconColor;

    switch (supplier.iconType) {
      case 'surgical':
        iconData = Icons.medical_services_outlined;
        iconBgColor = const Color(0xFFE3F2FD);
        iconColor = const Color(0xFF1976D2);
        break;
      case 'pill':
        iconData = Icons.medication_outlined;
        iconBgColor = const Color(0xFFFFF3E0);
        iconColor = const Color(0xFFF57C00);
        break;
      case 'biotech':
        iconData = Icons.science_outlined;
        iconBgColor = const Color(0xFFF3E5F5);
        iconColor = const Color(0xFF7B1FA2);
        break;
      case 'truck':
      default:
        iconData = Icons.local_shipping_outlined;
        iconBgColor = const Color(0xFFE8F5E9);
        iconColor = AppTheme.primaryGreen;
        break;
    }

    Color statusBgColor;
    Color statusTextColor;
    switch (supplier.status) {
      case 'Primary Partner':
        statusBgColor = const Color(0xFFE8EAF6);
        statusTextColor = const Color(0xFF3F51B5);
        break;
      case 'Expediting':
        statusBgColor = const Color(0xFFFFF8E1);
        statusTextColor = const Color(0xFFF57F17);
        break;
      case 'Active Vendor':
      default:
        statusBgColor = const Color(0xFFE8F5E9);
        statusTextColor = const Color(0xFF2E7D32);
        break;
    }

    final hasBill = supplier.billImagePath != null && supplier.billImagePath!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row (Icon + Status Pill)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(iconData, color: iconColor, size: 22),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    supplier.status,
                    style: TextStyle(
                      color: statusTextColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Supplier Name
            Text(
              supplier.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),

            // Contact Person
            if (supplier.contactPerson.isNotEmpty)
              Row(
                children: [
                  Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      supplier.contactPerson,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),

            // Category tags (if present)
            if (supplier.categories.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: supplier.categories.map((cat) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            // Attached Bill Banner (if any)
            if (hasBill) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.receipt_long, color: AppTheme.primaryGreen, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Supplier Bill Attached',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _viewAttachedBill(supplier),
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('View Bill', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primaryGreen,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Call & WhatsApp Action Buttons Component
            ContactActionButtons(
              phoneNumber: supplier.phone,
              supplierName: supplier.name,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardSupplierCard() {
    return InkWell(
      onTap: _showAddSupplierDialog,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.primaryGreen.withValues(alpha: 0.3),
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: AppTheme.primaryGreen, size: 24),
            ),
            const SizedBox(height: 12),
            const Text(
              'Onboard Supplier',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Add a new distributor and attach their bill photo',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkHealthCard(int totalSuppliers) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Network Health',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Suppliers',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              Text(
                '$totalSuppliers',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: 0.992,
              minHeight: 8,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Compliance Rate',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const Text(
                '99.2%',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Compliance Rate: 99.2% - All suppliers active & verified.'),
                    backgroundColor: AppTheme.primaryGreen,
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryGreen,
                side: const BorderSide(color: AppTheme.primaryGreen),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'View Compliance Report',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _viewAttachedBill(Supplier supplier) {
    showDialog(
      context: context,
      builder: (context) {
        final hasLocalFile = supplier.billImagePath != null &&
            supplier.billImagePath!.isNotEmpty &&
            File(supplier.billImagePath!).existsSync();

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Bill Photo: ${supplier.name}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                if (supplier.contactPerson.isNotEmpty)
                  Text('Contact: ${supplier.contactPerson}', style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 16),

                if (hasLocalFile)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: InteractiveViewer(
                      child: Image.file(
                        File(supplier.billImagePath!),
                        fit: BoxFit.contain,
                        height: 320,
                        width: double.infinity,
                      ),
                    ),
                  )
                else
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.receipt_long, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('Bill Photo Attached', style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  void _showAddSupplierDialog() {
    final nameCtrl = TextEditingController();
    final personCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();

    File? billImageFile;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              Future<void> pickBillImage(ImageSource source) async {
                try {
                  XFile? picked;
                  final picker = ImagePicker();

                  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
                    if (source == ImageSource.camera) {
                      final status = await Permission.camera.request();
                      if (status.isDenied || status.isPermanentlyDenied) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Camera permission is required to capture live photo.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                    }
                    picked = await picker.pickImage(
                      source: source,
                      imageQuality: 85,
                      maxWidth: 1200,
                      maxHeight: 1600,
                    );
                  } else {
                    // Desktop (Linux / Windows / macOS) or Web platform
                    try {
                      if (source == ImageSource.camera) {
                        try {
                          picked = await picker.pickImage(source: ImageSource.camera);
                        } catch (_) {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.image,
                            allowMultiple: false,
                            dialogTitle: 'Capture / Select Bill Image',
                          );
                          if (result != null && result.files.single.path != null) {
                            picked = XFile(result.files.single.path!);
                          }
                        }
                      } else {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.image,
                          allowMultiple: false,
                          dialogTitle: 'Select Bill Image from Gallery',
                        );
                        if (result != null && result.files.single.path != null) {
                          picked = XFile(result.files.single.path!);
                        } else {
                          picked = await picker.pickImage(source: ImageSource.gallery);
                        }
                      }
                    } catch (_) {
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.image,
                        allowMultiple: false,
                      );
                      if (result != null && result.files.single.path != null) {
                        picked = XFile(result.files.single.path!);
                      }
                    }
                  }

                  if (picked != null) {
                    setModalState(() {
                      billImageFile = File(picked!.path);
                    });
                  }
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error adding image: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }

              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Onboard New Supplier',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Supplier / Company Name *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: personCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Contact Person Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: phoneCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Phone Number',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email Address',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // --- PRODUCTION ATTACH SUPPLIER BILL SECTION ---
                    const Text(
                      'Attach Supplier Bill (Photo/Receipt)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Capture or choose bill image provided by the supplier.',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 12),

                    if (billImageFile != null)
                      Stack(
                        children: [
                          Container(
                            height: 160,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.primaryGreen, width: 2),
                              image: DecorationImage(
                                image: FileImage(billImageFile!),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: InkWell(
                              onTap: () => setModalState(() => billImageFile = null),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, color: Colors.white, size: 18),
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => pickBillImage(ImageSource.camera),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppTheme.primaryGreen,
                                side: const BorderSide(color: AppTheme.primaryGreen, width: 1.5),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Take Photo (Camera)', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => pickBillImage(ImageSource.gallery),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryGreen,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              icon: const Icon(Icons.photo_library),
                              label: const Text('Choose (Gallery)', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: Colors.white,
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          if (nameCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter Supplier / Company Name'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          final newSupplier = Supplier(
                            id: '',
                            name: nameCtrl.text.trim(),
                            contactPerson: personCtrl.text.trim(),
                            phone: phoneCtrl.text.trim(),
                            email: emailCtrl.text.trim(),
                            status: 'Active Vendor',
                            categories: const ['General Supplies'],
                            iconType: 'truck',
                            billImagePath: billImageFile?.path,
                          );

                          ref.read(supplierProvider.notifier).addSupplier(newSupplier);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Supplier onboarded & bill saved successfully!'),
                              backgroundColor: AppTheme.primaryGreen,
                            ),
                          );
                        },
                        child: const Text(
                          'ONBOARD SUPPLIER & SAVE',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
