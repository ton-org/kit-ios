//
//  TextCommentPayloadDecoder.swift
//  TONWalletApp
//
//  Created by Nikita Rodionov on 29.05.2026.
//
//  Copyright (c) 2026 TON Connect
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import Foundation

// Minimal BoC parser that mirrors the JS `decodeTextCommentPayload` from
// /Volumes/Neverland/Development/Web/kit/apps/demo-wallet/src/utils/payload.ts:
//   const slice = Cell.fromBase64(payload).beginParse();
//   if (slice.remainingBits < 32) return null;
//   const op = slice.loadUint(32);
//   if (op !== 0) return null;
//   const text = slice.loadStringTail();
//   return text.length > 0 ? text : null;
//
// Only the BoC envelope variants/cell features needed for a TonConnect text
// comment payload are supported (standard magic, non-exotic cells, root index
// 0, optional ref chain that carries the tail of a long comment).
enum TextCommentPayloadDecoder {
    static func decode(_ base64: String) -> String? {
        guard let data = Data(base64Encoded: base64), data.count >= 6 else { return nil }
        let bytes = [UInt8](data)

        guard bytes[0] == 0xB5, bytes[1] == 0xEE, bytes[2] == 0x9C, bytes[3] == 0x72 else { return nil }

        let flags = bytes[4]
        let hasIdx = (flags & 0x80) != 0
        let sizeBytes = Int(flags & 0x07)
        let offBytes = Int(bytes[5])
        guard sizeBytes >= 1, sizeBytes <= 4, offBytes >= 1, offBytes <= 8 else { return nil }

        var cursor = 6
        guard bytes.count >= cursor + 3 * sizeBytes + offBytes else { return nil }
        let cells = readUInt(bytes, cursor, sizeBytes); cursor += sizeBytes
        let roots = readUInt(bytes, cursor, sizeBytes); cursor += sizeBytes
        cursor += sizeBytes // absent
        cursor += offBytes  // tot_cells_size

        guard cells > 0, roots > 0 else { return nil }
        guard bytes.count >= cursor + roots * sizeBytes else { return nil }
        let rootIdx = readUInt(bytes, cursor, sizeBytes)
        cursor += roots * sizeBytes
        guard rootIdx == 0 else { return nil }

        if hasIdx {
            guard bytes.count >= cursor + cells * offBytes else { return nil }
            cursor += cells * offBytes
        }

        let cellsBase = cursor

        // Find offsets of each cell by walking sequentially from the root.
        var cellOffsets: [Int] = []
        cellOffsets.reserveCapacity(cells)
        var walking = cellsBase
        for _ in 0..<cells {
            cellOffsets.append(walking)
            guard let size = cellSize(bytes, walking, sizeBytes) else { return nil }
            walking += size
        }

        return readText(bytes: bytes, cellOffsets: cellOffsets, cellIndex: 0, sizeBytes: sizeBytes, isRoot: true)
    }

    private static func readText(
        bytes: [UInt8],
        cellOffsets: [Int],
        cellIndex: Int,
        sizeBytes: Int,
        isRoot: Bool
    ) -> String? {
        guard cellIndex < cellOffsets.count else { return nil }
        let offset = cellOffsets[cellIndex]
        guard offset + 2 <= bytes.count else { return nil }
        let d1 = bytes[offset]
        let d2 = bytes[offset + 1]

        let refsCount = Int(d1 & 0x07)
        let isExotic = (d1 & 0x08) != 0
        guard !isExotic else { return nil }

        let dataNibbles = Int(d2)
        let dataBytes = (dataNibbles + 1) / 2
        let hasPartialLastByte = (dataNibbles & 0x01) != 0

        guard offset + 2 + dataBytes + refsCount * sizeBytes <= bytes.count else { return nil }
        var data = Array(bytes[offset + 2 ..< offset + 2 + dataBytes])

        // Partial-bit cells encode a 1-bit followed by zero padding in the
        // tail of the last byte. For UTF-8 text in TonConnect comments the
        // common case has no partial byte; if it's there we drop the padding
        // byte conservatively rather than trying to recover sub-byte text.
        if hasPartialLastByte, !data.isEmpty {
            data.removeLast()
        }

        var textBytes: [UInt8]
        if isRoot {
            guard data.count >= 4 else { return nil }
            let op = (UInt32(data[0]) << 24) | (UInt32(data[1]) << 16)
                   | (UInt32(data[2]) << 8) | UInt32(data[3])
            guard op == 0 else { return nil }
            textBytes = Array(data[4...])
        } else {
            textBytes = data
        }

        var text = String(bytes: textBytes, encoding: .utf8) ?? ""

        if refsCount > 0 {
            // Long comments chain the tail through the first ref.
            let refStart = offset + 2 + dataBytes
            let nextIdx = readUInt(bytes, refStart, sizeBytes)
            if let cont = readText(
                bytes: bytes,
                cellOffsets: cellOffsets,
                cellIndex: nextIdx,
                sizeBytes: sizeBytes,
                isRoot: false
            ) {
                text += cont
            }
        }

        return text.isEmpty ? nil : text
    }

    private static func cellSize(_ bytes: [UInt8], _ start: Int, _ sizeBytes: Int) -> Int? {
        guard start + 2 <= bytes.count else { return nil }
        let d1 = bytes[start]
        let d2 = bytes[start + 1]
        let refsCount = Int(d1 & 0x07)
        let dataBytes = (Int(d2) + 1) / 2
        return 2 + dataBytes + refsCount * sizeBytes
    }

    private static func readUInt(_ bytes: [UInt8], _ offset: Int, _ length: Int) -> Int {
        var result = 0
        for i in 0..<length {
            result = (result << 8) | Int(bytes[offset + i])
        }
        return result
    }
}
