import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../features/auth/data/models/user_model.dart';
import '../../features/location/data/models/address_model.dart';
import '../network/dio_client.dart';
import 'order_notifications_service.dart';
import 'push_notification_service.dart';
import 'socket_service.dart';
import 'token_storage.dart';



class AuthService {
  final Dio _dio = DioClient().instance;

  // 1. جلب التوكن المخزن (من التخزين الآمن)
  Future<String?> getToken() => TokenStorage().getToken();

  // 2. جلب معرف المستخدم
  Future<String?> getUserId() => TokenStorage().getUserId();

  // 3. تسجيل الخروج
  //
  // v3.5 — نُعلم الباك أولاً ليمسح fcmToken من الحساب، ثم نمسح التوكن محلياً.
  // الترتيب مهم: النداء يحتاج التوكن للمصادقة. ولولا هذه الخطوة لبقي الجهاز
  // مربوطاً بالحساب القديم، فيستمر صاحبه في تلقّي إشعارات من يسجّل دخوله بعده
  // على نفس الجهاز.
  //
  // موضعها هنا مقصود: كل مواضع الخروج في التطبيق (زر الخروج، شاشة الحظر،
  // الخروج التلقائي عند 401/403) تمرّ من هنا فتلتزم بالتنظيف كاملاً تلقائياً.
  // كان التنظيف موزّعاً: توكن FCM هنا، وقطع السوكيت ومسح سجلّ الإشعارات
  // والكاش منسوخة في موضعَي خروج من ثلاثة — فمسار شاشة الحظر كان يترك سجلّ
  // الحساب السابق على الجهاز ويُبقي السوكيت متصلاً بتوكن ميّت.
  Future<void> logout() async {
    try {
      final token = await TokenStorage().getToken();
      if (token != null && token.isNotEmpty) {
        await _dio.post('api/user/logout');
      }
    } catch (e) {
      // فشل إعلام الباك (بلا إنترنت، أو توكن منتهٍ أصلاً) لا يمنع الخروج محلياً
      debugPrint("[LOGOUT]: server notification failed — continuing: $e");
    } finally {
      await PushNotificationService().clearCachedToken();
      SocketService().disconnect();
      // سجلّ الإشعارات يخصّ حساباً بعينه
      await OrderNotificationsService().clearOnLogout();
      await DioClient.clearCache();
      await TokenStorage().clear();
    }
  }

  // 4. تسجيل حساب جديد
  Future<Response> register({
    required String name,
    required String phone,
    required String password,
    required String gender,
    File? imageFile,
  }) async {
    try {
      Map<String, dynamic> data = {
        'name': name,
        'phone': phone,
        'password': password,
        'gender': gender,
      };

      FormData formData = FormData.fromMap(data);
      if (imageFile != null) {
        formData.files.add(MapEntry(
          "image", // يجب أن يطابق upload.single("image") في الباك أند
          await MultipartFile.fromFile(imageFile.path, filename: "profile.jpg"),
        ));
      }

      debugPrint(" [REGISTER ATTEMPT]: Sending to api/user/register");
      final response = await _dio.post('api/user/register', data: formData);
      debugPrint(" [REGISTER SUCCESS]: ${response.statusCode}");
      return response;
    } on DioException catch (e) {
      debugPrint(" [REGISTER ERROR] Status: ${e.response?.statusCode}");
      debugPrint(" [ERROR DATA]: ${e.response?.data}");
      debugPrint(" [ERROR TYPE]: ${e.type}");
      rethrow;
    }
  }

  // 5. تسجيل دخول عبر الهاتف (يدعمrequiresVerification الجديد من الباك أند)
  Future<Response> loginWithPhone(String phone, String password) async {
    try {
      return await _dio.post(
        'api/user/loginwithphone',
        data: {"phone": phone, "password": password},
      );
    } catch (e) {
      rethrow;
    }
  }

  // 7. تفعيل الحساب (هاتف)
  Future<Response> verifyPhoneOtp(String phone, String otp) async {
    return await _dio.post(
      'api/user/verifyphone',
      data: {"phone": phone, "otp": otp},
    );
  }

  // 9. جلب بيانات الملف الشخصي (تم التحديث ليتوافق مع Response.data['user'])
  Future<UserModel> getUserProfile() async {
    try {
      final response = await _dio.get('api/user/user-info');
      // التحديث: الباك أند يرسل البيانات الآن داخل كائن 'user'
      if (response.data['success'] == true) {
        return UserModel.fromJson(response.data['user']);
      } else {
        // في حال كان الباك أند يرسل البيانات مباشرة في بعض الحالات القديمة
        return UserModel.fromJson(response.data);
      }
    } catch (e) {
      rethrow;
    }
  }

  // 10. تحديث الملف الشخصي
  Future<void> updateProfile({
    required String name,
    required String gender,
    File? imageFile,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        "name": name,
        "gender": gender,
        if (imageFile != null)
          "image": await MultipartFile.fromFile(
            imageFile.path,
            filename: "profile.jpg",
          ),
      });

      await _dio.patch('api/user/update-profile', data: formData);
    } catch (e) {
      rethrow;
    }
  }

  // --- قسم العناوين (Addresses) ---

  // 11. جلب العناوين
  Future<Response> getUserAddresses() async {
    try {
      return await _dio.get('api/user/user-addresses');
    } catch (e) {
      rethrow;
    }
  }

  // 12. إضافة أو تحديث عنوان
  Future<Response> addOrUpdateAddress(AddressModel address) async {
    try {
      final Map<String, dynamic> addressData = {
        "name": address.addressName,
        "fullAddress": "${address.country} - ${address.city} - ${address
            .area} - ${address.streetChoice}",
        "country": address.country,
        "city": address.city,
        "area": address.area,
        "street": address.streetChoice,
        "building": address.buildingDetail,
        "lng": address.lng,
        "lat": address.lat,
        "isDefault": address.isDefault,
        "notes": "",
      };

      if (address.id != null && address.id!.isNotEmpty) {
        addressData["addressId"] = address.id;
        return await _dio.patch('api/user/user-addresses', data: addressData);
      } else {
        return await _dio.post('api/user/user-addresses', data: addressData);
      }
    } catch (e) {
      rethrow;
    }
  }

  // 13. حذف عنوان
  Future<Response> deleteAddress(String addressId) async {
    try {
      return await _dio.delete(
        'api/user/user-addresses',
        data: {"addressId": addressId},
      );
    } catch (e) {
      rethrow;
    }
  }

  // 14. تعيين عنوان كافتراضي
  Future<Response> setDefaultAddress(String addressId) async {
    try {
      return await _dio.patch('api/user/user-addresses/$addressId');
    } catch (e) {
      rethrow;
    }
  }

  // 15. طلب إعادة تعيين كلمة المرور
  // بالهاتف حصراً: موديل المستخدم في الباك لا يحوي حقل بريد إلكتروني أصلاً،
  // فالهاتف هو المعرّف الوحيد الممكن لاستعادة كلمة المرور.
  Future<Response> forgotPassword(String phone) async {
    return await _dio.post('api/user/forgot-password', data: {'phone': phone});
  }

  // 16. تأكيد الرمز وتعيين كلمة المرور الجديدة بخطوة واحدة
  // v4.3 — لم يعد هناك `:token` في المسار: الرمز يُرسل ضمن الـbody مع الهاتف
  // نفسه المستخدم في الخطوة السابقة، والباك يتحقق منهما معاً ثم يمسح الرمز.
  Future<Response> resetPassword({
    required String phone,
    required String otp,
    required String newPassword,
    required String confirmPassword,
  }) async {
    return await _dio.post('api/user/reset-password', data: {
      'phone': phone,
      'otp': otp,
      'newPassword': newPassword,
      'confirmPassword': confirmPassword,
    });
  }
}
