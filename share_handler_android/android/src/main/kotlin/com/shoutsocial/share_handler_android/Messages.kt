//package com.shoutsocial.share_handler_android
//
//import android.net.Uri
//import android.util.Log
//import io.flutter.plugin.common.StandardMessageCodec
//import io.flutter.plugin.common.MessageCodec
//import io.flutter.plugin.common.BinaryMessenger
//import io.flutter.plugin.common.BasicMessageChannel
//import java.io.ByteArrayOutputStream
//import java.lang.Error
//import java.lang.RuntimeException
//import java.nio.ByteBuffer
//import java.util.ArrayList
//import java.util.HashMap
//
//private fun wrapError(exception: Throwable): Map<String, Any> {
//    val errorMap: MutableMap<String, Any> = HashMap()
//    errorMap["message"] = exception.toString()
//    errorMap["code"] = exception.javaClass.simpleName
//    errorMap["details"] =
//        "Cause: " + exception.cause + ", Stacktrace: " + Log.getStackTraceString(
//            exception
//        )
//    return errorMap
//}
//
//enum class SharedAttachmentType(val index: Int) {
//    Image(0), Video(1), Audio(2), File(3);
//}
//
//data class SharedAttachment(val path: String, val type: SharedAttachmentType) {
//    fun toMap(): Map<String, Any?> {
//        val toMapResult: MutableMap<String, Any?> = HashMap()
//        toMapResult["path"] = path
//        toMapResult["type"] = type.index
//        return toMapResult
//    }
//
//    companion object {
//        fun fromMap(map: Map<String?, Any?>): SharedAttachment {
//            return SharedAttachment(
//                path = map["path"] as String,
//                type = SharedAttachmentType.values()[map["type"] as Int]
//            )
//        }
//    }
//}
//
//data class SharedMedia(val attachments: List<SharedAttachment>? = null, val conversationIdentifier: String? = null, val content: String? = null, val speakableGroupName: String? = null, val serviceName: String? = null, val senderIdentifier: String? = null, val imageFilePath: String? = null) {
//    fun toMap(): Map<String, Any?> {
//        val toMapResult: MutableMap<String, Any?> = HashMap()
//        toMapResult["attachments"] = attachments?.map { attachment -> attachment.toMap() }
//        toMapResult["conversationIdentifier"] = conversationIdentifier
//        toMapResult["content"] = content
//        toMapResult["speakableGroupName"] = speakableGroupName
//        toMapResult["serviceName"] = serviceName
//        toMapResult["senderIdentifier"] = senderIdentifier
//        toMapResult["imageFilePath"] = imageFilePath
//        return toMapResult
//    }
//
//    companion object {
//        @Suppress("UNCHECKED_CAST")
//        fun fromMap(map: Map<String?, Any?>): SharedMedia {
//            return SharedMedia(attachments = (map["attachments"] as List<*>?)?.map { attachment -> SharedAttachment.fromMap(attachment as Map<String?, Any?>) },
//                conversationIdentifier = map["conversationIdentifier"] as String?,
//                content = map["content"] as String?,
//                speakableGroupName = map["speakableGroupName"] as String?,
//                serviceName = map["serviceName"] as String?,
//                senderIdentifier = map["senderIdentifier"] as String?,
//                imageFilePath = map["imageFilePath"] as String?,
//            )
//        }
//    }
//}
//
//interface Result<T> {
//    fun success(result: T?)
//    fun error(error: Throwable)
//}
//
//private class ShareHandlerApiCodec private constructor() : StandardMessageCodec() {
//    @Suppress("UNCHECKED_CAST")
//    override fun readValueOfType(type: Byte, buffer: ByteBuffer): Any {
//        return when (type) {
//            128.toByte() -> SharedAttachment.fromMap(readValue(buffer) as Map<String?, Any?>)
//            129.toByte() -> SharedMedia.fromMap(readValue(buffer) as Map<String?, Any?>)
//            130.toByte() -> SharedMedia.fromMap(readValue(buffer) as Map<String?, Any?>)
//            else -> super.readValueOfType(type, buffer)
//        }
//    }
//
//    override fun writeValue(stream: ByteArrayOutputStream, value: Any) {
//        when (value) {
//            is SharedAttachment -> {
//                stream.write(128)
//                writeValue(stream, value.toMap())
//            }
//            is SharedMedia -> {
//                stream.write(129)
//                writeValue(stream, value.toMap())
//            }
//            is SharedMedia -> {
//                stream.write(130)
//                writeValue(stream, value.toMap())
//            }
//            else -> {
//                super.writeValue(stream, value)
//            }
//        }
//    }
//
//    companion object {
//        val INSTANCE = ShareHandlerApiCodec()
//    }
//}
//
//interface ShareHandlerApi {
//    fun getInitialSharedMedia(result: Result<SharedMedia>?)
//    fun recordSentMessage(media: SharedMedia)
//    fun resetInitialSharedMedia()
//
//    companion object {
//        /** The codec used by ShareHandlerApi.  */
//        private val codec: MessageCodec<Any>
//            get() = ShareHandlerApiCodec.INSTANCE
//
//        @Suppress("UNCHECKED_CAST")
//        fun setup(binaryMessenger: BinaryMessenger, api: ShareHandlerApi?) {
//            if (api == null) return
//            run {
//                val channel = BasicMessageChannel(
//                    binaryMessenger,
//                    "dev.flutter.pigeon.ShareHandlerApi.getInitialSharedMedia",
//                    codec
//                )
//                channel.setMessageHandler { _: Any?, reply: BasicMessageChannel.Reply<Any> ->
//                    val wrapped: MutableMap<String, Any?> = HashMap()
//                    try {
//                        val resultCallback: Result<SharedMedia> =
//                            object : Result<SharedMedia> {
//                                override fun success(result: SharedMedia?) {
//                                    result?.let { wrapped["result"] = result }
//                                    reply.reply(wrapped)
//                                }
//
//                                override fun error(error: Throwable) {
//                                    wrapped["error"] = wrapError(error)
//                                    reply.reply(wrapped)
//                                }
//                            }
//                        api.getInitialSharedMedia(resultCallback)
//                    } catch (exception: Error) {
//                        wrapped["error"] = wrapError(exception)
//                        reply.reply(wrapped)
//                    } catch (exception: RuntimeException) {
//                        wrapped["error"] = wrapError(exception)
//                        reply.reply(wrapped)
//                    }
//                }
//            }
//            run {
//                val channel = BasicMessageChannel(
//                    binaryMessenger,
//                    "dev.flutter.pigeon.ShareHandlerApi.recordSentMessage",
//                    codec
//                )
//                channel.setMessageHandler { message: Any?, reply: BasicMessageChannel.Reply<Any> ->
//                    val wrapped: MutableMap<String, Any?> = HashMap()
//                    try {
//                        val args = message as ArrayList<*>
//                        val mediaArg = args[0]
//                        val media = SharedMedia.fromMap(mediaArg as Map<String?, Any?>)
//                        api.recordSentMessage(media)
//                        wrapped["result"] = null
//                    } catch (exception: Error) {
//                        wrapped["error"] = wrapError(exception)
//                    } catch (exception: RuntimeException) {
//                        wrapped["error"] = wrapError(exception)
//                    }
//                    reply.reply(wrapped)
//                }
//            }
//            run {
//                val channel = BasicMessageChannel(
//                    binaryMessenger,
//                    "dev.flutter.pigeon.ShareHandlerApi.resetInitialSharedMedia",
//                    codec
//                )
//                channel.setMessageHandler { _: Any?, reply: BasicMessageChannel.Reply<Any> ->
//                    val wrapped: MutableMap<String, Any?> = HashMap()
//                    try {
//                        api.resetInitialSharedMedia()
//                        wrapped["result"] = null
//                    } catch (exception: Error) {
//                        wrapped["error"] = wrapError(exception)
//                    } catch (exception: RuntimeException) {
//                        wrapped["error"] = wrapError(exception)
//                    }
//                    reply.reply(wrapped)
//                }
//            }
//        }
//    }
//}