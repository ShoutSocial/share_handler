#include "include/share_handler/share_handler_linux.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>
#include <sys/utsname.h>

#include <cstring>

#define SHARE_HANDLER_LINUX_PLATFORM(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), share_handler_linux_get_type(), \
                              ShareHandlerLinuxPlatform))

struct _ShareHandlerLinuxPlatform {
  GObject parent_instance;
};

G_DEFINE_TYPE(ShareHandlerLinuxPlatform, share_handler_linux, g_object_get_type())

// Called when a method call is received from Flutter.
static void share_handler_linux_handle_method_call(
    ShareHandlerLinuxPlatform* self,
    FlMethodCall* method_call) {
  g_autoptr(FlMethodResponse) response = nullptr;

  const gchar* method = fl_method_call_get_name(method_call);

  if (strcmp(method, "getPlatformVersion") == 0) {
    struct utsname uname_data = {};
    uname(&uname_data);
    g_autofree gchar *version = g_strdup_printf("Linux %s", uname_data.version);
    g_autoptr(FlValue) result = fl_value_new_string(version);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  fl_method_call_respond(method_call, response, nullptr);
}

static void share_handler_linux_dispose(GObject* object) {
  G_OBJECT_CLASS(share_handler_linux_parent_class)->dispose(object);
}

static void share_handler_linux_class_init(ShareHandlerLinuxPlatform* klass) {
  G_OBJECT_CLASS(klass)->dispose = share_handler_linux_dispose;
}

static void share_handler_linux_init(ShareHandlerLinuxPlatform* self) {}

static void method_call_cb(FlMethodChannel* channel, FlMethodCall* method_call,
                           gpointer user_data) {
  ShareHandlerLinuxPlatform* plugin = SHARE_HANDLER_LINUX_PLATFORM(user_data);
  share_handler_linux_handle_method_call(plugin, method_call);
}

void share_handler_linux_register_with_registrar(FlPluginRegistrar* registrar) {
  ShareHandlerLinuxPlatform* plugin = SHARE_HANDLER_LINUX_PLATFORM(
      g_object_new(share_handler_linux_get_type(), nullptr));

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel =
      fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar),
                            "share_handler",
                            FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(channel, method_call_cb,
                                            g_object_ref(plugin),
                                            g_object_unref);

  g_object_unref(plugin);
}
