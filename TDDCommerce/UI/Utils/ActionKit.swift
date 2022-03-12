//
// This is free and unencumbered software released into the public domain.
// 
// Anyone is free to copy, modify, publish, use, compile, sell, or
// distribute this software, either in source code form or as a compiled
// binary, for any purpose, commercial or non-commercial, and by any
// means.
//
// In jurisdictions that recognize copyright laws, the author or authors
// of this software dedicate any and all copyright interest in the
// software to the public domain. We make this dedication for the benefit
// of the public at large and to the detriment of our heirs and
// successors. We intend this dedication to be an overt act of
// relinquishment in perpetuity of all present and future rights to this
// software under copyright law.
// 
// THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
// OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.
// 
// For more information, please refer to <https://unlicense.org>
//
//
//  ActionKit.swift
//  RamySDK
//
//  Created by Ahmed Ramy on 10/2/20.
//  Copyright © 2020 Ahmed Ramy. All rights reserved.
//

import Foundation
import UIKit

public typealias ActionKitVoidClosure = () -> Void
public typealias ActionKitControlClosure = (UIControl) -> Void
public typealias ActionKitGestureClosure = (UIGestureRecognizer) -> Void
public typealias ActionKitBarButtonItemClosure = (UIBarButtonItem) -> Void

public enum ActionKitClosure {
  case noParameters(ActionKitVoidClosure)
  case withControlParameter(ActionKitControlClosure)
  case withGestureParameter(ActionKitGestureClosure)
  case withBarButtonItemParameter(ActionKitBarButtonItemClosure)
}

public enum ActionKitControlType: Hashable {
  case control(UIControl, UIControl.Event)
  case gestureRecognizer(UIGestureRecognizer, String)
  case barButtonItem(UIBarButtonItem)

  public func hash(into hasher: inout Hasher) {
    switch self {
    case let .control(control, controlEvent):
      hasher.combine(control)
      hasher.combine(controlEvent)
    case let .gestureRecognizer(recognizer, name):
      hasher.combine(recognizer)
      hasher.combine(name)
    case let .barButtonItem(barButtonItem):
      hasher.combine(barButtonItem)
    }
  }
}

public func == (lhs: ActionKitControlType, rhs: ActionKitControlType) -> Bool {
  switch (lhs, rhs) {
  case let (.control(lhsControl, lhsControlEvent), .control(rhsControl, rhsControlEvent)):
    return lhsControl.hashValue == rhsControl.hashValue && lhsControlEvent.hashValue == rhsControlEvent.hashValue
  case let (.gestureRecognizer(lhsRecognizer, lhsName), .gestureRecognizer(rhsRecognizer, rhsName)):
    return lhsRecognizer.hashValue == rhsRecognizer.hashValue && lhsName == rhsName
  case let (.barButtonItem(lhsBarButtonItem), .barButtonItem(rhsBarButtonItem)):
    return lhsBarButtonItem.hashValue == rhsBarButtonItem.hashValue
  default:
    return false
  }
}

public class ActionKitSingleton {
  public static let shared: ActionKitSingleton = ActionKitSingleton()
  private init() {}

  var gestureRecognizerToName = [UIGestureRecognizer: Set<String>]()
  var controlToClosureDictionary = [ActionKitControlType: ActionKitClosure]()
}

// MARK: - UIBarButtonItem actions
extension ActionKitSingleton {
  func addBarButtonItemClosure(_ barButtonItem: UIBarButtonItem, closure: ActionKitClosure) {
    controlToClosureDictionary[.barButtonItem(barButtonItem)] = closure
  }

  func removeBarButtonItemClosure(_ barButtonItem: UIBarButtonItem) {
    controlToClosureDictionary[.barButtonItem(barButtonItem)] = nil
  }

  @objc(runBarButtonItem:)
  func runBarButtonItem(_ item: UIBarButtonItem) {
    if let closure = controlToClosureDictionary[.barButtonItem(item)] {
      switch closure {
      case let .noParameters(voidClosure):
        voidClosure()
      case let .withBarButtonItemParameter(barButtonItemClosure):
        barButtonItemClosure(item)
      default:
        assertionFailure("Bar button item closure not found, nor void closure")
      }
    }
  }
}

extension UIBarButtonItem {
  public func addClosure(_ closure: @escaping ActionKitVoidClosure) {
    ActionKitSingleton.shared.addBarButtonItemClosure(self, closure: .noParameters(closure))
  }

  public func addItemClosure(_ itemClosure: @escaping ActionKitBarButtonItemClosure) {
    ActionKitSingleton.shared.addBarButtonItemClosure(self, closure: .withBarButtonItemParameter(itemClosure))
  }

  public func clearActionKit() {
    ActionKitSingleton.shared.removeBarButtonItemClosure(self)
  }

  @objc public convenience init(
    image: UIImage,
    landscapeImagePhone: UIImage? = nil,
    style: UIBarButtonItem.Style = .plain,
    actionClosure: @escaping ActionKitVoidClosure
  ) {
    self.init(image: image,
              landscapeImagePhone: landscapeImagePhone,
              style: style,
              target: ActionKitSingleton.shared,
              action: #selector(ActionKitSingleton.runBarButtonItem(_:)))

    addClosure(actionClosure)
  }

  @objc public convenience init(
    title: String,
    style: UIBarButtonItem.Style = .plain,
    actionClosure: @escaping ActionKitVoidClosure
  ) {
    self.init(title: title,
              style: style,
              target: ActionKitSingleton.shared,
              action: #selector(ActionKitSingleton.runBarButtonItem(_:)))

    addClosure(actionClosure)
  }

  @objc public convenience init(
    barButtonSystemItem systemItem: UIBarButtonItem.SystemItem,
    actionClosure: @escaping ActionKitVoidClosure
  ) {
    self.init(barButtonSystemItem: systemItem,
              target: ActionKitSingleton.shared,
              action: #selector(ActionKitSingleton.runBarButtonItem(_:)))

    addClosure(actionClosure)
  }

  @nonobjc
  public convenience init(
    image: UIImage,
    landscapeImagePhone: UIImage? = nil,
    style: UIBarButtonItem.Style = .plain,
    actionClosure: @escaping ActionKitBarButtonItemClosure
  ) {
    self.init(image: image,
              landscapeImagePhone: landscapeImagePhone,
              style: style,
              target: ActionKitSingleton.shared,
              action: #selector(ActionKitSingleton.runBarButtonItem(_:)))

    addItemClosure(actionClosure)
  }

  @nonobjc
  public convenience init(
    title: String,
    style: UIBarButtonItem.Style = .plain,
    actionClosure: @escaping ActionKitBarButtonItemClosure
  ) {
    self.init(title: title,
              style: style,
              target: ActionKitSingleton.shared,
              action: #selector(ActionKitSingleton.runBarButtonItem(_:)))

    addItemClosure(actionClosure)
  }

  @nonobjc
  public convenience init(
    barButtonSystemItem systemItem: UIBarButtonItem.SystemItem,
    actionClosure: @escaping ActionKitBarButtonItemClosure
  ) {
    self.init(barButtonSystemItem: systemItem,
              target: ActionKitSingleton.shared,
              action: #selector(ActionKitSingleton.runBarButtonItem(_:)))

    addItemClosure(actionClosure)
  }
}

// MARK: - UIControl actions
extension ActionKitSingleton {
  func removeAction(_ control: UIControl, controlEvent: UIControl.Event) {
    control
      .removeTarget(ActionKitSingleton.shared, action: ActionKitSingleton.selectorForControlEvent(controlEvent),
                    for: controlEvent)
    controlToClosureDictionary[.control(control, controlEvent)] = nil
  }

  func addAction(_ control: UIControl, controlEvent: UIControl.Event, closure: ActionKitClosure) {
    controlToClosureDictionary[.control(control, controlEvent)] = closure
  }

  func runControlEventAction(_ control: UIControl, controlEvent: UIControl.Event) {
    if let closure = controlToClosureDictionary[.control(control, controlEvent)] {
      switch closure {
      case let .noParameters(voidClosure):
        voidClosure()
      case let .withControlParameter(controlClosure):
        controlClosure(control)
      default:
        assertionFailure("Control event closure not found, nor void closure")
      }
    }
  }

  @objc(runTouchDownAction:)
  func runTouchDownAction(_ control: UIControl) {
    runControlEventAction(control, controlEvent: .touchDown)
  }

  @objc(runTouchDownRepeatAction:)
  func runTouchDownRepeatAction(_ control: UIControl) {
    runControlEventAction(control, controlEvent: .touchDownRepeat)
  }

  @objc(runTouchDagInsideAction:)
  func runTouchDragInsideAction(_ control: UIControl) {
    runControlEventAction(control, controlEvent: .touchDragInside)
  }

  @objc(runTouchDragOutsideAction:)
  func runTouchDragOutsideAction(_ control: UIControl) {
    runControlEventAction(control, controlEvent: .touchDragOutside)
  }

  @objc(runTouchDragEnterAction:)
  func runTouchDragEnterAction(_ control: UIControl) {
    runControlEventAction(control, controlEvent: .touchDragEnter)
  }

  @objc(runTouchDragExitAction:)
  func runTouchDragExitAction(_ control: UIControl) {
    runControlEventAction(control, controlEvent: .touchDragExit)
  }

  @objc(runTouchUpInsideAction:)
  func runTouchUpInsideAction(_ control: UIControl) {
    runControlEventAction(control, controlEvent: .touchUpInside)
  }

  @objc(runTouchUpOutsideAction:)
  func runTouchUpOutsideAction(_ control: UIControl) {
    runControlEventAction(control, controlEvent: .touchUpOutside)
  }

  @objc(runTouchCancelAction:)
  func runTouchCancelAction(_ control: UIControl) {
    runControlEventAction(control, controlEvent: .touchCancel)
  }

  @objc(runValueChangedAction:)
  func runValueChangedAction(_ control: UIControl) {
    runControlEventAction(control, controlEvent: .valueChanged)
  }

  @objc(runPrimaryActionTriggeredAction:)
  func runPrimaryActionTriggeredAction(_ control: UIControl) {
    runControlEventAction(control, controlEvent: .primaryActionTriggered)
  }

  @objc(runEditingDidBeginAction:)
  func runEditingDidBeginAction(_ control: UIControl) {
    runControlEventAction(control, controlEvent: .editingDidBegin)
  }

  @objc(runEditingChangedAction:)
  func runEditingChangedAction(_ control: UIControl) {
    runControlEventAction(control, controlEvent: .editingChanged)
  }

  @objc(runEditingDidEndAction:)
  func runEditingDidEndAction(_ control: UIControl) {
    runControlEventAction(control, controlEvent: .editingDidEnd)
  }

  @objc(runEditingDidEndOnExit:)
  func runEditingDidEndOnExitAction(_ control: UIControl) {
    runControlEventAction(control, controlEvent: .editingDidEndOnExit)
  }

  @objc(runAllTouchEvents:)
  func runAllTouchEventsAction(_ control: UIControl) {
    runControlEventAction(control, controlEvent: .allTouchEvents)
  }

  @objc(runAllEditingEventsAction:)
  func runAllEditingEventsAction(_ control: UIControl) {
    runControlEventAction(control, controlEvent: .allEditingEvents)
  }

  @objc(runApplicationReservedAction:)
  func runApplicationReservedAction(_ control: UIControl) {
    runControlEventAction(control, controlEvent: .applicationReserved)
  }

  @objc(runSystemReservedAction:)
  func runSystemReservedAction(_ control: UIControl) {
    runControlEventAction(control, controlEvent: .systemReserved)
  }

  @objc(runAllEventsAction:)
  func runAllEventsAction(_ control: UIControl) {
    runControlEventAction(control, controlEvent: .allEvents)
  }

  @objc(runDefaultAction:)
  func runDefaultAction(_ control: UIControl) {
    runControlEventAction(control, controlEvent: .init(rawValue: 0))
  }

  fileprivate static func selectorForControlEvent(_ controlEvent: UIControl.Event) -> Selector {
    switch controlEvent {
    case .touchDown:
      return #selector(ActionKitSingleton.runTouchDownAction(_:))
    case .touchDownRepeat:
      return #selector(ActionKitSingleton.runTouchDownRepeatAction(_:))
    case .touchDragInside:
      return #selector(ActionKitSingleton.runTouchDragInsideAction(_:))
    case .touchDragOutside:
      return #selector(ActionKitSingleton.runTouchDragOutsideAction(_:))
    case .touchDragEnter:
      return #selector(ActionKitSingleton.runTouchDragEnterAction(_:))
    case .touchDragExit:
      return #selector(ActionKitSingleton.runTouchDragExitAction(_:))
    case .touchUpInside:
      return #selector(ActionKitSingleton.runTouchUpInsideAction(_:))
    case .touchUpOutside:
      return #selector(ActionKitSingleton.runTouchUpOutsideAction(_:))
    case .touchCancel:
      return #selector(ActionKitSingleton.runTouchCancelAction(_:))
    case .valueChanged:
      return #selector(ActionKitSingleton.runValueChangedAction(_:))
    case .primaryActionTriggered:
      return #selector(ActionKitSingleton.runPrimaryActionTriggeredAction(_:))
    case .editingDidBegin:
      return #selector(ActionKitSingleton.runEditingDidBeginAction(_:))
    case .editingChanged:
      return #selector(ActionKitSingleton.runEditingChangedAction(_:))
    case .editingDidEnd:
      return #selector(ActionKitSingleton.runEditingDidEndAction(_:))
    case .editingDidEndOnExit:
      return #selector(ActionKitSingleton.runEditingDidEndOnExitAction(_:))
    case .allTouchEvents:
      return #selector(ActionKitSingleton.runAllTouchEventsAction(_:))
    case .allEditingEvents:
      return #selector(ActionKitSingleton.runAllEditingEventsAction(_:))
    case .applicationReserved:
      return #selector(ActionKitSingleton.runApplicationReservedAction(_:))
    case .systemReserved:
      return #selector(ActionKitSingleton.runSystemReservedAction(_:))
    case .allEvents:
      return #selector(ActionKitSingleton.runAllEventsAction(_:))
    default:
      return #selector(ActionKitSingleton.runDefaultAction(_:))
    }
  }
}

extension UIControl.Event: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(rawValue)
  }

  public static var allValues: [UIControl.Event] {
    return [.touchDown, .touchDownRepeat, .touchDragInside, .touchDragOutside, .touchDragEnter,
            .touchDragExit, .touchUpInside, .touchUpOutside, .touchCancel, .valueChanged,
            .primaryActionTriggered, .editingDidBegin, .editingChanged, .editingDidEnd,
            .editingDidEndOnExit, .allTouchEvents, .allEditingEvents, .applicationReserved,
            .systemReserved, .allEvents]
  }
}

extension UIControl {
  open override func removeFromSuperview() {
    clearActionKit()
    super.removeFromSuperview()
  }

  public func clearActionKit() {
    for eventType in UIControl.Event.allValues {
      let closure = ActionKitSingleton.shared.controlToClosureDictionary[.control(self, eventType)]
      if closure != nil {
        ActionKitSingleton.shared.removeAction(self, controlEvent: eventType)
      }
    }
  }

  @objc public func removeControlEvent(_ controlEvent: UIControl.Event) {
    ActionKitSingleton.shared.removeAction(self, controlEvent: controlEvent)
  }

  @objc public func addControlEvent(
    _ controlEvent: UIControl.Event,
    _ controlClosure: @escaping ActionKitControlClosure
  ) {
    addTarget(ActionKitSingleton.shared, action: ActionKitSingleton.selectorForControlEvent(controlEvent),
              for: controlEvent)
    ActionKitSingleton.shared
      .addAction(self, controlEvent: controlEvent, closure: .withControlParameter(controlClosure))
  }

  @nonobjc
  public func addControlEvent(_ controlEvent: UIControl.Event, _ closure: @escaping ActionKitVoidClosure) {
    addTarget(ActionKitSingleton.shared, action: ActionKitSingleton.selectorForControlEvent(controlEvent),
              for: controlEvent)
    ActionKitSingleton.shared.addAction(self, controlEvent: controlEvent, closure: .noParameters(closure))
  }

  @nonobjc
  public func setControlEvent(_ controlEvent: UIControl.Event, _ closure: @escaping ActionKitVoidClosure) {
    removeControlEvent(controlEvent)
    addTarget(ActionKitSingleton.shared, action: ActionKitSingleton.selectorForControlEvent(controlEvent),
              for: controlEvent)
    ActionKitSingleton.shared.addAction(self, controlEvent: controlEvent, closure: .noParameters(closure))
  }

}

// MARK: - UIGestureRecognizer actions
extension ActionKitSingleton {
  func addGestureClosure(_ gesture: UIGestureRecognizer, name: String, closure: ActionKitClosure) {
    let set: Set<String>? = gestureRecognizerToName[gesture]
    var newSet: Set<String>
    if let nonOptSet = set {
      newSet = nonOptSet
    } else {
      newSet = Set<String>()
    }
    newSet.insert(name)
    gestureRecognizerToName[gesture] = newSet
    controlToClosureDictionary[.gestureRecognizer(gesture, name)] = closure
  }

  func canRemoveGesture(_ gesture: UIGestureRecognizer, _ name: String) -> Bool {
    if let _ = controlToClosureDictionary[.gestureRecognizer(gesture, name)] {
      return true
    } else {
      return false
    }
  }

  func removeGesture(_ gesture: UIGestureRecognizer, name: String) {
    if canRemoveGesture(gesture, name) {
      controlToClosureDictionary[.gestureRecognizer(gesture, name)] = nil
    }
  }

  @objc(runGesture:)
  func runGesture(_ gesture: UIGestureRecognizer) {
    for gestureName in gestureRecognizerToName[gesture] ?? Set<String>() {
      if let closure = controlToClosureDictionary[.gestureRecognizer(gesture, gestureName)] {
        switch closure {
        case let .noParameters(voidClosure):
          voidClosure()
        case let .withGestureParameter(gestureClosure):
          gestureClosure(gesture)
        default:
          assertionFailure("Gesture closure not found, nor void closure")
        }
      }
    }
  }
}

public extension UIGestureRecognizer {
  var actionKitNames: Set<String>? {
    get { return ActionKitSingleton.shared.gestureRecognizerToName[self] } set {}
  }
}

extension UIGestureRecognizer {
  public func clearActionKit() {
    let gestureRecognizerNames = ActionKitSingleton.shared.gestureRecognizerToName[self]
    ActionKitSingleton.shared.gestureRecognizerToName[self] = nil
    for gestureRecognizerName in gestureRecognizerNames ?? Set<String>() {
      ActionKitSingleton.shared.removeGesture(self, name: gestureRecognizerName)
    }
  }

  @objc public convenience init(_ name: String = .empty, _ gestureClosure: @escaping ActionKitGestureClosure) {
    self.init(target: ActionKitSingleton.shared, action: #selector(ActionKitSingleton.runGesture(_:)))
    addClosure(name, gestureClosure: gestureClosure)
  }

  @nonobjc
  public convenience init(_ name: String = .empty, _ closure: @escaping ActionKitVoidClosure) {
    self.init(target: ActionKitSingleton.shared, action: #selector(ActionKitSingleton.runGesture(_:)))
    addClosure(name, closure: closure)
  }

  public func addClosure(_ name: String, gestureClosure: @escaping ActionKitGestureClosure) {
    ActionKitSingleton.shared.addGestureClosure(self, name: name, closure: .withGestureParameter(gestureClosure))
  }

  public func addClosure(_ name: String, closure: @escaping ActionKitVoidClosure) {
    ActionKitSingleton.shared.addGestureClosure(self, name: name, closure: .noParameters(closure))
  }

  public func removeClosure(_ name: String) {
    ActionKitSingleton.shared.removeGesture(self, name: name)
  }
}
