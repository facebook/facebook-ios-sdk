### Hackbook for iOS ###

Demonstrates how to use the Facebook Platform to integrate your iOS app. This sample initially asks the user to log in to Facebook then provides the user with a sample set of Facebook API calls such as logging out, uninstalling the app, publishing news feeds, making app requests, etc.

Build Requirements
iOS 4.0 SDK


Runtime Requirements
iPhone OS 4.0 or later


Using the Sample
Install the Facebook SDK for iOS.
Launch the Hackbook project using Xcode from the <Facebook SDK>/samples/Hackbook directory.


Packaging List
HackbookAppDelegate.{h/m} -
The app delegate class used for managing the application's window and navigation controller.

RootViewController.{h/m} -
The root view controller used to set up the main menu and initial API calls to set the user context (basic information and permissions).

APICallsViewController.{h/m} -
View controllers pushed from the root view controller. Used to handle each of the API sub-sections. Most of the Facebook API examples are contained here.

APIResultsViewController.{h/m} -
View controllers pushed from the API calls view controller. Handles mostly displaying API call results that are not simple confirmations. Also handles any post-result API calls, such as checking in from a list of nearby places.

DataSet.{h/m} -
Class that defines the UI data for the app. The main menu, sub menus, and methods each menu calls are defined here.

Changes from Previous Versions
1.0 - First release.


