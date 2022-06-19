# UpdateLegacyHackbook

Produces a lightweight command-line executable that creates Hackbook E2E Smoke tests using the following static libraries:

FBSDKCoreKit,
FBSDKLoginKit,
FBSDKShareKit,
FBSDKGamingServicesKit

### Usage

From the package root directory, run:
`swift run UpdateLegacyHackbook <version>`

ex:
`swift run UpdateLegacyHackbook 10.0.1`

### Dependencies
Pulls dependencies as relative paths from VendorLib

### Troubleshooting

1. The compiler is hanging on a step like, "[3/100] Copying someFile".
 
If you are using eden you will need to add the argument `--build-path=`mkscratch path``.

A full command may look something like: `swift run --build-path=`mkscratch path` runner`
