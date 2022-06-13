import Iter "mo:base/Iter";
import Text "mo:base/Text";
import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import TrieMap "mo:base/TrieMap";
import Cycles "mo:base/ExperimentalCycles";
import Result "mo:base/Result";
import Principal "mo:base/Principal";

import Constants "../constants";
import Utils "../utils";
import Types "./types";
import Storage "./storage-canister";

module {
	public type StorageId = Principal;
	public type StorageStats = Types.StorageStats;
	public type FileMeta = Types.FileMeta;
	public type FileId = Types.FileId;
	public type Chunk = Types.Chunk;
	public type Err = Types.Err;

	public type Stable = ?{
		storages: [(StorageId, StorageStats)];
		storageByFileId: [(FileId, StorageId)];
	};

	public class StorageManager() {
		var storages: TrieMap.TrieMap<StorageId, StorageStats> = TrieMap.TrieMap(Principal.equal, Principal.hash);
		var storageByFileId: TrieMap.TrieMap<FileId, StorageId> = TrieMap.TrieMap(Text.equal, Text.hash);

		let MIN_UPLOADABLE_STORAGES = 1;
		let OWN_MIN_CYCLES = if (Constants.NETWORK == "ic") 5_000_000_000_000 else 100_000_000_000; // 5TC
		let STORAGE_INITIAL_CYCLES = if (Constants.NETWORK == "ic") 5_000_000_000_000 else 100_000_000_000; // 5TC
		let STORAGE_MIN_CYCLES = 2_000_000_000_000; // 2TC
		let STORAGE_TOP_UP_CYCLES = 3_000_000_000_000; // 3TC

		let MAX_STORAGE_SIZE = 1024 ** 3 * 2; // 2Gb;
		// let MIN_CHUNK_SIZE = 1024 * 512 / 8; // 512Kb
		// let MAX_CHUNK_SIZE = 1024 * 1024 / 8; // 1Mb
		// let MAX_FILE_SIZE = 1024 * 1024 * 10; // 10Mb

		func _spawnStorage(): async () {
			assert(Cycles.balance() > OWN_MIN_CYCLES + STORAGE_INITIAL_CYCLES);
			Cycles.add(STORAGE_INITIAL_CYCLES);
			let storage = await Storage.Storage();
			let stats = await storage.getStats();
			let storageId = Principal.fromActor(storage);
			storages.put(storageId, stats);
		};

		func _getUploadableStorages(): [StorageId] {
			var uploadableStorages = Buffer.Buffer<Principal>(0);

			for ((principal, stats) in storages.entries()) {
				if (stats.memorySize < MAX_STORAGE_SIZE) {
					uploadableStorages.add(principal);
				};
			};

			uploadableStorages.toArray();
		};

		func _updateStorageStats(): async () {
			for ((principal, stats) in storages.entries()) {
				let storage = actor(Principal.toText(principal)): Storage.Storage;
				let stats = await storage.getStats();
				storages.put(principal, stats);
			};
		};

		public func topUpStorages(): async () {
			for (principal in storages.keys()) {
				let storage = actor(Principal.toText(principal)): Storage.Storage;
				let stats = await storage.getStats();
				let mustTopUp = stats.cyclesBalance < STORAGE_MIN_CYCLES;
				let canTopUp = Cycles.balance() > OWN_MIN_CYCLES + STORAGE_TOP_UP_CYCLES;

				if (mustTopUp and canTopUp) {
					Cycles.add(STORAGE_TOP_UP_CYCLES);
					await storage.acceptCycles();
				};
			};
		};

		public func ensureUploadableStorages(): async () {
			var uploadableStorageCount = _getUploadableStorages().size();

			while (uploadableStorageCount < MIN_UPLOADABLE_STORAGES) {
				await _spawnStorage();
				uploadableStorageCount += 1;
			};
		};

		// UPLOAD
		public func startUpload(storageId: Principal, fileMeta: FileMeta): async () {
			let storage = actor(Principal.toText(storageId)): Storage.Storage;
			ignore await storage.startUpload(fileMeta);
		};

		public func uploadChunk(storageId: Principal, fileId: FileId, chunkIndex: Nat, chunk: Chunk): async () {
			let storage = actor(Principal.toText(storageId)): Storage.Storage;
			await storage.uploadChunk(fileId, chunkIndex, chunk);
		};

		var counter = 0;
		public func finishUpload(storageId: Principal, fileId: FileId): async () {
			let storage = actor(Principal.toText(storageId)): Storage.Storage;
			await storage.finishUpload(fileId);
			storageByFileId.put(fileId, storageId);

			counter += 1;
			if (counter % 100 == 0) {
				await _updateStorageStats();
				await ensureUploadableStorages();
			};
		};

		// QUERY
		public func getAllStorages(): [StorageId] {
			Iter.toArray(storages.keys());
		};

		public func getStorageForUpload(): StorageId {
			_getUploadableStorages()[0];
		};

		public func getStorageOfFile(fileId: FileId): StorageId {
			Utils.expect(storageByFileId.get(fileId), "Storage canister not found for file id '" # fileId # "'");
		};

		public func getStoragesForDownload(fileIds: [FileId]): [StorageId] {
			assert(fileIds.size() < 1000);

			Array.map<FileId, Principal>(fileIds, func(fileId) {
				Utils.expect(storageByFileId.get(fileId), "Storage canister not found for file id '" # fileId # "'");
			});
		};

		public func toStable(): Stable {
			return ?{
				storages = Iter.toArray(storages.entries());
				storageByFileId = Iter.toArray(storageByFileId.entries());
			};
		};

		public func loadStable(stab: Stable) {
			switch (stab) {
				case (null) {};
				case (?data) {
					storages := TrieMap.fromEntries<StorageId, StorageStats>(data.storages.vals(), Principal.equal, Principal.hash);
					storageByFileId := TrieMap.fromEntries<FileId, StorageId>(data.storageByFileId.vals(), Text.equal, Text.hash);
				};
			}
		};
	};
};