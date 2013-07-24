Scrumptious sample

Scrumptious demonstrates a "real-world" (albeit very limited) application that integrates with Facebook.
It allows a user to select from a small pre-defined list of cuisine types that they are eating, then
tag friends who they are with, and tag the restaurant they are in. Scrumptious then allows them to post an 
Open Graph Action to their Timeline which will display the the tagged friends and location.

The example utilizes several controls for the Facebook SDK including:
 FBLoginView - used on the landing page for authenticating the user.
 FBFriendPickerViewController - presented from the main UI to pick friends.
 FBPlacePickerViewController - presented from the main UI to pick a location.
 FBuserSettingsViewController - used to log the user out.
 
Furthermore, the sample demonstrates usage of Open Graph objects and actions. While the functionality is 
quite constrained in order to be of reasonable size for a sample, the Facebook integration could serve
as the basis for more full-featured applications. In particular, look for the text "Facebook SDK" to identify
key integration points.

Scrumptious also demonstrates how to override images and locale specific strings.  This uses the same image as the SDK, but it is actually
loaded from the Scrumptious bundle instead of the SDK.  Strings in English are the same, but if the phone is switched into Hebrew, Hebrew
strings will appear.  For further information please look at FacebookSDKResources.bundle.README

If using Scrumptious as the basis for another application, please note that all of the Open Graph namespaces will need
to be updated, and a hosted service must be provided in order to serve up Open Graph Objects. In addition, the logged-in
user will need to be a Developer or a Tester on the application until it is approved for posting Open Graph Actions.

Using the Sample
Install the Facebook SDK for iOS.
Launch the Scrumptious project using Xcode from the <Facebook SDK>/samples/Scrumptious directory.
