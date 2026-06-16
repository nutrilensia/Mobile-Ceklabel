import 'gamification.dart';

/// Mengurai field nutriScore yang bisa berupa objek {grade,label,color,finalScore}
/// (response baru) atau string polos (kompatibilitas mundur).
class _Grade {
  final String grade;
  final String color;
  final String label;
  final int finalScore;
  const _Grade(this.grade, this.color, this.label, this.finalScore);

  static _Grade parse(dynamic ns, {String? colorFallback}) {
    if (ns is Map) {
      return _Grade(
        ns['grade']?.toString() ?? '',
        ns['color']?.toString() ?? colorFallback ?? '#888888',
        ns['label']?.toString() ?? '',
        (ns['finalScore'] ?? 0).toInt(),
      );
    }
    return _Grade(ns?.toString() ?? '', colorFallback ?? '#888888', '', 0);
  }
}

class Product {
  final String id;
  final String name;
  final String? brand;
  final String category;
  final String nutriScore; // grade huruf A–E
  final String nutriScoreColor;
  final String nutriScoreLabel;
  final int finalScore;
  final int scanCount;
  final int? rank;
  final String? photoUrl;
  final Map<String, dynamic>? nutrition;
  final Map<String, dynamic>? ingredients;

  Product({
    required this.id,
    required this.name,
    this.brand,
    required this.category,
    required this.nutriScore,
    required this.nutriScoreColor,
    this.nutriScoreLabel = '',
    this.finalScore = 0,
    required this.scanCount,
    this.rank,
    this.photoUrl,
    this.nutrition,
    this.ingredients,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final g = _Grade.parse(
      json['nutriScore'],
      colorFallback: json['nutriScoreColor']?.toString(),
    );
    return Product(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      brand: json['brand']?.toString(),
      category: json['category']?.toString() ?? '',
      nutriScore: g.grade,
      nutriScoreColor: g.color,
      nutriScoreLabel: g.label,
      finalScore: g.finalScore,
      scanCount: (json['scanCount'] ?? json['scan_count'] ?? 0).toInt(),
      rank: json['rank'] != null ? (json['rank']).toInt() : null,
      photoUrl: json['photoUrl']?.toString(),
      nutrition: json['nutrition'] != null
          ? Map<String, dynamic>.from(json['nutrition'])
          : null,
      ingredients: json['ingredients'] != null
          ? Map<String, dynamic>.from(json['ingredients'])
          : null,
    );
  }
}

class ProductCategory {
  final String id;
  final int productCount;

  ProductCategory({required this.id, required this.productCount});

  factory ProductCategory.fromJson(Map<String, dynamic> json) => ProductCategory(
        id: json['id']?.toString() ?? '',
        productCount: (json['productCount'] ?? 0).toInt(),
      );
}

class CompareItem {
  final String? productId;
  final String? scanId;

  CompareItem({this.productId, this.scanId});
  Map<String, dynamic> toJson() {
    if (productId != null) return {'productId': productId};
    if (scanId != null) return {'scanId': scanId};
    return {};
  }
}

class CompareProduct {
  final String ref;
  final String name;
  final String nutriScore;
  final String nutriScoreColor;
  final int finalScore;
  final Map<String, dynamic> nutrition;
  final bool isRecommended;

  CompareProduct({
    required this.ref,
    required this.name,
    required this.nutriScore,
    required this.nutriScoreColor,
    required this.finalScore,
    required this.nutrition,
    required this.isRecommended,
  });

  factory CompareProduct.fromJson(Map<String, dynamic> json) {
    final g = _Grade.parse(
      json['nutriScore'],
      colorFallback: json['nutriScoreColor']?.toString(),
    );
    return CompareProduct(
      ref: json['ref']?.toString() ?? '',
      name: json['productName']?.toString() ?? json['name']?.toString() ?? '',
      nutriScore: g.grade,
      nutriScoreColor: g.color,
      finalScore: g.finalScore == 0 ? (json['finalScore'] ?? 0).toInt() : g.finalScore,
      nutrition: Map<String, dynamic>.from(json['nutrition'] ?? {}),
      isRecommended: json['isRecommended'] ?? false,
    );
  }
}

class CompareResult {
  final List<CompareProduct> products;
  final bool personalized;
  final String? recommendedRef;
  final String? recommendedName;
  final List<String> reasons;
  final GamificationUpdate? gamification;

  CompareResult({
    required this.products,
    this.personalized = false,
    this.recommendedRef,
    this.recommendedName,
    this.reasons = const [],
    this.gamification,
  });

  factory CompareResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    final rec = data['recommendation'] as Map<String, dynamic>?;
    return CompareResult(
      products: (data['products'] as List? ?? [])
          .map((p) => CompareProduct.fromJson(p as Map<String, dynamic>))
          .toList(),
      personalized: data['personalized'] ?? false,
      recommendedRef: rec?['ref']?.toString(),
      recommendedName: rec?['productName']?.toString(),
      reasons: List<String>.from(rec?['reasons'] ?? []),
      gamification: data['gamification'] != null
          ? GamificationUpdate.fromJson(data['gamification'] as Map<String, dynamic>)
          : null,
    );
  }
}
