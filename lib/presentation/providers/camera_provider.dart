// TODO Implement this library.import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/di/service_locator.dart';
import '../../domain/entities/photo_data.dart';
import '../../domain/usecases/upload_photo_usecase.dart';

final cameraProvider = StateNotifierProvider<CameraControllerNotifier, AsyncValue<void>>((ref) {
  return CameraControllerNotifier();
});

class CameraControllerNotifier extends StateNotifier<AsyncValue<void>> {
  CameraControllerNotifier() : super(const AsyncLoading()) {
    _init();
  }

  CameraController? controller;
  bool isUploading = false;

  Future<void> _init() async {
    try {
      final cameras = await availableCameras();
      final camera = cameras.first; // выбираем первую доступную камеру
      controller = CameraController(camera, ResolutionPreset.medium);
      await controller!.initialize();
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> takeAndUpload(String comment) async {
    if (controller == null || !controller!.value.isInitialized) return;

    isUploading = true;

    try {
      final photo = await controller!.takePicture();
      final position = await Geolocator.getCurrentPosition();

      final data = PhotoData(
        path: photo.path,
        comment: comment,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      await sl<UploadPhotoUseCase>()(data); // вызов use case
    } catch (e) {
      rethrow;
    } finally {
      isUploading = false;
    }
  }
}
