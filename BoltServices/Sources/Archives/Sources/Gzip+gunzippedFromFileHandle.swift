//
// Copyright (C) 2023 Bolt Contributors
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

import Foundation
import zlib

import Gzip

public extension Gzip {

  static func gunzipped(
    fromFileHandle fileHandle: FileHandle,
    offset: UInt64,
    outputSize outputCount: Int,
    wBits: Int32 = Gzip.maxWindowBits + 32,
    bufferSize: Int = 20 * 512
  ) throws -> Data {
    var inputCount: uLong = 0

    var data = Data(count: outputCount)
    var totalIn: uLong = 0
    var totalOut: uLong = 0

    repeat {
      var stream = z_stream()
      var status: Int32

      status = inflateInit2_(&stream, wBits, ZLIB_VERSION, Int32(DataSize.stream))

      guard status == Z_OK else {
        // inflateInit2 returns:
        // Z_VERSION_ERROR   The zlib library version is incompatible with the version assumed by the caller.
        // Z_MEM_ERROR       There was not enough memory.
        // Z_STREAM_ERROR    A parameters are invalid.

        throw GzipError(code: status, msg: stream.msg)
      }

      repeat {
        try fileHandle.seek(toOffset: offset + UInt64(stream.total_in))
        let inputData = fileHandle.readData(ofLength: bufferSize)

        inputData.withUnsafeBytes { (inputPointer: UnsafeRawBufferPointer) in
          stream.next_in = UnsafeMutablePointer<Bytef>(mutating: inputPointer.bindMemory(to: Bytef.self).baseAddress!)
          stream.avail_in = uInt(inputData.count)

          data.withUnsafeMutableBytes { (outputPointer: UnsafeMutableRawBufferPointer) in
            let outputStartPosition: uLong = totalOut + stream.total_out
            stream.next_out = outputPointer.bindMemory(to: Bytef.self).baseAddress!.advanced(by: Int(outputStartPosition))
            stream.avail_out = uInt(outputCount) - uInt(outputStartPosition)

            status = inflate(&stream, Z_SYNC_FLUSH)

            stream.next_out = nil
          }

          stream.next_in = nil
        }
      } while stream.total_out < outputCount && status == Z_OK

      totalIn += stream.total_in
      inputCount += stream.total_in

      guard inflateEnd(&stream) == Z_OK, status == Z_OK || status == Z_STREAM_END else {
        // inflate returns:
        // Z_DATA_ERROR   The input data was corrupted (input stream not conforming to the zlib format or incorrect check value).
        // Z_STREAM_ERROR The stream structure was inconsistent (for example if next_in or next_out was NULL).
        // Z_MEM_ERROR    There was not enough memory.
        // Z_BUF_ERROR    No progress is possible or there was not enough room in the output buffer when Z_FINISH is used.
        throw GzipError(code: status, msg: stream.msg)
      }

      totalOut += stream.total_out

    } while (totalIn < inputCount)

    data.count = Int(totalOut)

    return data
  }

}
