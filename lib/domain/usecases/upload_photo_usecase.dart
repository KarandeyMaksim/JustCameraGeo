import '../entities/photo_data.dart';
import '../../data/repository/photo_repository.dart';

class UploadPhotoUseCase {
  final PhotoRepository repository;
  UploadPhotoUseCase(this.repository);

  Future<void> call(PhotoData data) => repository.uploadPhoto(data);
}

