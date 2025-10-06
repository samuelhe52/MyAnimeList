.PHONY: clean
clean:
	xcodebuild clean -project MyAnimeList.xcodeproj -scheme MyAnimeList

.PHONY: refresh-packages
refresh-packages:
	rm MyAnimeList.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
	xcodebuild -resolvePackageDependencies

.PHONY: format
format:
	swift format -r -p -i .

.PHONY: lint
lint:
	swift format lint -r -p .

