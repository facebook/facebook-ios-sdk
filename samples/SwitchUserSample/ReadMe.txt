Switch User sample

Demonstrates an approach to allow switching between multiple users on, for example, a shared family iPad.

In this sample, we have the concept of a "Primary User" and up to three "Guest Users". The Primary User
authenticates using SSO, if possible, while the Guest Users are asked to login using their Facebook
credentials. Once authenticated, no further requests are made for user passwords, etc., so a solution
such as this would be applicable only in a scenario that implies a high degree of trust amongst the
various users.

Using the Sample
Install the Facebook SDK for iOS.
Launch the SwitchUsersSample project using Xcode from the <Facebook SDK>/samples/SwitchUsersSample directory.
