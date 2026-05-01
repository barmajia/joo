// lib/utils/product_presets.dart
// Last updated: 30/4/2026

import 'package:flutter/material.dart';

// ============================================================================
// ENUMS & TYPE DEFINITIONS
// ============================================================================

enum AttributeType { dropdown, boolean, number, text, multiSelect }

enum ProductCondition { new_, likeNew, good, fair }

enum ProductStatus { draft, active, inactive, archived }

/// Date when this preset data was last revised
const String presetDataLastUpdated = '2026-04-30';

// ============================================================================
// COLOR SYSTEM
// ============================================================================

class ColorOption {
  final String name;
  final String hexCode;

  const ColorOption({required this.name, required this.hexCode});

  Color get color => Color(int.parse(hexCode.replaceAll('#', '0xFF')));

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ColorOption && name == other.name && hexCode == other.hexCode;

  @override
  int get hashCode => name.hashCode ^ hexCode.hashCode;

  @override
  String toString() => 'ColorOption($name, $hexCode)';
}

const List<ColorOption> availableColors = [
  // Neutral & Basic
  ColorOption(name: 'Black', hexCode: '#000000'),
  ColorOption(name: 'White', hexCode: '#FFFFFF'),
  ColorOption(name: 'Gray', hexCode: '#808080'),
  ColorOption(name: 'Silver', hexCode: '#C0C0C0'),
  ColorOption(name: 'Charcoal', hexCode: '#36454F'),

  // Red Family
  ColorOption(name: 'Red', hexCode: '#FF0000'),
  ColorOption(name: 'Dark Red', hexCode: '#8B0000'),
  ColorOption(name: 'Burgundy', hexCode: '#800020'),
  ColorOption(name: 'Maroon', hexCode: '#800000'),
  ColorOption(name: 'Crimson', hexCode: '#DC143C'),
  ColorOption(name: 'Coral', hexCode: '#FF7F50'),
  ColorOption(name: 'Blush', hexCode: '#DE5D83'), // Added
  ColorOption(name: 'Dusty Rose', hexCode: '#DCAE96'), // Added
  // Blue Family
  ColorOption(name: 'Blue', hexCode: '#0000FF'),
  ColorOption(name: 'Navy', hexCode: '#000080'),
  ColorOption(name: 'Sky Blue', hexCode: '#87CEEB'),
  ColorOption(name: 'Royal Blue', hexCode: '#4169E1'),
  ColorOption(name: 'Teal', hexCode: '#008080'),
  ColorOption(name: 'Turquoise', hexCode: '#40E0D0'),
  ColorOption(name: 'Aqua', hexCode: '#00FFFF'),
  ColorOption(name: 'Cobalt', hexCode: '#0047AB'), // Added
  ColorOption(name: 'Indigo', hexCode: '#4B0082'), // Added
  ColorOption(name: 'Sapphire', hexCode: '#0F52BA'), // Added
  // Green Family
  ColorOption(name: 'Green', hexCode: '#008000'),
  ColorOption(name: 'Dark Green', hexCode: '#006400'),
  ColorOption(name: 'Olive', hexCode: '#808000'),
  ColorOption(name: 'Mint', hexCode: '#98FF98'),
  ColorOption(name: 'Emerald', hexCode: '#50C878'),
  ColorOption(name: 'Lime', hexCode: '#32CD32'),

  // Yellow/Orange Family
  ColorOption(name: 'Yellow', hexCode: '#FFFF00'),
  ColorOption(name: 'Gold', hexCode: '#FFD700'),
  ColorOption(name: 'Orange', hexCode: '#FFA500'),
  ColorOption(name: 'Peach', hexCode: '#FFE5B4'),
  ColorOption(name: 'Amber', hexCode: '#FFBF00'),
  ColorOption(name: 'Mustard', hexCode: '#FFDB58'), // Added
  ColorOption(name: 'Champagne', hexCode: '#F7E7CE'), // Added
  // Purple/Pink Family
  ColorOption(name: 'Purple', hexCode: '#800080'),
  ColorOption(name: 'Violet', hexCode: '#EE82EE'),
  ColorOption(name: 'Pink', hexCode: '#FFC0CB'),
  ColorOption(name: 'Hot Pink', hexCode: '#FF69B4'),
  ColorOption(name: 'Lavender', hexCode: '#E6E6FA'),
  ColorOption(name: 'Magenta', hexCode: '#FF00FF'),
  ColorOption(name: 'Lilac', hexCode: '#C8A2C8'), // Added
  // Brown/Neutral Family
  ColorOption(name: 'Brown', hexCode: '#A52A2A'),
  ColorOption(name: 'Beige', hexCode: '#F5F5DC'),
  ColorOption(name: 'Tan', hexCode: '#D2B48C'),
  ColorOption(name: 'Cream', hexCode: '#FFFDD0'),
  ColorOption(name: 'Ivory', hexCode: '#FFFFF0'),
  ColorOption(name: 'Taupe', hexCode: '#B38B6D'),
  ColorOption(name: 'Khaki', hexCode: '#C3B091'), // Added
  ColorOption(name: 'Sand', hexCode: '#C2B280'), // Added
  ColorOption(name: 'Camel', hexCode: '#C19A6B'), // Added
  // Metallic & Special
  ColorOption(name: 'Rose Gold', hexCode: '#B76E79'),
  ColorOption(name: 'Bronze', hexCode: '#CD7F32'),
  ColorOption(name: 'Copper', hexCode: '#B87333'),
];

// ============================================================================
// BRAND SYSTEM
// ============================================================================

class BrandOption {
  final String id;
  final String name;
  final String? category; // null = available for all categories
  final bool isLocal;
  final String? logoUrl; // Optional brand logo

  const BrandOption({
    required this.id,
    required this.name,
    this.category,
    this.isLocal = false,
    this.logoUrl,
  });

  static const localBrand = BrandOption(
    id: 'local',
    name: '✨ Add Local Brand',
    isLocal: true,
  );

  bool get isPredefined => !isLocal;
}

const List<BrandOption> predefinedBrands = [
  // === Electronics ===
  BrandOption(
    id: 'samsung',
    name: 'Samsung',
    category: 'Electronics',
    logoUrl: 'assets/brands/samsung.png',
  ),
  BrandOption(
    id: 'apple',
    name: 'Apple',
    category: 'Electronics',
    logoUrl: 'assets/brands/apple.png',
  ),
  BrandOption(id: 'sony', name: 'Sony', category: 'Electronics'),
  BrandOption(id: 'lg', name: 'LG', category: 'Electronics'),
  BrandOption(id: 'bose', name: 'Bose', category: 'Electronics'),
  BrandOption(id: 'jbl', name: 'JBL', category: 'Electronics'),
  BrandOption(id: 'anker', name: 'Anker', category: 'Electronics'),
  BrandOption(id: 'logitech', name: 'Logitech', category: 'Electronics'),
  BrandOption(id: 'dell', name: 'Dell', category: 'Electronics'), // Added
  BrandOption(id: 'hp', name: 'HP', category: 'Electronics'), // Added
  BrandOption(id: 'lenovo', name: 'Lenovo', category: 'Electronics'), // Added
  BrandOption(id: 'asus', name: 'ASUS', category: 'Electronics'), // Added
  BrandOption(id: 'acer', name: 'Acer', category: 'Electronics'), // Added
  BrandOption(
    id: 'microsoft',
    name: 'Microsoft',
    category: 'Electronics',
  ), // Added
  BrandOption(id: 'google', name: 'Google', category: 'Electronics'), // Added
  BrandOption(id: 'oneplus', name: 'OnePlus', category: 'Electronics'), // Added
  BrandOption(id: 'xiaomi', name: 'Xiaomi', category: 'Electronics'), // Added
  BrandOption(id: 'razer', name: 'Razer', category: 'Electronics'), // Added
  // === Fashion & Apparel ===
  BrandOption(id: 'nike', name: 'Nike', category: 'Fashion & Apparel'),
  BrandOption(id: 'adidas', name: 'Adidas', category: 'Fashion & Apparel'),
  BrandOption(id: 'zara', name: 'Zara', category: 'Fashion & Apparel'),
  BrandOption(id: 'hm', name: 'H&M', category: 'Fashion & Apparel'),
  BrandOption(id: 'uniqlo', name: 'Uniqlo', category: 'Fashion & Apparel'),
  BrandOption(id: 'levi', name: "Levi's", category: 'Fashion & Apparel'),
  BrandOption(id: 'puma', name: 'Puma', category: 'Fashion & Apparel'),
  BrandOption(
    id: 'underarmour',
    name: 'Under Armour',
    category: 'Fashion & Apparel',
  ),
  BrandOption(id: 'gap', name: 'GAP', category: 'Fashion & Apparel'), // Added
  BrandOption(
    id: 'oldnavy',
    name: 'Old Navy',
    category: 'Fashion & Apparel',
  ), // Added
  BrandOption(
    id: 'tommyhilfiger',
    name: 'Tommy Hilfiger',
    category: 'Fashion & Apparel',
  ), // Added
  BrandOption(
    id: 'ralphlauren',
    name: 'Ralph Lauren',
    category: 'Fashion & Apparel',
  ), // Added
  BrandOption(
    id: 'champion',
    name: 'Champion',
    category: 'Fashion & Apparel',
  ), // Added
  BrandOption(
    id: 'reebok',
    name: 'Reebok',
    category: 'Fashion & Apparel',
  ), // Added
  BrandOption(
    id: 'newbalance',
    name: 'New Balance',
    category: 'Fashion & Apparel',
  ), // Added
  BrandOption(
    id: 'converse',
    name: 'Converse',
    category: 'Fashion & Apparel',
  ), // Added
  BrandOption(id: 'vans', name: 'Vans', category: 'Fashion & Apparel'), // Added
  BrandOption(
    id: 'timberland',
    name: 'Timberland',
    category: 'Fashion & Apparel',
  ), // Added
  // === Home & Living ===
  BrandOption(id: 'ikea', name: 'IKEA', category: 'Home & Living'),
  BrandOption(id: 'dyson', name: 'Dyson', category: 'Home & Living'),
  BrandOption(id: 'philips', name: 'Philips', category: 'Home & Living'),
  BrandOption(id: 'rubbermaid', name: 'Rubbermaid', category: 'Home & Living'),
  BrandOption(
    id: 'lecreuset',
    name: 'Le Creuset',
    category: 'Home & Living',
  ), // Added
  BrandOption(
    id: 'kitchenaid',
    name: 'KitchenAid',
    category: 'Home & Living',
  ), // Added
  BrandOption(id: 'oxo', name: 'OXO', category: 'Home & Living'), // Added
  BrandOption(id: 'pyrex', name: 'Pyrex', category: 'Home & Living'), // Added
  BrandOption(id: 'tfal', name: 'T-fal', category: 'Home & Living'), // Added
  // === Beauty & Personal Care ===
  BrandOption(
    id: 'loreal',
    name: "L'Oréal",
    category: 'Beauty & Personal Care',
  ),
  BrandOption(
    id: 'maybelline',
    name: 'Maybelline',
    category: 'Beauty & Personal Care',
  ),
  BrandOption(id: 'cerave', name: 'CeraVe', category: 'Beauty & Personal Care'),
  BrandOption(
    id: 'neutrogena',
    name: 'Neutrogena',
    category: 'Beauty & Personal Care',
  ),
  BrandOption(
    id: 'esteelauder',
    name: 'Estée Lauder',
    category: 'Beauty & Personal Care',
  ), // Added
  BrandOption(
    id: 'clinique',
    name: 'Clinique',
    category: 'Beauty & Personal Care',
  ), // Added
  BrandOption(
    id: 'theordinary',
    name: 'The Ordinary',
    category: 'Beauty & Personal Care',
  ), // Added
  BrandOption(
    id: 'glossier',
    name: 'Glossier',
    category: 'Beauty & Personal Care',
  ), // Added
  BrandOption(
    id: 'fenty',
    name: 'Fenty Beauty',
    category: 'Beauty & Personal Care',
  ), // Added
  BrandOption(
    id: 'burtsbees',
    name: "Burt's Bees",
    category: 'Beauty & Personal Care',
  ), // Added
  // === Sports & Outdoors ===
  BrandOption(id: 'columbia', name: 'Columbia', category: 'Sports & Outdoors'),
  BrandOption(
    id: 'thenorthface',
    name: 'The North Face',
    category: 'Sports & Outdoors',
  ),
  BrandOption(id: 'yeti', name: 'YETI', category: 'Sports & Outdoors'),
  BrandOption(
    id: 'patagonia',
    name: 'Patagonia',
    category: 'Sports & Outdoors',
  ), // Added
  BrandOption(
    id: 'arcteryx',
    name: "Arc'teryx",
    category: 'Sports & Outdoors',
  ), // Added
  BrandOption(
    id: 'salomon',
    name: 'Salomon',
    category: 'Sports & Outdoors',
  ), // Added
  BrandOption(
    id: 'merrell',
    name: 'Merrell',
    category: 'Sports & Outdoors',
  ), // Added
  BrandOption(
    id: 'rei',
    name: 'REI Co-op',
    category: 'Sports & Outdoors',
  ), // Added
  // === Universal Brands (category = null) ===
  BrandOption(id: 'generic', name: 'Generic', category: null),
  BrandOption(id: 'unbranded', name: 'Unbranded', category: null),
  BrandOption(id: 'other', name: 'Other', category: null), // Added
];

// ============================================================================
// CATEGORY & SUBCATEGORY STRUCTURE
// ============================================================================

/// Main category definitions with metadata
class CategoryDefinition {
  final String id;
  final String name;
  final String icon;
  final String description;
  final List<String> subcategories;
  final bool requiresColor; // Show color picker for this category
  final bool requiresCondition; // Show condition selector

  const CategoryDefinition({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    required this.subcategories,
    this.requiresColor = false,
    this.requiresCondition = true,
  });
}

const Map<String, CategoryDefinition> categoryDefinitions = {
  'fashion_apparel': CategoryDefinition(
    id: 'fashion_apparel',
    name: 'Fashion & Apparel',
    icon: '👕',
    description: 'Clothing, shoes, accessories, and fashion items',
    requiresColor: true,
    subcategories: [
      'T-Shirts',
      'Jeans',
      'Shoes',
      'Jackets',
      'Dresses',
      'Activewear',
      'Accessories',
      'Sweaters',
      'Shorts',
      'Skirts',
      'Blouses & Shirts', // Added
      'Pants (Non-Denim)', // Added
      'Suits & Blazers', // Added
      'Underwear & Socks', // Added
      'Swimwear', // Added
      'Sleepwear', // Added
    ],
  ),
  'electronics': CategoryDefinition(
    id: 'electronics',
    name: 'Electronics',
    icon: '🔌',
    description: 'Phones, computers, audio, and electronic devices',
    subcategories: [
      'Smartphones',
      'Laptops',
      'Headphones',
      'Cameras',
      'Tablets',
      'Smart Watches',
      'Gaming Consoles',
      'Speakers',
      'Monitors',
      'Chargers',
      'Smart Home Devices', // Added
      'Drones', // Added
      'VR Headsets', // Added
      'E-Readers', // Added
      'Power Banks', // Added
      'Cables & Adapters', // Added
    ],
  ),
  'lighting_electrical': CategoryDefinition(
    id: 'lighting_electrical',
    name: 'Lighting & Electrical',
    icon: '💡',
    description: 'Light bulbs, lamps, wires, switches, and electrical supplies',
    subcategories: [
      'Light Bulbs',
      'Lamps',
      'Wires & Cables',
      'Switches',
      'LED Strips',
      'Outdoor Lighting',
      'Dimmers',
      'Outlets',
      'Smart Lighting', // Added
      'Decorative Lights', // Added
    ],
  ),
  'home_living': CategoryDefinition(
    id: 'home_living',
    name: 'Home & Living',
    icon: '🏠',
    description: 'Furniture, kitchenware, bedding, decor, and home essentials',
    subcategories: [
      'Furniture',
      'Kitchenware',
      'Bedding',
      'Decor',
      'Storage & Organization',
      'Bathroom',
      'Rugs',
      'Curtains',
      'Garden & Patio', // Added
      'Cleaning Supplies', // Added
      'Office Supplies', // Added
    ],
  ),
  'beauty_personal_care': CategoryDefinition(
    id: 'beauty_personal_care',
    name: 'Beauty & Personal Care',
    icon: '💄',
    description: 'Skincare, makeup, fragrance, haircare, and grooming',
    requiresColor: true,
    subcategories: [
      'Skincare',
      'Makeup',
      'Fragrance',
      'Haircare',
      'Personal Care',
      "Men's Grooming",
      'Nail Care',
      'Bath & Body',
      'Sun Care', // Added
      'Shaving & Hair Removal', // Added
      'Oral Care', // Added
      'Tools & Brushes', // Added
    ],
  ),
  'sports_outdoors': CategoryDefinition(
    id: 'sports_outdoors',
    name: 'Sports & Outdoors',
    icon: '⚽',
    description:
        'Gym equipment, camping gear, sports balls, and outdoor activities',
    subcategories: [
      'Gym Equipment',
      'Camping',
      'Sports Balls',
      'Cycling',
      'Water Sports',
      'Team Sports',
      'Running',
      'Hiking',
      'Snow Sports', // Added
      'Fitness Trackers', // Added
      'Water Bottles & Hydration', // Added
      'Sportswear', // Added
    ],
  ),
};

/// Helper getters for backward compatibility
String getCategoryIdByName(String categoryName) {
  return categoryDefinitions.entries
      .firstWhere(
        (e) => e.value.name == categoryName,
        orElse: () => categoryDefinitions.entries.first,
      )
      .key;
}

CategoryDefinition? getCategoryDefinitionById(String id) =>
    categoryDefinitions[id];
CategoryDefinition? getCategoryDefinitionByName(String name) {
  return categoryDefinitions.values.firstWhere(
    (c) => c.name == name,
    orElse: () => categoryDefinitions.values.first,
  );
}

List<String> getSubcategoriesForCategory(String categoryId) {
  return categoryDefinitions[categoryId]?.subcategories ?? [];
}

// ============================================================================
// PRODUCT ATTRIBUTE DEFINITIONS
// ============================================================================

class ProductAttribute {
  final String key;
  final String label;
  final AttributeType type;
  final List<String>? options; // For dropdown/multiSelect
  final String? hint; // Placeholder text for text/number fields
  final bool required;
  final String? unit; // e.g., 'W', 'V', 'kg', 'ml'
  final num? min; // For number type
  final num? maxlenth; // For number type
  final Map<String, String>?
  conditionalOptions; // Show options based on another attribute

  const ProductAttribute({
    required this.key,
    required this.label,
    required this.type,
    this.options,
    this.hint,
    this.required = false,
    this.unit,
    this.min,
    this.maxlenth,
    this.conditionalOptions,
  });

  String formatValue(dynamic value) {
    if (value == null) return '';
    if (unit != null && value is num) return '$value $unit';
    return value.toString();
  }
}

/// Get attributes for a specific subcategory
List<ProductAttribute> getAttributesForSubcategory(String subcategory) {
  switch (subcategory) {
    // === FASHION & APPAREL ===
    case 'T-Shirts':
      return [
        ProductAttribute(
          key: 'size',
          label: 'Size',
          type: AttributeType.dropdown,
          options: ['XS', 'S', 'M', 'L', 'XL', 'XXL', 'XXXL'],
          required: true,
        ),
        ProductAttribute(
          key: 'material',
          label: 'Material',
          type: AttributeType.dropdown,
          options: [
            '100% Cotton',
            'Cotton Blend',
            'Polyester',
            'Linen',
            'Bamboo',
            'Wool',
          ],
          required: true,
        ),
        ProductAttribute(
          key: 'fit',
          label: 'Fit Style',
          type: AttributeType.dropdown,
          options: ['Slim Fit', 'Regular Fit', 'Relaxed Fit', 'Oversized'],
        ),
        ProductAttribute(
          key: 'neckline',
          label: 'Neckline',
          type: AttributeType.dropdown,
          options: ['Crew Neck', 'V-Neck', 'Henley', 'Polo', 'Scoop Neck'],
        ),
        ProductAttribute(
          key: 'sleeve_length',
          label: 'Sleeve Length',
          type: AttributeType.dropdown,
          options: ['Short Sleeve', 'Long Sleeve', 'Sleeveless', '3/4 Sleeve'],
        ),
        ProductAttribute(
          key: 'care_instructions',
          label: 'Care Instructions',
          type: AttributeType.dropdown,
          options: [
            'Machine Wash',
            'Hand Wash',
            'Dry Clean Only',
            'Do Not Bleach',
          ],
          hint: 'Select primary care method',
        ),
      ];

    case 'Jeans':
      return [
        ProductAttribute(
          key: 'waist_size',
          label: 'Waist Size',
          type: AttributeType.dropdown,
          options: ['28', '30', '32', '34', '36', '38', '40', '42'],
          required: true,
          unit: 'in',
        ),
        ProductAttribute(
          key: 'inseam',
          label: 'Inseam Length',
          type: AttributeType.dropdown,
          options: ['30', '32', '34', '36'],
          unit: 'in',
        ),
        ProductAttribute(
          key: 'fit',
          label: 'Fit',
          type: AttributeType.dropdown,
          options: ['Skinny', 'Slim', 'Straight', 'Relaxed', 'Bootcut'],
          required: true,
        ),
        ProductAttribute(
          key: 'rise',
          label: 'Rise',
          type: AttributeType.dropdown,
          options: ['Low Rise', 'Mid Rise', 'High Rise'],
        ),
        ProductAttribute(
          key: 'stretch',
          label: 'Stretch',
          type: AttributeType.boolean,
          hint: 'Contains elastane/spandex',
        ),
        ProductAttribute(
          key: 'wash',
          label: 'Wash Style',
          type: AttributeType.dropdown,
          options: [
            'Dark Wash',
            'Medium Wash',
            'Light Wash',
            'Black',
            'Distressed',
          ],
        ),
      ];

    case 'Shoes':
      return [
        ProductAttribute(
          key: 'size_us',
          label: 'Size (US)',
          type: AttributeType.dropdown,
          options: [
            '7',
            '7.5',
            '8',
            '8.5',
            '9',
            '9.5',
            '10',
            '10.5',
            '11',
            '11.5',
            '12',
            '13',
          ],
          required: true,
        ),
        ProductAttribute(
          key: 'size_type',
          label: 'Size Type',
          type: AttributeType.dropdown,
          options: ['Men', 'Women', 'Unisex', 'Kids'],
          required: true,
        ),
        ProductAttribute(
          key: 'material_upper',
          label: 'Upper Material',
          type: AttributeType.dropdown,
          options: ['Leather', 'Suede', 'Canvas', 'Synthetic', 'Mesh', 'Knit'],
        ),
        ProductAttribute(
          key: 'sole_material',
          label: 'Sole Material',
          type: AttributeType.dropdown,
          options: ['Rubber', 'EVA', 'Leather', 'Synthetic'],
        ),
        ProductAttribute(
          key: 'closure',
          label: 'Closure Type',
          type: AttributeType.dropdown,
          options: ['Lace-Up', 'Slip-On', 'Velcro', 'Zipper', 'Buckle'],
        ),
        ProductAttribute(
          key: 'heel_height',
          label: 'Heel Height',
          type: AttributeType.dropdown,
          options: ['Flat (<1")', 'Low (1-2")', 'Medium (2-3")', 'High (3"+)'],
        ),
      ];

    case 'Jackets':
      return [
        ProductAttribute(
          key: 'size',
          label: 'Size',
          type: AttributeType.dropdown,
          options: ['XS', 'S', 'M', 'L', 'XL', 'XXL'],
          required: true,
        ),
        ProductAttribute(
          key: 'material_outer',
          label: 'Outer Material',
          type: AttributeType.dropdown,
          options: ['Leather', 'Denim', 'Polyester', 'Nylon', 'Cotton', 'Wool'],
          required: true,
        ),
        ProductAttribute(
          key: 'insulation',
          label: 'Insulation',
          type: AttributeType.dropdown,
          options: ['None/Light', 'Fleece', 'Down', 'Synthetic Fill'],
        ),
        ProductAttribute(
          key: 'waterproof',
          label: 'Waterproof',
          type: AttributeType.boolean,
        ),
        ProductAttribute(
          key: 'hood',
          label: 'Hood',
          type: AttributeType.boolean,
        ),
        ProductAttribute(
          key: 'seasons',
          label: 'Best For',
          type: AttributeType.multiSelect,
          options: ['Spring', 'Summer', 'Fall', 'Winter'],
        ),
      ];

    case 'Dresses':
      return [
        ProductAttribute(
          key: 'size',
          label: 'Size',
          type: AttributeType.dropdown,
          options: ['XS', 'S', 'M', 'L', 'XL'],
          required: true,
        ),
        ProductAttribute(
          key: 'length',
          label: 'Dress Length',
          type: AttributeType.dropdown,
          options: ['Mini', 'Midi', 'Knee-Length', 'Maxi'],
          required: true,
        ),
        ProductAttribute(
          key: 'fabric',
          label: 'Fabric',
          type: AttributeType.dropdown,
          options: ['Cotton', 'Polyester', 'Silk', 'Linen', 'Viscose', 'Lace'],
        ),
        ProductAttribute(
          key: 'sleeve',
          label: 'Sleeve Style',
          type: AttributeType.dropdown,
          options: [
            'Sleeveless',
            'Short Sleeve',
            '3/4 Sleeve',
            'Long Sleeve',
            'Off Shoulder',
          ],
        ),
        ProductAttribute(
          key: 'occasion',
          label: 'Occasion',
          type: AttributeType.dropdown,
          options: ['Casual', 'Formal', 'Party', 'Work', 'Beach'],
        ),
      ];

    case 'Activewear':
      return [
        ProductAttribute(
          key: 'size',
          label: 'Size',
          type: AttributeType.dropdown,
          options: ['XS', 'S', 'M', 'L', 'XL', 'XXL'],
          required: true,
        ),
        ProductAttribute(
          key: 'activity',
          label: 'Activity',
          type: AttributeType.multiSelect,
          options: ['Running', 'Yoga', 'Gym', 'Cycling', 'Swimming', 'Hiking'],
          required: true,
        ),
        ProductAttribute(
          key: 'material',
          label: 'Material',
          type: AttributeType.dropdown,
          options: ['Polyester', 'Spandex', 'Nylon', 'Cotton Blend', 'Bamboo'],
        ),
        ProductAttribute(
          key: 'moisture_wicking',
          label: 'Moisture Wicking',
          type: AttributeType.boolean,
        ),
        ProductAttribute(
          key: 'compression',
          label: 'Compression',
          type: AttributeType.boolean,
        ),
      ];

    case 'Accessories':
      return [
        ProductAttribute(
          key: 'type',
          label: 'Accessory Type',
          type: AttributeType.dropdown,
          options: [
            'Belt',
            'Sunglasses',
            'Watch',
            'Hat',
            'Scarf',
            'Gloves',
            'Wallet',
            'Bag',
          ],
          required: true,
        ),
        ProductAttribute(
          key: 'material',
          label: 'Material',
          type: AttributeType.dropdown,
          options: ['Leather', 'Metal', 'Fabric', 'Plastic', 'Canvas'],
        ),
        ProductAttribute(
          key: 'gender',
          label: 'Gender',
          type: AttributeType.dropdown,
          options: ['Men', 'Women', 'Unisex'],
        ),
        ProductAttribute(
          key: 'size',
          label: 'Size/One Size',
          type: AttributeType.text,
          hint: 'e.g., One Size, Medium, 7¾',
        ),
      ];

    case 'Sweaters':
      return [
        ProductAttribute(
          key: 'size',
          label: 'Size',
          type: AttributeType.dropdown,
          options: ['XS', 'S', 'M', 'L', 'XL', 'XXL'],
          required: true,
        ),
        ProductAttribute(
          key: 'material',
          label: 'Material',
          type: AttributeType.dropdown,
          options: [
            'Cashmere',
            'Merino Wool',
            'Cotton',
            'Acrylic',
            'Wool Blend',
          ],
          required: true,
        ),
        ProductAttribute(
          key: 'neckline',
          label: 'Neckline',
          type: AttributeType.dropdown,
          options: ['Crew Neck', 'V-Neck', 'Turtleneck', 'Cardigan', 'Shawl'],
        ),
        ProductAttribute(
          key: 'pattern',
          label: 'Pattern',
          type: AttributeType.dropdown,
          options: ['Solid', 'Striped', 'Fair Isle', 'Ribbed', 'Cable Knit'],
        ),
      ];

    case 'Shorts':
      return [
        ProductAttribute(
          key: 'size',
          label: 'Size',
          type: AttributeType.dropdown,
          options: ['XS', 'S', 'M', 'L', 'XL', 'XXL'],
          required: true,
        ),
        ProductAttribute(
          key: 'length_inseam',
          label: 'Inseam',
          type: AttributeType.dropdown,
          options: ['3"', '5"', '7"', '9"', '11"'],
          required: true,
          unit: 'in',
        ),
        ProductAttribute(
          key: 'fabric',
          label: 'Fabric',
          type: AttributeType.dropdown,
          options: ['Cotton', 'Denim', 'Linen', 'Polyester', 'Nylon'],
        ),
        ProductAttribute(
          key: 'style',
          label: 'Style',
          type: AttributeType.dropdown,
          options: ['Casual', 'Cargo', 'Athletic', 'Chino', 'Board Shorts'],
        ),
      ];

    case 'Skirts':
      return [
        ProductAttribute(
          key: 'size',
          label: 'Size',
          type: AttributeType.dropdown,
          options: ['XS', 'S', 'M', 'L', 'XL'],
          required: true,
        ),
        ProductAttribute(
          key: 'length',
          label: 'Length',
          type: AttributeType.dropdown,
          options: ['Mini', 'Knee', 'Midi', 'Maxi'],
          required: true,
        ),
        ProductAttribute(
          key: 'style',
          label: 'Style',
          type: AttributeType.dropdown,
          options: ['A-Line', 'Pencil', 'Pleated', 'Wrap', 'Fitted'],
        ),
        ProductAttribute(
          key: 'fabric',
          label: 'Fabric',
          type: AttributeType.dropdown,
          options: ['Cotton', 'Denim', 'Leather', 'Silk', 'Polyester'],
        ),
      ];

    case 'Blouses & Shirts':
      return [
        ProductAttribute(
          key: 'size',
          label: 'Size',
          type: AttributeType.dropdown,
          options: ['XS', 'S', 'M', 'L', 'XL'],
          required: true,
        ),
        ProductAttribute(
          key: 'collar',
          label: 'Collar',
          type: AttributeType.dropdown,
          options: ['Button-Down', 'Spread', 'Mandarin', 'Peter Pan', 'None'],
        ),
        ProductAttribute(
          key: 'sleeve',
          label: 'Sleeve',
          type: AttributeType.dropdown,
          options: ['Sleeveless', 'Short', '3/4', 'Long'],
        ),
        ProductAttribute(
          key: 'pattern',
          label: 'Pattern',
          type: AttributeType.dropdown,
          options: ['Solid', 'Striped', 'Checked', 'Floral', 'Polka Dot'],
        ),
      ];

    case 'Pants (Non-Denim)':
      return [
        ProductAttribute(
          key: 'size',
          label: 'Size',
          type: AttributeType.dropdown,
          options: ['XS', 'S', 'M', 'L', 'XL', 'XXL'],
          required: true,
        ),
        ProductAttribute(
          key: 'fit',
          label: 'Fit',
          type: AttributeType.dropdown,
          options: ['Slim', 'Straight', 'Relaxed', 'Wide Leg', 'Tapered'],
        ),
        ProductAttribute(
          key: 'material',
          label: 'Material',
          type: AttributeType.dropdown,
          options: ['Cotton', 'Linen', 'Polyester', 'Wool', 'Viscose'],
        ),
        ProductAttribute(
          key: 'style',
          label: 'Style',
          type: AttributeType.dropdown,
          options: ['Chinos', 'Khakis', 'Dress Pants', 'Sweatpants', 'Cargos'],
        ),
      ];

    case 'Suits & Blazers':
      return [
        ProductAttribute(
          key: 'size',
          label: 'Size',
          type: AttributeType.dropdown,
          options: ['36', '38', '40', '42', '44', '46', '48'],
          required: true,
        ),
        ProductAttribute(
          key: 'fit',
          label: 'Fit',
          type: AttributeType.dropdown,
          options: ['Slim', 'Modern', 'Classic'],
        ),
        ProductAttribute(
          key: 'pieces',
          label: 'Piece(s)',
          type: AttributeType.multiSelect,
          options: ['Jacket', 'Trousers', 'Vest'],
          required: true,
        ),
        ProductAttribute(
          key: 'material',
          label: 'Material',
          type: AttributeType.dropdown,
          options: ['Wool', 'Cotton', 'Linen', 'Polyester', 'Blend'],
        ),
      ];

    case 'Underwear & Socks':
      return [
        ProductAttribute(
          key: 'size',
          label: 'Size',
          type: AttributeType.dropdown,
          options: ['S', 'M', 'L', 'XL', 'One Size'],
          required: true,
        ),
        ProductAttribute(
          key: 'type',
          label: 'Type',
          type: AttributeType.dropdown,
          options: [
            'Briefs',
            'Boxers',
            'Boxer Briefs',
            'Bras',
            'Panties',
            'Socks',
          ],
          required: true,
        ),
        ProductAttribute(
          key: 'material',
          label: 'Material',
          type: AttributeType.dropdown,
          options: ['Cotton', 'Modal', 'Bamboo', 'Microfiber', 'Wool'],
        ),
        ProductAttribute(
          key: 'pack_size',
          label: 'Pack Size',
          type: AttributeType.number,
          min: 1,
          maxlenth: 20,
          hint: 'Number of items in pack',
        ),
      ];

    case 'Swimwear':
      return [
        ProductAttribute(
          key: 'size',
          label: 'Size',
          type: AttributeType.dropdown,
          options: ['XS', 'S', 'M', 'L', 'XL'],
          required: true,
        ),
        ProductAttribute(
          key: 'style',
          label: 'Style',
          type: AttributeType.dropdown,
          options: [
            'Bikini',
            'Tankini',
            'One-Piece',
            'Swim Trunks',
            'Boardshorts',
          ],
          required: true,
        ),
        ProductAttribute(
          key: 'material',
          label: 'Material',
          type: AttributeType.dropdown,
          options: ['Nylon', 'Spandex', 'Polyester', 'Lycra'],
        ),
        ProductAttribute(
          key: 'upf',
          label: 'UPF Rating',
          type: AttributeType.dropdown,
          options: ['None', 'UPF 15', 'UPF 30', 'UPF 50+'],
        ),
      ];

    case 'Sleepwear':
      return [
        ProductAttribute(
          key: 'size',
          label: 'Size',
          type: AttributeType.dropdown,
          options: ['XS', 'S', 'M', 'L', 'XL'],
          required: true,
        ),
        ProductAttribute(
          key: 'material',
          label: 'Material',
          type: AttributeType.dropdown,
          options: ['Cotton', 'Silk', 'Flannel', 'Modal', 'Fleece'],
          required: true,
        ),
        ProductAttribute(
          key: 'set',
          label: 'Set',
          type: AttributeType.boolean,
          hint: 'Top and bottom set',
        ),
        ProductAttribute(
          key: 'season',
          label: 'Season',
          type: AttributeType.dropdown,
          options: ['Summer', 'Winter', 'All Season'],
        ),
      ];

    // === ELECTRONICS ===
    case 'Smartphones':
      return [
        ProductAttribute(
          key: 'storage',
          label: 'Storage Capacity',
          type: AttributeType.dropdown,
          options: ['64GB', '128GB', '256GB', '512GB', '1TB'],
          required: true,
        ),
        ProductAttribute(
          key: 'ram',
          label: 'RAM',
          type: AttributeType.dropdown,
          options: ['4GB', '6GB', '8GB', '12GB', '16GB'],
          required: true,
        ),
        ProductAttribute(
          key: 'color',
          label: 'Color',
          type: AttributeType.dropdown,
          options: availableColors.map((c) => c.name).toList(),
        ),
        ProductAttribute(
          key: 'condition_details',
          label: 'Condition Details',
          type: AttributeType.text,
          hint: 'Describe any wear, scratches, or included accessories',
          maxlenth: 200,
        ),
        ProductAttribute(
          key: 'carrier_locked',
          label: 'Carrier Locked',
          type: AttributeType.boolean,
          hint: 'Only works with specific carrier',
        ),
        ProductAttribute(
          key: 'battery_health',
          label: 'Battery Health',
          type: AttributeType.dropdown,
          options: ['90-100%', '80-89%', '70-79%', 'Below 70%', 'Unknown'],
        ),
      ];

    case 'Laptops':
      return [
        ProductAttribute(
          key: 'processor',
          label: 'Processor',
          type: AttributeType.dropdown,
          options: [
            'Intel Core i3',
            'Intel Core i5',
            'Intel Core i7',
            'Intel Core i9',
            'AMD Ryzen 3',
            'AMD Ryzen 5',
            'AMD Ryzen 7',
            'AMD Ryzen 9',
            'Apple M1',
            'Apple M2',
            'Apple M3',
            'Apple M3 Pro',
            'Apple M3 Max',
          ],
          required: true,
        ),
        ProductAttribute(
          key: 'ram',
          label: 'RAM',
          type: AttributeType.dropdown,
          options: ['8GB', '16GB', '32GB', '64GB'],
          required: true,
        ),
        ProductAttribute(
          key: 'storage_type',
          label: 'Storage Type',
          type: AttributeType.dropdown,
          options: ['SSD', 'HDD', 'SSD + HDD'],
          required: true,
        ),
        ProductAttribute(
          key: 'storage_capacity',
          label: 'Storage Capacity',
          type: AttributeType.dropdown,
          options: ['256GB', '512GB', '1TB', '2TB', '4TB'],
          required: true,
        ),
        ProductAttribute(
          key: 'screen_size',
          label: 'Screen Size',
          type: AttributeType.dropdown,
          options: ['13"', '14"', '15.6"', '16"', '17"'],
          required: true,
        ),
        ProductAttribute(
          key: 'graphics',
          label: 'Graphics',
          type: AttributeType.dropdown,
          options: [
            'Integrated',
            'NVIDIA GeForce',
            'AMD Radeon',
            'Apple Silicon',
          ],
        ),
        ProductAttribute(
          key: 'os',
          label: 'Operating System',
          type: AttributeType.dropdown,
          options: ['Windows 11', 'Windows 10', 'macOS', 'Linux', 'ChromeOS'],
        ),
        ProductAttribute(
          key: 'keyboard_layout',
          label: 'Keyboard Layout',
          type: AttributeType.dropdown,
          options: ['US QWERTY', 'UK QWERTY', 'International', 'Backlit'],
        ),
      ];

    case 'Headphones':
      return [
        ProductAttribute(
          key: 'type',
          label: 'Type',
          type: AttributeType.dropdown,
          options: ['Over-Ear', 'On-Ear', 'In-Ear', 'True Wireless Earbuds'],
          required: true,
        ),
        ProductAttribute(
          key: 'connectivity',
          label: 'Connectivity',
          type: AttributeType.dropdown,
          options: [
            'Wireless (Bluetooth)',
            'Wired (3.5mm)',
            'USB-C',
            'Wireless + Wired',
          ],
          required: true,
        ),
        ProductAttribute(
          key: 'noise_cancelling',
          label: 'Active Noise Cancelling',
          type: AttributeType.boolean,
        ),
        ProductAttribute(
          key: 'battery_life',
          label: 'Battery Life',
          type: AttributeType.dropdown,
          options: [
            '<10 hours',
            '10-20 hours',
            '20-30 hours',
            '30+ hours',
            'N/A (Wired)',
          ],
          unit: 'h',
        ),
        ProductAttribute(
          key: 'microphone',
          label: 'Built-in Microphone',
          type: AttributeType.boolean,
        ),
        ProductAttribute(
          key: 'water_resistant',
          label: 'Water/Sweat Resistant',
          type: AttributeType.boolean,
          hint: 'IPX4 or higher rating',
        ),
      ];

    case 'Cameras':
      return [
        ProductAttribute(
          key: 'type',
          label: 'Camera Type',
          type: AttributeType.dropdown,
          options: [
            'DSLR',
            'Mirrorless',
            'Point & Shoot',
            'Instant',
            'Action Cam',
          ],
          required: true,
        ),
        ProductAttribute(
          key: 'megapixels',
          label: 'Megapixels',
          type: AttributeType.number,
          unit: 'MP',
          required: true,
          min: 1,
          maxlenth: 60,
        ),
        ProductAttribute(
          key: 'lens_mount',
          label: 'Lens Mount',
          type: AttributeType.dropdown,
          options: [
            'Canon EF',
            'Nikon F',
            'Sony E',
            'Micro Four Thirds',
            'Fixed',
          ],
        ),
        ProductAttribute(
          key: 'video_resolution',
          label: 'Video Resolution',
          type: AttributeType.dropdown,
          options: ['1080p', '4K', '6K', '8K'],
        ),
        ProductAttribute(
          key: 'includes_lens',
          label: 'Includes Lens',
          type: AttributeType.boolean,
        ),
      ];

    case 'Tablets':
      return [
        ProductAttribute(
          key: 'storage',
          label: 'Storage',
          type: AttributeType.dropdown,
          options: ['32GB', '64GB', '128GB', '256GB', '512GB'],
          required: true,
        ),
        ProductAttribute(
          key: 'ram',
          label: 'RAM',
          type: AttributeType.dropdown,
          options: ['3GB', '4GB', '6GB', '8GB', '16GB'],
          required: true,
        ),
        ProductAttribute(
          key: 'screen_size',
          label: 'Screen Size',
          type: AttributeType.dropdown,
          options: ['7-8"', '9-10"', '11-12"', '12.9"+'],
          required: true,
        ),
        ProductAttribute(
          key: 'connectivity',
          label: 'Connectivity',
          type: AttributeType.dropdown,
          options: ['Wi-Fi Only', 'Wi-Fi + Cellular'],
          required: true,
        ),
        ProductAttribute(
          key: 'stylus_support',
          label: 'Stylus Support',
          type: AttributeType.boolean,
        ),
      ];

    case 'Smart Watches':
      return [
        ProductAttribute(
          key: 'compatibility',
          label: 'Compatibility',
          type: AttributeType.multiSelect,
          options: ['iOS', 'Android'],
          required: true,
        ),
        ProductAttribute(
          key: 'display_type',
          label: 'Display',
          type: AttributeType.dropdown,
          options: ['AMOLED', 'LCD', 'Always-On AMOLED'],
        ),
        ProductAttribute(
          key: 'gps',
          label: 'Built-in GPS',
          type: AttributeType.boolean,
        ),
        ProductAttribute(
          key: 'heart_rate',
          label: 'Heart Rate Monitor',
          type: AttributeType.boolean,
        ),
        ProductAttribute(
          key: 'water_resistance',
          label: 'Water Resistance',
          type: AttributeType.dropdown,
          options: ['None', 'Water Resistant', 'Swimproof (5ATM)'],
        ),
        ProductAttribute(
          key: 'battery_life_days',
          label: 'Battery Life',
          type: AttributeType.number,
          unit: 'days',
          hint: 'Typical battery life',
        ),
      ];

    case 'Gaming Consoles':
      return [
        ProductAttribute(
          key: 'platform',
          label: 'Platform',
          type: AttributeType.dropdown,
          options: [
            'PlayStation 5',
            'Xbox Series X/S',
            'Nintendo Switch',
            'Steam Deck',
          ],
          required: true,
        ),
        ProductAttribute(
          key: 'edition',
          label: 'Edition',
          type: AttributeType.dropdown,
          options: ['Digital Only', 'Disc Version', 'OLED Model', 'Lite'],
        ),
        ProductAttribute(
          key: 'storage',
          label: 'Internal Storage',
          type: AttributeType.dropdown,
          options: ['64GB', '128GB', '256GB', '512GB', '1TB'],
        ),
        ProductAttribute(
          key: 'includes_controller',
          label: 'Controllers Included',
          type: AttributeType.number,
          min: 0,
          maxlenth: 4,
          required: true,
        ),
        ProductAttribute(
          key: 'condition_peripherals',
          label: 'Condition of included items',
          type: AttributeType.text,
          hint: 'Describe condition of console, cables, packaging',
        ),
      ];

    case 'Speakers':
      return [
        ProductAttribute(
          key: 'type',
          label: 'Speaker Type',
          type: AttributeType.dropdown,
          options: [
            'Bluetooth Portable',
            'Smart Speaker',
            'Soundbar',
            'Bookshelf',
            'Subwoofer',
          ],
          required: true,
        ),
        ProductAttribute(
          key: 'connectivity',
          label: 'Connectivity',
          type: AttributeType.multiSelect,
          options: ['Bluetooth', 'Wi-Fi', '3.5mm AUX', 'USB', 'Optical'],
        ),
        ProductAttribute(
          key: 'waterproof_rating',
          label: 'Waterproof Rating',
          type: AttributeType.dropdown,
          options: ['None', 'IPX4', 'IPX5', 'IPX7', 'IP67'],
        ),
        ProductAttribute(
          key: 'voice_assistant',
          label: 'Voice Assistant Built-in',
          type: AttributeType.dropdown,
          options: ['None', 'Alexa', 'Google Assistant', 'Siri'],
        ),
        ProductAttribute(
          key: 'battery_life_hours',
          label: 'Battery Life',
          type: AttributeType.number,
          unit: 'h',
          hint: 'For portable speakers',
        ),
      ];

    case 'Monitors':
      return [
        ProductAttribute(
          key: 'screen_size',
          label: 'Screen Size',
          type: AttributeType.dropdown,
          options: ['21-24"', '27"', '32"', '34" Ultrawide', '27" 4K'],
          required: true,
        ),
        ProductAttribute(
          key: 'resolution',
          label: 'Resolution',
          type: AttributeType.dropdown,
          options: ['1080p (FHD)', '1440p (QHD)', '4K (UHD)', '5K'],
          required: true,
        ),
        ProductAttribute(
          key: 'refresh_rate',
          label: 'Refresh Rate',
          type: AttributeType.dropdown,
          options: ['60Hz', '75Hz', '120Hz', '144Hz', '240Hz'],
        ),
        ProductAttribute(
          key: 'panel',
          label: 'Panel Type',
          type: AttributeType.dropdown,
          options: ['IPS', 'VA', 'TN', 'OLED'],
        ),
        ProductAttribute(
          key: 'adjustability',
          label: 'Adjustability',
          type: AttributeType.multiSelect,
          options: ['Height Adjust', 'Tilt', 'Swivel', 'Pivot', 'VESA Mount'],
        ),
      ];

    case 'Chargers':
      return [
        ProductAttribute(
          key: 'charging_type',
          label: 'Charging Type',
          type: AttributeType.dropdown,
          options: [
            'Wall Charger',
            'Car Charger',
            'Wireless Charger',
            'Multi-Port',
          ],
          required: true,
        ),
        ProductAttribute(
          key: 'wattage',
          label: 'Max Output',
          type: AttributeType.dropdown,
          options: ['5W', '10W', '18W', '25W', '45W', '65W', '100W+'],
          unit: 'W',
        ),
        ProductAttribute(
          key: 'ports',
          label: 'Ports',
          type: AttributeType.text,
          hint: 'e.g., 1x USB-C, 1x USB-A',
        ),
        ProductAttribute(
          key: 'fast_charging',
          label: 'Fast Charging Supported',
          type: AttributeType.boolean,
        ),
        ProductAttribute(
          key: 'cable_included',
          label: 'Cable Included',
          type: AttributeType.boolean,
        ),
      ];

    case 'Smart Home Devices':
      return [
        ProductAttribute(
          key: 'device_type',
          label: 'Device Type',
          type: AttributeType.dropdown,
          options: [
            'Smart Plug',
            'Smart Bulb',
            'Smart Thermostat',
            'Smart Lock',
            'Hub',
          ],
          required: true,
        ),
        ProductAttribute(
          key: 'compatibility',
          label: 'Works With',
          type: AttributeType.multiSelect,
          options: [
            'Alexa',
            'Google Assistant',
            'Apple HomeKit',
            'IFTTT',
            'Zigbee',
          ],
        ),
        ProductAttribute(
          key: 'hub_required',
          label: 'Hub Required',
          type: AttributeType.boolean,
        ),
        ProductAttribute(
          key: 'wifi',
          label: 'Wi-Fi',
          type: AttributeType.boolean,
          hint: 'Connects directly to Wi-Fi',
        ),
      ];

    case 'Drones':
      return [
        ProductAttribute(
          key: 'type',
          label: 'Drone Type',
          type: AttributeType.dropdown,
          options: ['Mini/Sub-250g', 'Hobby (250g-2kg)', 'Prosumer', 'FPV'],
          required: true,
        ),
        ProductAttribute(
          key: 'camera_resolution',
          label: 'Camera Resolution',
          type: AttributeType.dropdown,
          options: ['None', '1080p', '2.7K', '4K', '5.1K+'],
        ),
        ProductAttribute(
          key: 'flight_time',
          label: 'Flight Time',
          type: AttributeType.number,
          unit: 'min',
          min: 1,
          maxlenth: 45,
        ),
        ProductAttribute(key: 'gps', label: 'GPS', type: AttributeType.boolean),
        ProductAttribute(
          key: 'foldable',
          label: 'Foldable',
          type: AttributeType.boolean,
        ),
      ];

    case 'VR Headsets':
      return [
        ProductAttribute(
          key: 'platform',
          label: 'Platform',
          type: AttributeType.dropdown,
          options: ['PC VR', 'Standalone', 'PlayStation VR2', 'Mixed Reality'],
          required: true,
        ),
        ProductAttribute(
          key: 'resolution',
          label: 'Resolution (per eye)',
          type: AttributeType.text,
          hint: 'e.g., 1832x1920',
        ),
        ProductAttribute(
          key: 'refresh_rate',
          label: 'Refresh Rate',
          type: AttributeType.dropdown,
          options: ['72Hz', '90Hz', '120Hz'],
        ),
        ProductAttribute(
          key: 'controllers_included',
          label: 'Controllers Included',
          type: AttributeType.boolean,
        ),
      ];

    case 'E-Readers':
      return [
        ProductAttribute(
          key: 'screen_size',
          label: 'Screen Size',
          type: AttributeType.dropdown,
          options: ['6"', '6.8"', '7"', '8"', '10.3"'],
          required: true,
        ),
        ProductAttribute(
          key: 'backlight',
          label: 'Adjustable Backlight',
          type: AttributeType.boolean,
        ),
        ProductAttribute(
          key: 'waterproof',
          label: 'Waterproof (IPX8)',
          type: AttributeType.boolean,
        ),
        ProductAttribute(
          key: 'storage',
          label: 'Storage',
          type: AttributeType.dropdown,
          options: ['8GB', '16GB', '32GB'],
        ),
        ProductAttribute(
          key: 'stylus',
          label: 'Stylus Support',
          type: AttributeType.boolean,
        ),
      ];

    case 'Power Banks':
      return [
        ProductAttribute(
          key: 'capacity',
          label: 'Capacity',
          type: AttributeType.number,
          unit: 'mAh',
          required: true,
          min: 1000,
          maxlenth: 50000,
        ),
        ProductAttribute(
          key: 'output_ports',
          label: 'Output Ports',
          type: AttributeType.text,
          hint: 'e.g., 2x USB-A, 1x USB-C',
          required: true,
        ),
        ProductAttribute(
          key: 'fast_charging',
          label: 'Fast Charging',
          type: AttributeType.boolean,
        ),
        ProductAttribute(
          key: 'wireless_charging',
          label: 'Wireless Charging',
          type: AttributeType.boolean,
        ),
        ProductAttribute(
          key: 'weight',
          label: 'Weight',
          type: AttributeType.number,
          unit: 'g',
          hint: 'In grams',
        ),
      ];

    case 'Cables & Adapters':
      return [
        ProductAttribute(
          key: 'type',
          label: 'Type',
          type: AttributeType.dropdown,
          options: [
            'USB-C to USB-C',
            'USB-C to Lightning',
            'USB-C to HDMI',
            'USB-C Hub',
            'AUX Cable',
            'Ethernet Cable',
          ],
          required: true,
        ),
        ProductAttribute(
          key: 'length',
          label: 'Length',
          type: AttributeType.text,
          hint: 'e.g., 1m, 3ft',
        ),
        ProductAttribute(
          key: 'speed',
          label: 'Data Transfer Speed',
          type: AttributeType.dropdown,
          options: ['USB 2.0', 'USB 3.0', 'USB 3.1 Gen2', 'Thunderbolt 3/4'],
        ),
        ProductAttribute(
          key: 'braided',
          label: 'Braided',
          type: AttributeType.boolean,
        ),
      ];

    // === LIGHTING & ELECTRICAL ===
    case 'Light Bulbs':
      return [
        ProductAttribute(
          key: 'wattage',
          label: 'Wattage',
          type: AttributeType.number,
          required: true,
          unit: 'W',
          min: 1,
          maxlenth: 200,
        ),
        ProductAttribute(
          key: 'base_type',
          label: 'Base Type',
          type: AttributeType.dropdown,
          options: [
            'E26/E27 (Standard)',
            'E12/Candelabra',
            'E14',
            'B22 Bayonet',
            'GU10',
            'MR16',
          ],
          required: true,
        ),
        ProductAttribute(
          key: 'color_temp',
          label: 'Color Temperature',
          type: AttributeType.dropdown,
          options: [
            'Warm White (2700K)',
            'Soft White (3000K)',
            'Neutral (4000K)',
            'Cool White (5000K)',
            'Daylight (6500K)',
          ],
          required: true,
        ),
        ProductAttribute(
          key: 'lumens',
          label: 'Brightness',
          type: AttributeType.number,
          unit: 'lm',
          hint: 'Higher = brighter',
          min: 100,
          maxlenth: 3000,
        ),
        ProductAttribute(
          key: 'dimmable',
          label: 'Dimmable',
          type: AttributeType.boolean,
        ),
        ProductAttribute(
          key: 'bulb_shape',
          label: 'Bulb Shape',
          type: AttributeType.dropdown,
          options: [
            'A19 (Standard)',
            'A21',
            'BR30',
            'PAR38',
            'Globe',
            'Candle',
          ],
        ),
        ProductAttribute(
          key: 'lifespan',
          label: 'Estimated Lifespan',
          type: AttributeType.dropdown,
          options: ['1,000 hrs', '10,000 hrs', '15,000 hrs', '25,000+ hrs'],
          unit: 'hrs',
        ),
      ];

    case 'Lamps':
      return [
        ProductAttribute(
          key: 'type',
          label: 'Lamp Type',
          type: AttributeType.dropdown,
          options: ['Table Lamp', 'Floor Lamp', 'Desk Lamp', 'Clip Lamp'],
          required: true,
        ),
        ProductAttribute(
          key: 'bulb_included',
          label: 'Bulb Included',
          type: AttributeType.boolean,
        ),
        ProductAttribute(
          key: 'max_wattage',
          label: 'Max Wattage',
          type: AttributeType.number,
          unit: 'W',
        ),
        ProductAttribute(
          key: 'material',
          label: 'Material',
          type: AttributeType.dropdown,
          options: ['Metal', 'Wood', 'Plastic', 'Glass', 'Ceramic'],
        ),
      ];

    case 'Smart Lighting':
      return [
        ProductAttribute(
          key: 'type',
          label: 'Type',
          type: AttributeType.dropdown,
          options: ['Smart Bulb', 'Light Strip', 'Smart Switch', 'Smart Panel'],
          required: true,
        ),
        ProductAttribute(
          key: 'compatibility',
          label: 'Works With',
          type: AttributeType.multiSelect,
          options: [
            'Alexa',
            'Google Assistant',
            'Apple HomeKit',
            'Zigbee',
            'Bluetooth',
          ],
        ),
        ProductAttribute(
          key: 'color_rgb',
          label: 'Color (RGB)',
          type: AttributeType.boolean,
        ),
        ProductAttribute(
          key: 'tuneable_white',
          label: 'Tuneable White',
          type: AttributeType.boolean,
        ),
      ];

    case 'Decorative Lights':
      return [
        ProductAttribute(
          key: 'type',
          label: 'Type',
          type: AttributeType.dropdown,
          options: ['String Lights', 'Fairy Lights', 'Neon Sign', 'LED Strip'],
          required: true,
        ),
        ProductAttribute(
          key: 'length',
          label: 'Length',
          type: AttributeType.text,
          hint: 'e.g., 10m, 33ft',
        ),
        ProductAttribute(
          key: 'power_source',
          label: 'Power Source',
          type: AttributeType.dropdown,
          options: ['Plug-in', 'Battery', 'USB', 'Solar'],
        ),
        ProductAttribute(
          key: 'indoor_outdoor',
          label: 'Indoor/Outdoor',
          type: AttributeType.dropdown,
          options: ['Indoor Only', 'Outdoor Rated'],
        ),
      ];

    // === HOME & LIVING ===
    case 'Furniture':
      return [
        ProductAttribute(
          key: 'material',
          label: 'Primary Material',
          type: AttributeType.dropdown,
          options: [
            'Solid Wood',
            'Engineered Wood',
            'Metal',
            'Plastic',
            'Glass',
            'Fabric Upholstery',
            'Leather',
          ],
          required: true,
        ),
        ProductAttribute(
          key: 'dimensions',
          label: 'Dimensions (L×W×H)',
          type: AttributeType.text,
          hint: 'e.g., 60" × 30" × 36"',
          required: true,
        ),
        ProductAttribute(
          key: 'weight_capacity',
          label: 'Weight Capacity',
          type: AttributeType.number,
          unit: 'lbs',
          min: 1,
          maxlenth: 1000,
        ),
        ProductAttribute(
          key: 'assembly_required',
          label: 'Assembly Required',
          type: AttributeType.boolean,
        ),
        ProductAttribute(
          key: 'style',
          label: 'Style',
          type: AttributeType.dropdown,
          options: [
            'Modern',
            'Contemporary',
            'Traditional',
            'Industrial',
            'Scandinavian',
            'Rustic',
            'Mid-Century',
          ],
        ),
        ProductAttribute(
          key: 'room',
          label: 'Best For Room',
          type: AttributeType.multiSelect,
          options: [
            'Living Room',
            'Bedroom',
            'Dining Room',
            'Office',
            'Kitchen',
            'Outdoor',
          ],
        ),
      ];

    case 'Kitchenware':
      return [
        ProductAttribute(
          key: 'material',
          label: 'Material',
          type: AttributeType.dropdown,
          options: [
            'Stainless Steel',
            'Cast Iron',
            'Ceramic',
            'Glass',
            'Non-Stick Coating',
            'Silicone',
            'Copper',
          ],
          required: true,
        ),
        ProductAttribute(
          key: 'pieces',
          label: 'Number of Pieces',
          type: AttributeType.number,
          min: 1,
          maxlenth: 50,
        ),
        ProductAttribute(
          key: 'dishwasher_safe',
          label: 'Dishwasher Safe',
          type: AttributeType.boolean,
        ),
        ProductAttribute(
          key: 'oven_safe',
          label: 'Oven Safe',
          type: AttributeType.boolean,
          hint: 'Max temperature if applicable',
        ),
        ProductAttribute(
          key: 'induction_compatible',
          label: 'Induction Compatible',
          type: AttributeType.boolean,
        ),
        ProductAttribute(
          key: 'capacity',
          label: 'Capacity',
          type: AttributeType.text,
          hint: 'e.g., 3 Qt, 12 cups, 2L',
        ),
      ];

    case 'Decor':
      return [
        ProductAttribute(
          key: 'type',
          label: 'Decor Type',
          type: AttributeType.dropdown,
          options: [
            'Wall Art',
            'Vase',
            'Candles',
            'Clock',
            'Mirror',
            'Plant Pot',
          ],
          required: true,
        ),
        ProductAttribute(
          key: 'material',
          label: 'Material',
          type: AttributeType.dropdown,
          options: ['Ceramic', 'Glass', 'Metal', 'Wood', 'Canvas'],
        ),
        ProductAttribute(
          key: 'dimensions',
          label: 'Dimensions',
          type: AttributeType.text,
          hint: 'e.g., 12" × 16"',
        ),
        ProductAttribute(
          key: 'handmade',
          label: 'Handmade',
          type: AttributeType.boolean,
        ),
      ];

    case 'Storage & Organization':
      return [
        ProductAttribute(
          key: 'type',
          label: 'Type',
          type: AttributeType.dropdown,
          options: ['Basket', 'Bin', 'Shelf', 'Drawer Organizer', 'Hanger'],
          required: true,
        ),
        ProductAttribute(
          key: 'capacity',
          label: 'Capacity/Size',
          type: AttributeType.text,
          hint: 'e.g., 30L, 2-tier',
        ),
        ProductAttribute(
          key: 'material',
          label: 'Material',
          type: AttributeType.dropdown,
          options: ['Plastic', 'Fabric', 'Metal', 'Wood', 'Wicker'],
        ),
        ProductAttribute(
          key: 'stackable',
          label: 'Stackable',
          type: AttributeType.boolean,
        ),
      ];

    case 'Bedding':
      return [
        ProductAttribute(
          key: 'size',
          label: 'Bed Size',
          type: AttributeType.dropdown,
          options: ['Twin', 'Full', 'Queen', 'King', 'California King'],
          required: true,
        ),
        ProductAttribute(
          key: 'material',
          label: 'Material',
          type: AttributeType.dropdown,
          options: ['Cotton', 'Linen', 'Microfiber', 'Bamboo', 'Silk'],
        ),
        ProductAttribute(
          key: 'thread_count',
          label: 'Thread Count',
          type: AttributeType.number,
          hint: 'For sheets',
        ),
        ProductAttribute(
          key: 'set_includes',
          label: 'Set Includes',
          type: AttributeType.multiSelect,
          options: ['Fitted Sheet', 'Flat Sheet', 'Pillowcases', 'Duvet Cover'],
        ),
      ];

    case 'Bathroom':
      return [
        ProductAttribute(
          key: 'type',
          label: 'Type',
          type: AttributeType.dropdown,
          options: [
            'Towel',
            'Shower Curtain',
            'Bath Mat',
            'Soap Dispenser',
            'Toilet Brush',
          ],
          required: true,
        ),
        ProductAttribute(
          key: 'material',
          label: 'Material',
          type: AttributeType.dropdown,
          options: ['Cotton', 'Microfiber', 'Bamboo', 'Plastic', 'Ceramic'],
        ),
        ProductAttribute(
          key: 'size',
          label: 'Size',
          type: AttributeType.text,
          hint: 'e.g., 27" × 52" for towels',
        ),
      ];

    case 'Rugs':
      return [
        ProductAttribute(
          key: 'size',
          label: 'Size',
          type: AttributeType.dropdown,
          options: ['2x3', '4x6', '5x8', '8x10', '9x12'],
          required: true,
        ),
        ProductAttribute(
          key: 'material',
          label: 'Material',
          type: AttributeType.dropdown,
          options: ['Wool', 'Cotton', 'Synthetic', 'Jute', 'Silk'],
        ),
        ProductAttribute(
          key: 'pile_height',
          label: 'Pile Height',
          type: AttributeType.dropdown,
          options: ['Low', 'Medium', 'High/Shag'],
        ),
        ProductAttribute(
          key: 'indoor_outdoor',
          label: 'Indoor/Outdoor',
          type: AttributeType.dropdown,
          options: ['Indoor', 'Outdoor', 'Both'],
        ),
      ];

    case 'Curtains':
      return [
        ProductAttribute(
          key: 'length',
          label: 'Length',
          type: AttributeType.dropdown,
          options: ['63"', '84"', '96"', '108"', '120"'],
          required: true,
        ),
        ProductAttribute(
          key: 'width_per_panel',
          label: 'Width per Panel',
          type: AttributeType.text,
          hint: 'e.g., 52"',
        ),
        ProductAttribute(
          key: 'material',
          label: 'Material',
          type: AttributeType.dropdown,
          options: ['Cotton', 'Polyester', 'Linen', 'Velvet', 'Blackout'],
        ),
        ProductAttribute(
          key: 'header_type',
          label: 'Header Type',
          type: AttributeType.dropdown,
          options: ['Rod Pocket', 'Grommet', 'Tab Top', 'Pinch Pleat'],
        ),
      ];

    case 'Garden & Patio':
      return [
        ProductAttribute(
          key: 'type',
          label: 'Type',
          type: AttributeType.dropdown,
          options: [
            'Planter',
            'Garden Tools',
            'Outdoor Furniture',
            'Grill',
            'Umbrella',
          ],
          required: true,
        ),
        ProductAttribute(
          key: 'material',
          label: 'Material',
          type: AttributeType.dropdown,
          options: ['Wood', 'Metal', 'Plastic', 'Wicker', 'Ceramic'],
        ),
        ProductAttribute(
          key: 'weather_resistant',
          label: 'Weather Resistant',
          type: AttributeType.boolean,
        ),
      ];

    case 'Cleaning Supplies':
      return [
        ProductAttribute(
          key: 'type',
          label: 'Type',
          type: AttributeType.dropdown,
          options: [
            'Mop',
            'Broom',
            'Vacuum Attachment',
            'Spray Bottle',
            'Scrubber',
          ],
          required: true,
        ),
        ProductAttribute(
          key: 'material',
          label: 'Material',
          type: AttributeType.dropdown,
          options: ['Microfiber', 'Cotton', 'Plastic', 'Silicone'],
        ),
        ProductAttribute(
          key: 'reusable',
          label: 'Reusable',
          type: AttributeType.boolean,
        ),
      ];

    case 'Office Supplies':
      return [
        ProductAttribute(
          key: 'type',
          label: 'Type',
          type: AttributeType.dropdown,
          options: [
            'Notebook',
            'Pen',
            'Desk Organizer',
            'Stapler',
            'Whiteboard',
          ],
          required: true,
        ),
        ProductAttribute(
          key: 'material',
          label: 'Material',
          type: AttributeType.text,
          hint: 'e.g., Leather, Paper, Plastic',
        ),
        ProductAttribute(
          key: 'size',
          label: 'Size/Format',
          type: AttributeType.text,
          hint: 'e.g., A5, 3-hole punch',
        ),
      ];

    // === BEAUTY & PERSONAL CARE ===
    case 'Skincare':
      return [
        ProductAttribute(
          key: 'skin_type',
          label: 'Skin Type',
          type: AttributeType.multiSelect,
          options: [
            'Normal',
            'Dry',
            'Oily',
            'Combination',
            'Sensitive',
            'All Types',
          ],
          required: true,
        ),
        ProductAttribute(
          key: 'volume',
          label: 'Volume',
          type: AttributeType.number,
          unit: 'ml',
          required: true,
          min: 1,
          maxlenth: 1000,
        ),
        ProductAttribute(
          key: 'spf',
          label: 'SPF Rating',
          type: AttributeType.dropdown,
          options: ['None', 'SPF 15', 'SPF 30', 'SPF 50', 'SPF 50+'],
        ),
        ProductAttribute(
          key: 'key_ingredients',
          label: 'Key Ingredients',
          type: AttributeType.multiSelect,
          options: [
            'Hyaluronic Acid',
            'Vitamin C',
            'Retinol',
            'Niacinamide',
            'Salicylic Acid',
            'AHA/BHA',
            'Ceramides',
            'Peptides',
          ],
        ),
        ProductAttribute(
          key: 'fragrance_free',
          label: 'Fragrance Free',
          type: AttributeType.boolean,
        ),
        ProductAttribute(
          key: 'cruelty_free',
          label: 'Cruelty Free',
          type: AttributeType.boolean,
        ),
        ProductAttribute(
          key: 'vegan',
          label: 'Vegan Formula',
          type: AttributeType.boolean,
        ),
      ];

    case 'Makeup':
      return [
        ProductAttribute(
          key: 'type',
          label: 'Product Type',
          type: AttributeType.dropdown,
          options: [
            'Foundation',
            'Lipstick',
            'Eyeshadow',
            'Mascara',
            'Blush',
            'Concealer',
          ],
          required: true,
        ),
        ProductAttribute(
          key: 'shade',
          label: 'Shade/Color',
          type: AttributeType.text,
          hint: 'e.g., Ivory, Ruby, 220 Natural',
        ),
        ProductAttribute(
          key: 'finish',
          label: 'Finish',
          type: AttributeType.dropdown,
          options: ['Matte', 'Dewy', 'Satin', 'Shimmer', 'Glossy'],
        ),
        ProductAttribute(
          key: 'long_wear',
          label: 'Long Wear',
          type: AttributeType.boolean,
        ),
      ];

    case 'Fragrance':
      return [
        ProductAttribute(
          key: 'type',
          label: 'Type',
          type: AttributeType.dropdown,
          options: [
            'Eau de Parfum',
            'Eau de Toilette',
            'Eau de Cologne',
            'Perfume Oil',
          ],
          required: true,
        ),
        ProductAttribute(
          key: 'volume',
          label: 'Volume',
          type: AttributeType.number,
          unit: 'ml',
          required: true,
        ),
        ProductAttribute(
          key: 'scent_family',
          label: 'Scent Family',
          type: AttributeType.multiSelect,
          options: ['Floral', 'Woody', 'Citrus', 'Oriental', 'Fresh'],
        ),
        ProductAttribute(
          key: 'unisex',
          label: 'Unisex',
          type: AttributeType.boolean,
        ),
      ];

    case 'Haircare':
      return [
        ProductAttribute(
          key: 'type',
          label: 'Type',
          type: AttributeType.dropdown,
          options: [
            'Shampoo',
            'Conditioner',
            'Hair Mask',
            'Styling Cream',
            'Oil',
          ],
          required: true,
        ),
        ProductAttribute(
          key: 'volume',
          label: 'Volume',
          type: AttributeType.number,
          unit: 'ml',
        ),
        ProductAttribute(
          key: 'hair_type',
          label: 'Hair Type',
          type: AttributeType.multiSelect,
          options: ['Curly', 'Straight', 'Wavy', 'Coily', 'All Hair Types'],
        ),
        ProductAttribute(
          key: 'sulfate_free',
          label: 'Sulfate Free',
          type: AttributeType.boolean,
        ),
      ];

    case 'Personal Care':
      return [
        ProductAttribute(
          key: 'type',
          label: 'Type',
          type: AttributeType.dropdown,
          options: [
            'Deodorant',
            'Body Wash',
            'Lotion',
            'Hand Sanitizer',
            'Sunscreen',
          ],
          required: true,
        ),
        ProductAttribute(
          key: 'volume',
          label: 'Volume',
          type: AttributeType.number,
          unit: 'ml',
        ),
        ProductAttribute(
          key: 'scent',
          label: 'Scent',
          type: AttributeType.text,
          hint: 'e.g., Lavender, Unscented',
        ),
      ];

    case "Men's Grooming":
      return [
        ProductAttribute(
          key: 'type',
          label: 'Type',
          type: AttributeType.dropdown,
          options: [
            'Beard Oil',
            'Shaving Cream',
            'Aftershave',
            'Electric Trimmer',
            'Razor',
          ],
          required: true,
        ),
        ProductAttribute(
          key: 'volume_or_length',
          label: 'Volume/Size',
          type: AttributeType.text,
          hint: 'e.g., 30ml, adjustable comb',
        ),
        ProductAttribute(
          key: 'sensitive_skin',
          label: 'For Sensitive Skin',
          type: AttributeType.boolean,
        ),
      ];

    case 'Nail Care':
      return [
        ProductAttribute(
          key: 'type',
          label: 'Type',
          type: AttributeType.dropdown,
          options: [
            'Nail Polish',
            'Gel Polish',
            'Nail Art',
            'Nail Tools',
            'Remover',
          ],
          required: true,
        ),
        ProductAttribute(
          key: 'color_family',
          label: 'Color Family',
          type: AttributeType.text,
          hint: 'e.g., Red, Nude, Glitter',
        ),
        ProductAttribute(
          key: 'vegan',
          label: 'Vegan & Cruelty Free',
          type: AttributeType.boolean,
        ),
      ];

    case 'Bath & Body':
      return [
        ProductAttribute(
          key: 'type',
          label: 'Type',
          type: AttributeType.dropdown,
          options: [
            'Bath Bomb',
            'Body Scrub',
            'Bubble Bath',
            'Soap',
            'Body Spray',
          ],
          required: true,
        ),
        ProductAttribute(
          key: 'scent',
          label: 'Scent',
          type: AttributeType.text,
        ),
        ProductAttribute(
          key: 'weight',
          label: 'Weight/Volume',
          type: AttributeType.text,
          hint: 'e.g., 200g, 8oz',
        ),
      ];

    case 'Sun Care':
      return [
        ProductAttribute(
          key: 'spf',
          label: 'SPF',
          type: AttributeType.dropdown,
          options: ['SPF 15', 'SPF 30', 'SPF 50', 'SPF 50+'],
          required: true,
        ),
        ProductAttribute(
          key: 'type',
          label: 'Type',
          type: AttributeType.dropdown,
          options: ['Sunscreen Lotion', 'Spray', 'Stick', 'After Sun'],
          required: true,
        ),
        ProductAttribute(
          key: 'water_resistant',
          label: 'Water Resistant (min)',
          type: AttributeType.dropdown,
          options: ['None', '40 min', '80 min'],
        ),
      ];

    case 'Shaving & Hair Removal':
      return [
        ProductAttribute(
          key: 'type',
          label: 'Type',
          type: AttributeType.dropdown,
          options: ['Razor', 'Wax Kit', 'Epilator', 'Depilatory Cream'],
          required: true,
        ),
        ProductAttribute(
          key: 'body_area',
          label: 'Body Area',
          type: AttributeType.multiSelect,
          options: ['Face', 'Legs', 'Bikini', 'Underarm', 'Full Body'],
        ),
        ProductAttribute(
          key: 'sensitive_formula',
          label: 'Sensitive Formula',
          type: AttributeType.boolean,
        ),
      ];

    case 'Oral Care':
      return [
        ProductAttribute(
          key: 'type',
          label: 'Type',
          type: AttributeType.dropdown,
          options: [
            'Toothbrush',
            'Electric Toothbrush',
            'Toothpaste',
            'Mouthwash',
            'Floss',
          ],
          required: true,
        ),
        ProductAttribute(
          key: 'whitening',
          label: 'Whitening',
          type: AttributeType.boolean,
        ),
        ProductAttribute(
          key: 'fluoride',
          label: 'Fluoride',
          type: AttributeType.boolean,
        ),
      ];

    case 'Tools & Brushes':
      return [
        ProductAttribute(
          key: 'type',
          label: 'Type',
          type: AttributeType.dropdown,
          options: [
            'Makeup Brush Set',
            'Beauty Sponge',
            'Eyelash Curler',
            'Tweezers',
            'Hair Brush',
          ],
          required: true,
        ),
        ProductAttribute(
          key: 'material',
          label: 'Bristle Material',
          type: AttributeType.dropdown,
          options: ['Synthetic', 'Natural', 'Mixed'],
        ),
        ProductAttribute(
          key: 'cruelty_free',
          label: 'Cruelty Free',
          type: AttributeType.boolean,
        ),
      ];

    // === SPORTS & OUTDOORS ===
    case 'Gym Equipment':
      return [
        ProductAttribute(
          key: 'type',
          label: 'Equipment Type',
          type: AttributeType.dropdown,
          options: [
            'Dumbbells',
            'Yoga Mat',
            'Resistance Bands',
            'Kettlebell',
            'Bench',
            'Treadmill',
          ],
          required: true,
        ),
        ProductAttribute(
          key: 'weight',
          label: 'Weight',
          type: AttributeType.number,
          unit: 'lbs',
          hint: 'If applicable',
        ),
        ProductAttribute(
          key: 'material',
          label: 'Material',
          type: AttributeType.dropdown,
          options: ['Rubber', 'Neoprene', 'Cast Iron', 'PVC', 'Foam'],
        ),
      ];

    case 'Camping':
      return [
        ProductAttribute(
          key: 'type',
          label: 'Item Type',
          type: AttributeType.dropdown,
          options: [
            'Tent',
            'Sleeping Bag',
            'Backpack',
            'Camping Stove',
            'Lantern',
            'Sleeping Pad',
            'Cookware',
          ],
          required: true,
        ),
        ProductAttribute(
          key: 'capacity',
          label: 'Capacity',
          type: AttributeType.text,
          hint: 'e.g., 2-person, 30L, 3-season',
        ),
        ProductAttribute(
          key: 'season_rating',
          label: 'Season Rating',
          type: AttributeType.dropdown,
          options: ['Summer', '3-Season', '4-Season/Winter'],
        ),
        ProductAttribute(
          key: 'weight',
          label: 'Weight',
          type: AttributeType.number,
          unit: 'lbs',
          min: 0.1,
          maxlenth: 50,
        ),
        ProductAttribute(
          key: 'waterproof',
          label: 'Waterproof/Water-Resistant',
          type: AttributeType.boolean,
        ),
        ProductAttribute(
          key: 'material',
          label: 'Primary Material',
          type: AttributeType.dropdown,
          options: [
            'Nylon',
            'Polyester',
            'Ripstop',
            'Canvas',
            'Aluminum',
            'Titanium',
          ],
        ),
      ];

    case 'Sports Balls':
      return [
        ProductAttribute(
          key: 'sport',
          label: 'Sport',
          type: AttributeType.dropdown,
          options: ['Soccer', 'Basketball', 'Football', 'Volleyball', 'Tennis'],
          required: true,
        ),
        ProductAttribute(
          key: 'size',
          label: 'Size',
          type: AttributeType.dropdown,
          options: ['Size 3', 'Size 4', 'Size 5', 'Size 6', 'Size 7'],
        ),
        ProductAttribute(
          key: 'material',
          label: 'Material',
          type: AttributeType.dropdown,
          options: ['Synthetic Leather', 'Rubber', 'Composite'],
        ),
        ProductAttribute(
          key: 'official_match',
          label: 'Official Match Ball',
          type: AttributeType.boolean,
        ),
      ];

    case 'Cycling':
      return [
        ProductAttribute(
          key: 'type',
          label: 'Type',
          type: AttributeType.dropdown,
          options: [
            'Road Bike',
            'Mountain Bike',
            'Hybrid',
            'Electric Bike',
            'Helmet',
          ],
          required: true,
        ),
        ProductAttribute(
          key: 'frame_size',
          label: 'Frame Size',
          type: AttributeType.dropdown,
          options: [
            'XS (47-49cm)',
            'S (50-52cm)',
            'M (53-55cm)',
            'L (56-58cm)',
            'XL (59-61cm)',
          ],
        ),
        ProductAttribute(
          key: 'wheel_size',
          label: 'Wheel Size',
          type: AttributeType.dropdown,
          options: ['26"', '27.5"', '29"', '700c'],
        ),
        ProductAttribute(
          key: 'condition_brakes_gears',
          label: 'Brakes & Gears Condition',
          type: AttributeType.text,
          hint: 'Describe functionality',
        ),
      ];

    case 'Water Sports':
      return [
        ProductAttribute(
          key: 'type',
          label: 'Type',
          type: AttributeType.dropdown,
          options: [
            'Kayak',
            'Paddleboard',
            'Surfboard',
            'Snorkel Set',
            'Wetsuit',
          ],
          required: true,
        ),
        ProductAttribute(
          key: 'size',
          label: 'Size',
          type: AttributeType.text,
          hint: 'e.g., 10\'6" length, 32" width',
        ),
        ProductAttribute(
          key: 'material',
          label: 'Material',
          type: AttributeType.dropdown,
          options: ['Inflatable PVC', 'Fiberglass', 'Epoxy', 'Neoprene'],
        ),
      ];

    case 'Team Sports':
      return [
        ProductAttribute(
          key: 'sport',
          label: 'Sport',
          type: AttributeType.dropdown,
          options: ['Soccer', 'Basketball', 'Baseball', 'Hockey', 'Volleyball'],
          required: true,
        ),
        ProductAttribute(
          key: 'type',
          label: 'Equipment Type',
          type: AttributeType.dropdown,
          options: ['Jersey', 'Shin Guards', 'Glove', 'Net', 'Training Aid'],
          required: true,
        ),
        ProductAttribute(
          key: 'size',
          label: 'Size',
          type: AttributeType.dropdown,
          options: ['Youth S', 'Youth M', 'Adult S', 'Adult M', 'Adult L'],
        ),
      ];

    case 'Running':
      return [
        ProductAttribute(
          key: 'shoe_size',
          label: 'Shoe Size (US)',
          type: AttributeType.dropdown,
          options: ['7', '8', '9', '10', '11', '12', '13'],
        ),
        ProductAttribute(
          key: 'terrain',
          label: 'Terrain',
          type: AttributeType.dropdown,
          options: ['Road', 'Trail', 'Track', 'Treadmill'],
        ),
        ProductAttribute(
          key: 'arch_support',
          label: 'Arch Support',
          type: AttributeType.dropdown,
          options: ['Neutral', 'Stability', 'Motion Control'],
        ),
      ];

    case 'Hiking':
      return [
        ProductAttribute(
          key: 'type',
          label: 'Type',
          type: AttributeType.dropdown,
          options: [
            'Hiking Boots',
            'Hiking Shoes',
            'Trekking Poles',
            'Daypack',
            'Hydration Pack',
          ],
          required: true,
        ),
        ProductAttribute(
          key: 'size',
          label: 'Size/Volume',
          type: AttributeType.text,
          hint: 'e.g., 25L, size 10.5',
        ),
        ProductAttribute(
          key: 'waterproof',
          label: 'Waterproof',
          type: AttributeType.boolean,
        ),
      ];

    case 'Snow Sports':
      return [
        ProductAttribute(
          key: 'type',
          label: 'Type',
          type: AttributeType.dropdown,
          options: [
            'Skis',
            'Snowboard',
            'Ski Boots',
            'Snowboard Boots',
            'Helmet',
            'Goggles',
          ],
          required: true,
        ),
        ProductAttribute(
          key: 'size',
          label: 'Size',
          type: AttributeType.text,
          hint: 'e.g., 158cm, size 10, medium',
        ),
        ProductAttribute(
          key: 'condition_edges',
          label: 'Condition (Edges/Base)',
          type: AttributeType.text,
          hint: 'Describe any damage, recent tunes',
        ),
      ];

    case 'Fitness Trackers':
      return [
        ProductAttribute(
          key: 'model',
          label: 'Model/Generation',
          type: AttributeType.text,
          hint: 'e.g., Charge 5, Fenix 7',
        ),
        ProductAttribute(
          key: 'features',
          label: 'Features',
          type: AttributeType.multiSelect,
          options: [
            'Heart Rate',
            'GPS',
            'SpO2',
            'Sleep Tracking',
            'Music Storage',
          ],
        ),
        ProductAttribute(
          key: 'battery_life',
          label: 'Battery Life',
          type: AttributeType.text,
          unit: 'days',
          hint: 'Typical use',
        ),
      ];

    case 'Water Bottles & Hydration':
      return [
        ProductAttribute(
          key: 'type',
          label: 'Type',
          type: AttributeType.dropdown,
          options: [
            'Insulated Bottle',
            'Plastic Bottle',
            'Hydration Bladder',
            'Filter Bottle',
          ],
          required: true,
        ),
        ProductAttribute(
          key: 'capacity',
          label: 'Capacity',
          type: AttributeType.number,
          unit: 'oz',
          min: 8,
          maxlenth: 128,
        ),
        ProductAttribute(
          key: 'material',
          label: 'Material',
          type: AttributeType.dropdown,
          options: ['Stainless Steel', 'Tritan Plastic', 'Glass'],
        ),
        ProductAttribute(
          key: 'bpa_free',
          label: 'BPA Free',
          type: AttributeType.boolean,
        ),
      ];

    case 'Sportswear':
      return [
        ProductAttribute(
          key: 'size',
          label: 'Size',
          type: AttributeType.dropdown,
          options: ['XS', 'S', 'M', 'L', 'XL', 'XXL'],
          required: true,
        ),
        ProductAttribute(
          key: 'type',
          label: 'Type',
          type: AttributeType.dropdown,
          options: ['Shorts', 'Tights', 'Tank Top', 'Hoodie', 'Jacket'],
          required: true,
        ),
        ProductAttribute(
          key: 'material',
          label: 'Material',
          type: AttributeType.dropdown,
          options: ['Polyester', 'Spandex', 'Nylon', 'Merino Wool'],
        ),
        ProductAttribute(
          key: 'moisture_wicking',
          label: 'Moisture Wicking',
          type: AttributeType.boolean,
        ),
      ];

    // === DEFAULT FALLBACK ===
    default:
      return [
        ProductAttribute(
          key: 'notes',
          label: 'Additional Specifications',
          type: AttributeType.text,
          hint: 'Add any other relevant details about this product',
          maxlenth: 500,
        ),
      ];
  }
}

// ============================================================================
// DESCRIPTION GENERATOR
// ============================================================================

class DescriptionGenerator {
  static String generate({
    required String title,
    required String brand,
    required String category,
    required String subcategory,
    required Map<String, dynamic> attributes,
    required String condition,
    String? customNotes,
  }) {
    final buf = StringBuffer();

    // Header
    buf.write('$title by $brand. ');
    buf.write('Category: $category > $subcategory. ');
    buf.write('Condition: $condition. ');

    // Color priority for fashion/beauty
    if (attributes['color'] != null) {
      buf.write('Color: ${attributes['color']}. ');
    }

    // Key specs first (size, storage, etc.)
    final priorityKeys = [
      'size',
      'storage',
      'ram',
      'processor',
      'material',
      'capacity',
    ];
    for (final key in priorityKeys) {
      if (attributes[key] != null && attributes[key].toString().isNotEmpty) {
        final attr = _findAttributeDefinition(subcategory, key);
        final label = attr?.label ?? key.replaceAll('_', ' ').toUpperCase();
        final value = attr?.formatValue(attributes[key]) ?? attributes[key];
        buf.write('$label: $value. ');
      }
    }

    // Remaining attributes
    attributes.forEach((key, value) {
      if (priorityKeys.contains(key)) return; // Already added
      if (key == 'color' || key == 'color_hex') return;
      if (value == null || value.toString().trim().isEmpty) return;
      if (value is bool) return; // Handle booleans separately

      final attr = _findAttributeDefinition(subcategory, key);
      final label = attr?.label ?? key.replaceAll('_', ' ').toUpperCase();
      final formattedValue = attr?.formatValue(value) ?? value.toString();
      buf.write('$label: $formattedValue. ');
    });

    // Boolean attributes as features
    final boolAttrs = attributes.entries.where(
      (e) => e.value is bool && e.value == true,
    );
    if (boolAttrs.isNotEmpty) {
      final features = boolAttrs
          .map((e) {
            final attr = _findAttributeDefinition(subcategory, e.key);
            return attr?.label ?? e.key.replaceAll('_', ' ').toUpperCase();
          })
          .join(', ');
      buf.write('Features: $features. ');
    }

    // Custom notes
    if (customNotes?.isNotEmpty == true) {
      buf.write('Notes: $customNotes. ');
    }

    return buf.toString().trim();
  }

  static ProductAttribute? _findAttributeDefinition(
    String subcategory,
    String key,
  ) {
    final attrs = getAttributesForSubcategory(subcategory);
    return attrs.firstWhere(
      (a) => a.key == key,
      orElse: () =>
          ProductAttribute(key: key, label: key, type: AttributeType.text),
    );
  }
}

// ============================================================================
// UTILITY HELPERS
// ============================================================================

/// Format price with currency
String formatPrice(num? price, String currency) {
  if (price == null) return '—';
  final symbols = {'USD': '\$', 'EUR': '€', 'GBP': '£', 'JPY': '¥'};
  final symbol = symbols[currency] ?? currency;
  return '$symbol${price.toStringAsFixed(2)}';
}

/// Validate attribute value based on definition
String? validateAttributeValue(ProductAttribute attr, dynamic value) {
  if (attr.required && (value == null || value.toString().trim().isEmpty)) {
    return '${attr.label} is required';
  }

  if (value == null || value.toString().trim().isEmpty)
    return null; // Optional and empty

  switch (attr.type) {
    case AttributeType.number:
      final numVal = double.tryParse(value.toString());
      if (numVal == null) return 'Must be a valid number';
      if (attr.min != null && numVal < attr.min!)
        return 'Minimum value: ${attr.min}';
      if (attr.maxlenth != null && numVal > attr.maxlenth!)
        return 'Maximum value: ${attr.maxlenth}';
      break;
    case AttributeType.dropdown:
    case AttributeType.multiSelect:
      if (attr.options != null && !attr.options!.contains(value.toString())) {
        return 'Invalid option selected';
      }
      break;
    case AttributeType.text:
      // Could add regex validation here if needed
      break;
    case AttributeType.boolean:
      // Always valid if it's a bool
      break;
  }
  return null;
}

/// Get all possible values for an attribute (for search/filtering)
Set<String> getAllPossibleValuesForAttribute(
  String subcategory,
  String attributeKey,
) {
  final attrs = getAttributesForSubcategory(subcategory);
  final attr = attrs.firstWhere(
    (a) => a.key == attributeKey,
    orElse: () => ProductAttribute(
      key: attributeKey,
      label: attributeKey,
      type: AttributeType.text,
    ),
  );

  if (attr.options != null) return attr.options!.toSet();
  return {};
}
