import 'dart:convert';
import 'dart:io';

import 'package:aurora/models/product/productModel.dart';
import 'package:aurora/services/product_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

class ProductImportResult {
  final int imported;
  final int skipped;
  final List<String> errors;

  const ProductImportResult({
    required this.imported,
    required this.skipped,
    required this.errors,
  });
}

class ProductImportExportService {
  ProductImportExportService({ProductService? productService})
    : _productService = productService ?? ProductService();

  final ProductService _productService;

  static const List<String> headers = [
    'sku',
    'asin',
    'title',
    'description',
    'brand',
    'category',
    'subcategory',
    'currency',
    'price',
    'quantity',
    'status',
    'cost',
  ];

  Future<void> exportInventory({
    required String sellerId,
    required List<Product> products,
  }) async {
    final buffer = StringBuffer();
    buffer.writeln(headers.map(_escapeCsv).join(','));

    for (final product in products) {
      final row = [
        product.sku ?? '',
        product.asin ?? '',
        product.title,
        product.description,
        product.brand,
        product.category ?? '',
        product.subcategory ?? '',
        product.currency,
        product.price?.toStringAsFixed(2) ?? '',
        product.quantity.toString(),
        product.status,
        _readCost(product)?.toStringAsFixed(2) ?? '',
      ];
      buffer.writeln(row.map(_escapeCsv).join(','));
    }

    final dir = await getTemporaryDirectory();
    final date = DateTime.now().toIso8601String().split('T').first;
    final file = File(
      '${dir.path}${Platform.pathSeparator}aurora_inventory_$date.csv',
    );
    await file.writeAsString(buffer.toString(), encoding: utf8);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'text/csv')],
        subject: 'Aurora inventory export',
        text: 'Inventory export for $sellerId',
      ),
    );
  }

  Future<ProductImportResult> importInventory({
    required String sellerId,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'txt'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return const ProductImportResult(imported: 0, skipped: 0, errors: []);
    }

    final picked = result.files.single;
    final bytes =
        picked.bytes ??
        (picked.path != null ? await File(picked.path!).readAsBytes() : null);
    if (bytes == null) {
      return const ProductImportResult(
        imported: 0,
        skipped: 1,
        errors: ['Could not read the selected file.'],
      );
    }

    final text = utf8.decode(bytes, allowMalformed: true);
    final rows = _parseCsv(text);
    if (rows.length < 2) {
      return const ProductImportResult(
        imported: 0,
        skipped: 1,
        errors: ['The file does not contain product rows.'],
      );
    }

    final fileHeaders = rows.first.map((h) => h.trim().toLowerCase()).toList();
    final errors = <String>[];
    int imported = 0;
    int skipped = 0;

    for (var index = 1; index < rows.length; index++) {
      final row = rows[index];
      if (row.every((cell) => cell.trim().isEmpty)) continue;

      final data = <String, String>{};
      for (
        var cell = 0;
        cell < fileHeaders.length && cell < row.length;
        cell++
      ) {
        data[fileHeaders[cell]] = row[cell].trim();
      }

      final title = data['title'] ?? '';
      if (title.isEmpty) {
        skipped++;
        errors.add('Row ${index + 1}: missing title.');
        continue;
      }

      final price = double.tryParse(data['price'] ?? '');
      final quantity = int.tryParse(data['quantity'] ?? '') ?? 0;
      final cost = double.tryParse(data['cost'] ?? '');
      final attributes = <String, dynamic>{};
      if (cost != null) attributes['cost'] = cost;

      final productData = {
        'id': const Uuid().v4(),
        'seller_id': sellerId,
        'sku': _nullable(data['sku']),
        'asin': _nullable(data['asin']),
        'title': title,
        'description': data['description'] ?? '',
        'brand': data['brand'] ?? '',
        'category': _nullable(data['category']),
        'subcategory': _nullable(data['subcategory']),
        'currency': (data['currency']?.isNotEmpty ?? false)
            ? data['currency']!.toUpperCase()
            : 'USD',
        'price': price,
        'quantity': quantity,
        'status': (data['status']?.isNotEmpty ?? false)
            ? data['status']
            : 'draft',
        'attributes': attributes,
        'is_local_brand': true,
        'allow_chat': true,
        'is_deleted': false,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      try {
        await _productService.createProduct(productData);
        imported++;
      } catch (e) {
        skipped++;
        errors.add('Row ${index + 1}: $e');
      }
    }

    return ProductImportResult(
      imported: imported,
      skipped: skipped,
      errors: errors,
    );
  }

  static String? _nullable(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return value.trim();
  }

  static double? _readCost(Product product) {
    final value = product.attributes?['cost'];
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static String _escapeCsv(String value) {
    final mustQuote =
        value.contains(',') || value.contains('"') || value.contains('\n');
    final escaped = value.replaceAll('"', '""');
    return mustQuote ? '"$escaped"' : escaped;
  }

  static List<List<String>> _parseCsv(String input) {
    final rows = <List<String>>[];
    final row = <String>[];
    final cell = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < input.length; i++) {
      final char = input[i];
      final next = i + 1 < input.length ? input[i + 1] : null;

      if (char == '"') {
        if (inQuotes && next == '"') {
          cell.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        row.add(cell.toString());
        cell.clear();
      } else if ((char == '\n' || char == '\r') && !inQuotes) {
        if (char == '\r' && next == '\n') i++;
        row.add(cell.toString());
        rows.add(List<String>.from(row));
        row.clear();
        cell.clear();
      } else {
        cell.write(char);
      }
    }

    if (cell.isNotEmpty || row.isNotEmpty) {
      row.add(cell.toString());
      rows.add(row);
    }

    return rows;
  }
}
