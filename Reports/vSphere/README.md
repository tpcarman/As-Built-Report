# VMware vSphere As-Built Report

# Getting Started
Below is a information relating to the VMware vSphere As-Built report.

## Pre-requisites
The following PowerShell modules are required for generating a VMware vSphere As-Built report.

Each of these modules can be easily downloaded and installed via the PowerShell Gallery 

- [PScribo Module](https://www.powershellgallery.com/packages/PScribo/)
- [VMware PowerCLI Module](https://www.powershellgallery.com/packages/VMware.PowerCLI/)

## Configuration
The vSphere report utilises a JSON file (vSphere.json) to allow configuration of report information, features and details.

### vSphere.json

#### Report
This schema provides configuration of the vSphere report information
- *Name*
- *Version*
- *Release Status*

#### Options
This schema allows certain options within the report to be toggled on/off
##### ShowLicenses
Option to mask/unmask  vSphere license keys within the As-Built report.

#### InfoLevel
This schema allows configuration of each section of the report at a granular level.

There are 5 levels (0-4) of detail granularity as follows;

 - 0 = Disabled - section is excluded from the report
 - 1 = Summary - provides summarised information for the section
 - 2 = Detailed - provides detailed information for the section
- 3 = Full - provides more comprehensive information for the section
- 4 = Everything - provides the most comprehensive information for the section

#### Healthcheck
This schema is used to toggle health checks on or off.

#### vCenter
This schema is used to configure health checks for vCenter Server.

##### Licensing
Highlights product evaluation licenses

![Warning](https://placehold.it/15/FFE860/000000?text=+) Product evaluation license in use

#### Cluster
This schema is used to configure health checks for vSphere Clusters.

##### HAEnabled
Highlights vSphere Clusters which do not have vSphere HA enabled

![Warning](https://placehold.it/15/FFE860/000000?text=+) vSphere HA disabled

##### HAAdmissionControl
Highlights vSphere Clusters which do not have vSphere HA Admission Control enabled

![Warning](https://placehold.it/15/FFE860/000000?text=+) vSphere HA Admission Control disabled

##### DRSEnabled
Highlights vSphere Clusters which do not have vSphere DRS enabled

![Warning](https://placehold.it/15/FFE860/000000?text=+) vSphere DRS disabled

##### DRSAutomationLevel
Enables/Disables checking the vSphere DRS Automation Level

##### DRSAutomationLevelSetting 
Highlights vSphere Clusters which do not match the specified DRS Automation Level. 

Specify one of the follwoing settings;

- Off
- Manual
- PartiallyAutomated
- FullyAutomated

##### DRSVMHostRules
Highlights DRS VMHost rules which are disabled

![Warning](https://placehold.it/15/FFE860/000000?text=+) DRS VMHost rule disabled

##### DRSRules
Highlights DRS rules which are disabled

![Warning](https://placehold.it/15/FFE860/000000?text=+) DRS rule disabled

##### EVCEnabled
Highlights vSphere Clusters which do not have Enhanced vMotion Compatibility (EVC) enabled

![Warning](https://placehold.it/15/FFE860/000000?text=+) vSphere EVC disabled

##### VUMCompliance
Highlights vSphere Clusters which do not comply with VMware Update Manager baselines

![Warning](https://placehold.it/15/FFE860/000000?text=+) Unknown

![Critical](https://placehold.it/15/FFB38F/000000?text=+)  Not Compliant

#### VMHost
This schema is used to configure health checks for vSphere Hosts.

##### ConnectionState
Highlights VMHosts connection state

![Warning](https://placehold.it/15/FFE860/000000?text=+) Maintenance

![Critical](https://placehold.it/15/FFB38F/000000?text=+)  Disconnected

##### ScratchLocation
Highlights VMHosts which are configured with the default scratch location

![Warning](https://placehold.it/15/FFE860/000000?text=+) Scratch location is /tmp/scratch

##### IPv6Enabled
Highlights VMHosts which do not have IPv6 enabled

![Warning](https://placehold.it/15/FFE860/000000?text=+) IPv6 disabled

##### UpTimeDays
Highlights VMHosts with uptime days greater than 9 months

![Warning](https://placehold.it/15/FFE860/000000?text=+) 9 - 12 months

![Critical](https://placehold.it/15/FFB38F/000000?text=+)  >12 months

##### Licensing
Highlights VMHosts which are using production evaluation licenses

![Warning](https://placehold.it/15/FFE860/000000?text=+) Product evaluation license in use
##### Services
Highlights status of important VMHost services

![Warning](https://placehold.it/15/FFE860/000000?text=+) TSM / TSM-SSH service enabled

##### TimeConfig
Highlights if the NTP service has stopped on a VMHost

![Critical](https://placehold.it/15/FFB38F/000000?text=+)  NTP service stopped

##### VUMCompliance
Highlights VMHosts which are not compliant with VMware Update Manager software packages

![Warning](https://placehold.it/15/FFE860/000000?text=+) Unknown

![Critical](https://placehold.it/15/FFB38F/000000?text=+)  Incompatible

#### vSAN
This schema is used to configure health checks for vSAN.

Currently there are no vSAN health checks defined.

#### Storage
This schema is used to configure health checks for vSphere Storage.

##### CapacityUtilization
Highlights datastores with storage capacity utilization over 75%

![Warning](https://placehold.it/15/FFE860/000000?text=+) 75 - 90% utilized

![Critical](https://placehold.it/15/FFB38F/000000?text=+) >90% utilized
#### VM
This schema is used to configure health checks for Virtual Machines.
##### VMTools
Highlights Virtual Machines which do not have VM Tools installed or are out of date

![Warning](https://placehold.it/15/FFE860/000000?text=+) VM Tools not installed or out of date

##### VMSnapshots
Highlights Virtual Machines which have snapshots older than 7 days

![Warning](https://placehold.it/15/FFE860/000000?text=+) VM Snapshot age >= 7 days

![Critical](https://placehold.it/15/FFB38F/000000?text=+) VM Snapshot age >= 14 days