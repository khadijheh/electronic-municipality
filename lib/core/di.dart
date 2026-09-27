import 'package:electronic_municipality_final/core/network/api_client.dart';
import 'package:electronic_municipality_final/core/storage/token_storage.dart';
import 'package:flutter/foundation.dart';

import 'package:electronic_municipality_final/core/network/api_client.dart';
import 'package:electronic_municipality_final/core/repositories/auth_repository.dart';
import 'package:electronic_municipality_final/core/storage/token_storage.dart';
import 'package:electronic_municipality_final/features/authentication/data/auth_remote_data_source.dart';
import 'package:electronic_municipality_final/features/authentication/data/auth_repository_api.dart';
import 'package:electronic_municipality_final/features/complaints/data/complaints_remote_data_source.dart';
import 'package:electronic_municipality_final/features/field_inspector/data/field_inspector_remote_data_source.dart';
import 'package:electronic_municipality_final/features/complaints/data/complaints_repository_api.dart';
import 'package:electronic_municipality_final/features/complaints/domain/complaints_repository.dart';
import 'package:electronic_municipality_final/features/profile/data/citizen_verification_remote_data_source.dart';
import 'package:electronic_municipality_final/features/profile/data/citizen_verification_repository_api.dart';
import 'package:electronic_municipality_final/features/home/data/unified_complaints_map_repository_api.dart';
import 'package:electronic_municipality_final/features/home/domain/unified_complaints_map_repository.dart';

/// Dependencies used by the running application.
///
/// Tests can continue using AuthRepositoryFake directly.
class DI {
  DI._();

  static final TokenStorage tokenStorage = TokenStorage();

  static final ApiClient apiClient = ApiClient(
    tokenStorage: tokenStorage,
  );

  static final AuthRemoteDataSource authRemoteDataSource =
      AuthRemoteDataSource(apiClient);

  static final FieldInspectorRemoteDataSource fieldInspector =
      FieldInspectorRemoteDataSource(apiClient);

  static AuthRepository _auth = _buildAuthRepository();
  static CitizenVerificationRepository _citizenVerification =
      _buildCitizenVerificationRepository();
  static ComplaintsRepository _complaints = _buildComplaintsRepository();
  static UnifiedComplaintsMapRepository _unifiedComplaintsMap =
      _buildUnifiedComplaintsMapRepository();

  static AuthRepository get auth => _auth;
  static CitizenVerificationRepository get citizenVerification =>
      _citizenVerification;
  static ComplaintsRepository get complaints => _complaints;
  static UnifiedComplaintsMapRepository get unifiedComplaintsMap =>
      _unifiedComplaintsMap;

  @visibleForTesting
  static void overrideAuth(AuthRepository repository) {
    _auth = repository;
  }

  @visibleForTesting
  static void resetAuth() {
    _auth = _buildAuthRepository();
    _citizenVerification = _buildCitizenVerificationRepository();
    _complaints = _buildComplaintsRepository();
    _unifiedComplaintsMap = _buildUnifiedComplaintsMapRepository();
  }

  @visibleForTesting
  static void overrideCitizenVerification(
    CitizenVerificationRepository repository,
  ) {
    _citizenVerification = repository;
  }

  @visibleForTesting
  static void overrideComplaints(ComplaintsRepository repository) {
    _complaints = repository;
  }

  @visibleForTesting
  static void overrideUnifiedComplaintsMap(
    UnifiedComplaintsMapRepository repository,
  ) {
    _unifiedComplaintsMap = repository;
  }

  static AuthRepository _buildAuthRepository() {
    return AuthRepositoryApi(
      remoteDataSource: authRemoteDataSource,
      tokenStorage: tokenStorage,
    );
  }

  static CitizenVerificationRepository _buildCitizenVerificationRepository() {
    return CitizenVerificationRepositoryApi(
      remoteDataSource: CitizenVerificationRemoteDataSource(apiClient),
    );
  }

  static ComplaintsRepository _buildComplaintsRepository() {
    return ComplaintsRepositoryApi(
      remoteDataSource: ComplaintsRemoteDataSource(apiClient),
    );
  }

  static UnifiedComplaintsMapRepository _buildUnifiedComplaintsMapRepository() {
    return UnifiedComplaintsMapRepositoryApi(apiClient: apiClient);
  }
}
