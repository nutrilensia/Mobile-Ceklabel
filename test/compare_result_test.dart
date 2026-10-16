import 'package:flutter_test/flutter_test.dart';
import 'package:cek_label/models/product.dart';

Map<String, dynamic> productJson(Map<String, dynamic> overrides) {
  return {
    'ref': 'product:1',
    'productName': 'Susu',
    'nutriScore': {'grade': 'B', 'label': 'Baik', 'color': '#7ED321', 'finalScore': 3},
    'nutrition': {'calories': 120, 'sugarG': 10, 'sodiumMg': 100, 'fatTotalG': 4, 'proteinG': 6},
    'isRecommended': false,
    ...overrides,
  };
}

void main() {
  test('compare product defaults to label source', () {
    final p = CompareProduct.fromJson(productJson({}));
    expect(p.source, 'label');
    expect(p.isEstimate, isFalse);
    expect(p.isFood, isFalse);
    expect(p.confidence, 0.8);
    expect(p.servingSize, '');
  });

  test('isFood covers food and label-front sources', () {
    expect(CompareProduct.fromJson(productJson({'source': 'food'})).isFood, isTrue);
    expect(CompareProduct.fromJson(productJson({'source': 'label-front'})).isFood, isTrue);
    expect(
      CompareProduct.fromJson(productJson({'source': 'label', 'isEstimate': true})).isFood,
      isTrue,
    );
    expect(
      CompareProduct.fromJson(productJson({'source': 'label', 'isEstimate': false})).isFood,
      isFalse,
    );
  });

  test('compare result parses mixed sources and failed list', () {
    final r = CompareResult.fromJson({
      'data': {
        'products': [
          productJson({'ref': 'product:1', 'source': 'label'}),
          productJson({'ref': 'product:2', 'source': 'food', 'isEstimate': true}),
        ],
        'recommendation': {'ref': 'product:1', 'productName': 'Susu', 'reasons': ['Skor terbaik']},
        'mixedSources': true,
        'estimateCount': 1,
        'confidenceNote': 'Pemenang sementara.',
        'failed': [
          {'index': 2, 'error': 'Makanan tidak dikenali'},
        ],
      }
    });
    expect(r.products.length, 2);
    expect(r.mixedSources, isTrue);
    expect(r.estimateCount, 1);
    expect(r.confidenceNote, 'Pemenang sementara.');
    expect(r.failed.length, 1);
    expect(r.failed.first.index, 2);
    expect(r.recommendedRef, 'product:1');
  });

  test('compare result defaults failed to empty', () {
    final r = CompareResult.fromJson({
      'data': {
        'products': [productJson({})],
        'recommendation': {'ref': 'product:1', 'productName': 'Susu', 'reasons': []},
      }
    });
    expect(r.failed, isEmpty);
    expect(r.mixedSources, isFalse);
    expect(r.confidenceNote, isNull);
  });
}
