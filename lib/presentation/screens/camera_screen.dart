import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/camera_provider.dart';

class CameraScreen extends ConsumerWidget {
  const CameraScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controllerState = ref.watch(cameraProvider);
    final cameraController = ref.read(cameraProvider.notifier);
    final commentController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('Фото с ФК')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: controllerState.when(
                data: (_) => AspectRatio(
                  aspectRatio: cameraController.controller!.value.aspectRatio,
                  child: CameraPreview(cameraController.controller!),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Ошибка: $e')),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: commentController,
              decoration: const InputDecoration(
                labelText: 'Комментарий',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                child: const Text('Сделать фото и отправить'),
                onPressed: () async {
                  await cameraController.takeAndUpload(commentController.text);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Фото отправлено!')),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
