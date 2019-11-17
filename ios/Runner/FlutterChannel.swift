import Foundation
import Flutter

class FlutterChannel {
  typealias MethodChannelHandlerFunc = (_ args: Any?, _ result: @escaping FlutterResult) throws -> Void
  typealias EventChannelHandlerFunc = (_ args: Any?, _ eventSink: FlutterEventSink?) throws -> Void

  private var subChannels = Dictionary<String, FlutterChannel>()
  private var methodChannelHandlers = Dictionary<String, MethodChannelHandler>()
  private var eventChannelHandlers = Dictionary<String, EventChannelHandler>()

  func setup(_ channelName: String, _ controller: FlutterViewController) {
    // Setup sub channels.
    subChannels.forEach { (subName, subChannel) in
      subChannel.setup("\(channelName)/\(subName)", controller)
    }

    // Setup method channels.
    if !methodChannelHandlers.isEmpty {
      FlutterMethodChannel(name: channelName, binaryMessenger: controller.binaryMessenger)
        .setMethodCallHandler { [unowned self] (call, result) in
          guard let handler = self.methodChannelHandlers[call.method] else {
            result(FlutterMethodNotImplemented)
            return
          }

          do {
            try handler.handle(call.arguments, result)
          } catch {
            result(FlutterError(error: error))
          }
      }
    }

    // Setup event channels.
    eventChannelHandlers.forEach { (method, handler) in
      let eventChannelName = "\(channelName)/\(method)"
      FlutterEventChannel(name: eventChannelName, binaryMessenger: controller.binaryMessenger)
        .setStreamHandler(FlutterStreamListener(eventChannelName, handler))
    }
  }

  func dispose() {
    methodChannelHandlers.values.forEach { $0.dispose() }
    methodChannelHandlers.removeAll()
    eventChannelHandlers.values.forEach { $0.dispose() }
    eventChannelHandlers.removeAll()
    subChannels.values.forEach { $0.dispose() }
    subChannels.removeAll()
  }

  func setSubChannel(_ subName: String, _ subChannel: FlutterChannel) {
    // Sub channel, method channel, event channel cannot have the same name. Flutter doesn't allow it.
    assert(!methodChannelHandlers.keys.contains(subName), "Method channel with the same name(\(subName)) exists.")
    assert(!eventChannelHandlers.keys.contains(subName), "Event channel with the same name(\(subName)) exists.")
    subChannels[subName] = subChannel
  }

  func setMethodChannel(_ method: String, _ handler: MethodChannelHandler) {
    // Sub channel, method channel, event channel cannot have the same name. Flutter doesn't allow it.
    assert(!subChannels.keys.contains(method), "Sub channel with the same name(\(method)) exists.")
    assert(!eventChannelHandlers.keys.contains(method), "Event channel with the same name(\(method)) exists.")
    methodChannelHandlers[method] = handler
  }

  func setMethodChannel(_ method: String, _ handlerFunc: @escaping MethodChannelHandlerFunc) {
    setMethodChannel(method, AnonymousMethodChannelHandler(handlerFunc))
  }

  func setEventChannel(_ method: String, _ handler: EventChannelHandler) {
    // Sub channel, method channel, event channel cannot have the same name. Flutter doesn't allow it.
    assert(!subChannels.keys.contains(method), "Sub channel with the same name(\(method)) exists.")
    assert(!methodChannelHandlers.keys.contains(method), "Method channel with the same name(\(method)) exists.")
    eventChannelHandlers[method] = handler
  }

  func setEventChannel(_ method: String, _ handlerFunc: @escaping EventChannelHandlerFunc) {
    setEventChannel(method, AnonymousEventChannelHandler(handlerFunc))
  }
}

class FlutterStreamListener: NSObject, FlutterStreamHandler {
  let channelName: String
  var eventChannelHandler: EventChannelHandler

  init(_ name: String, _ handler: EventChannelHandler) {
    channelName = name
    eventChannelHandler = handler
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    return handle(arguments, events)
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    return handle(arguments, nil)
  }

  func handle(_ arguments: Any?, _ events: FlutterEventSink?) -> FlutterError? {
    do {
      try eventChannelHandler.handle(arguments, events)
    } catch {
      return FlutterError(error: error)
    }
    return nil
  }
}

protocol MethodChannelHandler {
  func handle(_ args: Any?, _ result: @escaping FlutterResult) throws -> Void
  func dispose()
}

protocol EventChannelHandler {
  func handle(_ args: Any?, _ eventSink: FlutterEventSink?) throws -> Void
  func dispose()
}

class AnonymousMethodChannelHandler: MethodChannelHandler {
  private let handlerFunc: FlutterChannel.MethodChannelHandlerFunc

  init(_ methodChannelHandlerFunc: @escaping FlutterChannel.MethodChannelHandlerFunc) {
    handlerFunc = methodChannelHandlerFunc
  }

  func handle(_ args: Any?, _ result: @escaping FlutterResult) throws {
    try handlerFunc(args, result)
  }

  func dispose() {}
}

class AnonymousEventChannelHandler: EventChannelHandler {
  private let handlerFunc: FlutterChannel.EventChannelHandlerFunc

  init(_ eventChannelHandlerFunc: @escaping FlutterChannel.EventChannelHandlerFunc) {
    handlerFunc = eventChannelHandlerFunc
  }

  func handle(_ args: Any?, _ eventSink: FlutterEventSink?) throws {
    try handlerFunc(args, eventSink)
  }

  func dispose() {}
}

extension FlutterError {
  convenience init(error: Error) {
    if let flutterError = error as? FlutterError {
      self.init(code: flutterError.code, message: flutterError.message, details: flutterError.details)
      return
    }

    self.init(code: "Unknown", message: error.localizedDescription, details: nil)
  }
}
