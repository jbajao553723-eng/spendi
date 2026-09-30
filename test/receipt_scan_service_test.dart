import 'dart:convert';
import 'dart:typed_data';

import 'package:final_project/services/receipt_scan_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker/image_picker.dart';

class _FakeImagePicker extends ImagePicker {
  _FakeImagePicker(this.image);

  final XFile? image;

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    return image;
  }
}

void main() {
  test(
    'sends a schema-constrained vision request and parses the receipt',
    () async {
      late http.Request capturedRequest;
      final client = MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {
                  'content': jsonEncode({
                    'isReceiptOrInvoice': true,
                    'title': 'Corner Cafe',
                    'totalAmount': 245.75,
                    'totalAmountText': '245.75',
                    'currencyCode': 'USD',
                    'category': 'Food',
                    'purchaseDate': '2026-09-14',
                    'note': 'Lunch receipt',
                  }),
                },
              },
            ],
          }),
          200,
        );
      });
      final picker = _FakeImagePicker(
        XFile.fromData(
          Uint8List.fromList([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
          mimeType: 'image/png',
          name: 'receipt.png',
        ),
      );

      final result = await ReceiptScanService(
        picker,
        client,
        'test-api-key',
      ).scan(ImageSource.gallery);

      expect(result?.title, 'Corner Cafe');
      expect(result?.amount, 245.75);
      expect(result?.currencyCode, 'USD');
      expect(
        capturedRequest.url.toString(),
        'https://integrate.api.nvidia.com/v1/chat/completions',
      );
      expect(capturedRequest.headers['authorization'], 'Bearer test-api-key');

      final body = jsonDecode(capturedRequest.body) as Map<String, dynamic>;
      expect(body['model'], 'meta/llama-3.2-11b-vision-instruct');
      expect(
        (body['response_format'] as Map<String, dynamic>)['type'],
        'json_schema',
      );
      final responseFormat = body['response_format'] as Map<String, dynamic>;
      final jsonSchema = responseFormat['json_schema'] as Map<String, dynamic>;
      final schema = jsonSchema['schema'] as Map<String, dynamic>;
      expect(schema['required'], contains('isReceiptOrInvoice'));
      final messages = body['messages'] as List<dynamic>;
      final content =
          (messages.last as Map<String, dynamic>)['content'] as List<dynamic>;
      expect(
        (content.first as Map<String, dynamic>)['text'],
        contains('clearly shows a purchase receipt or an invoice'),
      );
      expect(
        (content.first as Map<String, dynamic>)['text'],
        contains('Detect currencyCode from the original document itself'),
      );
      final image = content[1] as Map<String, dynamic>;
      final imageUrl = image['image_url'] as Map<String, dynamic>;
      expect(imageUrl['url'], startsWith('data:image/png;base64,'));
    },
  );

  test('retries invalid AI text with JSON mode', () async {
    var requestCount = 0;
    final responseFormats = <String>[];
    final client = MockClient((request) async {
      requestCount++;
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      responseFormats.add(
        (body['response_format'] as Map<String, dynamic>)['type'] as String,
      );
      final content = requestCount == 1
          ? 'I could not format the response.'
          : jsonEncode({
              'isReceiptOrInvoice': true,
              'title': 'Retry Store',
              'totalAmount': 99.50,
              'totalAmountText': '99,50',
              'currencyCode': 'EUR',
              'category': 'Shopping',
              'purchaseDate': '2026-09-15',
              'note': 'Recovered on retry',
            });
      return http.Response(
        jsonEncode({
          'choices': [
            {
              'message': {'content': content},
            },
          ],
        }),
        200,
      );
    });
    final picker = _FakeImagePicker(
      XFile.fromData(
        Uint8List.fromList([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
        mimeType: 'image/png',
        name: 'receipt.png',
      ),
    );

    final result = await ReceiptScanService(
      picker,
      client,
      'test-api-key',
    ).scan(ImageSource.camera);

    expect(result?.title, 'Retry Store');
    expect(requestCount, 2);
    expect(responseFormats, ['json_schema', 'json_object']);
  });

  test('rejects an image that is not a receipt or invoice', () async {
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'choices': [
            {
              'message': {
                'content': jsonEncode({
                  'isReceiptOrInvoice': false,
                  'title': '',
                  'totalAmount': 0,
                  'totalAmountText': '',
                  'currencyCode': 'PHP',
                  'category': 'Other',
                  'purchaseDate': '',
                  'note': '',
                }),
              },
            },
          ],
        }),
        200,
      );
    });
    final picker = _FakeImagePicker(
      XFile.fromData(
        Uint8List.fromList([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
        mimeType: 'image/png',
        name: 'not-a-receipt.png',
      ),
    );

    expect(
      () => ReceiptScanService(
        picker,
        client,
        'test-api-key',
      ).scan(ImageSource.gallery),
      throwsA(
        isA<ReceiptScanException>().having(
          (error) => error.message,
          'message',
          contains('not a receipt or invoice'),
        ),
      ),
    );
  });
}
