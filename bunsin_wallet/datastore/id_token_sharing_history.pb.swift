// DO NOT EDIT.
// swift-format-ignore-file
// swiftlint:disable all
//
// Generated by the Swift generator plugin for the protocol buffer compiler.
// Source: id_token_sharing_history.proto
//
// For information on using the generated types, please see the documentation:
//   https://github.com/apple/swift-protobuf/

import SwiftProtobuf

// If the compiler emits an error on this type, it is because this file
// was generated by a version of the `protoc` Swift plug-in that is
// incompatible with the version of SwiftProtobuf to which you are linking.
// Please ensure that you are building against the same version of the API
// that was used to generate this file.
fileprivate struct _GeneratedWithProtocGenSwiftVersion: SwiftProtobuf.ProtobufAPIVersionCheck {
  struct _2: SwiftProtobuf.ProtobufAPIVersion_2 {}
  typealias Version = _2
}

struct Datastore_IdTokenSharingHistory: Sendable {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var rp: String = String()

  var accountIndex: Int32 = 0

  var createdAt: SwiftProtobuf.Google_Protobuf_Timestamp {
    get {return _createdAt ?? SwiftProtobuf.Google_Protobuf_Timestamp()}
    set {_createdAt = newValue}
  }
  /// Returns true if `createdAt` has been explicitly set.
  var hasCreatedAt: Bool {return self._createdAt != nil}
  /// Clears the value of `createdAt`. Subsequent reads from it will return its default value.
  mutating func clearCreatedAt() {self._createdAt = nil}

  var accountUseCase: String = String()

  var thumbprint: String = String()

  var unknownFields = SwiftProtobuf.UnknownStorage()

  init() {}

  fileprivate var _createdAt: SwiftProtobuf.Google_Protobuf_Timestamp? = nil
}

// MARK: - Code below here is support for the SwiftProtobuf runtime.

fileprivate let _protobuf_package = "datastore"

extension Datastore_IdTokenSharingHistory: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = _protobuf_package + ".IdTokenSharingHistory"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "rp"),
    2: .same(proto: "accountIndex"),
    3: .same(proto: "createdAt"),
    4: .same(proto: "accountUseCase"),
    5: .same(proto: "thumbprint"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularStringField(value: &self.rp) }()
      case 2: try { try decoder.decodeSingularInt32Field(value: &self.accountIndex) }()
      case 3: try { try decoder.decodeSingularMessageField(value: &self._createdAt) }()
      case 4: try { try decoder.decodeSingularStringField(value: &self.accountUseCase) }()
      case 5: try { try decoder.decodeSingularStringField(value: &self.thumbprint) }()
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    // The use of inline closures is to circumvent an issue where the compiler
    // allocates stack space for every if/case branch local when no optimizations
    // are enabled. https://github.com/apple/swift-protobuf/issues/1034 and
    // https://github.com/apple/swift-protobuf/issues/1182
    if !self.rp.isEmpty {
      try visitor.visitSingularStringField(value: self.rp, fieldNumber: 1)
    }
    if self.accountIndex != 0 {
      try visitor.visitSingularInt32Field(value: self.accountIndex, fieldNumber: 2)
    }
    try { if let v = self._createdAt {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 3)
    } }()
    if !self.accountUseCase.isEmpty {
      try visitor.visitSingularStringField(value: self.accountUseCase, fieldNumber: 4)
    }
    if !self.thumbprint.isEmpty {
      try visitor.visitSingularStringField(value: self.thumbprint, fieldNumber: 5)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: Datastore_IdTokenSharingHistory, rhs: Datastore_IdTokenSharingHistory) -> Bool {
    if lhs.rp != rhs.rp {return false}
    if lhs.accountIndex != rhs.accountIndex {return false}
    if lhs._createdAt != rhs._createdAt {return false}
    if lhs.accountUseCase != rhs.accountUseCase {return false}
    if lhs.thumbprint != rhs.thumbprint {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}
