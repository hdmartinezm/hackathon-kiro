import 'package:flutter_test/flutter_test.dart';

import 'package:babyhealth/models/analysis_result.dart';
import 'package:babyhealth/models/analysis_status.dart';

void main() {
  group('AnalysisResult', () {
    const fullResult = AnalysisResult(
      status: AnalysisStatus.normal,
      observations: 'Observación de prueba',
      recommendations: 'Recomendación de prueba',
      confidence: 0.87,
      cryCategory: 'hambre',
      sessionId: 'session-001',
      disclaimer: 'Disclaimer médico de prueba',
    );

    test('creates instance with all required fields', () {
      const result = AnalysisResult(
        status: AnalysisStatus.normal,
        observations: 'Test observations',
        recommendations: 'Test recommendations',
        sessionId: 'session-001',
        disclaimer: 'Test disclaimer',
      );

      expect(result.status, equals(AnalysisStatus.normal));
      expect(result.observations, equals('Test observations'));
      expect(result.recommendations, equals('Test recommendations'));
      expect(result.sessionId, equals('session-001'));
      expect(result.disclaimer, equals('Test disclaimer'));
    });

    test('optional fields default to null', () {
      const result = AnalysisResult(
        status: AnalysisStatus.urgente,
        observations: 'obs',
        recommendations: 'rec',
        sessionId: 's1',
        disclaimer: 'disc',
      );

      expect(result.confidence, isNull);
      expect(result.cryCategory, isNull);
      expect(result.error, isNull);
    });

    test('creates instance with all optional fields', () {
      expect(fullResult.confidence, equals(0.87));
      expect(fullResult.cryCategory, equals('hambre'));
      expect(fullResult.error, isNull);
    });

    test('error field semantics — null means fully successful', () {
      const successResult = AnalysisResult(
        status: AnalysisStatus.normal,
        observations: 'obs',
        recommendations: 'rec',
        sessionId: 's1',
        disclaimer: 'disc',
      );

      expect(successResult.error, isNull);
    });

    test('error field semantics — non-null means partial degradation', () {
      const partialResult = AnalysisResult(
        status: AnalysisStatus.requiereAtencion,
        observations: 'obs parcial',
        recommendations: 'rec parcial',
        error: 'No se pudo clasificar el llanto',
        sessionId: 's2',
        disclaimer: 'disc',
      );

      expect(partialResult.error, isNotNull);
      expect(partialResult.error, contains('clasificar'));
    });

    test('equality — same values are equal', () {
      const result1 = AnalysisResult(
        status: AnalysisStatus.normal,
        observations: 'obs',
        recommendations: 'rec',
        confidence: 0.5,
        sessionId: 's1',
        disclaimer: 'disc',
      );
      const result2 = AnalysisResult(
        status: AnalysisStatus.normal,
        observations: 'obs',
        recommendations: 'rec',
        confidence: 0.5,
        sessionId: 's1',
        disclaimer: 'disc',
      );

      expect(result1, equals(result2));
      expect(result1.hashCode, equals(result2.hashCode));
    });

    test('equality — different status are not equal', () {
      const result1 = AnalysisResult(
        status: AnalysisStatus.normal,
        observations: 'obs',
        recommendations: 'rec',
        sessionId: 's1',
        disclaimer: 'disc',
      );
      const result2 = AnalysisResult(
        status: AnalysisStatus.urgente,
        observations: 'obs',
        recommendations: 'rec',
        sessionId: 's1',
        disclaimer: 'disc',
      );

      expect(result1, isNot(equals(result2)));
    });

    test('copyWith preserves unchanged fields', () {
      final copy = fullResult.copyWith(observations: 'Nueva observación');

      expect(copy.observations, equals('Nueva observación'));
      expect(copy.status, equals(AnalysisStatus.normal));
      expect(copy.recommendations, equals('Recomendación de prueba'));
      expect(copy.confidence, equals(0.87));
      expect(copy.sessionId, equals('session-001'));
    });

    test('copyWith clears optional fields when clear flags are true', () {
      final copy = fullResult.copyWith(
        clearConfidence: true,
        clearCryCategory: true,
        clearError: true,
      );

      expect(copy.confidence, isNull);
      expect(copy.cryCategory, isNull);
      expect(copy.error, isNull);
    });

    test('supports all AnalysisStatus values', () {
      for (final status in AnalysisStatus.values) {
        final result = AnalysisResult(
          status: status,
          observations: 'obs',
          recommendations: 'rec',
          sessionId: 's1',
          disclaimer: 'disc',
        );
        expect(result.status, equals(status));
      }
    });
  });
}
