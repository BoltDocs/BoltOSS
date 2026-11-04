//
// Copyright (C) 2026 Bolt Contributors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
//
// Original source under MIT license license:
// https://github.com/pointfreeco/swift-overture/blob/912dce67981da3c228b9244a7af8dbdab91afd41/Sources/Overture/Update.swift
//

/// Left-to-right, in-place function application.
///
/// - Parameters:
///   - a: A mutable value.
///   - f: An in-out function.
/// - Note: This function is commonly seen in operator form as "pipe-forward", `|>`.
public func update<A>(_ a: inout A, _ f: (inout A) -> Void) {
  f(&a)
}

/// Left-to-right, in-place throwing function application.
///
/// - Parameters:
///   - a: A mutable value.
///   - f: An in-out function.
/// - Note: This function is commonly seen in operator form as "pipe-forward", `|>`.
public func update<A>(_ a: inout A, _ f: (inout A) throws -> Void) throws {
  try f(&a)
}

/// Left-to-right, value-mutable function application.
///
/// - Parameters:
///   - a: A value.
///   - f: An in-out function.
/// - Returns: The result of `f` applied to `a`.
/// - Note: This function is commonly seen in operator form as "pipe-forward", `|>`.
public func update<A>(_ a: A, _ f: (inout A) -> Void) -> A {
  var a = a
  f(&a)
  return a
}

/// Left-to-right, value-mutable, throwing function application.
///
/// - Parameters:
///   - a: A value.
///   - f: An in-out function.
/// - Returns: The result of `f` applied to `a`.
/// - Note: This function is commonly seen in operator form as "pipe-forward", `|>`.
public func update<A>(_ a: A, _ f: (inout A) throws -> Void) throws -> A {
  var a = a
  try f(&a)
  return a
}

/// Left-to-right, reference-mutable function application.
///
/// - Parameters:
///   - a: A mutable value.
///   - f: An function from `A` to `Void`.
/// - Returns: The result of `f` applied to `a`.
/// - Note: This function is commonly seen in operator form as "pipe-forward", `|>`.
@discardableResult
public func updateObject<A: AnyObject>(_ a: A, _ f: (A) -> Void) -> A {
  f(a)
  return a
}

/// Left-to-right, reference-mutable, throwing function application.
///
/// - Parameters:
///   - a: A mutable value.
///   - f: An function from `A` to `Void`.
/// - Returns: The result of `f` applied to `a`.
/// - Note: This function is commonly seen in operator form as "pipe-forward", `|>`.
@discardableResult
public func updateObject<A: AnyObject>(_ a: A, _ f: (A) throws -> Void) throws -> A {
  try f(a)
  return a
}
