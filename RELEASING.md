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

This script will modify the relevant version references and will edit the Changelog.

Ensure that the version changes and Changelog updates are correct, then commit these changes with the title: "Bump
Version: 4.40.0" and submit a Pull Request.

### 2. Tag Version

Once the bump version diff has successfully landed on the branch you wish to release, and all CI builds have passed, run
the tag current version script:

```sh
# Ensure you're on the correct, e.g. master
git checkout master && git pull

# Tag the currently set version and, optionally, push to origin
sh scripts/run.sh tag-current-version --push
```
