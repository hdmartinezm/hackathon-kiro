import 'dart:io';

/// Handler de privacidad para audio en iOS.
/// Elimina archivos de audio inmediatamente después del procesamiento.
class IosAudioPrivacyHandler {
  /// Elimina archivo de audio de forma segura.
  Future<void> deleteAudioFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Silently fail - best effort deletion
    }
  }

  /// Elimina todos los archivos de audio temporales.
  Future<void> cleanupTemporaryAudio(String directoryPath) async {
    try {
      final dir = Directory(directoryPath);
      if (await dir.exists()) {
        final files = await dir.list().toList();
        for (final entity in files) {
          if (entity is File &&
              (entity.path.endsWith('.wav') ||
                  entity.path.endsWith('.m4a') ||
                  entity.path.endsWith('.aac'))) {
            await entity.delete();
          }
        }
      }
    } catch (_) {
      // Best effort cleanup
    }
  }

  /// Sobrescribe y elimina para mayor seguridad.
  Future<void> secureDelete(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        // Sobrescribir con ceros antes de eliminar
        final length = await file.length();
        await file.writeAsBytes(List.filled(length, 0));
        await file.delete();
      }
    } catch (_) {
      // Fallback to normal delete
      await deleteAudioFile(path);
    }
  }
}
