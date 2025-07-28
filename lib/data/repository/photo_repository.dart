import '../../domain/entities/photo_data.dart';

abstract class PhotoRepository {
  Future<void> uploadPhoto(PhotoData photo);
}
