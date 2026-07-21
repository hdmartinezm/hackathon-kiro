import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:baby_health/services/ios_audio_classifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MethodChannel channel;
  late IosAudioClassifier classifier;
  late List<MethodCall> log;

  setUp(() {
    log = [];
    channel = const MethodChannel(IosAudioClassifier.channelName);
    classifier = IosAudioClassifier(channel: channel);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  void setMockHandler(
      Future<dynamic> Function(MethodCall call)? handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      log.add(call);
      if (handler != null) return handler(call);
      return null;
    });
  }

  group('IosAudioClassifier', () {
    group('isModelReady', () {
      test('returns true when native side reports model is ready', () async {
        setMockHandler((call) async {
          if (call.method == 'isModelReady') return true;
          return null;
        });

        final ready = await classifier.isModelReady();
        expect(ready, isTrue);
      });

      test('returns false when native side reports model not ready', () async {
        setMockHandler((call) async {
          if (call.method == 'isModelReady') return false;
          return null;
        });

        final ready = await classifier.isModelReady();
        expect(ready, isFalse);
      });

      test('returns false when PlatformException occurs', () async {
        setMockHandler((call) async {
          throw PlatformException(code: 'ERROR', message: 'Model not found');
        });

        final ready = await classifier.isModelReady();
        expect(ready, isFalse);
      });

      test('returns false when native returns null', () async {
        setMockHandler((call) async => null);

        final ready = await classifier.isModelReady();
        expect(ready, isFalse);
      });
    });

    group('classifyAudio', () {
      final testAudioData = Uint8List.fromList(List.filled(112000, 0));

      test('returns correct AudioResult for hungry classification', () async {
        setMockHandler((call) async {
          if (call.method == 'classifyAudio') {
            return {'categoryIndex': 0, 'confidence': 0.92};
          }
          return null;
        });

        final result = await classifier.classifyAudio(audioData: testAudioData);

        expect(result.category, equals('hungry'));
        expect(result.label, equals('Hambre'));
        expect(result.confidence, equals(0.92));
        expect(result.recommendation, equals('Ofrecer alimentación'));
      });

      test('returns correct AudioResult for pain classification', () async {
        setMockHandler((call) async {
          if (call.method == 'classifyAudio') {
            return {'categoryIndex': 1, 'confidence': 0.78};
          }
          return null;
        });

        final result = await classifier.classifyAudio(audioData: testAudioData);

        expect(result.category, equals('pain'));
        expect(result.label, equals('Dolor'));
        expect(result.confidence, equals(0.78));
        expect(result.recommendation, equals('Revisar, consultar si persiste'));
      });

      test('returns unknown when confidence below threshold', () async {
        setMockHandler((call) async {
          if (call.method == 'classifyAudio') {
            return {'categoryIndex': 0, 'confidence': 0.3};
          }
          return null;
        });

        final result = await classifier.classifyAudio(audioData: testAudioData);

        expect(result.category, equals('unknown'));
        expect(result.label, equals('Desconocido'));
        expect(result.confidence, equals(0.3));
        expect(
          result.recommendation,
          equals('Intentar de nuevo en ambiente silencioso'),
        );
      });

      test('returns original category when confidence equals threshold', () async {
        setMockHandler((call) async {
          if (call.method == 'classifyAudio') {
            return {'categoryIndex': 3, 'confidence': 0.5};
          }
          return null;
        });

        final result = await classifier.classifyAudio(audioData: testAudioData);

        expect(result.category, equals('discomfort'));
        expect(result.label, equals('Incomodidad'));
        expect(result.confidence, equals(0.5));
      });

      test('passes correct arguments to native channel', () async {
        setMockHandler((call) async {
          if (call.method == 'classifyAudio') {
            return {'categoryIndex': 2, 'confidence': 0.75};
          }
          return null;
        });

        await classifier.classifyAudio(
          audioData: testAudioData,
          sampleRate: 16000,
        );

        expect(log.length, equals(1));
        final call = log.first;
        expect(call.method, equals('classifyAudio'));
        expect(call.arguments['audioData'], equals(testAudioData));
        expect(call.arguments['sampleRate'], equals(16000));
        expect(call.arguments['audioDurationSeconds'], equals(7));
      });

      test('throws AudioClassificationException on PlatformException', () async {
        setMockHandler((call) async {
          throw PlatformException(
            code: 'INFERENCE_ERROR',
            message: 'CoreML failed',
          );
        });

        expect(
          () => classifier.classifyAudio(audioData: testAudioData),
          throwsA(isA<AudioClassificationException>().having(
            (e) => e.code,
            'code',
            equals('INFERENCE_ERROR'),
          )),
        );
      });

      test('throws AudioClassificationException when result is null', () async {
        setMockHandler((call) async => null);

        expect(
          () => classifier.classifyAudio(audioData: testAudioData),
          throwsA(isA<AudioClassificationException>()),
        );
      });

      test('throws on invalid categoryIndex', () async {
        setMockHandler((call) async {
          if (call.method == 'classifyAudio') {
            return {'categoryIndex': 99, 'confidence': 0.9};
          }
          return null;
        });

        expect(
          () => classifier.classifyAudio(audioData: testAudioData),
          throwsA(isA<AudioClassificationException>().having(
            (e) => e.code,
            'code',
            equals('INVALID_CATEGORY'),
          )),
        );
      });

      test('throws when categoryIndex is missing', () async {
        setMockHandler((call) async {
          if (call.method == 'classifyAudio') {
            return {'confidence': 0.9};
          }
          return null;
        });

        expect(
          () => classifier.classifyAudio(audioData: testAudioData),
          throwsA(isA<AudioClassificationException>().having(
            (e) => e.code,
            'code',
            equals('INVALID_RESULT'),
          )),
        );
      });

      test('classifies all 9 categories correctly', () async {
        for (int i = 0; i < 9; i++) {
          setMockHandler((call) async {
            if (call.method == 'classifyAudio') {
              return {'categoryIndex': i, 'confidence': 0.85};
            }
            return null;
          });

          final result =
              await classifier.classifyAudio(audioData: testAudioData);
          final expected = IosAudioClassifier.cryCategories[i];

          expect(result.category, equals(expected.category));
          expect(result.label, equals(expected.label));
          expect(result.recommendation, equals(expected.recommendation));
        }
      });
    });

    group('getCategoryByKey', () {
      test('returns correct category for valid key', () {
        final category = IosAudioClassifier.getCategoryByKey('hungry');
        expect(category, isNotNull);
        expect(category!.id, equals(0));
        expect(category.label, equals('Hambre'));
      });

      test('returns null for invalid key', () {
        final category = IosAudioClassifier.getCategoryByKey('invalid');
        expect(category, isNull);
      });
    });

    group('getCategoryById', () {
      test('returns correct category for valid ID', () {
        final category = IosAudioClassifier.getCategoryById(5);
        expect(category, isNotNull);
        expect(category!.category, equals('temperature'));
        expect(category.label, equals('Temperatura'));
      });

      test('returns null for negative ID', () {
        expect(IosAudioClassifier.getCategoryById(-1), isNull);
      });

      test('returns null for ID >= 9', () {
        expect(IosAudioClassifier.getCategoryById(9), isNull);
      });
    });

    group('cryCategories', () {
      test('has exactly 9 categories', () {
        expect(IosAudioClassifier.cryCategories.length, equals(9));
      });

      test('IDs are sequential from 0 to 8', () {
        for (int i = 0; i < 9; i++) {
          expect(IosAudioClassifier.cryCategories[i].id, equals(i));
        }
      });

      test('last category is unknown', () {
        final last = IosAudioClassifier.cryCategories.last;
        expect(last.category, equals('unknown'));
        expect(last.label, equals('Desconocido'));
      });
    });
  });
}
