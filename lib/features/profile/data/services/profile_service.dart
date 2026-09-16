import 'dart:io';
import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';

class ProfileService {
  final Dio _dio = DioClient().instance;

  Future<Response> updateProfile(
      {String? name, String? gender, File? imageFile}) async {
    try {
      Map<String, dynamic> data = {};
      if (name != null) data['name'] = name;
      if (gender != null) data['gender'] = gender;

      if (imageFile != null) {
        data["image"] = await MultipartFile.fromFile(imageFile.path);
      }

      return await _dio.patch('api/user/update-profile', data: FormData.fromMap(data));
    } on DioException { rethrow; }
  }
}