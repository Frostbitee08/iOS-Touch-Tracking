# Track Touch Data in iOS
<a href="https://github.com/Frostbitee08/iOS-Touch-Tracking"><img alt="Release" src="https://img.shields.io/github/release/frostbitee08/iOS-Touch-Tracking.svg" /></a>
<a href="https://github.com/Frostbitee08/iOS-Touch-Tracking/blob/master/License.txt"><img alt="License" src="https://img.shields.io/github/license/mashape/apistatus.svg?maxAge=2592000" /></a>

Touch Tracking is an [RCOS](http://rcos.io) project that collects data about a user's touches. The goal is to visualize this data in order to help both designers and developers have a better understanding of how iOS devices are used. Touch Tracking records the following properties of each touch:

* "t" : The time in seconds at which the touch occured, relative to the first touch in the sequence.
* "tc" : The tap count of each recorded touch.
* "kb" : A boolean value that reflects whether the touch was keyboard input.
* "x" : The x coordinate in points that represents the center of the touch.
* "y" : The y coordinate in points that represents the center of the touch.
 
<b>Note:</b> Touch tracking disables any tracking of keyboard interaction by default. 

Touch tracking writes this data to logs seperated by each calander date. Example, `01_01_2016.json`. Logs are stored in the following locations:

* Active Log `/var/mobile/Library/TouchTracking/`
* Closed Log `/var/mobile/Library/TouchTracking/Closed/`
* Uploaded Log `/var/mobile/Library/TouchTracking/Closed/Uploaded/`

All logs contain only the information listed above, and are uploaded anonymously with the user's permission.

##Requirements
A jailbroken iOS device running iOS 9.0 or above.

## Installation
The latest beta can be installed by adding `http://repo.roccodelpriore.com` as a repository to cydia.

Alternatively, you can download the latest version [here](https://www.dropbox.com/s/m2bcxg2qvqht3nr/com.roccodelpriore.touchtracking_0.4-15_iphoneos-arm.deb?dl=0)

##Data Visualization
An early example of non-keyboard touches on an iPhone 6. A single Day was used as the dataset.
![alt text](http://f.cl.ly/items/3K3v3R0k2p2N2w2L2g1B/confirmed_output.png "iPhone 6")
