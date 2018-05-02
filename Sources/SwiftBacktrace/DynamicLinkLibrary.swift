//
//  DynamicLinkLibrary.swift
//  SwiftBacktrace
//
//  Created by Norio Nomura on 5/1/18.
//

import Foundation

struct DynamicLinkLibrary {
    let path: String
    let handle: UnsafeMutableRawPointer

    func load<T>(symbols: [String]) -> T {
        for symbol in symbols {
            if let sym = dlsym(handle, symbol) {
                return unsafeBitCast(sym, to: T.self)
            }
        }
        let errorString = String(validatingUTF8: dlerror())
        fatalError("Finding symbol \(symbols.joined(separator: ",")) failed: \(errorString ?? "unknown error")")
    }
}

struct Loader {
    let searchPaths: [String]

    func load(path: String) -> DynamicLinkLibrary {
        let fullPaths = searchPaths
            .map { URL(fileURLWithPath: $0).appendingPathComponent(path).path }
            .filter(FileManager.default.fileExists(atPath:))

        // try all fullPaths that contains target file,
        // then try loading with simple path that depends resolving to DYLD
        for fullPath in fullPaths + [path] {
            if let handle = dlopen(fullPath, RTLD_LAZY) {
                return DynamicLinkLibrary(path: path, handle: handle)
            }
        }
        let errorString = String(validatingUTF8: dlerror())
        fatalError("Loading \(path) failed: \(errorString ?? "unknown error")")
    }
}
