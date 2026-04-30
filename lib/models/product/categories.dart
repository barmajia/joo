class ProductCategory {
  final String id;
  final String name;
  final String icon;
  final List<String> subcategories;

  const ProductCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.subcategories,
  });
}

class ProductCategories {
  static const List<ProductCategory> categories = [
    ProductCategory(
      id: 'electronics',
      name: 'Electronics & Components',
      icon: '💡',
      subcategories: [
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
    ),
    ProductCategory(
      id: 'textiles',
      name: 'Textiles & Fabrics',
      icon: '🧵',
      subcategories: [
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
    ),
    ProductCategory(
      id: 'machinery',
      name: 'Machinery & Equipment',
      icon: '⚙️',
      subcategories: [
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
    ),
    ProductCategory(
      id: 'construction',
      name: 'Construction Materials',
      icon: '🏗️',
      subcategories: [
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
    ),
    ProductCategory(
      id: 'packaging',
      name: 'Packaging & Printing',
      icon: '📦',
      subcategories: [
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
    ),
    ProductCategory(
      id: 'food',
      name: 'Food & Beverage',
      icon: '🍔',
      subcategories: [
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
    ),
    ProductCategory(
      id: 'agriculture',
      name: 'Agriculture',
      icon: '🌾',
      subcategories: [
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
    ),
    ProductCategory(
      id: 'beauty',
      name: 'Beauty & Personal Care',
      icon: '💄',
      subcategories: [
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
    ),
    ProductCategory(
      id: 'home',
      name: 'Home & Furniture',
      icon: '🪑',
      subcategories: [
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
    ),
    ProductCategory(
      id: 'automotive',
      name: 'Automotive',
      icon: '🚗',
      subcategories: [
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
    ),
    ProductCategory(
      id: 'office',
      name: 'Office Supplies',
      icon: '📎',
      subcategories: [
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
    ),
    ProductCategory(
      id: 'sports',
      name: 'Sports & Outdoors',
      icon: '⚽',
      subcategories: [
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
    ),
    ProductCategory(
      id: 'toys',
      name: 'Toys & Games',
      icon: '🎮',
      subcategories: [
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
    ),
    ProductCategory(
      id: 'medical',
      name: 'Medical & Health',
      icon: '💊',
      subcategories: [
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
    ),
    ProductCategory(
      id: 'industrial',
      name: 'Industrial Supplies',
      icon: '🔧',
      subcategories: [
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
    ),
  ];

  static List<String> get categoryNames =>
      categories.map((c) => c.name).toList();

  static List<String> getSubcategories(String categoryId) {
    final category = categories.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => categories.first,
    );
    return category.subcategories;
  }

  static ProductCategory? getCategoryById(String id) {
    try {
      return categories.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  static ProductCategory? getCategoryByName(String name) {
    try {
      return categories.firstWhere(
        (c) => c.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }
}

// ============================================================================
// ATTRIBUTE DEFINITIONS FOR SUBCATEGORIES
// ============================================================================

enum AttributeType { dropdown, multiSelect, text, number, boolean }

class ProductAttribute {
  final String key;
  final String label;
  final AttributeType type;
  final List<String>? options;
  final String? hint;

  const ProductAttribute({
    required this.key,
    required this.label,
    required this.type,
    this.options,
    this.hint,
  });
}

const Map<String, List<ProductAttribute>> subcategoryAttributes = {
  'Denim': [
    ProductAttribute(
      key: 'available_colors',
      label: 'Available Colors',
      type: AttributeType.multiSelect,
      options: ['Black', 'Blue', 'Dark Blue', 'Light Blue', 'White', 'Grey', 'Navy'],
    ),
    ProductAttribute(
      key: 'available_sizes',
      label: 'Available Sizes',
      type: AttributeType.multiSelect,
      options: ['28', '30', '32', '34', '36', '38', '40'],
    ),
    ProductAttribute(
      key: 'fit',
      label: 'Fit Type',
      type: AttributeType.dropdown,
      options: ['Slim', 'Straight', 'Relaxed', 'Bootcut', 'Skinny'],
    ),
    ProductAttribute(
      key: 'material',
      label: 'Material',
      type: AttributeType.text,
      hint: 'e.g., 100% Cotton, Elastane blend',
    ),
    ProductAttribute(
      key: 'length',
      label: 'Length (inches)',
      type: AttributeType.dropdown,
      options: ['30', '32', '34', '36'],
    ),
    ProductAttribute(
      key: 'wash_type',
      label: 'Wash Type',
      type: AttributeType.dropdown,
      options: ['Dark Wash', 'Medium Wash', 'Light Wash', 'Raw Denim', 'Distressed'],
    ),
  ],
  'Cotton Fabrics': [
    ProductAttribute(
      key: 'available_colors',
      label: 'Available Colors',
      type: AttributeType.multiSelect,
      options: ['White', 'Cream', 'Beige', 'Black', 'Navy', 'Red', 'Blue', 'Green'],
    ),
    ProductAttribute(
      key: 'fabric_width',
      label: 'Width (inches)',
      type: AttributeType.dropdown,
      options: ['36', '44', '54', '60'],
    ),
    ProductAttribute(
      key: 'thread_count',
      label: 'Thread Count',
      type: AttributeType.dropdown,
      options: ['200', '300', '400', '600', '800', '1000+'],
    ),
    ProductAttribute(
      key: 'material_composition',
      label: 'Material Composition',
      type: AttributeType.text,
      hint: 'e.g., 100% Cotton',
    ),
  ],
  'Smartphones & Accessories': [
    ProductAttribute(
      key: 'storage',
      label: 'Storage (GB)',
      type: AttributeType.dropdown,
      options: ['64', '128', '256', '512', '1024'],
    ),
    ProductAttribute(
      key: 'ram',
      label: 'RAM (GB)',
      type: AttributeType.dropdown,
      options: ['4', '6', '8', '12', '16'],
    ),
    ProductAttribute(
      key: 'color',
      label: 'Color',
      type: AttributeType.dropdown,
      options: ['Black', 'White', 'Blue', 'Gold', 'Silver', 'Green', 'Purple'],
    ),
    ProductAttribute(
      key: 'condition_details',
      label: 'Condition Details',
      type: AttributeType.text,
    ),
  ],
  'Computers & Laptops': [
    ProductAttribute(
      key: 'processor',
      label: 'Processor',
      type: AttributeType.dropdown,
      options: ['Intel i3', 'Intel i5', 'Intel i7', 'Intel i9', 'AMD Ryzen 3', 'AMD Ryzen 5', 'AMD Ryzen 7', 'AMD Ryzen 9'],
    ),
    ProductAttribute(
      key: 'ram',
      label: 'RAM (GB)',
      type: AttributeType.dropdown,
      options: ['4', '8', '16', '32', '64'],
    ),
    ProductAttribute(
      key: 'storage',
      label: 'Storage (GB)',
      type: AttributeType.dropdown,
      options: ['128', '256', '512', '1024', '2048'],
    ),
    ProductAttribute(
      key: 'screen_size',
      label: 'Screen Size (inches)',
      type: AttributeType.dropdown,
      options: ['13', '14', '15.6', '16', '17'],
    ),
  ],
};

List<ProductAttribute> getAttributesForSubcategory(String subcategory) {
  return subcategoryAttributes[subcategory] ?? [];
}