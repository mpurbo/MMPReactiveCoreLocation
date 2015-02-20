# MMPReactiveCoreLocation CHANGELOG

## 0.6.2

* Added: Beacon ranging signal.
* Added: Direct access to underlying CLLocationManager.
* Added: New options: `locationAgeLimit`, `timeout`.
* Fix: visits and headingUpdates subscription doesn't trigger the location manager start.
* Fix: required delegate methods available as signals (`locationUpdatePauses`, `locationUpdateResumes`).
* Added: request and subscribe to a specific region states (`statesForRegion:`).
* Code cleanup.

## 0.6.1

* Fix: signals sharing identical settings are not automatically stopped.

## 0.6.0

* Complete library design overhaul, simpler functions, intelligent resource management. **Incompatible** with previous versions.

## 0.5.2

* Fix: region monitoring didn't work.
* Sample code for region monitoring.

## 0.5.1

* Manual request for authorization (e.g. for MapKit integration).
* Fix: request for authorization for all type of signals.

## 0.5.0

* Complete library design overhaul, implementing all CLLocationManager (up to iOS 8) functionalities. **Incompatible** with previous versions.

## 0.4.1

* Support for iOS 8 "Always" and "WhenInUse" authorization.

## 0.4.0

* iBeacon signals.
* Updated usage examples.

## 0.3.0

* Delegate leak bug-fix (Credit: [longlongjump](https://github.com/longlongjump))
* Custom location manager signals.
* Updated usage examples.

## 0.2.0

* Signals for one-time location request.

## 0.1.1

* More robust location updating logic.
* Signals with accuracy and timeout.

## 0.1.0

Initial release.
