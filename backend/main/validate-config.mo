import Nat "mo:base/Nat";
import Text "mo:base/Text";
import Char "mo:base/Char";
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import Result "mo:base/Result";

import Types "./types";
import Version "./version";
import {isLowerCaseLetter} "./is-letter";
import {validateLicense} "./validate-license";

module {
	type PackageConfigV2 = Types.PackageConfigV2;
	type Err = Types.Err;

	let CONFIG_MAX_SIZES = {
		name = 50;
		version = 20;
		keywords = (5, 20);
		description = 200;
		repository = 300;
		documentation = 300;
		homepage = 300;
		readme = 100;
		license = 40;
		scripts = (40, 50, 200);
		dfx = 10;
		moc = 10;
		donation = 64;
		dependencies = 100;
		devDependencies = 100;
	};

	let reservedNames = [
		"mops",
		"doc",
		"docs",
		"search",
		"pkg",
		"package",
		"packages",
		"api",
		"p",
		"page",
		"about",
		"help",
		"support",
		"contact",
		"policy",
		"policies",
		"how-to",
		"howto",
		"faq",
		"wiki",
		"cli",
	];

	public func validateConfig(config: PackageConfigV2): Result.Result<(), Err> {
		// temporarily disabled fields
		if (config.dfx.size() > 0) {
			return #err("invalid config: 'dfx' field is not supported yet");
		};
		if (config.moc.size() > 0) {
			return #err("invalid config: 'moc' field is not supported yet");
		};
		if (config.homepage.size() > 0) {
			return #err("invalid config: 'homepage' field is not supported yet");
		};
		if (config.documentation.size() > 0) {
			return #err("invalid config: 'documentation' field is not supported yet");
		};
		if (config.scripts.size() > 0) {
			return #err("invalid config: 'scripts' field is not supported yet");
		};
		if (config.baseDir != "src") {
			return #err("invalid config: 'baseDir' field must be equal to 'src'");
		};

		if (config.name.size() == 0) {
			return #err("invalid config: name cannot be empty");
		};
		if (config.name.size() > CONFIG_MAX_SIZES.name) {
			return #err("invalid config: name max length is " # Nat.toText(CONFIG_MAX_SIZES.name));
		};

		// reserved package names
		for (reserved in reservedNames.vals()) {
			if (config.name == reserved) {
				return #err("invalid config: reserved package name '" # config.name # "'");
			};
		};

		// [a-z0-9-_.]
		var prevChar = '.';
		for (char in config.name.chars()) {
			let err = #err("invalid config: unexpected char '" # Char.toText(char) # "' in name '" # config.name # "'");
			if (not isLowerCaseLetter(char) and not Char.isDigit(char) and char != '.' and char != '-' and char != '_') {
				return err;
			};
			// deny -lib, .lib, _lib, li..b
			if ((prevChar == '.' or prevChar == '-' or prevChar == '_') and (char == '.' or char == '-' or char == '_')) {
				return err;
			};
			prevChar := char;
		};
		// deny lib., lib_, lib-
		if (prevChar == '.' or prevChar == '-' or prevChar == '_') {
			return  #err("invalid config: name cannot end with '.', '-', '_' in name '" # config.name # "'");
		};

		if (config.version.size() > CONFIG_MAX_SIZES.version) {
			return #err("invalid config: version max length is " # Nat.toText(CONFIG_MAX_SIZES.version));
		};

		let versionValid = Version.validate(config.version);
		if (Result.isErr(versionValid)) {
			return versionValid;
		};

		if (config.description.size() > CONFIG_MAX_SIZES.description) {
			return #err("invalid config: description max length is " # Nat.toText(CONFIG_MAX_SIZES.description));
		};
		if (config.repository.size() > CONFIG_MAX_SIZES.repository) {
			return #err("invalid config: repository max length is " # Nat.toText(CONFIG_MAX_SIZES.repository));
		};
		if (config.documentation.size() > CONFIG_MAX_SIZES.documentation) {
			return #err("invalid config: documentation max length is " # Nat.toText(CONFIG_MAX_SIZES.documentation));
		};
		if (config.homepage.size() > CONFIG_MAX_SIZES.homepage) {
			return #err("invalid config: homepage max length is " # Nat.toText(CONFIG_MAX_SIZES.homepage));
		};
		if (config.readme.size() > CONFIG_MAX_SIZES.readme) {
			return #err("invalid config: readme max length is " # Nat.toText(CONFIG_MAX_SIZES.readme));
		};

		if (config.license.size() > CONFIG_MAX_SIZES.license) {
			return #err("invalid config: license max length is " # Nat.toText(CONFIG_MAX_SIZES.license));
		};
		let licenseValid = validateLicense(config.license);
		if (Result.isErr(licenseValid)) {
			return licenseValid;
		};

		if (config.dfx.size() > CONFIG_MAX_SIZES.dfx) {
			return #err("invalid config: dfx max length is " # Nat.toText(CONFIG_MAX_SIZES.dfx));
		};
		if (config.moc.size() > CONFIG_MAX_SIZES.moc) {
			return #err("invalid config: moc max length is " # Nat.toText(CONFIG_MAX_SIZES.moc));
		};
		if (config.donation.size() != 0 and config.donation.size() != CONFIG_MAX_SIZES.donation) {
			return #err("invalid config: donation length must be " # Nat.toText(CONFIG_MAX_SIZES.donation));
		};
		if (config.keywords.size() > CONFIG_MAX_SIZES.keywords.0) {
			return #err("invalid config: max keywords is " # Nat.toText(CONFIG_MAX_SIZES.keywords.0));
		};
		if (config.dependencies.size() > CONFIG_MAX_SIZES.dependencies) {
			return #err("invalid config: max dependencies is " # Nat.toText(CONFIG_MAX_SIZES.dependencies));
		};
		if (config.devDependencies.size() > CONFIG_MAX_SIZES.devDependencies) {
			return #err("invalid config: max devDependencies is " # Nat.toText(CONFIG_MAX_SIZES.devDependencies));
		};
		if (config.scripts.size() > CONFIG_MAX_SIZES.scripts.0) {
			return #err("invalid config: max scripts is " # Nat.toText(CONFIG_MAX_SIZES.scripts.0));
		};
		for (keyword in config.keywords.vals()) {
			if (keyword.size() > CONFIG_MAX_SIZES.keywords.1) {
				return #err("invalid config: max keyword length is " # Nat.toText(CONFIG_MAX_SIZES.keywords.1));
			};
		};
		for (script in config.scripts.vals()) {
			if (script.name.size() > CONFIG_MAX_SIZES.scripts.1) {
				return #err("invalid config: max script name length is " # Nat.toText(CONFIG_MAX_SIZES.scripts.1));
			};
			if (script.value.size() > CONFIG_MAX_SIZES.scripts.2) {
				return #err("invalid config: max script value length is " # Nat.toText(CONFIG_MAX_SIZES.scripts.2));
			};
		};
		for (dep in config.dependencies.vals()) {
			if (dep.name.size() > CONFIG_MAX_SIZES.name) {
				return #err("invalid config: dependency name max length is " # Nat.toText(CONFIG_MAX_SIZES.name));
			};
			if (dep.version.size() > CONFIG_MAX_SIZES.version) {
				return #err("invalid config: dependency version max length is " # Nat.toText(CONFIG_MAX_SIZES.version));
			};

			if (dep.repo.size() > CONFIG_MAX_SIZES.repository) {
				return #err("invalid config: dependency repo url max length is " # Nat.toText(CONFIG_MAX_SIZES.repository));
			};

			if (dep.repo.size() == 0) {
				let versionValid = Version.validate(dep.version);
				if (Result.isErr(versionValid)) {
					return versionValid;
				};
			};
		};
		for (dep in config.devDependencies.vals()) {
			if (dep.name.size() > CONFIG_MAX_SIZES.name) {
				return #err("invalid config: dependency name max length is " # Nat.toText(CONFIG_MAX_SIZES.name));
			};
			if (dep.version.size() > CONFIG_MAX_SIZES.version) {
				return #err("invalid config: dependency version max length is " # Nat.toText(CONFIG_MAX_SIZES.version));
			};

			if (dep.repo.size() > CONFIG_MAX_SIZES.repository) {
				return #err("invalid config: dependency repo url max length is " # Nat.toText(CONFIG_MAX_SIZES.repository));
			};

			if (dep.repo.size() == 0) {
				let versionValid = Version.validate(dep.version);
				if (Result.isErr(versionValid)) {
					return versionValid;
				};
			};
		};
		#ok();
	};
};