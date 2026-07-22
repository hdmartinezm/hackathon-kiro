import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:babyhealth/models/analysis_result.dart';
import 'package:babyhealth/models/analysis_status.dart';
import 'package:babyhealth/models/captured_media.dart';
import 'package:babyhealth/repositories/analysis_repository.dart';
import 'package:babyhealth/models/upload_url_dto.dart';
import 'package:babyhealth/repositories/upload_repository.dart';
import 'package:babyhealth/services/http_client.dart';
import 'package:babyhealth/viewmodels/analysis_viewmodel.dart';

/// A fake [UploadRepository] with configurable behavior for testing.
class FakeUploadRepository implements UploadRepository {
  final String? uploadMediaResult;
  final Object? uploadMediaError;

  bool uploadMediaCalled = false;
  CapturedMedia? capturedMediaArg;

  FakeUploadRepository({
    this.uploadMediaResult,
    this.uploadMediaError,
  });

  @override
  Future<String> uploadMedia(CapturedMedia media) async {
    uploadMediaCalled = true;
    capturedMediaArg = media;
    if (uploadMediaError != null) {
      throw uploadMediaError!;
    }
    return uploadMediaResult ?? 'sessions/test/video.mp4';
  }

  @override
  Future<UploadUrlDto> getUploadUrl(String contentType) {
    throw UnimplementedError('Not used in tests');
  }
}

/// A fake [AnalysisRepository] with configurable behavior for testing.
class FakeAnalysisRepository implements AnalysisRepository {
  final AnalysisResult? analyzeResult;
  final Object? analyzeError;

  bool analyzeCalled = false;
  bool analyzeWithGeminiCalled = false;
  String? videoKeyArg;

  FakeAnalysisRepository({
    this.analyzeResult,
    this.analyzeError,
  });

  @override
  Future<AnalysisResult> analyze(String videoKey, {String? sessionId}) async {
    analyzeCalled = true;
    videoKeyArg = videoKey;
    if (analyzeError != null) {
      throw analyzeError!;
    }
    return analyzeResult ?? _defaultResult;
  }

  @override
  Future<AnalysisResult> analyzeWithGemini(String videoKey, {String? sessionId}) async {
    analyzeWithGeminiCalled = true;
    videoKeyArg = videoKey;
    if (analyzeError != null) {
      throw analyzeError!;
    }
    return analyzeResult ?? _defaultResult;
  }
}

final _defaultResult = const AnalysisResult(
  status: AnalysisStatus.normal,
  observations: 'Test observation',
  recommendations: 'Test recommendation',
  sessionId: 'test-session-001',
  disclaimer: 'Test disclaimer',
);

void main() {
  group('AnalysisViewModel', () {
    final testBytes = Uint8List.fromList([0x00, 0x01, 0x02, 0x03]);
    final testMedia = CapturedMedia(
      bytes: testBytes,
      fileName: 'test_video.mp4',
      mimeType: 'video/mp4',
    );

    late FakeUploadRepository fakeUploadRepo;
    late FakeAnalysisRepository fakeAnalysisRepo;
    late AnalysisViewModel viewModel;

    setUp(() {
      fakeUploadRepo = FakeUploadRepository();
      fakeAnalysisRepo = FakeAnalysisRepository();
      viewModel = AnalysisViewModel(
        uploadRepository: fakeUploadRepo,
        analysisRepository: fakeAnalysisRepo,
      );
    });

    group('initial state', () {
      test('status is "idle" by default', () {
        expect(viewModel.state.status, equals('idle'));
      });

      test('result is null by default', () {
        expect(viewModel.state.result, isNull);
      });

      test('errorMessage is null by default', () {
        expect(viewModel.state.errorMessage, isNull);
      });
    });

    group('startAnalysis', () {
      test('completes full flow on success', () async {
        final states = <String>[];
        viewModel.addListener(() {
          states.add(viewModel.state.status);
        });

        await viewModel.startAnalysis(testMedia);

        expect(fakeUploadRepo.uploadMediaCalled, isTrue);
        expect(fakeUploadRepo.capturedMediaArg, equals(testMedia));
        expect(fakeAnalysisRepo.analyzeCalled, isTrue);
        expect(fakeAnalysisRepo.videoKeyArg, equals('sessions/test/video.mp4'));
        expect(states, contains('uploading'));
        expect(states, contains('analyzing'));
        expect(viewModel.state.status, equals('completed'));
        expect(viewModel.state.result, isNotNull);
        expect(viewModel.state.result!.status, equals(AnalysisStatus.normal));
        expect(viewModel.state.errorMessage, isNull);
      });

      test('notifies listeners during transitions', () async {
        var listenerCallCount = 0;
        viewModel.addListener(() {
          listenerCallCount++;
        });

        await viewModel.startAnalysis(testMedia);

        // At least 3 notifications: uploading → analyzing → completed
        expect(listenerCallCount, greaterThanOrEqualTo(3));
      });

      test('sets error state when upload fails', () async {
        fakeUploadRepo = FakeUploadRepository(
          uploadMediaError: Exception('Upload failed: network error'),
        );
        viewModel = AnalysisViewModel(
          uploadRepository: fakeUploadRepo,
          analysisRepository: fakeAnalysisRepo,
        );

        await viewModel.startAnalysis(testMedia);

        expect(viewModel.state.status, equals('error'));
        expect(viewModel.state.errorMessage, contains('Upload failed'));
        expect(viewModel.state.result, isNull);
        expect(fakeAnalysisRepo.analyzeCalled, isFalse);
      });

      test('sets error state when analysis fails', () async {
        fakeAnalysisRepo = FakeAnalysisRepository(
          analyzeError: Exception('Analysis service unavailable'),
        );
        viewModel = AnalysisViewModel(
          uploadRepository: fakeUploadRepo,
          analysisRepository: fakeAnalysisRepo,
        );

        await viewModel.startAnalysis(testMedia);

        expect(viewModel.state.status, equals('error'));
        expect(viewModel.state.errorMessage, contains('Analysis service unavailable'));
        expect(viewModel.state.result, isNull);
        expect(fakeUploadRepo.uploadMediaCalled, isTrue);
        expect(fakeAnalysisRepo.analyzeCalled, isTrue);
      });

      test('handles HttpClientException from upload', () async {
        fakeUploadRepo = FakeUploadRepository(
          uploadMediaError: const HttpClientException(
            message: 'Failed to get upload URL with HTTP 500',
            statusCode: 500,
          ),
        );
        viewModel = AnalysisViewModel(
          uploadRepository: fakeUploadRepo,
          analysisRepository: fakeAnalysisRepo,
        );

        await viewModel.startAnalysis(testMedia);

        expect(viewModel.state.status, equals('error'));
        expect(viewModel.state.errorMessage, contains('HTTP 500'));
      });

      test('handles HttpClientException from analysis', () async {
        fakeAnalysisRepo = FakeAnalysisRepository(
          analyzeError: const HttpClientException(
            message: 'Analysis request failed with HTTP 503',
            statusCode: 503,
          ),
        );
        viewModel = AnalysisViewModel(
          uploadRepository: fakeUploadRepo,
          analysisRepository: fakeAnalysisRepo,
        );

        await viewModel.startAnalysis(testMedia);

        expect(viewModel.state.status, equals('error'));
        expect(viewModel.state.errorMessage, contains('HTTP 503'));
      });
    });

    group('reset', () {
      test('resets state to initial values', () async {
        await viewModel.startAnalysis(testMedia);
        expect(viewModel.state.status, equals('completed'));

        viewModel.reset();

        expect(viewModel.state.status, equals('idle'));
        expect(viewModel.state.result, isNull);
        expect(viewModel.state.errorMessage, isNull);
      });

      test('notifies listeners', () {
        var listenerCallCount = 0;
        viewModel.addListener(() {
          listenerCallCount++;
        });

        viewModel.reset();

        expect(listenerCallCount, equals(1));
      });
    });
  });
}
