// lib/pages/product/add_product_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aurora/models/product/productModel.dart';
import 'package:aurora/models/product/categories.dart';
import 'package:aurora/utils/product_presets.dart';
import 'package:aurora/storage/product_vault_storage.dart';
import 'package:aurora/storage/product_secrets_storage.dart';

class AddProductPage extends StatefulWidget {
  final Product? product;
  const AddProductPage({super.key, this.product});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();

  // === Controllers (managed lifecycle) ===
  late final TextEditingController _titleController;
  late final TextEditingController _priceController;
  late final TextEditingController _quantityController;
  late final TextEditingController _customBrandController;

  // === Selection State (preset-only) ===
  String? _selectedCategoryId;
  String? _selectedSubcategory;
  BrandOption? _selectedBrand;
  ColorOption? _selectedColor;
  String _condition = 'New'; // preset options only
  String _status = 'draft';

  // === Dynamic Attributes (preset schema) ===
  final Map<String, dynamic> _attributes = {};

  // === Images ===
  final List<XFile> _selectedImages = [];
  final List<String> _existingImageUrls = [];
  final ImagePicker _picker = ImagePicker();

  // === Backend ===
  final _supabase = Supabase.instance.client;
  late final ProductVaultStorage _productVault;
  late final ProductSecretsStorage _secretsStorage;
  bool _isSaving = false;
  bool get _isEditing => widget.product != null;

  // === Currency (preset) ===
  final String _currency = 'USD'; // Could be loaded from user profile

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _priceController = TextEditingController();
    _quantityController = TextEditingController();
    _customBrandController = TextEditingController();

    _initVault();
    if (_isEditing) _loadProductData();
  }

  Future<void> _initVault() async {
    _productVault = await ProductVaultStorage.getInstance();
    _secretsStorage = await ProductSecretsStorage.getInstance();
  }

  void _loadProductData() {
    final p = widget.product!;

    _titleController.text = p.title ?? '';
    _priceController.text = p.price?.toString() ?? '';
    _quantityController.text = p.quantity?.toString() ?? '0';
    _status = p.status ?? 'draft';
    _condition = p.attributes?['condition'] as String? ?? 'New';

    // Load category
    final cat = ProductCategories.categories.firstWhere(
      (c) => c.name == p.category,
      orElse: () => ProductCategories.categories.first,
    );
    _selectedCategoryId = cat.id;

    // Load subcategory
    if (p.subcategory != null &&
        categoryStructure[cat.name]?.contains(p.subcategory) == true) {
      _selectedSubcategory = p.subcategory;
    }

    // Load brand
    if (p.brand != null) {
      final brand = predefinedBrands.firstWhere(
        (b) =>
            b.name == p.brand && (b.category == null || b.category == cat.name),
        orElse: () {
          // Local brand fallback
          _customBrandController.text = p.brand!;
          return BrandOption.localBrand;
        },
      );
      _selectedBrand = brand;
    }

    // Load color
    if (p.attributes?['color'] != null) {
      _selectedColor = availableColors.firstWhere(
        (c) => c.name == p.attributes!['color'],
        orElse: () => availableColors.first,
      );
    }

    // Load attributes
    if (p.attributes != null) {
      _attributes.addAll(Map<String, dynamic>.from(p.attributes!));
    }

    // Load images
    if (p.images != null) {
      _existingImageUrls.addAll(
        p.images!.map((img) => img.url).whereType<String>(),
      );
    }
  }

  @override
  void dispose() {
    // ✅ Proper controller disposal
    _titleController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _customBrandController.dispose();
    super.dispose();
  }

  // === Image Handling ===
  Future<void> _pickImages() async {
    try {
      final images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85, // ✅ Compression
      );
      if (images != null && mounted) {
        setState(() => _selectedImages.addAll(images));
      }
    } catch (e) {
      _showError('Failed to pick images: $e');
    }
  }

  void _removeImage(int index, {bool isExisting = false}) {
    setState(() {
      if (isExisting) {
        _existingImageUrls.removeAt(index);
      } else {
        _selectedImages.removeAt(index);
      }
    });
  }

  // === Save Logic ===
  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null || _selectedSubcategory == null) {
      _showError('Please select category and subcategory');
      return;
    }
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      // === Determine Brand ===
      final isLocalBrand = _selectedBrand?.isLocal == true;
      final brandName = isLocalBrand
          ? _customBrandController.text.trim()
          : _selectedBrand?.name ?? '';

      if (isLocalBrand && brandName.isEmpty) {
        throw Exception('Please enter your brand name');
      }

      // === Generate Description (auto) ===
      final description = DescriptionGenerator.generate(
        title: _titleController.text.trim(),
        brand: brandName,
        category:
            ProductCategories.getCategoryById(_selectedCategoryId!)?.name ?? '',
        subcategory: _selectedSubcategory!,
        attributes: _attributes,
        condition: _condition,
      );

      // === Prepare Product Data ===
      final productData = {
        'title': _titleController.text.trim(),
        'description': description,
        'brand': brandName,
        'price': double.tryParse(_priceController.text),
        'quantity': int.tryParse(_quantityController.text) ?? 0,
        'status': _status,
        'category': ProductCategories.getCategoryById(
          _selectedCategoryId!,
        )?.name,
        'subcategory': _selectedSubcategory,
        'currency': _currency,
        'attributes': {
          ..._attributes,
          if (_selectedColor != null) ...{
            'color': _selectedColor!.name,
            'color_hex': _selectedColor!.hexCode,
          },
          'condition': _condition,
        },
        'brand_id': isLocalBrand ? null : _selectedBrand?.id,
        'is_local_brand': isLocalBrand,
      };

      // === Handle Images ===
      List<Map<String, String>> images = _existingImageUrls
          .map((url) => {'url': url})
          .toList();

      if (_selectedImages.isNotEmpty) {
        for (var i = 0; i < _selectedImages.length; i++) {
          final img = _selectedImages[i];
          final fileName = '${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
          final path = '$userId/${widget.product?.id ?? 'new'}/$fileName';

          await _supabase.storage.from('products').upload(path, File(img.path));
          images.add({'url': path});
        }
      }
      productData['images'] = images;

      // === Insert or Update ===
      String? productId;

       if (_isEditing) {
          // ✅ Use primary key 'id' for updates (not ASIN)
          final response = await _supabase
              .from('products')
              .update(productData)
              .eq('id', widget.product!.id!)
              .select()
              .single();

          productId = widget.product!.id!;

          // Update vault cache
          final updatedProduct = Product.fromJson(response);
          await _productVault.saveProduct(productId, updatedProduct);

          _showSuccess('Product updated');
        } else {
          productData['seller_id'] = userId;
          productData['sku'] = DateTime.now().millisecondsSinceEpoch.toString();
          productData['asin'] = DateTime.now().toIso8601String();

          final response = await _supabase
              .from('products')
              .insert(productData)
              .select()
              .single();

          productId = response['id'] as String;

          // Save to vault
          final newProduct = Product.fromJson(response);
          await _productVault.saveProduct(productId, newProduct);

          // Update seller's product list in vault
          final cachedProducts = _productVault.getSellerProducts(userId);
          cachedProducts.add(newProduct);
          await _productVault.saveSellerProducts(userId, cachedProducts);

          _showSuccess('Product created');
        }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      debugPrint('[Save Error] $e');
      _showError('Save failed: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );
    }
  }

  // === UI Builders ===

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCategoryId,
      decoration: const InputDecoration(
        labelText: 'Category *',
        border: OutlineInputBorder(),
      ),
      items: ProductCategories.categories.map((cat) {
        return DropdownMenuItem(
          value: cat.id,
          child: Text('${cat.icon} ${cat.name}'),
        );
      }).toList(),
      onChanged: (val) => setState(() {
        _selectedCategoryId = val;
        _selectedSubcategory = null;
        _attributes.clear(); // Reset attributes when category changes
      }),
      validator: (v) => v == null ? 'Required' : null,
    );
  }

  Widget _buildSubcategoryDropdown() {
    final subcategories = _selectedCategoryId == null
        ? []
        : categoryStructure[ProductCategories.getCategoryById(
                    _selectedCategoryId!,
                  )?.name ??
                  ''] ??
              [];

    return DropdownButtonFormField<String>(
      value: _selectedSubcategory,
      decoration: const InputDecoration(
        labelText: 'Subcategory *',
        border: OutlineInputBorder(),
      ),
      items: subcategories.map((sub) {
        return DropdownMenuItem<String>(value: sub, child: Text(sub));
      }).toList(),
      onChanged: (val) => setState(() {
        _selectedSubcategory = val;
        _attributes.clear(); // Reset attributes when subcategory changes
      }),
      validator: (v) => v == null ? 'Required' : null,
    );
  }

  Widget _buildBrandDropdown() {
    final filteredBrands = _selectedCategoryId == null
        ? predefinedBrands.where((b) => !b.isLocal).toList()
        : predefinedBrands
              .where(
                (b) =>
                    b.isLocal ||
                    b.category == null ||
                    b.category ==
                        ProductCategories.getCategoryById(
                          _selectedCategoryId!,
                        )?.name,
              )
              .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<BrandOption>(
          value: _selectedBrand?.isLocal == true
              ? BrandOption.localBrand
              : _selectedBrand,
          decoration: const InputDecoration(
            labelText: 'Brand *',
            border: OutlineInputBorder(),
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
            ),
            validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
          ),
        ],
      ],
    );
  }

  Widget _buildColorDropdown() {
    // Only show for Fashion & Apparel (configurable)
    final category = ProductCategories.getCategoryById(
      _selectedCategoryId ?? '',
    );
    if (category?.name != 'Fashion & Apparel') return const SizedBox();

    return DropdownButtonFormField<ColorOption>(
      value: _selectedColor,
      decoration: const InputDecoration(
        labelText: 'Color',
        border: OutlineInputBorder(),
      ),
      items: availableColors.map((color) {
        return DropdownMenuItem(
          value: color,
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: color.color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey),
                ),
              ),
              const SizedBox(width: 8),
              Text(color.name),
            ],
          ),
        );
      }).toList(),
      onChanged: (val) => setState(() => _selectedColor = val),
    );
  }

  Widget _buildConditionSelector() {
    return DropdownButtonFormField<String>(
      value: _condition,
      decoration: const InputDecoration(
        labelText: 'Condition',
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: 'New', child: Text('✨ New')),
        DropdownMenuItem(value: 'Like New', child: Text('👍 Like New')),
        DropdownMenuItem(value: 'Good', child: Text('✓ Good')),
        DropdownMenuItem(value: 'Fair', child: Text('⚠ Fair')),
      ],
      onChanged: (val) => setState(() => _condition = val!),
    );
  }

  Widget _buildDynamicAttributes() {
    if (_selectedSubcategory == null) return const SizedBox();

    final attrs = getAttributesForSubcategory(_selectedSubcategory!);
    if (attrs.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Specifications',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        ...attrs.map((attr) => _buildAttributeField(attr)),
      ],
    );
  }

  Widget _buildAttributeField(ProductAttribute attr) {
    switch (attr.type) {
      case AttributeType.dropdown:
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DropdownButtonFormField<String>(
            value: _attributes[attr.key] as String?,
            decoration: InputDecoration(
              labelText: attr.label,
              border: const OutlineInputBorder(),
            ),
            items: attr.options!
                .map((opt) => DropdownMenuItem(value: opt, child: Text(opt)))
                .toList(),
            onChanged: (val) => setState(() => _attributes[attr.key] = val),
          ),
        );
      case AttributeType.boolean:
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Text(
                attr.label,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              Switch(
                value: _attributes[attr.key] as bool? ?? false,
                onChanged: (val) => setState(() => _attributes[attr.key] = val),
              ),
            ],
          ),
        );
      case AttributeType.number:
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextFormField(
            initialValue: _attributes[attr.key]?.toString(),
            decoration: InputDecoration(
              labelText: attr.label,
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onChanged: (val) =>
                setState(() => _attributes[attr.key] = double.tryParse(val)),
          ),
        );
      case AttributeType.text:
      case AttributeType.multiSelect:
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextFormField(
            initialValue: _attributes[attr.key] as String?,
            decoration: InputDecoration(
              labelText: attr.label,
              border: const OutlineInputBorder(),
            ),
            onChanged: (val) => setState(() => _attributes[attr.key] = val),
            maxLength: 100,
          ),
        );
    }
  }

  Widget _buildImageSection() {
    final allImages = [
      ..._existingImageUrls.map((url) => {'url': url, 'isExisting': true}),
      ..._selectedImages.map((file) => {'file': file, 'isExisting': false}),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Images',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...allImages.asMap().entries.map((entry) {
              final index = entry.key;
              final data = entry.value as Map<String, dynamic>;
              final isExisting = data['isExisting'] as bool;

              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: isExisting
                        ? Image.network(
                            data['url'] as String,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          )
                        : Image.file(
                            File((data['file'] as XFile).path),
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: GestureDetector(
                      onTap: () => _removeImage(index, isExisting: isExisting),
                      child: const CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.red,
                        child: Icon(Icons.close, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              );
            }),
            GestureDetector(
              onTap: _pickImages,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.add_a_photo),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Product' : 'Add Product'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(icon: const Icon(Icons.save), onPressed: _saveProduct),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title (only free-text field - product identity)
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Product Title *',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
              maxLength: 100,
            ),
            const SizedBox(height: 16),

            // Category → Subcategory (preset hierarchy)
            _buildCategoryDropdown(),
            const SizedBox(height: 12),
            _buildSubcategoryDropdown(),
            const SizedBox(height: 16),

            // Brand (predefined + local fallback)
            _buildBrandDropdown(),
            const SizedBox(height: 16),

            // Color (visual preset picker - fashion only)
            _buildColorDropdown(),
            const SizedBox(height: 16),

            // Condition (preset only)
            _buildConditionSelector(),
            const SizedBox(height: 16),

            // Dynamic attributes (preset schema per subcategory)
            _buildDynamicAttributes(),
            const SizedBox(height: 16),

            // Price & Quantity (numeric only)
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    decoration: InputDecoration(
                      labelText: 'Price ($_currency)*',
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        v?.isEmpty == true || double.tryParse(v!) == null
                        ? 'Valid price required'
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Quantity*',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        v?.isEmpty == true || int.tryParse(v!) == null
                        ? 'Valid quantity required'
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Status (preset only)
            DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'draft', child: Text('📝 Draft')),
                DropdownMenuItem(value: 'active', child: Text('🟢 Active')),
                DropdownMenuItem(value: 'inactive', child: Text('⚪ Inactive')),
              ],
              onChanged: (val) => setState(() => _status = val!),
            ),
            const SizedBox(height: 24),

            // Images
            _buildImageSection(),
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProduct,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isEditing ? 'Update Product' : 'Create Product'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
