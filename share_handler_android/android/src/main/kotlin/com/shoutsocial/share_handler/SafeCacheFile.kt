package com.shoutsocial.share_handler

import java.io.File
import java.io.IOException

// A shared stream's display name is chosen by the SENDING app's content
// provider, and any installed app can send an explicit ACTION_SEND to the
// receiving app's exported activity. Using that name as a path
// (File(cacheDir, displayName)) let a name like "../shared_prefs/x.xml"
// escape the cache directory and overwrite the receiving app's private
// files (CWE-23, issue #140).

/**
 * The file [name] may be written to inside [dir]: only its last path segment
 * is kept, and the result must be a direct child of [dir]. Returns null for
 * names that are unusable (null, empty, ".", "..", or containing NUL), so the
 * caller can fall back to a generated name.
 */
internal fun safeCacheFile(dir: File, name: String?): File? {
    if (name == null || name.indexOf('\u0000') >= 0) return null
    val base = File(name).name
    if (base.isEmpty() || base == "." || base == "..") return null
    val file = File(dir, base)
    return try {
        if (file.canonicalFile.parentFile == dir.canonicalFile) file else null
    } catch (e: IOException) {
        null
    }
}
