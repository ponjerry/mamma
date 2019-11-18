package com.papa.mamma

import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import io.flutter.view.FlutterView

interface MethodChannelHandler {
  fun handle(args: Any?, result: MethodChannel.Result)
  fun dispose()
}

interface EventChannelHandler {
  fun handle(args: Any?, eventSink: EventChannel.EventSink?)
  fun dispose()
}

typealias MethodChannelHandlerFunc = (args: Any?, result: MethodChannel.Result) -> Unit
typealias EventChannelHandlerFunc = (args: Any?, eventSink: EventChannel.EventSink?) -> Unit

open class FlutterChannel {
  private val subChannels = mutableMapOf<String, FlutterChannel>()
  private val methodChannelHandlers = mutableMapOf<String, MethodChannelHandler>()
  private var eventChannelHandlers = mutableMapOf<String, EventChannelHandler>()

  fun setup(channelName: String, view: FlutterView) {
    subChannels.forEach { (subName, subChannel) -> subChannel.setup("$channelName/$subName", view) }

    if (methodChannelHandlers.isNotEmpty()) {
      MethodChannel(view, channelName).setMethodCallHandler { call, result ->
        try {
          val handler = methodChannelHandlers[call.method] ?: throw NotImplementedError()
          handler.handle(call.arguments, result)
        } catch (error: NotImplementedError) {
          result.notImplemented()
        } catch (error: Exception) {
          result.error(channelName, error.toString(), null)
        }
      }
    }

    eventChannelHandlers.forEach { (method, handler) ->
      EventChannel(view, "$channelName/$method")
        .setStreamHandler(object : EventChannel.StreamHandler {
          override fun onListen(args: Any?, eventSink: EventChannel.EventSink) {
            handler.handle(args, eventSink)
          }

          override fun onCancel(args: Any?) {
            handler.handle(args, null)
          }
        })
    }
  }

  fun dispose() {
    subChannels.values.forEach { it.dispose() }
    methodChannelHandlers.values.forEach { it.dispose() }
    eventChannelHandlers.values.forEach { it.dispose() }
  }

  fun setSubChannel(subName: String, subChannel: FlutterChannel) {
    // Sub channel, method channel, event channel cannot have the same name.
    // Flutter doesn't allow it.
    assert(!methodChannelHandlers.keys.contains(subName)) {
      "Method channel with the same name($subName) exists."
    }
    assert(!eventChannelHandlers.keys.contains(subName)) {
      "Event channel with the same name($subName) exists."
    }
    subChannels[subName] = subChannel
  }

  fun setMethodChannel(method: String, handler: MethodChannelHandler) {
    // Sub channel, method channel, event channel cannot have the same name.
    // Flutter doesn't allow it.
    assert(!subChannels.keys.contains(method)) {
      "Sub channel with the same name($method) exists."
    }
    assert(!eventChannelHandlers.keys.contains(method)) {
      "Event channel with the same name($method) exists."
    }
    methodChannelHandlers[method] = handler
  }

  fun setMethodChannel(method: String, handlerFunc: MethodChannelHandlerFunc) {
    setMethodChannel(method, object : MethodChannelHandler {
      override fun handle(args: Any?, result: MethodChannel.Result) {
        handlerFunc(args, result)
      }

      override fun dispose() {
        // Do nothing.
      }
    })
  }

  fun setEventChannel(method: String, handler: EventChannelHandler) {
    // Sub channel, method channel, event channel cannot have the same name.
    // Flutter doesn't allow it.
    assert(!subChannels.keys.contains(method)) {
      "Sub channel with the same name($method) exists."
    }
    assert(!methodChannelHandlers.keys.contains(method)) {
      "Method channel with the same name($method) exists."
    }
    eventChannelHandlers[method] = handler
  }

  fun setEventChannel(method: String, handlerFunc: EventChannelHandlerFunc) {
    setEventChannel(method, object : EventChannelHandler {
      override fun handle(args: Any?, eventSink: EventChannel.EventSink?) {
        handlerFunc(args, eventSink)
      }

      override fun dispose() {
        // Do nothing.
      }
    })
  }
}
