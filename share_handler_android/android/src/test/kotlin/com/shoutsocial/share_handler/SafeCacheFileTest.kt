package com.shoutsocial.share_handler

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder
import java.io.File

/**
 * The display name of a shared stream comes from the SENDING app's content
 * provider. Any app can send an explicit ACTION_SEND to the exported
 * launcher activity, so the name must never be able to leave the cache dir
 * ("Dirty Stream" path traversal).
 */
class SafeCacheFileTest {
  @get:Rule
  val tmp = TemporaryFolder()

  private fun cache(): File = tmp.newFolder("cache")

  @Test
  fun plainNameStaysInCache() {
    val dir = cache()
    assertEquals(File(dir, "hello.gif"), safeCacheFile(dir, "hello.gif"))
  }

  @Test
  fun traversalIsReducedToTheBaseName() {
    val dir = cache()
    assertEquals(File(dir, "x.xml"), safeCacheFile(dir, "../shared_prefs/x.xml"))
    assertEquals(File(dir, "x"), safeCacheFile(dir, "../../app_flutter/x"))
    assertEquals(File(dir, "passwd"), safeCacheFile(dir, "/etc/passwd"))
  }

  @Test
  fun unusableNamesAreRejected() {
    val dir = cache()
    for (bad in listOf(null, "", ".", "..", "/", "a/..", "a\u0000.gif")) {
      assertNull("name '$bad' must be rejected", safeCacheFile(dir, bad))
    }
  }

  @Test
  fun resultIsAlwaysADirectChildOfTheCacheDir() {
    val dir = cache()
    for (name in listOf("a.gif", "../a.gif", "sub/a.gif", "..\u0000/a.gif")) {
      val f = safeCacheFile(dir, name) ?: continue
      assertEquals(dir.canonicalFile, f.canonicalFile.parentFile)
    }
  }
}
