# Instructions

Make sure you build the XCFrameworks that this project relies on. It uses relative pathing and assumes they will be in ios-sdk/build/XCFrameworks/
You can build them with the command

```
cd internal/scripts/Runner

// Dynamic
swift run runner build xcframeworks

// Static
swift run runner build xcframeworks --linking static
```

If you are using Eden you must change the build path to be a temporary directory since Eden doesn't like build files being written to the working copy

```
cd internal/scripts/Runner

// Dynamic
swift run --build-path=`mkscratch path` runner build xcframeworks

// Static
swift run --build-path=`mkscratch path` runner build xcframeworks --linking static
```
