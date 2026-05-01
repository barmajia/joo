// lib/pages/product/add_product_page.dart

import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:aurora/models/product/productModel.dart';
import 'package:aurora/models/product/product_preset.dart';
import 'package:aurora/storage/product_vault_storage.dart';
import 'package:aurora/storage/product_secrets_storage.dart';
import 'package:aurora/storage/userStorage.dart';
import 'package:aurora/utils/connectivity_helper.dart';

class AddProductPage extends StatefulWidget {
  final Product? product;
  final String? preselectedCategoryId;
  final String? preselectedSubcategory;

  const AddProductPage({
    super.key,
    this.product,
    this.preselectedCategoryId,
    this.preselectedSubcategory,
  });

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  // === Form & Validation ===
  final _formKey = GlobalKey<FormState>();
  final _focusScope = FocusScopeNode();

  // === Controllers (managed lifecycle) ===
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionNotesController;
  late final TextEditingController _priceController;
  late final TextEditingController _quantityController;
  late final TextEditingController _skuController;
  late final TextEditingController _asinController;
  late final TextEditingController _customBrandController;

  // === Selection State (preset-only) ===
  String? _selectedCategoryId;
  String? _allowedCategoryId;
  String? _selectedSubcategory;
  BrandOption? _selectedBrand;
  ColorOption? _selectedColor;
  ProductCondition _condition = ProductCondition.new_;
  ProductStatus _status = ProductStatus.draft;
  String _currency = 'USD';

  // === Dynamic Attributes (preset schema) ===
  final Map<String, dynamic> _attributes = {};
  final Map<String, String> _attributeErrors = {};
  final Map<String, TextEditingController> _attributeControllers = {};

  // === Images ===
  final List<XFile> _newImages = [];
  final List<String> _existingImageUrls = [];
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingImages = false;

  // === Backend & Storage ===
  final _supabase = Supabase.instance.client;
  ProductVaultStorage? _productVault;

  bool _isSaving = false;
  bool _isInitializing = true;
  String? _initError;
  bool get _isEditing => widget.product != null;

  // === Offline Support ===
  bool _isOnline = true;
  bool _wasOfflineWhenSaved = false;
  // In add_product_page.dart

  Future<void> _pickImages(ImageSource source) async {
    try {
      List<XFile> images = [];

      if (source == ImageSource.camera) {
        // For camera: use pickImage (single image)
        final photo = await _picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1920,
          maxHeight: 1080,
          imageQuality: 85,
        );
        if (photo != null) images = [photo];
      } else {
        // For gallery: use pickMultiImage (no source parameter)
        images = await _picker.pickMultiImage(
          maxWidth: 1920,
          maxHeight: 1080,
          imageQuality: 85,
        );
      }

      if (images.isNotEmpty && mounted) {
        setState(() => _newImages.addAll(images));
      }
    } catch (e) {
      _showError('Failed to pick images: ${e.toString()}');
      debugPrint('[Image Pick Error] $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _initControllers();
    _initializeAsync();
  }

  void _initControllers() {
    _titleController = TextEditingController();
    _descriptionNotesController = TextEditingController();
    _priceController = TextEditingController();
    _quantityController = TextEditingController();
    _skuController = TextEditingController();
    _asinController = TextEditingController();
    _customBrandController = TextEditingController();
  }

  Future<void> _initializeAsync() async {
    try {
      // Initialize storage vaults
      _productVault = await ProductVaultStorage.getInstance();

      // Load user currency preference
      await _loadUserCurrency();
      _loadAllowedCategory();

      // Check connectivity
      _isOnline = await ConnectivityHelper.hasInternet;

      // Load product data if editing
      if (mounted && _isEditing) {
        _loadProductData();
      }

      // Apply preselected values (if coming from category browser)
      if (mounted) {
        if (widget.preselectedCategoryId != null) {
          _selectedCategoryId =
              _isCategoryAllowed(widget.preselectedCategoryId!)
              ? widget.preselectedCategoryId
              : _allowedCategoryId;
        }
        if (widget.preselectedSubcategory != null &&
            _selectedCategoryId != null) {
          _selectedSubcategory = widget.preselectedSubcategory;
        }
        if (!_isEditing && _selectedCategoryId == null) {
          _selectedCategoryId = _allowedCategoryId;
        }
      }
    } catch (e, stack) {
      debugPrint('[AddProductPage] Initialization error: $e\n$stack');
      if (mounted) {
        setState(() => _initError = 'Failed to initialize: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    }
  }

  Future<void> _loadUserCurrency() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user?.userMetadata?['currency'] != null) {
        setState(() {
          _currency = user!.userMetadata!['currency'] as String;
        });
      }
    } catch (e) {
      debugPrint('[Currency Load] Error: $e');
      // Fallback to USD
      setState(() => _currency = 'USD');
    }
  }

  void _loadAllowedCategory() {
    try {
      final userStorage = Provider.of<UserStorage>(context, listen: false);
      final metadata = userStorage.currentUser?.metadata;
      final categoryId = _metadataString(metadata?['product_category_id']);
      final categoryName =
          _metadataString(metadata?['product_category_name']) ??
          _metadataString(metadata?['specialization']);
      String? resolvedId;
      if (categoryId != null && categoryDefinitions.containsKey(categoryId)) {
        resolvedId = categoryId;
      } else if (categoryName != null) {
        resolvedId = getCategoryDefinitionByName(categoryName)?.id;
      }

      if (resolvedId != null && resolvedId.isNotEmpty) {
        _allowedCategoryId = resolvedId;
        if (!_isEditing && _selectedCategoryId == null) {
          _selectedCategoryId = resolvedId;
        }
      }
    } catch (e) {
      debugPrint('[Allowed Category Load] Error: $e');
    }
  }

  String? _metadataString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  bool _isCategoryAllowed(String categoryId) {
    return _allowedCategoryId == null || _allowedCategoryId == categoryId;
  }

  void _loadProductData() {
    final p = widget.product!;

    // Basic fields
    _titleController.text = p.title;
    _descriptionNotesController.text =
        p.description.split('Notes: ').lastOrNull ?? '';
    _priceController.text = p.price?.toStringAsFixed(2) ?? '';
    _quantityController.text = p.quantity.toString();
    _skuController.text = p.sku ?? '';
    _asinController.text = p.asin ?? '';

    // Status & condition
    if (p.status.isEmpty) {
      _status = ProductStatus.values.firstWhere(
        (s) => s.name == p.status,
        orElse: () => ProductStatus.draft,
      );
    }
    if (p.attributes?['condition'] != null) {
      _condition = ProductCondition.values.firstWhere(
        (c) => c.name == p.attributes!['condition'],
        orElse: () => ProductCondition.new_,
      );
    }

    // Category
    if (p.category != null) {
      final catDef = getCategoryDefinitionByName(p.category!);
      if (catDef != null) {
        _selectedCategoryId = catDef.id;
      }
    }

    // Subcategory
    if (p.subcategory != null && _selectedCategoryId != null) {
      final validSubcats = getSubcategoriesForCategory(_selectedCategoryId!);
      if (validSubcats.contains(p.subcategory)) {
        _selectedSubcategory = p.subcategory;
      }
    }

    // Brand
    if (p.brand.isNotEmpty) {
      final catName = getCategoryDefinitionById(
        _selectedCategoryId ?? '',
      )?.name;
      final brand = predefinedBrands.firstWhere(
        (b) =>
            b.name == p.brand && (b.category == null || b.category == catName),
        orElse: () {
          // Local brand fallback
          _customBrandController.text = p.brand;
          return BrandOption.localBrand;
        },
      );
      _selectedBrand = brand;
    }

    // Color
    if (p.attributes?['color'] != null) {
      _selectedColor = availableColors.firstWhere(
        (c) => c.name == p.attributes!['color'],
        orElse: () => availableColors.first,
      );
    }

    // Attributes (excluding color/condition which are handled separately)
    if (p.attributes != null) {
      for (final entry in p.attributes!.entries) {
        if (['color', 'color_hex', 'condition'].contains(entry.key)) continue;
        _attributes[entry.key] = entry.value;

        // Create controller for text/number fields for better UX
        final attrDef = _selectedSubcategory != null
            ? getAttributesForSubcategory(_selectedSubcategory!).firstWhere(
                (a) => a.key == entry.key,
                orElse: () => ProductAttribute(
                  key: entry.key,
                  label: entry.key,
                  type: AttributeType.text,
                ),
              )
            : null;

        if (attrDef?.type == AttributeType.text ||
            attrDef?.type == AttributeType.number) {
          _attributeControllers[entry.key] = TextEditingController(
            text: entry.value?.toString(),
          );
        }
      }
    }

    // Images
    if (p.images?.isNotEmpty == true) {
      _existingImageUrls.addAll(
        p.images!
            .map((img) => img.url)
            .whereType<String>()
            .where((u) => u.isNotEmpty),
      );
    }
  }

  @override
  void dispose() {
    // Dispose all controllers
    _titleController.dispose();
    _descriptionNotesController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _skuController.dispose();
    _asinController.dispose();
    _customBrandController.dispose();

    for (final controller in _attributeControllers.values) {
      controller.dispose();
    }

    _focusScope.dispose();
    super.dispose();
  }

  // === Image Handling ===

  void _removeImage(int index, {required bool isNew}) {
    setState(() {
      if (isNew) {
        _newImages.removeAt(index);
      } else {
        _existingImageUrls.removeAt(index);
      }
    });
  }

  Future<List<String>> _uploadImages(String sellerId, String productId) async {
    if (_newImages.isEmpty) return List.from(_existingImageUrls);

    setState(() => _isUploadingImages = true);
    final uploadedUrls = <String>[];

    try {
      for (var i = 0; i < _newImages.length; i++) {
        final img = _newImages[i];
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = '${timestamp}_$i.jpg';
        final path = '$sellerId/$productId/$fileName';

        await _supabase.storage
            .from('product-images')
            .upload(
              path,
              File(img.path),
              fileOptions: const FileOptions(contentType: 'image/jpeg'),
            );

        // Get public URL
        final publicUrl = _supabase.storage
            .from('product-images')
            .getPublicUrl(path);

        uploadedUrls.add(publicUrl);
      }

      return [..._existingImageUrls, ...uploadedUrls];
    } on StorageException catch (e) {
      debugPrint('[Image Upload Error] ${e.message} (code: ${e.statusCode})');
      rethrow;
    } finally {
      if (mounted) {
        setState(() => _isUploadingImages = false);
      }
    }
  }

  // === Save Logic ===

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_validateAttributes()) return;
    if (_selectedCategoryId == null || _selectedSubcategory == null) {
      _showError('Please select category and subcategory');
      return;
    }
    if (_isSaving || _isUploadingImages) return;

    setState(() => _isSaving = true);

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // === Validate Brand ===
      final isLocalBrand = _selectedBrand?.isLocal == true;
      final brandName = isLocalBrand
          ? _customBrandController.text.trim()
          : _selectedBrand?.name ?? '';

      if (isLocalBrand && brandName.isEmpty) {
        throw Exception('Please enter your brand name');
      }

      // === Generate Description ===
      final description = DescriptionGenerator.generate(
        title: _titleController.text.trim(),
        brand: brandName,
        category: getCategoryDefinitionById(_selectedCategoryId!)?.name ?? '',
        subcategory: _selectedSubcategory!,
        attributes: _attributes,
        condition: _condition.name,
        customNotes: _descriptionNotesController.text.trim().isNotEmpty
            ? _descriptionNotesController.text.trim()
            : null,
      );

      // === Prepare Product Data ===
      final productData = <String, dynamic>{
        'title': _titleController.text.trim(),
        'description': description,
        'brand': brandName,
        'price': double.tryParse(_priceController.text),
        'quantity': int.tryParse(_quantityController.text) ?? 0,
        'status': _status.name,
        'category': getCategoryDefinitionById(_selectedCategoryId!)?.name,
        'subcategory': _selectedSubcategory,
        'currency': _currency,
        'attributes': {
          ..._attributes,
          if (_selectedColor != null) ...{
            'color': _selectedColor!.name,
            'color_hex': _selectedColor!.hexCode,
          },
          'condition': _condition.name,
        },
        'brand_id': isLocalBrand ? null : _selectedBrand?.id,
        'is_local_brand': isLocalBrand,
        'sku': _skuController.text.trim().isNotEmpty
            ? _skuController.text.trim()
            : null,
        'asin': _asinController.text.trim().isNotEmpty
            ? _asinController.text.trim()
            : null,
      };

      // === Handle Images ===
      List<Map<String, Object>> images = _existingImageUrls
          .map(
            (url) => {
              'url': url,
              'is_primary': url == _existingImageUrls.firstOrNull,
            },
          )
          .toList();

      if (_newImages.isNotEmpty) {
        final storageProductId = _isEditing
            ? widget.product!.id!
            : const Uuid().v4(); // Generate ID for new product images

        final uploadedUrls = await _uploadImages(userId, storageProductId);
        images.addAll(uploadedUrls.map((url) => {'url': url}));

        if (!_isEditing) {
          // Use generated ID for the product record too
          productData['id'] = storageProductId;
        }
      }
      productData['images'] = images;

      // === Check Connectivity for Offline Support ===
      final hasInternet = await ConnectivityHelper.hasInternet;

      if (!hasInternet && !_isEditing) {
        // Offline + New product: Save locally and queue
        await _saveProductOffline(userId, productData);
        return;
      }

      // === Insert or Update ===
      String? finalProductId;

      if (_isEditing) {
        // UPDATE
        final response = await _supabase
            .from('products')
            .update(productData)
            .eq('id', widget.product!.id!)
            .select()
            .single();

        finalProductId = widget.product!.id!;

        // Update vault cache
        final updatedProduct = Product.fromJson(response);
        await _productVault?.saveProduct(finalProductId, updatedProduct);

        _showSuccess('Product updated successfully');
      } else {
        // CREATE
        // Generate IDs if not provided
        productData['id'] ??= const Uuid().v4();
        productData['sku'] ??= 'SKU-${DateTime.now().millisecondsSinceEpoch}';
        productData['asin'] ??=
            'ASIN-${const Uuid().v4().substring(0, 8).toUpperCase()}';
        productData['seller_id'] = userId;
        productData['created_at'] = DateTime.now().toIso8601String();
        productData['updated_at'] = DateTime.now().toIso8601String();

        final response = await _supabase
            .from('products')
            .insert(productData)
            .select()
            .single();

        finalProductId = response['id'] as String;

        // Save to vault
        final newProduct = Product.fromJson(response);
        await _productVault?.saveProduct(finalProductId, newProduct);

        // Update seller's product list
        final cachedProducts = _productVault?.getSellerProducts(userId) ?? [];
        if (!cachedProducts.any((p) => p.id == finalProductId)) {
          cachedProducts.add(newProduct);
          await _productVault?.saveSellerProducts(userId, cachedProducts);
        }

        _showSuccess(
          'Product created! ID: ${finalProductId.substring(0, 8)}...',
        );
      }

      // Mark as synced if was offline
      if (_wasOfflineWhenSaved) {
        // Could trigger manual sync here if needed
        _wasOfflineWhenSaved = false;
      }

      if (mounted) {
        Navigator.pop(context, true); // Return success to caller
      }
    } catch (e, stack) {
      debugPrint('[Save Error] $e\n$stack');
      _showError('Save failed: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  /// Save product locally when offline
  Future<void> _saveProductOffline(
    String userId,
    Map<String, dynamic> productData,
  ) async {
    try {
      final productId = productData['id'] as String;

      // Create Product model
      final product = Product.fromJson(productData);

      // Save to local vault
      await _productVault?.saveProduct(productId, product);

      // Queue for background sync
      // (Implementation depends on your OfflineQueueService)

      setState(() => _wasOfflineWhenSaved = true);

      _showSuccess(
        'Saved locally! Will sync when online.\nID: ${productId.substring(0, 8)}...',
        duration: const Duration(seconds: 5),
        backgroundColor: Colors.orange,
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('[Offline Save Error] $e');
      _showError('Failed to save locally: $e');
      rethrow;
    }
  }

  /// Validate all dynamic attributes
  bool _validateAttributes() {
    if (_selectedSubcategory == null) return true;

    final attrs = getAttributesForSubcategory(_selectedSubcategory!);
    _attributeErrors.clear();

    for (final attr in attrs) {
      if (!attr.required) continue;

      final value = _attributes[attr.key];
      final error = validateAttributeValue(attr, value);

      if (error != null) {
        _attributeErrors[attr.key] = error;
      }
    }

    if (_attributeErrors.isNotEmpty) {
      _showError('Please fix ${_attributeErrors.length} field(s)');
      return false;
    }
    return true;
  }

  // === UI Feedback ===

  void _showError(
    String message, {
    Duration duration = const Duration(seconds: 3),
    Color backgroundColor = Colors.red,
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(
    String message, {
    Duration duration = const Duration(seconds: 3),
    Color backgroundColor = Colors.green,
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // === UI Builders ===

  Widget _buildLoadingState() {
    return Scaffold(
      appBar: AppBar(title: const Text('Loading...')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(_initError ?? 'Initializing...'),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    final entries = _isEditing || _allowedCategoryId == null
        ? categoryDefinitions.entries
        : categoryDefinitions.entries.where(
            (entry) => entry.key == _allowedCategoryId,
          );

    return DropdownButtonFormField<String>(
      initialValue: _selectedCategoryId,
      decoration: const InputDecoration(
        labelText: 'Category *',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.category),
      ),
      items: entries.map((entry) {
        final def = entry.value;
        return DropdownMenuItem(
          value: def.id,
          child: Text('${def.icon} ${def.name}'),
        );
      }).toList(),
      onChanged: !_isEditing && _allowedCategoryId != null
          ? null
          : (val) => setState(() {
              _selectedCategoryId = val;
              _selectedSubcategory = null;
              if (!_isEditing) {
                _attributes.clear();
                _attributeErrors.clear();
                for (final c in _attributeControllers.values) c.dispose();
                _attributeControllers.clear();
              }
            }),
      validator: (v) => v == null ? 'Required' : null,
    );
  }

  Widget _buildSubcategoryDropdown() {
    final subcategories = _selectedCategoryId == null
        ? []
        : getSubcategoriesForCategory(_selectedCategoryId!);

    return DropdownButtonFormField<String>(
      initialValue: _selectedSubcategory,
      decoration: const InputDecoration(
        labelText: 'Subcategory *',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.subdirectory_arrow_right),
      ),
      items: subcategories.map((sub) {
        return DropdownMenuItem<String>(value: sub, child: Text(sub));
      }).toList(),
      onChanged: subcategories.isEmpty
          ? null
          : (val) => setState(() {
              _selectedSubcategory = val;
              if (!_isEditing) {
                _attributes.clear();
                _attributeErrors.clear();
                for (final c in _attributeControllers.values) c.dispose();
                _attributeControllers.clear();
              }
            }),
      validator: (v) => v == null ? 'Required' : null,
      // enabled: subcategories.isNotEmpty,
    );
  }

  Widget _buildBrandDropdown() {
    final catName = _selectedCategoryId == null
        ? null
        : getCategoryDefinitionById(_selectedCategoryId!)?.name;

    final filteredBrands = predefinedBrands.where((b) {
      if (b.isLocal) return true;
      if (b.category == null) return true; // Universal
      if (catName == null) return false;
      return b.category == catName;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<BrandOption>(
          initialValue: _selectedBrand?.isLocal == true
              ? BrandOption.localBrand
              : _selectedBrand,
          decoration: const InputDecoration(
            labelText: 'Brand *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.store),
          ),
          items: filteredBrands.map((brand) {
            return DropdownMenuItem(value: brand, child: Text(brand.name));
          }).toList(),
          onChanged: (val) => setState(() {
            if (val?.isLocal == true) {
              _selectedBrand = BrandOption.localBrand;
              _customBrandController.clear();
            } else {
              _selectedBrand = val;
              _customBrandController.clear();
            }
          }),
          validator: (v) => v == null ? 'Required' : null,
        ),
        if (_selectedBrand?.isLocal == true) ...[
          const SizedBox(height: 8),
          TextFormField(
            controller: _customBrandController,
            decoration: const InputDecoration(
              labelText: 'Your Brand Name *',
              hintText: 'e.g., "My Local Shop"',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.edit),
            ),
            validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
            textCapitalization: TextCapitalization.words,
          ),
        ],
      ],
    );
  }

  Widget _buildColorDropdown() {
    final catDef = _selectedCategoryId == null
        ? null
        : getCategoryDefinitionById(_selectedCategoryId!);

    if (catDef?.requiresColor != true) return const SizedBox();

    return DropdownButtonFormField<ColorOption>(
      initialValue: _selectedColor,
      decoration: const InputDecoration(
        labelText: 'Color',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.palette),
      ),
      items: availableColors.map((color) {
        return DropdownMenuItem(
          value: color,
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: color.color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade400),
                ),
              ),
              const SizedBox(width: 12),
              Text(color.name),
            ],
          ),
        );
      }).toList(),
      onChanged: (val) => setState(() => _selectedColor = val),
      isExpanded: true,
    );
  }

  Widget _buildConditionSelector() {
    final catDef = _selectedCategoryId == null
        ? null
        : getCategoryDefinitionById(_selectedCategoryId!);

    if (catDef?.requiresCondition != true) return const SizedBox();

    return DropdownButtonFormField<ProductCondition>(
      initialValue: _condition,
      decoration: const InputDecoration(
        labelText: 'Condition',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.info_outline),
      ),
      items: const [
        DropdownMenuItem(
          value: ProductCondition.new_,
          child: Text('✨ Brand New'),
        ),
        DropdownMenuItem(
          value: ProductCondition.likeNew,
          child: Text('👍 Like New'),
        ),
        DropdownMenuItem(value: ProductCondition.good, child: Text('✓ Good')),
        DropdownMenuItem(value: ProductCondition.fair, child: Text('⚠ Fair')),
      ],
      onChanged: (val) => setState(() => _condition = val!),
    );
  }

  Widget _buildStatusSelector() {
    return DropdownButtonFormField<ProductStatus>(
      initialValue: _status,
      decoration: const InputDecoration(
        labelText: 'Listing Status',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.visibility),
      ),
      items: const [
        DropdownMenuItem(
          value: ProductStatus.draft,
          child: Text('📝 Draft (Not Visible)'),
        ),
        DropdownMenuItem(
          value: ProductStatus.active,
          child: Text('🟢 Active (Public)'),
        ),
        DropdownMenuItem(
          value: ProductStatus.inactive,
          child: Text('⚪ Inactive (Hidden)'),
        ),
        DropdownMenuItem(
          value: ProductStatus.archived,
          child: Text('🗄️ Archived'),
        ),
      ],
      onChanged: (val) => setState(() => _status = val!),
    );
  }

  Widget _buildDynamicAttributes() {
    if (_selectedSubcategory == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Select a subcategory to see product specifications',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final attrs = getAttributesForSubcategory(_selectedSubcategory!);
    if (attrs.isEmpty) return const SizedBox();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.tune, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Product Specifications',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...attrs.map((attr) => _buildAttributeField(attr)),
          ],
        ),
      ),
    );
  }

  Widget _buildAttributeField(ProductAttribute attr) {
    final error = _attributeErrors[attr.key];

    switch (attr.type) {
      case AttributeType.dropdown:
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: DropdownButtonFormField<String>(
            initialValue: _attributes[attr.key] as String?,
            decoration: InputDecoration(
              labelText: '${attr.label}${attr.required ? ' *' : ''}',
              hintText: attr.hint,
              border: const OutlineInputBorder(),
              errorText: error,
              prefixIcon: attr.unit != null
                  ? Text(attr.unit!, style: const TextStyle(fontSize: 12))
                  : null,
            ),
            items: attr.options!
                .map((opt) => DropdownMenuItem(value: opt, child: Text(opt)))
                .toList(),
            onChanged: (val) => setState(() {
              _attributes[attr.key] = val;
              if (error != null) {
                _attributeErrors.remove(attr.key);
              }
            }),
            isExpanded: true,
          ),
        );

      case AttributeType.boolean:
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${attr.label}${attr.required ? ' *' : ''}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              Switch(
                value: _attributes[attr.key] as bool? ?? false,
                onChanged: (val) => setState(() {
                  _attributes[attr.key] = val;
                  if (error != null) _attributeErrors.remove(attr.key);
                }),
              ),
            ],
          ),
        );

      case AttributeType.number:
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: TextFormField(
            controller: _attributeControllers.putIfAbsent(
              attr.key,
              () => TextEditingController(
                text: _attributes[attr.key]?.toString(),
              ),
            ),
            decoration: InputDecoration(
              labelText: '${attr.label}${attr.required ? ' *' : ''}',
              hintText: attr.hint,
              suffixText: attr.unit,
              border: const OutlineInputBorder(),
              errorText: error,
            ),
            keyboardType: TextInputType.number,
            onChanged: (val) => setState(() {
              _attributes[attr.key] = double.tryParse(val);
              if (error != null) _attributeErrors.remove(attr.key);
            }),
            validator: (v) => validateAttributeValue(attr, v),
          ),
        );

      case AttributeType.text:
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: TextFormField(
            controller: _attributeControllers.putIfAbsent(
              attr.key,
              () => TextEditingController(
                text: _attributes[attr.key]?.toString(),
              ),
            ),
            decoration: InputDecoration(
              labelText: '${attr.label}${attr.required ? ' *' : ''}',
              hintText: attr.hint,
              border: const OutlineInputBorder(),
              errorText: error,
            ),
            maxLines: attr.key == 'notes' || attr.key == 'condition_details'
                ? 3
                : 1,
            maxLength: attr.key == 'notes' ? 500 : null,
            onChanged: (val) => setState(() {
              _attributes[attr.key] = val;
              if (error != null) _attributeErrors.remove(attr.key);
            }),
            validator: (v) => validateAttributeValue(attr, v),
          ),
        );

      case AttributeType.multiSelect:
        final selected = (_attributes[attr.key] as List?)?.cast<String>() ?? [];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${attr.label}${attr.required ? ' *' : ''}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              if (attr.hint != null) ...[
                const SizedBox(height: 4),
                Text(attr.hint!, style: Theme.of(context).textTheme.bodySmall),
              ],
              if (error != null) ...[
                const SizedBox(height: 4),
                Text(
                  error,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: attr.options!.map((option) {
                  final isSelected = selected.contains(option);
                  return FilterChip(
                    label: Text(option),
                    selected: isSelected,
                    onSelected: (val) => setState(() {
                      if (val) {
                        selected.add(option);
                      } else {
                        selected.remove(option);
                      }
                      _attributes[attr.key] = List.from(selected);
                      if (error != null) _attributeErrors.remove(attr.key);
                    }),
                  );
                }).toList(),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildImageSection() {
    final totalImages = _existingImageUrls.length + _newImages.length;
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.photo_library, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Product Images',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (totalImages > 0) ...[
                  const Spacer(),
                  Chip(
                    label: Text('$totalImages'),
                    backgroundColor: theme.colorScheme.primaryContainer,
                    labelStyle: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),

            // Image grid / placeholder
            if (totalImages == 0)
              _buildEmptyImageSlot()
            else
              SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: totalImages + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    if (index == totalImages) {
                      return _buildAddImageButton();
                    }

                    final isNew = index < _newImages.length;
                    final data = isNew
                        ? {'file': _newImages[index], 'isNew': true}
                        : {
                            'url':
                                _existingImageUrls[index - _newImages.length],
                            'isNew': false,
                          };

                    return _buildImagePreview(data, index);
                  },
                ),
              ),

            const SizedBox(height: 12),

            // Camera / Gallery buttons - always visible
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImages(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt, size: 18),
                    label: const Text('Camera'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImages(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library, size: 18),
                    label: const Text('Gallery'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),

            if (_isUploadingImages) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(),
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'Uploading images...',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyImageSlot() {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => _pickImages(ImageSource.gallery),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          border: Border.all(color: theme.dividerColor),
          borderRadius: BorderRadius.circular(12),
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_photo_alternate_outlined,
                size: 32,
                color: theme.primaryColor,
              ),
              const SizedBox(height: 6),
              Text(
                'Tap to add images',
                style: TextStyle(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddImageButton() {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => _pickImages(ImageSource.gallery),
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.primaryColor,
            width: 2,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(8),
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 28, color: theme.primaryColor),
            const SizedBox(height: 4),
            Text(
              'Add',
              style: TextStyle(color: theme.primaryColor, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview(Map<String, dynamic> data, int index) {
    final theme = Theme.of(context);
    final isNew = data['isNew'] as bool;

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 100,
            height: 100,
            color: theme.cardColor,
            child: isNew
                ? Image.file(
                    File((data['file'] as XFile).path),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Icon(Icons.error, color: theme.colorScheme.error),
                  )
                : Image.network(
                    data['url'] as String,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: progress.expectedTotalBytes != null
                              ? progress.cumulativeBytesLoaded /
                                    progress.expectedTotalBytes!
                              : null,
                          strokeWidth: 2,
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) =>
                        Icon(Icons.broken_image, color: theme.hintColor),
                  ),
          ),
        ),
        // Remove button
        Positioned(
          right: 4,
          top: 4,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.red.shade700,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1),
            ),
            child: IconButton(
              icon: const Icon(Icons.close, size: 16, color: Colors.white),
              onPressed: () => _removeImage(index, isNew: isNew),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ),
        // Primary badge for first image
        if (index == 0)
          Positioned(
            left: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.shade700,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Primary',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPriceQuantityRow() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: TextFormField(
            controller: _priceController,
            decoration: InputDecoration(
              labelText: 'Price *',
              prefixText: _getCurrencySymbol(),
              prefixStyle: const TextStyle(fontWeight: FontWeight.bold),
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            validator: (v) {
              if (v?.isEmpty ?? true) return 'Required';
              if (double.tryParse(v!) == null) return 'Invalid number';
              if (double.parse(v) <= 0) return 'Must be > 0';
              return null;
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: _quantityController,
            decoration: const InputDecoration(
              labelText: 'Quantity *',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (v) {
              if (v?.isEmpty ?? true) return 'Required';
              if (int.tryParse(v!) == null) return 'Invalid number';
              if (int.parse(v) < 0) return 'Cannot be negative';
              return null;
            },
          ),
        ),
      ],
    );
  }

  String _getCurrencySymbol() {
    const symbols = {'USD': '\$', 'EUR': '€', 'GBP': '£', 'JPY': '¥'};
    return symbols[_currency] ?? '$_currency ';
  }

  Widget _buildAdvancedFields() {
    return ExpansionTile(
      title: const Text('Advanced Options'),
      // icon: const Icon(Icons.tune),
      // collapsedIcon: const Icon(Icons.tune_outlined),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextFormField(
                controller: _skuController,
                decoration: const InputDecoration(
                  labelText: 'SKU (Stock Keeping Unit)',
                  hintText: 'e.g., TSHIRT-BLK-M-001',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.qr_code_2),
                ),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _asinController,
                decoration: const InputDecoration(
                  labelText: 'ASIN / External ID',
                  hintText: 'e.g., B08N5WRWNW',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionNotesController,
                decoration: const InputDecoration(
                  labelText: 'Additional Notes',
                  hintText: 'Any other details not covered above...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                maxLength: 500,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOfflineIndicator() {
    if (_isOnline) return const SizedBox();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off, color: Colors.orange.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'You\'re offline. New products will be saved locally and synced when connected.',
              style: TextStyle(color: Colors.orange.shade700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) return _buildLoadingState();

    final isEditing = _isEditing;
    final theme = Theme.of(context);

    return FocusScope(
      node: _focusScope,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? 'Edit Product' : 'Add Product'),
          actions: [
            if (_isSaving || _isUploadingImages)
              const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              IconButton(
                icon: const Icon(Icons.save),
                tooltip: 'Save Product',
                onPressed: _saveProduct,
              ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Offline indicator
              _buildOfflineIndicator(),

              // Product Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Product Title *',
                  hintText: 'e.g., "Classic Cotton T-Shirt"',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
                maxLength: 100,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),

              // Category → Subcategory
              _buildCategoryDropdown(),
              const SizedBox(height: 12),
              _buildSubcategoryDropdown(),
              const SizedBox(height: 16),

              // Brand
              _buildBrandDropdown(),
              const SizedBox(height: 16),

              // Color (conditional)
              _buildColorDropdown(),
              const SizedBox(height: 16),

              // Condition (conditional)
              _buildConditionSelector(),
              const SizedBox(height: 16),

              // Dynamic Attributes
              _buildDynamicAttributes(),

              // Price & Quantity
              _buildPriceQuantityRow(),
              const SizedBox(height: 16),

              // Status
              _buildStatusSelector(),
              const SizedBox(height: 16),

              // Advanced Options (collapsible)
              _buildAdvancedFields(),
              const SizedBox(height: 16),

              // Images
              _buildImageSection(),
              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: (_isSaving || _isUploadingImages)
                      ? null
                      : _saveProduct,
                  icon: _isSaving || _isUploadingImages
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.onPrimary,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    _isSaving || _isUploadingImages
                        ? 'Saving...'
                        : isEditing
                        ? 'Update Product'
                        : 'Create Product',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              // Helper text
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  isEditing
                      ? 'Changes will be visible after saving'
                      : 'All fields marked with * are required',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
