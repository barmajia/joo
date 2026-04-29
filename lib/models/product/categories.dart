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