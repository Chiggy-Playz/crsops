package tech.chiggydoes.crs_ops

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // In-app updates from GitHub Releases (lib/core/updates/). Remove
        // along with REQUEST_INSTALL_PACKAGES when moving to the Play Store.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "crs_ops/app_update")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "supportedAbis" -> result.success(Build.SUPPORTED_ABIS.toList())
                    "installApk" -> {
                        val path = call.argument<String>("path")
                        if (path == null) {
                            result.error("bad_args", "path is required", null)
                        } else {
                            result.success(installApk(File(path)))
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    // "started" once Android's installer is open, or "needs_permission" after
    // sending the user to allow "Install unknown apps" for this app first.
    private fun installApk(apk: File): String {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            !packageManager.canRequestPackageInstalls()
        ) {
            val settings = Intent(
                Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                Uri.parse("package:$packageName"),
            )
            startActivity(settings)
            return "needs_permission"
        }

        val uri = FileProvider.getUriForFile(this, "$packageName.updates", apk)
        val install = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, "application/vnd.android.package-archive")
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        startActivity(install)
        return "started"
    }
}

// Own subclass so this provider can't clash with a plugin's FileProvider
// entry when the manifests are merged.
class UpdateFileProvider : FileProvider()
