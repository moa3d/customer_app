package com.nomnow.app

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/// صلاحية الإشعارات على أندرويد صلاحية نظام لا علاقة لها بـ FCM، لذلك تُدار
/// هنا أصلياً بدل الاعتماد على `FirebaseMessaging.requestPermission` — فيبقى
/// طلبها ممكناً حتى قبل اكتمال إعدادات Firebase.
class MainActivity : FlutterFragmentActivity() {

    private companion object {
        const val CHANNEL = "com.nomnow.app/notification_permission"
        const val REQUEST_CODE = 7311

        /// يجب أن يطابق default_notification_channel_id في AndroidManifest.xml
        /// حرفياً، وإلا هبط الإشعار إلى قناة احتياطية بأهمية افتراضية.
        const val ORDER_CHANNEL_ID = "order_status"

        // القيم المتفق عليها مع NotificationPermissionService في Dart
        const val GRANTED = "granted"
        const val DENIED = "denied"
        const val PERMANENTLY_DENIED = "permanentlyDenied"
        const val BLOCKED_BY_SETTINGS = "blockedBySettings"
    }

    /// نتيجة نداء `request` المعلّق ريثما يرد حوار النظام — تُصفّر بعد أول رد
    /// حتى لا يُردّ على نفس الـ Result مرتين (يُسقط التطبيق).
    private var pendingResult: MethodChannel.Result? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createOrderChannel()
    }

    /// قناة تحديثات الطلب.
    ///
    /// على أندرويد 8+ أهمية القناة — لا أولوية الرسالة — هي ما يقرّر الظهور
    /// المنبثق. الباك يرسل `priority: "high"` لكن ذلك لا يرفع أهمية القناة،
    /// فبلا هذه الدالة يدخل الإشعار الدرج بهدوء بلا ظهور فوق الشاشة.
    ///
    /// `createNotificationChannel` عملية idempotent: استدعاؤها على قناة قائمة
    /// لا ينشئ ثانية ولا يعيد ضبط ما غيّره المستخدم من إعدادات النظام.
    private fun createOrderChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val channel = NotificationChannel(
            ORDER_CHANNEL_ID,
            getString(R.string.notification_channel_order_name),
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = getString(R.string.notification_channel_order_desc)
            enableVibration(true)
        }

        val manager = getSystemService(NotificationManager::class.java)
        manager?.createNotificationChannel(channel)
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "status" -> result.success(currentStatus())
                    "request" -> requestPermission(result)
                    "openSettings" -> {
                        openNotificationSettings()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /// `areNotificationsEnabled` هي الحقيقة النهائية: تعود false أيضاً حين
    /// يُغلق المستخدم الإشعارات من إعدادات النظام رغم منح الصلاحية سابقاً.
    private fun currentStatus(): String {
        if (NotificationManagerCompat.from(this).areNotificationsEnabled()) {
            return GRANTED
        }

        // دون أندرويد 13 لا توجد صلاحية تشغيلية تُطلب — الإصلاح من الإعدادات فقط
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            return BLOCKED_BY_SETTINGS
        }

        val granted = ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.POST_NOTIFICATIONS
        ) == PackageManager.PERMISSION_GRANTED

        // الصلاحية ممنوحة لكن الإشعارات مغلقة يدوياً من الإعدادات
        if (granted) return BLOCKED_BY_SETTINGS

        // shouldShowRationale تعود false قبل أول سؤال وبعد الرفض النهائي معاً،
        // ولهذا يميّز بينهما علمُ "سبق أن سألنا" المحفوظ في طبقة Dart.
        return if (ActivityCompat.shouldShowRequestPermissionRationale(
                this,
                Manifest.permission.POST_NOTIFICATIONS
            )
        ) DENIED else PERMANENTLY_DENIED
    }

    private fun requestPermission(result: MethodChannel.Result) {
        // لا حوار نظام دون أندرويد 13 — نعيد الحالة الحالية فوراً
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            result.success(currentStatus())
            return
        }

        if (ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.POST_NOTIFICATIONS
            ) == PackageManager.PERMISSION_GRANTED
        ) {
            result.success(currentStatus())
            return
        }

        // نداء ثانٍ قبل رد الأول: نُنهي المعلّق بحالته الراهنة بدل تسريبه
        pendingResult?.success(currentStatus())
        pendingResult = result

        ActivityCompat.requestPermissions(
            this,
            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
            REQUEST_CODE
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != REQUEST_CODE) return

        val result = pendingResult ?: return
        pendingResult = null
        result.success(currentStatus())
    }

    /// شاشة إشعارات التطبيق مباشرةً على أندرويد 8+، وصفحة تفاصيل التطبيق قبلها.
    private fun openNotificationSettings() {
        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
        } else {
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                .setData(Uri.fromParts("package", packageName, null))
        }

        try {
            startActivity(intent)
        } catch (e: Exception) {
            // بعض الأجهزة المعدّلة لا تملك هذه الشاشة — نرجع لتفاصيل التطبيق
            try {
                startActivity(
                    Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                        .setData(Uri.fromParts("package", packageName, null))
                )
            } catch (_: Exception) {
                // لا شيء يمكن فعله — الفشل هنا لا يجب أن يُسقط التطبيق
            }
        }
    }
}
