Humanify iOS SDK & Test Harness
============

Release Notes: https://docs.google.com/document/d/1QNO8MH9b_T3K6y3shlNPH6PXnItqZRbSORNS60OaXhw

This repository includes the native iOS SDK (EXPERTconnect.framework) as well as the EXPERTconnect Test Harness app. These are two XCode projects within the same XCode workspace. 

There are three schemes in the workspace: 
* ExpertConnect - used for running unit tests mostly.  
* ExpertConnectDemo - Builds the Test Harness (automatically compiles in the SDK as well). 
* ECSUniveral - When "archive" is used, this builds the releasable .framework files. It outputs three files -- (iphoneos, iphonesimulator, and iphoneuniversal). iphoneos and iphoneuniversal are copied into the SDK-iOS-Integrator repo. 

WARNING: Currently, when archiving the "ECSUniversal" .framework files, the output contains an error. Each of the EXPERTconnect.framework files in the Finder folder that pops up at the end of the process must be modified. Expand one of these EXPERTconnect.framework files, and find the "EXPERTconnect.framework" file within it. Delete this. Basically, the build scripts are inadvertantly placing a copy of the framework inside itself. This causes problems when uploading to the app store (obviously). 

UNIT TESTING: To run the unit tests, select the "ExpertConnect" scheme, then Product-->Test. 

BUILDING TEST HARNESS FOR HOCKEYAPP: Select the "ExpertConnectDemo" scheme, then Product-->Archive. Once the archive shows up in the organizer window, select it (usually the top one) and choose "Export...". Choose "Save for Enterprise Deployment", team is "TeleTech Holdings, Inc." (currently our only Enterprise Apple Account). Then save to a location on disk. This will be the .ipa file you drag-drop into HockeyApp here: https://rink.hockeyapp.net/manage/apps/196433

Some commonly used features of the SDK: 
* Chat
* Voice Callback
* Forms
* Answer Engine
* Breadcrumbs
* Decisioning
