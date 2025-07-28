import 'dart:io';
import 'package:flutter_application_2/domain/usecases/upload_photo_usecase.dart';
import 'package:http/http.dart' as http;
import '../../domain/entities/photo_data.dart';
import 'photo_repository.dart';

class PhotoRepositoryImpl implements PhotoRepository {
  @override
  Future<void> uploadPhoto(PhotoData photo) async {
    var uri = Uri.parse('https://flutter-sandbox.free.beeceptor.com/upload_photo/');
    var request = http.MultipartRequest('POST', uri);

    request.fields['comment'] = photo.comment;
    request.fields['latitude'] = photo.latitude.toString();
    request.fields['longitude'] = photo.longitude.toString();
    request.files.add(await http.MultipartFile.fromPath('photo', photo.path));

    final response = await request.send();
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Upload failed: ${response.statusCode}');
    }
  }
}