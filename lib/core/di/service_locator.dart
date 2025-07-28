import 'package:flutter_application_2/data/repository/photo_repository_impl.dart';
import 'package:get_it/get_it.dart';
import '../../data/repository/photo_repository_impl.dart';
import '../../domain/usecases/upload_photo_usecase.dart';

final sl = GetIt.instance;

Future<void> setupLocator() async {
  sl.registerLazySingleton(() => PhotoRepositoryImpl());
  sl.registerLazySingleton(() => UploadPhotoUseCase(sl()));
}