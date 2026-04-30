import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aurora/models/product/productModel.dart';
import 'package:aurora/models/product/categories.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _brandController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  String? _selectedCategoryId;
  String? _selectedSubcategory;
  final _skuController = TextEditingController();
  final _asinController = TextEditingController();

  String _status = 'draft';
  List<XFile> _selectedImages = [];
  bool _isSaving = false;
  final _picker = ImagePicker();
  final _supabase = Supabase.instance.client;

  Future<void> _pickImages() async {
    try {
      final images = await _picker.pickMultiImage();
      if (images != null && mounted) {
        setState(() => _selectedImages = images);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick images: $e')),
        );
      }
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final productData = {
        'seller_id': userId,
        'title': _titleController.text,
        'description': _descriptionController.text,
        'brand': _brandController.text,
        'currency': 'USD',
        'price': double.tryParse(_priceController.text),
        'quantity': int.tryParse(_quantityController.text) ?? 0,
        'status': _status,
        'category': _selectedCategoryId != null
            ? ProductCategories.getCategoryById(_selectedCategoryId!)?.name
            : null,
        'subcategory': _selectedSubcategory,
        'sku': _skuController.text.isEmpty ? null : _skuController.text,
        'asin': _asinController.text.isEmpty ? null : _asinController.text,
        'is_local_brand': false,
        'allow_chat': true,
        'attributes': {},
      };

      final inserted = await _supabase
          .from('products')
          .insert(productData)
          .select()
          .single();

      final productId = inserted['id'] as String;

      if (_selectedImages.isNotEmpty) {
        final images = <ProductImage>[];
        for (var i = 0; i < _selectedImages.length; i++) {
          final img = _selectedImages[i];
          final fileName = '${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
          final path = '$userId/$productId/$fileName';

          await _supabase.storage.from('products').upload(path, File(img.path));
          images.add(ProductImage(url: path, id: 'img_$i'));
        }

        await _supabase.from('products').update({
          'images': images.map((e) => e.toJson()).toList(),
        }).eq('id', productId);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product added successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _brandController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _categoryController.dispose();
    _subcategoryController.dispose();
    _skuController.dispose();
    _asinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Product'),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
              ),
            )
          else
            IconButton(icon: const Icon(Icons.save), onPressed: _saveProduct),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title *'),
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description *'),
                maxLines: 3,
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _brandController,
                decoration: const InputDecoration(labelText: 'Brand *'),
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(labelText: 'Price'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(labelText: 'Quantity'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                decoration: const InputDecoration(labelText: 'Category *'),
                items: ProductCategories.categories.map((cat) {
                  return DropdownMenuItem(
                    value: cat.id,
                    child: Text('${cat.icon} ${cat.name}'),
                  );
                }).toList(),
                onChanged: (v) => setState(() {
                  _selectedCategoryId = v;
                  _selectedSubcategory = null;
                }),
                validator: (v) => v == null ? 'Select a category' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedSubcategory,
                decoration: const InputDecoration(labelText: 'Subcategory'),
                items: _selectedCategoryId == null
                    ? []
                    : ProductCategories.getSubcategories(_selectedCategoryId!).map((sub) {
                        return DropdownMenuItem(value: sub, child: Text(sub));
                      }).toList(),
                onChanged: (v) => setState(() => _selectedSubcategory = v),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _skuController,
                      decoration: const InputDecoration(labelText: 'SKU'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _asinController,
                      decoration: const InputDecoration(labelText: 'ASIN'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: 'draft', child: Text('Draft')),
                  DropdownMenuItem(value: 'active', child: Text('Active')),
                  DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                ],
                onChanged: (v) => setState(() => _status = v!),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Images', style: Theme.of(context).textTheme.titleSmall),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._selectedImages.map((img) {
                    return Stack(
                      children: [
                        Image.file(File(img.path), width: 80, height: 80, fit: BoxFit.cover),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedImages.remove(img)),
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
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProduct,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save Product'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
