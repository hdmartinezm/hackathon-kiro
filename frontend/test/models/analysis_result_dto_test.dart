import 'package:flutter_test/flutter_test.dart';

import 'package:babyhealth/models/analysis_result.dart';
import 'package:babyhealth/models/analysis_result_dto.dart';
import 'package:babyhealth/models/analysis_status.dart';

void main() {
  group('AnalysisResultDto', () {
    // Mock JSON from api-contracts.md — normal status
    final normalJson = <String, dynamic>{
      'status': 'normal',
      'observations':
          'El bebé presenta coloración de piel dentro de parámetros normales.',
      'recommendations':
          'Continúe con los cuidados habituales. Mantenga las visitas regulares al pediatra.',
      'confidence': 0.87,
      'cry_category': 'hambre',
      'error': null,
      'session_id': 'mock-session-001',
      'disclaimer':
          'Esta herramienta es solo orientativa. No reemplaza la evaluación médica profesional.',
    };

    // Mock JSON — requiere atención with partial degradation
    final partialJson = <String, dynamic>{
      'status': 'requiere_atencion',
      'observations':
          'No fue posible analizar el video correctamente. La calidad de la imagen o el audio pueden ser insuficientes.',
      'recommendations':
          'Grabe un nuevo video con mejor iluminación y en un ambiente silencioso.',
      'confidence': null,
      'cry_category': null,
      'error':
          'El frame extraído no contiene un rostro detectable. La pista de audio no contiene llanto distinguible.',
      'session_id': 'mock-session-004',
      'disclaimer':
          'Esta herramienta es solo orientativa. No reemplaza la evaluación médica profesional.',
    };

    // Mock JSON — urgente
    final urgentJson = <String, dynamic>{
      'status': 'urgente',
      'observations':
          'Se detecta coloración amarilla pronunciada en piel y esclerótica.',
      'recommendations':
          'ACUDA A URGENCIAS PEDIÁTRICAS DE INMEDIATO. No espere a una cita programada.',
      'confidence': 0.94,
      'cry_category': 'dolor',
      'error': null,
      'session_id': 'mock-session-003',
      'disclaimer':
          'Esta herramienta es solo orientativa. No reemplaza la evaluación médica profesional.',
    };

    test('fromJson parses normal status correctly', () {
      final dto = AnalysisResultDto.fromJson(normalJson);

      expect(dto.status, equals('normal'));
      expect(dto.observations, contains('coloración de piel'));
      expect(dto.recommendations, contains('cuidados habituales'));
      expect(dto.confidence, equals(0.87));
      expect(dto.cryCategory, equals('hambre'));
      expect(dto.error, isNull);
      expect(dto.sessionId, equals('mock-session-001'));
      expect(dto.disclaimer, isNotEmpty);
    });

    test('fromJson parses partial degradation correctly', () {
      final dto = AnalysisResultDto.fromJson(partialJson);

      expect(dto.status, equals('requiere_atencion'));
      expect(dto.confidence, isNull);
      expect(dto.cryCategory, isNull);
      expect(dto.error, isNotNull);
      expect(dto.error, contains('frame extraído'));
    });

    test('fromJson parses urgent status correctly', () {
      final dto = AnalysisResultDto.fromJson(urgentJson);

      expect(dto.status, equals('urgente'));
      expect(dto.confidence, equals(0.94));
      expect(dto.cryCategory, equals('dolor'));
      expect(dto.error, isNull);
    });

    test('fromJson handles confidence as integer (num type)', () {
      final json = <String, dynamic>{
        'status': 'normal',
        'observations': 'obs',
        'recommendations': 'rec',
        'confidence': 1, // integer, not double
        'session_id': 's1',
        'disclaimer': 'disc',
      };

      final dto = AnalysisResultDto.fromJson(json);

      expect(dto.confidence, equals(1.0));
    });

    test('toDomain converts to AnalysisResult correctly', () {
      final dto = AnalysisResultDto.fromJson(normalJson);
      final domain = dto.toDomain();

      expect(domain, isA<AnalysisResult>());
      expect(domain.status, equals(AnalysisStatus.normal));
      expect(domain.observations, equals(dto.observations));
      expect(domain.recommendations, equals(dto.recommendations));
      expect(domain.confidence, equals(0.87));
      expect(domain.cryCategory, equals('hambre'));
      expect(domain.error, isNull);
      expect(domain.sessionId, equals('mock-session-001'));
      expect(domain.disclaimer, isNotEmpty);
    });

    test('toDomain preserves partial degradation semantics', () {
      final dto = AnalysisResultDto.fromJson(partialJson);
      final domain = dto.toDomain();

      expect(domain.error, isNotNull);
      expect(domain.error, contains('frame extraído'));
      expect(domain.confidence, isNull);
      expect(domain.cryCategory, isNull);
    });

    test('toDomain handles all three status values', () {
      for (final json in [normalJson, partialJson, urgentJson]) {
        final dto = AnalysisResultDto.fromJson(json);
        final domain = dto.toDomain();
        expect(domain.status, isA<AnalysisStatus>());
      }
    });
  });
}
