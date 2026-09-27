import '../../../core/repositories/auth_repository.dart';
import 'citizen_verification_remote_data_source.dart';

class CitizenVerificationRepositoryApi
    implements CitizenVerificationRepository {
  const CitizenVerificationRepositoryApi({
    required CitizenVerificationRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final CitizenVerificationRemoteDataSource _remoteDataSource;

  @override
  Future<void> uploadIdentityPhotos({
    required CitizenIdentityPhoto frontPhoto,
    required CitizenIdentityPhoto backPhoto,
  }) {
    return _remoteDataSource.uploadIdentityPhotos(
      frontPhoto: frontPhoto,
      backPhoto: backPhoto,
    );
  }
}
