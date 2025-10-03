// android/.../MainActivity.kt  (TEMPLATE)
// Move this content into your real MainActivity.kt file and fix the package line.

package YOUR.PACKAGE.NAME.HERE

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.provider.DocumentsContract
import androidx.documentfile.provider.DocumentFile
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL = "daily_diary/saf"
        private const val REQ_PICK_TREE = 9101
    }

    private var treeUri: Uri? = null
    private lateinit var channel: MethodChannel

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        channel = MethodChannel(flutterEngine?.dartExecutor?.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "pickRoot" -> {
                    val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
                        putExtra(DocumentsContract.EXTRA_PROMPT, "Choose Daily Diary folder")
                    }
                    startActivityForResult(intent, REQ_PICK_TREE)
                    result.success(null)
                }
                "setRoot" -> {
                    val uriStr = call.argument<String>("uri")
                    treeUri = if (uriStr.isNullOrEmpty()) null else Uri.parse(uriStr)
                    result.success(true)
                }
                "ensureDirs" -> {
                    ensureDirs(call.argument<List<String>>("segments") ?: emptyList())
                    result.success(true)
                }
                "readText" -> {
                    val segments = call.argument<List<String>>("segments") ?: emptyList()
                    val filename = call.argument<String>("filename")!!
                    val file = findFile(segments, filename, createIfMissing = false)
                    if (file == null) {
                        result.success(null)
                    } else {
                        contentResolver.openInputStream(file.uri).use { stream ->
                            val text = stream?.bufferedReader()?.readText()
                            result.success(text)
                        }
                    }
                }
                "writeText" -> {
                    val segments = call.argument<List<String>>("segments") ?: emptyList()
                    val filename = call.argument<String>("filename")!!
                    val content = call.argument<String>("content")!!
                    val file = findFile(segments, filename, createIfMissing = true)!!
                    contentResolver.openOutputStream(file.uri, "rwt").use { stream ->
                        stream!!.writer().use { it.write(content) }
                    }
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQ_PICK_TREE && resultCode == Activity.RESULT_OK) {
            val uri = data?.data ?: return
            val flags = Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
            try {
                contentResolver.takePersistableUriPermission(uri, flags)
            } catch (_: SecurityException) {
                // If the permission can't be persisted, ignore. We'll still try to use it in-session.
            }
            treeUri = uri
            channel.invokeMethod("onPicked", uri.toString())
        }
    }

    private fun ensureDirs(segments: List<String>): DocumentFile? {
        val root = treeUri?.let { DocumentFile.fromTreeUri(this, it) } ?: return null
        var dir = root
        for (name in segments) {
            val existing = dir?.findFile(name)
            dir = if (existing == null || !existing.isDirectory) {
                dir?.createDirectory(name)
            } else existing
        }
        return dir
    }

    private fun findFile(segments: List<String>, filename: String, createIfMissing: Boolean): DocumentFile? {
        val parent = ensureDirs(segments) ?: return null
        val existing = parent.findFile(filename)
        return existing ?: if (createIfMissing) parent.createFile("text/plain", filename) else null
    }
}
