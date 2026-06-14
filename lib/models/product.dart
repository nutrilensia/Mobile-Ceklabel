class Product {
  final String id;
  final String name;
  final String category;
  final String nutriScore;
  final String nutriScoreColor;
  final int scanCount;
  final Map<String, dynamic>? nutrition;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.nutriScore,
    required this.nutriScoreColor,
    required this.scanCount,
    this.nutrition,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    category: json['category']?.toString() ?? '',
    nutriScore: json['nutriScore']?.toString() ?? '',
    nutriScoreColor: json['nutriScoreColor']?.toString() ?? '#888888',
    scanCount: (json['scanCount'] ?? json['scan_count'] ?? 0).toInt(),
    nutrition: json['nutrition'] != null
        ? Map<String, dynamic>.from(json['nutrition'])
        : null,
  );
}

class CompareItem {
  final String? barcode;
  final String? productId;
  final String? scanId;

  CompareItem({this.barcode, this.productId, this.scanId});
  Map<String, dynamic> toJson() {
    if (barcode != null) return {'barcode': barcode};
    if (productId != null) return {'productId': productId};
    if (scanId != null) return {'scanId': scanId};
    return {};
  }
}

class CompareProduct {
  final String name;
  final String nutriScore;
  final String nutriScoreColor;
  final int nutriScoreValue;
  final Map<String, dynamic> nutrition;
  final bool isRecommended;
  final String? recommendationReason;

  CompareProduct({
    required this.name,
    required this.nutriScore,
    required this.nutriScoreColor,
    required this.nutriScoreValue,
    required this.nutrition,
    required this.isRecommended,
    this.recommendationReason,
  });

  factory CompareProduct.fromJson(Map<String, dynamic> json) => CompareProduct(
    name: json['name']?.toString() ?? '',
    nutriScore: json['nutriScore']?.toString() ?? '',
    nutriScoreColor: json['nutriScoreColor']?.toString() ?? '#888888',
    nutriScoreValue: (json['nutriScoreValue'] ?? 0).toInt(),
    nutrition: Map<String, dynamic>.from(json['nutrition'] ?? {}),
    isRecommended: json['isRecommended'] ?? false,
    recommendationReason: json['recommendationReason']?.toString(),
  );
}

class CompareResult {
  final List<CompareProduct> products;
  final String? summary;

  CompareResult({required this.products, this.summary});

  factory CompareResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return CompareResult(
      products: (data['products'] as List? ?? [])
          .map((p) => CompareProduct.fromJson(p as Map<String, dynamic>))
          .toList(),
      summary: data['summary']?.toString(),
    );
  }
}
