import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../config/app_config.dart';
import '../models/analysis_result.dart';
import '../models/audio_result.dart';

/// Servicio para comunicación con el backend.
class ApiService {
  final String _baseUrl = AppConfig.apiBaseUrl;

  /// Obtiene URL presigned para subir video.
  Future<Map<String, dynamic>> getVideoUploadUrl(
      [String contentType = 'video/mp4']) async {
    final uri = Uri.parse(
        '$_baseUrl${AppConfig.uploadUrlEndpoint}?content_type=$contentType');
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Error obteniendo upload URL: ${response.body}');
    }
    return jsonDecode(response.body);
  }

  /// Sube archivo a S3 via presigned URL.
  Future<void> uploadToS3(
    String uploadUrl,
    Uint8List fileBytes,
    String contentType,
  ) async {
    final uri = Uri.parse(uploadUrl);
    final response = await http.put(
      uri,
      headers: {'Content-Type': contentType},
      body: fileBytes,
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      // Si falla por expiración, renovar URL
      if (response.statusCode == 403) {
        final newData = await getVideoUploadUrl(contentType);
        final newUrl = newData['upload_url'] as String;
        final retryResponse = await http.put(
          Uri.parse(newUrl),
          headers: {'Content-Type': contentType},
          body: fileBytes,
        );
        if (retryResponse.statusCode != 200 &&
            retryResponse.statusCode != 204) {
          throw Exception(
              'Error subiendo a S3 (retry): ${retryResponse.statusCode}');
        }
        return;
      }
      throw Exception('Error subiendo a S3: ${response.statusCode}');
    }
  }

  /// Analiza imagen enviando multipart directamente.
  Future<AnalysisResult> analyzeImageDirect(
    Uint8List imageBytes,
    String mimeType,
  ) async {
    final uri = Uri.parse('$_baseUrl${AppConfig.analyzeImageEndpoint}');
    final request = http.MultipartRequest('POST', uri);

    final parts = mimeType.split('/');
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      imageBytes,
      filename: 'capture.${parts.last}',
      contentType: MediaType(parts.first, parts.last),
    ));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception('Error analizando imagen: ${response.body}');
    }
    return AnalysisResult.fromJson(jsonDecode(response.body));
  }

  /// Analiza video ya subido a S3.
  Future<AnalysisResult> analyzeVideo(String videoKey,
      [String? sessionId]) async {
    final uri = Uri.parse('$_baseUrl${AppConfig.analyzeEndpoint}');
    final body = {'video_key': videoKey};
    if (sessionId != null) body['session_id'] = sessionId;

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('Error analizando video: ${response.body}');
    }
    return AnalysisResult.fromJson(jsonDecode(response.body));
  }

  /// Analiza audio (envía como multipart).
  Future<AudioResult> analyzeAudio(Uint8List audioBytes) async {
    final uri = Uri.parse('$_baseUrl${AppConfig.analyzeImageEndpoint}');
    final request = http.MultipartRequest('POST', uri);

    request.files.add(http.MultipartFile.fromBytes(
      'file',
      audioBytes,
      filename: 'recording.wav',
      contentType: MediaType('audio', 'wav'),
    ));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception('Error analizando audio: ${response.body}');
    }
    return AudioResult.fromJson(jsonDecode(response.body));
  }

  /// Obtiene URL para subir imagen.
  Future<Map<String, dynamic>> getUploadUrl(
      [String contentType = 'image/jpeg']) async {
    final uri = Uri.parse(
        '$_baseUrl/upload-image-url?content_type=$contentType');
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Error obteniendo upload URL: ${response.body}');
    }
    return jsonDecode(response.body);
  }

  /// Analiza imagen ya subida a S3.
  Future<AnalysisResult> analyzeImage(String imageKey) async {
    final uri = Uri.parse('$_baseUrl${AppConfig.analyzeEndpoint}');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'video_key': imageKey}),
    );

    if (response.statusCode != 200) {
      throw Exception('Error analizando imagen: ${response.body}');
    }
    return AnalysisResult.fromJson(jsonDecode(response.body));
  }
}
