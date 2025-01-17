import Time "mo:base/Time";

module {
	public type PackageName = Text; // lib
	public type PackageId = Text; // lib@1.2.3
	public type Err = Text;

	public type Access = {
		#readOnly;
		#readWrite;
	};

	public type Permission = {
		user: Principal;
		access: Access;
	};

	public type Script = {
		name: Text; // max 50
		value: Text; // max 200
	};

	public type PackagePublication = {
		time: Time.Time;
		user: Principal;
		storage: Principal;
	};

	public type DependencyV2 = {
		name: PackageName; // max 50
		repo: Text; // max 300
		version: Text; // max 20
	};

	public type PackageConfigV2 = {
		name: PackageName; // max 50
		version: Text; // max 20
		description: Text; // max 200
		repository: Text; // max 300
		keywords: [Text]; // max 5 items, max 20 chars
		documentation: Text; // max 300
		homepage: Text; // max 300
		baseDir: Text; // max 50
		readme: Text; // max 100
		license: Text; // max 30
		donation: Text; // empty or 64 chars
		dependencies: [DependencyV2]; // max 100 items
		devDependencies: [DependencyV2]; // max 100 items
		scripts: [Script]; // max 40 items
		dfx: Text; // max 10
		moc: Text; // max 10
	};

	public type PackageDetails = {
		owner: Principal;
		config: PackageConfigV2;
		publication: PackagePublication;
		downloadsTotal: Nat;
		downloadsInLast30Days: Nat;
		downloadsInLast7Days: Nat;
	};
};