//
//  PathComponent.swift
//  Nevertheless
//
//  Created by Ben Gottlieb on 6/10/17.
//  Copyright © 2017 Ben Gottlieb. All rights reserved.
//

import Foundation

public class Path: CustomStringConvertible {
	public enum Error: Swift.Error { case movedToTrashReturnedInvalidURL }
	let url: URL
	
	public var path: String { return self.url.path }
	public var description: String { return "path: " + self.url.path }
	
	#if os(iOS) || os(macOS)
		public static var documents: Path = { Path(path: NSSearchPathForDirectoriesInDomains(.documentDirectory, [.userDomainMask], true).first!) }()
		public static var library: Path = { Path(path: NSSearchPathForDirectoriesInDomains(.libraryDirectory, [.userDomainMask], true).first!) }()
		public static var caches: Path = { Path(path: NSSearchPathForDirectoriesInDomains(.cachesDirectory, [.userDomainMask], true).first!) }()
	#endif

	public init(path: String, createPathIfNecessary: Bool = true) {
		self.url = URL(fileURLWithPath: path)
		if createPathIfNecessary, let parent = self.parent, !parent.exists { try? parent.create() }
	}
	
	public init?(url: URL, createPathIfNecessary: Bool = false) {
		self.url = url
		if !url.isFileURL { return nil }
	}
	
	public init(parent: Path, component: String, createPathIfNecessary: Bool = true) {
		self.url = parent.url.appendingPathComponent(component)
		if createPathIfNecessary, let parent = self.parent, !parent.exists { try? parent.create() }
	}
	
	public func child(_ name: String, createPathIfNecessary: Bool = true) -> Path {
		return Path(parent: self, component: name, createPathIfNecessary: createPathIfNecessary)
	}
	
	public var parent: Path? {
		let parentURL = self.url.deletingLastPathComponent()
		
		if parentURL == self.url { return nil }
		return Path(url: parentURL, createPathIfNecessary: false)
	}
	
	public subscript(_ name: String) -> Data? {
		get {
			let fileURL = self.url.appendingPathComponent(name)
			return try? Data(contentsOf: fileURL)
		}
		set {
			if !self.exists { try? self.create() }
			let fileURL = self.url.appendingPathComponent(name)
			try? newValue?.write(to: fileURL)
		}
	}
	
	public subscript<Type: Decodable>(_ name: String) -> Type? {
		get {
			guard let data: Data = self[name] else { return nil }
			
			let decoder = JSONDecoder()
			
			return try? decoder.decode(Type.self, from: data)
		}
		set {
			let encoder = JSONEncoder()
			if let data = try? encoder.encode(newValue) {
				self[name] = data
			}
		}
	}
	
	public func remove() throws {
		if self.exists { try FileManager.default.removeItem(at: self.url) }
	}
	
	public var exists: Bool {
		return FileManager.default.fileExists(atPath: self.url.path)
	}
	
	public func create(attributes: [FileAttributeKey : Any]? = nil) throws {
		print("Creating at \(self.path)\n")
		try FileManager.default.createDirectory(at: self.url, withIntermediateDirectories: true, attributes: attributes)
	}
	
	func moveToTrash() throws -> Path {
		var newURL: NSURL?
		
		try FileManager.default.trashItem(at: self.url, resultingItemURL: &newURL)
		if let result = Path(url: newURL as URL!) { return result }
		throw Error.movedToTrashReturnedInvalidURL
	}
}
