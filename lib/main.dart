import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

List<CameraDescription> cameras = [];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: CameraScreen(),
    );
  }
}

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});
  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? controller;
  bool isCameraInitialized = false;
  String errorText = '';
  final TextEditingController commentController = TextEditingController();
  bool isUploading = false;

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  Future<void> initializeCamera() async {
    if (cameras.isEmpty) {
      setState(() {
        errorText = 'Камеры не найдены';
      });
      return;
    }

    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    controller = CameraController(frontCamera, ResolutionPreset.medium);

    try {
      await controller!.initialize();
      if (!mounted) return;
      setState(() {
        isCameraInitialized = true;
        errorText = '';
      });
    } catch (e) {
      setState(() {
        errorText = 'Ошибка инициализации камеры: $e';
      });
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    commentController.dispose();
    super.dispose();
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Проверяем, включена ли служба геолокации
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Служба геолокации отключена.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Разрешение на геолокацию отклонено.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Разрешение на геолокацию отклонено навсегда.');
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<void> _takePhotoAndUpload() async {
    if (controller == null || !controller!.value.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Камера не готова')));
      return;
    }

    setState(() {
      isUploading = true;
    });

    try {
      final position = await _determinePosition();

      final XFile photo = await controller!.takePicture();
      final tempDir = await getTemporaryDirectory();
      final savedImage = await File(photo.path).copy('${tempDir.path}/${path.basename(photo.path)}');

      // насколько реален это адрес не знаю, но если он есть, на него точно отправляется, в сборке ловлю 404, но позиция и фото с коментом сохраняются в запросе перед отправкой, так что функциональная часть в порядке
      var uri = Uri.parse('https://flutter-sandbox.free.beeceptor.com/upload_photo/');
      var request = http.MultipartRequest('POST', uri);

      request.fields['comment'] = commentController.text;
      request.fields['latitude'] = position.latitude.toString();
      request.fields['longitude'] = position.longitude.toString();
      request.files.add(await http.MultipartFile.fromPath('photo', savedImage.path));

      
      var response = await request.send();

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Данные успешно отправлены!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка отправки: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    } finally {
      setState(() {
        isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Фото с ФК'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: errorText.isNotEmpty
                    ? Text(errorText)
                    : isCameraInitialized && controller != null
                        ? AspectRatio(
                            aspectRatio: controller!.value.aspectRatio,
                            child: CameraPreview(controller!),
                          )
                        : const CircularProgressIndicator(),
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
              child: ElevatedButton.icon(
                icon: isUploading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.cloud_upload),
                label: Text(isUploading ? 'Отправка...' : 'Сделать фото и отправить'),
                onPressed: isUploading ? null : _takePhotoAndUpload,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
