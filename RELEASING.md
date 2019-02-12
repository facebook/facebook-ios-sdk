# Releasing Facebook ObjC SDK

## Introduction

This document will guide you through the process of issuing a new version of the Facebook SDK.

## Release Steps

### Bump Version

Run this script:

```sh
# Change directory to the SDK directory
cd path/to/sdk

# Run the bump version script and pass in the desired semantic version
sh scripts/run.sh bump-version "4.40.0"

# Commit these changes
git commit -am "Bump version: 4.40.0"
```
