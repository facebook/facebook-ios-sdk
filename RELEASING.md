# Releasing Facebook ObjC SDK

## Introduction

This document will guide you through the process of issuing a new version of the Facebook SDK.

## Release Steps

### Bump Version

1. Run the bump version script:

   ```sh
   # Call `bump-version` and pass in the desired semantic version, e.g. 4.40.0
   sh scripts/run.sh bump-version 4.40.0
   ```

2. Commit these changes with the title: "Bump Version: 4.40.0"
