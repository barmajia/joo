import 'package:flutter/material.dart';

// ============================================================================
// Brand Options
// ============================================================================

class BrandOption {
  final String id;
  final String name;
  final String? category;
  final bool isLocal;

  const BrandOption({
    required this.id,
    required this.name,
    this.category,
    this.isLocal = false,
  });

  static const BrandOption localBrand = BrandOption(
    id: 'local',
    name: 'Other / Local Brand',
    isLocal: true,
  );
}

// ============================================================================
// Predefined Brands
// ============================================================================

const List<BrandOption> predefinedBrands = [
  // Electronics
  BrandOption(id: 'apple', name: 'Apple', category: 'Electronics & Components'),
  BrandOption(id: 'samsung', name: 'Samsung', category: 'Electronics & Components'),
  BrandOption(id: 'sony', name: 'Sony', category: 'Electronics & Components'),
  BrandOption(id: 'lg', name: 'LG', category: 'Electronics & Components'),
  BrandOption(id: 'xiaomi', name: 'Xiaomi', category: 'Electronics & Components'),
  BrandOption(id: 'huawei', name: 'Huawei', category: 'Electronics & Components'),
  BrandOption(id: 'dell', name: 'Dell', category: 'Electronics & Components'),
  BrandOption(id: 'hp', name: 'HP', category: 'Electronics & Components'),
  BrandOption(id: 'lenovo', name: 'Lenovo', category: 'Electronics & Components'),
  BrandOption(id: 'asus', name: 'ASUS', category: 'Electronics & Components'),

  // Textiles & Fabrics
  BrandOption(id: 'unifi_fabrics', name: 'UniFi Fabrics', category: 'Textiles & Fabrics'),
  BrandOption(id: 'burlington', name: 'Burlington Fabrics', category: 'Textiles & Fabrics'),
  BrandOption(id: 'milliken', name: 'Milliken & Co', category: 'Textiles & Fabrics'),
  BrandOption(id: 'mount_vernon', name: 'Mount Vernon Mills', category: 'Textiles & Fabrics'),

  // Machinery & Equipment
  BrandOption(id: 'caterpillar', name: 'Caterpillar', category: 'Machinery & Equipment'),
  BrandOption(id: 'john_deere', name: 'John Deere', category: 'Machinery & Equipment'),
  BrandOption(id: 'komatsu', name: 'Komatsu', category: 'Machinery & Equipment'),
  BrandOption(id: 'siemens', name: 'Siemens', category: 'Machinery & Equipment'),
  BrandOption(id: 'abb', name: 'ABB', category: 'Machinery & Equipment'),

  // Automotive
  BrandOption(id: 'bosch', name: 'Bosch', category: 'Automotive'),
  BrandOption(id: 'denso', name: 'Denso', category: 'Automotive'),
  BrandOption(id: 'michelin', name: 'Michelin', category: 'Automotive'),
  BrandOption(id: 'bridgestone', name: 'Bridgestone', category: 'Automotive'),

  // Beauty & Personal Care
  BrandOption(id: 'loreal', name: "L'Oréal", category: 'Beauty & Personal Care'),
  BrandOption(id: 'nivea', name: 'Nivea', category: 'Beauty & Personal Care'),
  BrandOption(id: 'dove', name: 'Dove', category: 'Beauty & Personal Care'),
  BrandOption(id: 'olay', name: 'Olay', category: 'Beauty & Personal Care'),

  // Home & Furniture
  BrandOption(id: 'ikea', name: 'IKEA', category: 'Home & Furniture'),
  BrandOption(id: 'ashley', name: 'Ashley Furniture', category: 'Home & Furniture'),
  BrandOption(id: 'wayfair', name: 'Wayfair', category: 'Home & Furniture'),

  // General (no category restriction)
  BrandOption(id: 'generic', name: 'Generic'),
  BrandOption(id: 'oem', name: 'OEM'),
  BrandOption(id: 'white_label', name: 'White Label'),

  // Always keep local brand as the last option
  BrandOption.localBrand,
];

// ============================================================================
// Color Options
// ============================================================================

class ColorOption {
  final String name;
  final Color color;
  final String hexCode;

  const ColorOption({
    required this.name,
    required this.color,
    required this.hexCode,
  });
}

const List<ColorOption> availableColors = [
  ColorOption(name: 'Black', color: Color(0xFF000000), hexCode: '#000000'),
  ColorOption(name: 'White', color: Color(0xFFFFFFFF), hexCode: '#FFFFFF'),
  ColorOption(name: 'Red', color: Color(0xFFE53935), hexCode: '#E53935'),
  ColorOption(name: 'Blue', color: Color(0xFF1E88E5), hexCode: '#1E88E5'),
  ColorOption(name: 'Green', color: Color(0xFF43A047), hexCode: '#43A047'),
  ColorOption(name: 'Yellow', color: Color(0xFFFFD600), hexCode: '#FFD600'),
  ColorOption(name: 'Orange', color: Color(0xFFFF9800), hexCode: '#FF9800'),
  ColorOption(name: 'Purple', color: Color(0xFF8E24AA), hexCode: '#8E24AA'),
  ColorOption(name: 'Pink', color: Color(0xFFE91E63), hexCode: '#E91E63'),
  ColorOption(name: 'Brown', color: Color(0xFF795548), hexCode: '#795548'),
  ColorOption(name: 'Grey', color: Color(0xFF9E9E9E), hexCode: '#9E9E9E'),
  ColorOption(name: 'Silver', color: Color(0xFFBDBDBD), hexCode: '#BDBDBD'),
  ColorOption(name: 'Gold', color: Color(0xFFFFC107), hexCode: '#FFC107'),
  ColorOption(name: 'Navy', color: Color(0xFF1A237E), hexCode: '#1A237E'),
  ColorOption(name: 'Teal', color: Color(0xFF009688), hexCode: '#009688'),
  ColorOption(name: 'Beige', color: Color(0xFFF5F5DC), hexCode: '#F5F5DC'),
  ColorOption(name: 'Cream', color: Color(0xFFFFFDD0), hexCode: '#FFFDD0'),
  ColorOption(name: 'Maroon', color: Color(0xFF800000), hexCode: '#800000'),
];

// ============================================================================
// Category Structure (maps category name to subcategories)
// ============================================================================

const Map<String, List<String>> categoryStructure = {
  'Electronics & Components': [
    'Smartphones & Accessories',
    'Computers & Laptops',
    'Tablets & e-Readers',
    'Consumer Electronics',
    'Electronic Components',
    'LED & Lighting',
    'Cables & Chargers',
    'Batteries & Power Banks',
    'Audio & Headphones',
    'Gaming Accessories',
  ],
  'Textiles & Fabrics': [
    'Cotton Fabrics',
    'Silk Fabrics',
    'Wool Fabrics',
    'Synthetic Fabrics',
    'Denim',
    'Lace & Embroidery',
    'Knitted Fabrics',
    'Technical Textiles',
    'Fashion Fabrics',
    'Home Textiles',
  ],
  'Machinery & Equipment': [
    'Industrial Machinery',
    'Agricultural Machinery',
    'Construction Equipment',
    'Packaging Machinery',
    'Textile Machinery',
    'Food Processing Equipment',
    'Woodworking Machinery',
    'Metalworking Tools',
    'HVAC Equipment',
    'Printing Machinery',
  ],
  'Construction Materials': [
    'Cement & Concrete',
    'Bricks & Blocks',
    'Steel & Iron',
    'Timber & Wood',
    'Sand & Gravel',
    'Roofing Materials',
    'Insulation Materials',
    'Flooring Materials',
    'Paints & Coatings',
    'Glass & Windows',
  ],
  'Packaging & Printing': [
    'Cardboard Boxes',
    'Plastic Bags',
    'Paper Bags',
    'Bubble Wrap',
    'Tape & Adhesives',
    'Labels & Stickers',
    'Flexible Packaging',
    'Corrugated Boxes',
    'Gift Boxes',
    'Shopping Bags',
  ],
  'Food & Beverage': [
    'Fresh Produce',
    'Dried Foods',
    'Canned Foods',
    'Frozen Foods',
    'Snacks & Confectionery',
    'Beverages',
    'Dairy Products',
    'Oils & Fats',
    'Spices & Seasonings',
    'Instant Foods',
  ],
  'Agriculture': [
    'Seeds & Bulbs',
    'Fertilizers',
    'Pesticides',
    'Farm Tools',
    'Irrigation Equipment',
    'Greenhouses',
    'Animal Feed',
    'Agricultural Films',
    'Harvesting Equipment',
    'Organic Products',
  ],
  'Beauty & Personal Care': [
    'Skincare Products',
    'Hair Care',
    'Makeup & Cosmetics',
    'Fragrances',
    'Body Care',
    'Manicure & Pedicure',
    'Beauty Tools',
    'Organic Beauty',
    'Men Grooming',
    'Baby Care',
  ],
  'Home & Furniture': [
    'Living Room Furniture',
    'Bedroom Furniture',
    'Dining Furniture',
    'Office Furniture',
    'Kitchenware',
    'Home Decor',
    'Bedding & Linens',
    'Curtains & Blinds',
    'Rugs & Carpets',
    'Lighting',
  ],
  'Automotive': [
    'Auto Parts',
    'Engine Oil',
    'Tires & Wheels',
    'Car Electronics',
    'Car Accessories',
    'Battery & Charging',
    'Brakes & Clutches',
    'Suspension Parts',
    'Body Parts',
    'Car Care',
  ],
  'Office Supplies': [
    'Stationery',
    'Office Furniture',
    'Office Electronics',
    'File & Storage',
    'Writing Instruments',
    'Paper Products',
    'Binders & Clips',
    'Desk Accessories',
    'Ink & Toner',
    'Conference Supplies',
  ],
  'Sports & Outdoors': [
    'Sports Equipment',
    'Fitness Accessories',
    'Outdoor Gear',
    'Camping & Hiking',
    'Cycling',
    'Water Sports',
    'Team Sports',
    'Winter Sports',
    'Sportswear',
    'Sports Bags',
  ],
  'Toys & Games': [
    'Action Figures',
    'Board Games',
    'Puzzles',
    'Outdoor Toys',
    'Educational Toys',
    'Building Blocks',
    'Dolls & Dollhouses',
    'Electronic Toys',
    'Remote Control',
    'Art & Craft Toys',
  ],
  'Medical & Health': [
    'Medical Equipment',
    'Medical Supplies',
    'Pharmaceuticals',
    'Health Supplements',
    'Personal Protective Equipment',
    'Diagnostic Tools',
    'Mobility Aids',
    'Medical Furniture',
    'First Aid Supplies',
    'Medical Consumables',
  ],
  'Industrial Supplies': [
    'Hardware & Fasteners',
    'Tools & Accessories',
    'Safety Equipment',
    'Pumps & Valves',
    'Bearings & Seals',
    'Hydraulic Systems',
    'Pneumatic Systems',
    'Industrial Filters',
    'Adhesives & Sealants',
    'Cutting Tools',
  ],
};

// ============================================================================
// Description Generator
// ============================================================================

class DescriptionGenerator {
  static String generate({
    required String title,
    required String brand,
    required String category,
    required String subcategory,
    Map<String, dynamic>? attributes,
    String? condition,
  }) {
    final parts = <String>[];

    parts.add('$title by $brand');
    parts.add('Category: $category - $subcategory');

    if (condition != null) {
      parts.add('Condition: $condition');
    }

    if (attributes != null && attributes.isNotEmpty) {
      final attrList = <String>[];
      attributes.forEach((key, value) {
        if (value != null && value.toString().isNotEmpty) {
          attrList.add('$key: $value');
        }
      });
      if (attrList.isNotEmpty) {
        parts.add('Specifications:');
        attrList.forEach((attr) => parts.add('  • $attr'));
      }
    }

    parts.add('Quality B2B product available for wholesale orders.');

    return parts.join('\n');
  }
}
