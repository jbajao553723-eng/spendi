import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class CloudinaryUploadException implements Exception {
  const CloudinaryUploadException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CloudinaryService {
  factory CloudinaryService({
    String? cloudName,
    String? apiKey,
    String? uploadPreset,
    http.Client? client,
  }) => CloudinaryService._(
    cloudName ?? const String.fromEnvironment('CLOUDINARY_CLOUD_NAME'),
    apiKey ?? const String.fromEnvironment('CLOUDINARY_API_KEY'),
    uploadPreset ?? const String.fromEnvironment('CLOUDINARY_UPLOAD_PRESET'),
    client,
  );

  CloudinaryService._(
    this._cloudName,
    this._apiKey,
    this._uploadPreset,
    this._client,
  );

  final String _cloudName;
  final String _apiKey;
  final String _uploadPreset;
  final http.Client? _client;

  Future<String> uploadReceipt({
    required Uint8List bytes,
    required String mimeType,
  }) async {
    if (_cloudName.isEmpty || _apiKey.isEmpty || _uploadPreset.isEmpty) {
      throw const CloudinaryUploadException(
        'Cloudinary is not configured. Start Flutter with '
        '--dart-define-from-file=.env.',
      );
    }

    final client = _client ?? http.Client();
    try {
      final request =
          http.MultipartRequest(
              'POST',
              Uri.https('api.cloudinary.com', '/v1_1/$_cloudName/image/upload'),
            )
            ..fields['api_key'] = _apiKey
            ..fields['upload_preset'] = _uploadPreset
            ..files.add(
              http.MultipartFile.fromBytes(
                'file',
                bytes,
                filename: 'receipt.${mimeType.split('/').last}',
                contentType: MediaType.parse(mimeType),
              ),
            );
      final streamed = await client
          .send(request)
          .timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamed);
      final Object? payload;
      try {
        payload = jsonDecode(response.body);
      } on FormatException {
        throw const CloudinaryUploadException(
          'Cloudinary returned an invalid response.',
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final errorPayload = payload is Map ? payload['error'] : null;
        final message = errorPayload is Map ? errorPayload['message'] : null;
        final normalizedMessage = message?.toString().toLowerCase();
        if (normalizedMessage?.contains('file format') == true &&
            normalizedMessage?.contains('not allowed') == true) {
          throw const CloudinaryUploadException(
            'Cloudinary is blocking this image format. Open the upload preset, '
            'clear the Allowed formats field completely, and click Save.',
          );
        }
        if (normalizedMessage?.contains('unknown api key') == true) {
          throw const CloudinaryUploadException(
            'Cloudinary rejected the configured cloud name or public API key.',
          );
        }
        throw CloudinaryUploadException(
          message?.toString() ?? 'Cloudinary could not save the receipt image.',
        );
      }
      if (payload is! Map || payload['secure_url'] is! String) {
        throw const CloudinaryUploadException(
          'Cloudinary returned an invalid image URL.',
        );
      }
      return payload['secure_url'] as String;
    } on CloudinaryUploadException {
      rethrow;
    } catch (error, stackTrace) {
      debugPrint('Cloudinary receipt upload failed: $error\n$stackTrace');
      throw const CloudinaryUploadException(
        'Could not save the receipt image. Check your connection and try again.',
      );
    } finally {
      if (_client == null) client.close();
    }
  }
}
