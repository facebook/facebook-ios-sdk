# Releasing Facebook ObjC SDK

## Introduction

This document will guide you through the process of issuing a new version of the Facebook SDK.

## Release Steps

### 1. Bump Version

Run the bump version script:

```sh
# Call `bump-version` and pass in the desired semantic version, e.g. 4.40.0
sh scripts/run.sh bump-version 4.40.0
```

Then, commit these changes with the title: "Bump Version: 4.40.0"

### 2. Tag Version

Once the bump version diff has successfully landed on the branch you wish to release, follow these steps:

```sh
# Ensure you're on the correct, e.g. master
git checkout master && git pull

# Ship the currently set version
sh scripts/run.sh tag-push-current-version
```
