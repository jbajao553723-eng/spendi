import 'dart:convert';
import 'dart:typed_data';

import 'package:final_project/services/cloudinary_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

class _RecordingClient extends http.BaseClient {
  http.BaseRequest? lastRequest;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    lastRequest = request;
    return http.StreamedResponse(
      Stream.value(
        utf8.encode(
          jsonEncode({
            'secure_url':
                'https://res.cloudinary.com/demo/image/upload/receipt.jpg',
          }),
        ),
      ),
      200,
    );
  }
}

class _ErrorClient extends http.BaseClient {
  _ErrorClient([this.message = 'Unknown API key ']);

  final String message;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return http.StreamedResponse(
      Stream.value(
        utf8.encode(
          jsonEncode({
            'error': {'message': message},
          }),
        ),
      ),
      401,
    );
  }
}

void main() {
  test('uploads a receipt using the configured unsigned preset', () async {
    final client = _RecordingClient();
    final service = CloudinaryService(
      client: client,
      cloudName: 'demo',
      apiKey: 'public-api-key',
      uploadPreset: 'receipt-preset',
    );

    final result = await service.uploadReceipt(
      bytes: Uint8List.fromList([1, 2, 3]),
      mimeType: 'image/png',
    );

    expect(result, contains('res.cloudinary.com'));
    final request = client.lastRequest as http.MultipartRequest;
    expect(request.url.path, '/v1_1/demo/image/upload');
    expect(request.fields, {
      'api_key': 'public-api-key',
      'upload_preset': 'receipt-preset',
    });
    expect(request.files.single.contentType.toString(), 'image/png');
  });

  test('explains when Cloudinary rejects the public API key', () async {
    final service = CloudinaryService(
      client: _ErrorClient(),
      cloudName: 'demo',
      apiKey: 'public-api-key',
      uploadPreset: 'receipt-preset',
    );

    expect(
      () => service.uploadReceipt(
        bytes: Uint8List.fromList([1, 2, 3]),
        mimeType: 'image/png',
      ),
      throwsA(
        isA<CloudinaryUploadException>().having(
          (error) => error.message,
          'message',
          contains('public API key'),
        ),
      ),
    );
  });

  test('explains when the preset blocks the receipt format', () async {
    final service = CloudinaryService(
      client: _ErrorClient('Image file format jpg not allowed'),
      cloudName: 'demo',
      apiKey: 'public-api-key',
      uploadPreset: 'receipt-preset',
    );

    expect(
      () => service.uploadReceipt(
        bytes: Uint8List.fromList([1, 2, 3]),
        mimeType: 'image/jpeg',
      ),
      throwsA(
        isA<CloudinaryUploadException>().having(
          (error) => error.message,
          'message',
          contains('clear the Allowed formats field completely'),
        ),
      ),
    );
  });
}
