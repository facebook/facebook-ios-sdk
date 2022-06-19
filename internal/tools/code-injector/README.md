# Code Injector Plugin

This is iOS tweak that depends on MobileSubstrate which only works on jailbroken device.
It can inject code into the third-party apps in jailbroken devices, which can be used to test or debug certain features in the third-party apps. The benefit is two-folds:
- We can test a certain feature in third-party apps before release.
- We can reproduce the error and debug a certain buggy feature in third-party apps.

## Develop Guide:
### Prerequisitions
- Install [theos](https://github.com/theos/theos) on your mac
- Jailbroken device ([unc0ver](https://github.com/pwn20wndstuff/Undecimus) can jailbreak iOS 11.0~12.4)
- Install openssh on the jailbroken device
### Development
- Use sample project RatingTool to debug and test your changes
### Deploy plugin
- Run `make`, `RatingHelper.dylib` will be generated at `.theos/obj/debug/`
- Upload `RatingHelper.dylib` and `RatingHelper.plist` to jailbroken device at `/Library/MobileSubstrate/DynamicLibraries/`
  - Use scp to upload file: `scp .theos/obj/debug/RatingHelper.dylib root@[IP_ADDRESS_OF_JAILBROKEN_DEVICE]:/Library/MobileSubstrate/DynamicLibraries/`
