//
//  DirectoryPath.swift
//  Nevertheless
//
//  Created by Ben Gottlieb on 6/10/17.
//  Copyright © 2017 Ben Gottlieb. All rights reserved.
//

import Foundation

public class DirectoryPath: CustomStringConvertible {
	public enum Error: Swift.Error { case movedToTrashReturnedInvalidURL }
	public let url: URL
	
	public var path: String { return self.url.path }
	public var description: String { return self.url.path }
	
	#if os(iOS) || os(macOS)
		public static var documents: DirectoryPath = { DirectoryPath(path: NSSearchPathForDirectoriesInDomains(.documentDirectory, [.userDomainMask], true).first!) }()
		public static var library: DirectoryPath = { DirectoryPath(path: NSSearchPathForDirectoriesInDomains(.libraryDirectory, [.userDomainMask], true).first!) }()
		public static var caches: DirectoryPath = { DirectoryPath(path: NSSearchPathForDirectoriesInDomains(.cachesDirectory, [.userDomainMask], true).first!) }()
	#endif

	public init(path: String, createPathIfNecessary: Bool = true) {
		self.url = URL(fileURLWithPath: path)
		if createPathIfNecessary, let parent = self.parent, !parent.exists { try? parent.create() }
	}
	
	public init?(url: URL, createPathIfNecessary: Bool = false) {
		self.url = url
		if !url.isFileURL { return nil }
	}
	
	public init(parent: DirectoryPath, component: String, createPathIfNecessary: Bool = true) throws {
		self.url = parent.url.appendingPathComponent(component)
		if createPathIfNecessary, !self.exists { try self.create() }
	}
	
	public func subdirectory(_ name: String, createPathIfNecessary: Bool = true) throws -> DirectoryPath {
		return try DirectoryPath(parent: self, component: name, createPathIfNecessary: createPathIfNecessary)
	}
	
	public func child(_ name: String, createPathIfNecessary: Bool = true) throws -> FilePath {
		return try FilePath(parent: self, component: name, createPathIfNecessary: createPathIfNecessary)
	}
	
	public var parent: DirectoryPath? {
		let parentURL = self.url.deletingLastPathComponent()
		
		if parentURL == self.url { return nil }
		return DirectoryPath(url: parentURL, createPathIfNecessary: false)
	}
	
	public subscript(_ name: String) -> Data? {
		get {
			let fileURL = self.url.appendingPathComponent(name)
			return try? Data(contentsOf: fileURL)
		}
		set {
			if !self.exists { try? self.create() }
			let child = try? self.child(name)
			child?.data = newValue
		}
	}
	#if swift(>=4)
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
	#endif
	
	public func remove() throws {
		if self.exists { try FileManager.default.removeItem(at: self.url) }
	}
	
	public var exists: Bool {
		var isDirectory: ObjCBool = false
		return FileManager.default.fileExists(atPath: self.url.path, isDirectory: &isDirectory) && isDirectory.boolValue
	}
	
	var existsAsFile: Bool {
		var isDirectory: ObjCBool = false
		return FileManager.default.fileExists(atPath: self.url.path, isDirectory: &isDirectory) && !isDirectory.boolValue
	}
	
	#if swift(>=4)
		public func create(withoutPredjudice: Bool = false, attributes: [FileAttributeKey : Any]? = nil) throws {
			print("Creating at \(self.path)\n")
			if withoutPredjudice, self.existsAsFile { try self.remove() }
			try FileManager.default.createDirectory(at: self.url, withIntermediateDirectories: true, attributes: attributes)
		}
		
		func moveToTrash() throws -> FilePath {
			var newURL: NSURL?
			
			try FileManager.default.trashItem(at: self.url, resultingItemURL: &newURL)
			if let result = FilePath(url: newURL as URL!) { return result }
			throw Error.movedToTrashReturnedInvalidURL
		}
	#else
		public func create(withoutPredjudice: Bool = false, attributes: [String : Any]? = nil) throws {
			if withoutPredjudice, self.existsAsFile { try self.remove() }
			try FileManager.default.createDirectory(at: self.url, withIntermediateDirectories: true, attributes: attributes)
		}
	#endif
}

public class FilePath: DirectoryPath {
	public override var description: String { return "\(self.url.lastPathComponent) [\(self.parent!.path)]" + (!self.exists ? " missing" : "") }
	
	override public var exists: Bool {
		return self.existsAsFile
	}
	
	public var data: Data? {
		set { try? self.set(data: newValue) }
		
		get {
			return try? Data(contentsOf: self.url)
		}
	}
	
	public func set(data: Data?) throws {
		try? self.remove()
		if let data = data {
			try? data.write(to: self.url)
		}
		
	}
	
	public override init(parent: DirectoryPath, component: String, createPathIfNecessary: Bool = true) throws {
		try super.init(parent: parent, component: component, createPathIfNecessary: false)
	}
	
	public override init?(url: URL, createPathIfNecessary: Bool = false) {
		super.init(url: url, createPathIfNecessary: false)
	}
	
}
