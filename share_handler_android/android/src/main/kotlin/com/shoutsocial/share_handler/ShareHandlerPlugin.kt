package com.shoutsocial.share_handler

import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.net.Uri

import androidx.annotation.NonNull
import androidx.core.app.Person
import androidx.core.content.pm.ShortcutInfoCompat
import androidx.core.content.pm.ShortcutManagerCompat
import androidx.core.graphics.drawable.IconCompat

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.*
import java.net.URLConnection

private const val kEventsChannel = "com.shoutsocial.share_handler/sharedMediaStream"

/** ShareHandlerPlugin */
class ShareHandlerPlugin: FlutterPlugin, Messages.ShareHandlerApi, EventChannel.StreamHandler, ActivityAware, PluginRegistry.NewIntentListener {
  private var initialMedia: Messages.SharedMedia? = null
  private var eventChannel: EventChannel? = null
  private var eventSink: EventChannel.EventSink? = null

  private var binding: ActivityPluginBinding? = null
  private lateinit var applicationContext: Context

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    applicationContext = flutterPluginBinding.applicationContext

    val messenger = flutterPluginBinding.binaryMessenger
    Messages.ShareHandlerApi.setup(messenger, this)

    eventChannel = EventChannel(messenger, kEventsChannel)
    eventChannel?.setStreamHandler(this)
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    Messages.ShareHandlerApi.setup(binding.binaryMessenger, null)
  }

//  override fun getInitialSharedMedia(result: Result<SharedMedia>?) {
//    result?.let { _result -> {
//      initialMedia?.let { _media -> _result.success(_media) }
//    } }
//  }

//  override fun recordSentMessage(media: SharedMedia) {
//    val packageName = applicationContext.packageName
//    val shortcutTarget = "$packageName.dynamic_share_target"
//    val shortcutBuilder = ShortcutInfoCompat.Builder(applicationContext, media.conversationIdentifier ?: "").setShortLabel(media.speakableGroupName ?: "Unknown")
//      .setIsConversation()
//      .setCategories(setOf(shortcutTarget))
//      .setIntent(Intent(Intent.ACTION_DEFAULT))
//      .setLongLived(true)
//
//    val personBuilder = Person.Builder()
//      .setKey(media.conversationIdentifier)
//      .setName(media.speakableGroupName)
//
//    media.imageFilePath?.let {
//      val bitmap = BitmapFactory.decodeFile(it)
//      val icon = IconCompat.createWithAdaptiveBitmap(bitmap)
//      shortcutBuilder.setIcon(icon)
//      personBuilder.setIcon(icon)
//    }
//
//    val person = personBuilder.build()
//    shortcutBuilder.setPerson(person)
//
//    val shortcut = shortcutBuilder.build()
//
//    ShortcutManagerCompat.addDynamicShortcuts(applicationContext, listOf(shortcut))
//  }

  override fun getInitialSharedMedia(result: Messages.Result<Messages.SharedMedia>?) {
    result?.success(initialMedia)
  }

  override fun recordSentMessage(media: Messages.SharedMedia) {
    val packageName = applicationContext.packageName
    val intent = Intent(applicationContext, Class.forName("$packageName.MainActivity")).apply {
      action = Intent.ACTION_SEND
      putExtra("conversationIdentifier", media.conversationIdentifier)
    }
//    val intent = Intent(Intent.ACTION_VIEW).apply {
//      putExtra("conversationIdentifier", media.conversationIdentifier)
//    }
    val shortcutTarget = "$packageName.dynamic_share_target"
    val shortcutBuilder = ShortcutInfoCompat.Builder(applicationContext, media.conversationIdentifier ?: "").setShortLabel(media.speakableGroupName ?: "Unknown")
      .setIsConversation()
      .setCategories(setOf(shortcutTarget))
      .setIntent(intent)
      .setLongLived(true)

    val personBuilder = Person.Builder()
      .setKey(media.conversationIdentifier)
      .setName(media.speakableGroupName)

    media.imageFilePath?.let {
      val bitmap = BitmapFactory.decodeFile(it)
      val icon = IconCompat.createWithAdaptiveBitmap(bitmap)
      shortcutBuilder.setIcon(icon)
      personBuilder.setIcon(icon)
    }

    val person = personBuilder.build()
    shortcutBuilder.setPerson(person)

    val shortcut = shortcutBuilder.build()

    ShortcutManagerCompat.addDynamicShortcuts(applicationContext, listOf(shortcut))
  }

  override fun resetInitialSharedMedia() {
    initialMedia = null
  }

  override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
    eventSink = events
  }

  override fun onCancel(arguments: Any?) {
    eventSink = null
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    this.binding = binding
    binding.addOnNewIntentListener(this)
    handleIntent(binding.activity.intent, true)
  }

  override fun onDetachedFromActivityForConfigChanges() {
    binding?.removeOnNewIntentListener(this)
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    this.binding = binding
    binding.addOnNewIntentListener(this)
  }

  override fun onDetachedFromActivity() {
    binding?.removeOnNewIntentListener(this)
  }

  override fun onNewIntent(intent: Intent): Boolean {
    handleIntent(intent, false)
    return false
  }

  private fun handleIntent(intent: Intent, initial: Boolean) {
    val attachments: List<Messages.SharedAttachment>?
    val text: String?
    when {
      (intent.type?.startsWith("text") != true)
              && (intent.action == Intent.ACTION_SEND
              || intent.action == Intent.ACTION_SEND_MULTIPLE) -> { // Sharing images or videos

        attachments = attachmentsFromIntent(intent)
        text = null
      }
      (intent.type == null || intent.type?.startsWith("text") == true)
              && intent.action == Intent.ACTION_SEND -> { // Sharing text
        text = intent.getStringExtra(Intent.EXTRA_TEXT)
        attachments = if (text == null) {
          attachmentsFromIntent(intent)
        } else {
          null
        }
      }
      intent.action == Intent.ACTION_VIEW -> { // Opening URL
        attachments = null
        text = intent.dataString
      }
      else -> {
        attachments = null
        text = null
      }
    }
//    val conversationIdentifier = intent.getStringExtra(Intent.EXTRA_SHORTCUT_ID)
    val conversationIdentifier = intent.getStringExtra("android.intent.extra.shortcut.ID") ?: intent.getStringExtra("conversationIdentifier")
    if (attachments != null || text != null || conversationIdentifier != null) {
//      val media = SharedMedia(attachments = attachments, content = text)
      val media = Messages.SharedMedia.Builder().setAttachments(attachments).setContent(text).setConversationIdentifier(conversationIdentifier).build()
      if (initial) initialMedia = media
      eventSink?.success(media.toMap())
    }
  }

  private fun attachmentsFromIntent(intent: Intent?): List<Messages.SharedAttachment>? {
    if (intent == null) return null
    return when (intent.action) {
      Intent.ACTION_SEND -> {
        val uri = intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM) ?: return null
        return listOf(attachmentForUri(uri)).mapNotNull { it }
      }
      Intent.ACTION_SEND_MULTIPLE -> {
        val uris = intent.getParcelableArrayListExtra<Uri>(Intent.EXTRA_STREAM)
        val value = uris?.mapNotNull { uri ->
          attachmentForUri(uri)
        }?.toList()
        return value
      }
      else -> null
    }
  }

  private fun attachmentForUri(uri: Uri): Messages.SharedAttachment? {
    val path = FileDirectory.getAbsolutePath(applicationContext, uri)
    return if (path != null) {
      val type = getAttachmentType(path)
//      SharedAttachment(path = path, type = type)
      Messages.SharedAttachment.Builder().setPath(path).setType(type).build()
    } else {
      null
    }
  }

  private fun getAttachmentType(path: String?): Messages.SharedAttachmentType {
    val mimeType = URLConnection.guessContentTypeFromName(path)
    return when {
      mimeType?.startsWith("image") == true -> Messages.SharedAttachmentType.image
      mimeType?.startsWith("video") == true -> Messages.SharedAttachmentType.video
      mimeType?.startsWith("audio") == true -> Messages.SharedAttachmentType.audio
      else -> Messages.SharedAttachmentType.file
    }
  }
}
