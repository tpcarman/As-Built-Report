# VMware vSphere As Built Report

# Getting Started
Below are the instructions on how to install, configure and generate a VMware vSphere As Built report.

## Pre-requisites
The following PowerShell modules are required for generating a VMware vSphere As Built report.

Each of these modules can be easily downloaded and installed via the PowerShell Gallery 

- [PScribo Module](https://www.powershellgallery.com/packages/PScribo/)
- [VMware PowerCLI Module](https://www.powershellgallery.com/packages/VMware.PowerCLI/)

### Module Installation

Open a Windows PowerShell terminal window and install each of the required modules as follows;

    install-module PScribo

    install-module VMware.PowerCLI

## Configuration
The vSphere As Built report utilises a JSON file (vSphere.json) to allow configuration of report information, features and section detail. All report settings are configured via the JSON file.

**Modification of the PowerShell script (vSphere.ps1) is not required or recommended.**

The following provides information of how to configure each schema within the report's JSON file.

### Report
The **Report** sub-schema provides configuration of the vSphere report information

| Schema | Sub-Schema | Description |
| ------ | ---------- | ----------- |
| Report | Name | The name of the As Built report
| Report | Version | The document version
| Report | Status | The document release status

### Options
The **Options** sub-schema allows certain options within the report to be toggled on or off

| Schema | Sub-Schema | Setting | Description |
| ------ | ---------- | ------- | ----------- |
| Options | ShowLicenses | true / false | Toggle to mask/unmask  vSphere license keys within the As Built report.<br><br> **Masked License Key**<br>\*\*\*\*\*-\*\*\*\*\*-\*\*\*\*\*-56YDM-AS12K<br><br> **Unmasked License Key**<br>AKLU4-PFG8M-W2D8J-56YDM-AS12K

### InfoLevel
The **InfoLevel** sub-schema allows configuration of each section of the report at a granular level. The following sections can be set

| Schema | Sub-Schema | Default Setting |
| ------ | ---------- | --------------- |
| InfoLevel | vCenter | 2
| InfoLevel | ResourcePool | 2
| InfoLevel | Cluster | 2
| InfoLevel | VMhost | 2
| InfoLevel | Network | 2
| InfoLevel | vSAN | 2
| InfoLevel | Datastore | 2
| InfoLevel | DSCluster | 2
| InfoLevel | VM | 2
| InfoLevel | VUM | 2
| InfoLevel | NSX\* | 0
| InfoLevel | SRM\*\* | 0

\* *Requires PowerShell module [PowerNSX](https://github.com/vmware/powernsx) to be installed*

\*\* *Placeholder for future release* 

There are 5 levels (0-4) of detail granularity for each section as follows;

| Setting | InfoLevel | Description |
| ------- | ---- | ----------- |
| 0 | Disabled | excludes section from the report
| 1 | Summary | provides summarised information for the section
| 2 | Detailed | provides detailed information for the section
| 3 | Full | provides more detailed information for the section
| 4 | Everything | provides the most detailed information for the section

### Healthcheck
The **Healthcheck** sub-schema is used to toggle health checks on or off.

#### vCenter
The **vCenter** sub-schema is used to configure health checks for vCenter Server.

| Schema | Sub-Schema | Setting | Description | Highlight |
| ------ | ---------- | ------- | ----------- | --------- |
| vCenter | Mail | true / false | Highlights mail settings which are not configured | ![Critical](https://placehold.it/15/FFB38F/000000?text=+) Not Configured 
| vCenter | Licensing | true / false | Highlights product evaluation licenses | ![Warning](https://placehold.it/15/FFE860/000000?text=+) Product evaluation license in use

#### Cluster
The **Cluster** sub-schema is used to configure health checks for vSphere Clusters.

| Schema | Sub-Schema | Setting | Description | Highlight |
| ------ | ---------- | ------- | ----------- | --------- |
| Cluster | HAEnabled | true / false | Highlights vSphere Clusters which do not have vSphere HA enabled | ![Warning](https://placehold.it/15/FFE860/000000?text=+) vSphere HA disabled
| Cluster | HAAdmissionControl | true / false | Highlights vSphere Clusters which do not have vSphere HA Admission Control enabled | ![Warning](https://placehold.it/15/FFE860/000000?text=+) vSphere HA Admission Control disabled
| Cluster | DRSEnabled | true / false | Highlights vSphere Clusters which do not have vSphere DRS enabled | ![Warning](https://placehold.it/15/FFE860/000000?text=+) vSphere DRS disabled
| Cluster | DRSAutomationLevel | true / false | Enables/Disables checking the vSphere DRS Automation Level
| Cluster | DRSAutomationLevelSetting | Off / Manual / PartiallyAutomated / FullyAutomated | Highlights vSphere Clusters which do not match the specified DRS Automation Level | ![Warning](https://placehold.it/15/FFE860/000000?text=+) Does not match specified DRS Automation Level
| Cluster | DRSVMHostRules | true / false | Highlights DRS VMHost rules which are disabled | ![Warning](https://placehold.it/15/FFE860/000000?text=+) DRS VMHost rule disabled
| Cluster | DRSRules | true / false | Highlights DRS rules which are disabled | ![Warning](https://placehold.it/15/FFE860/000000?text=+) DRS rule disabled
| Cluster | EVCEnabled | true / false | Highlights vSphere Clusters which do not have Enhanced vMotion Compatibility (EVC) enabled | ![Warning](https://placehold.it/15/FFE860/000000?text=+) vSphere EVC disabled
| Cluster | VUMCompliance | true / false | Highlights vSphere Clusters which do not comply with VMware Update Manager baselines | ![Warning](https://placehold.it/15/FFE860/000000?text=+) Unknown<br> ![Critical](https://placehold.it/15/FFB38F/000000?text=+)  Not Compliant

#### VMHost
The **VMHost** sub-schema is used to configure health checks for VMHosts.

| Schema | Sub-Schema | Setting | Description | Highlight |
| ------ | ---------- | ------- | ----------- | --------- |
| VMhost | ConnectionState | true / false | Highlights VMHosts connection state | ![Warning](https://placehold.it/15/FFE860/000000?text=+) Maintenance<br>  ![Critical](https://placehold.it/15/FFB38F/000000?text=+)  Disconnected
| VMhost | ScratchLocation | true / false | Highlights VMHosts which are configured with the default scratch location | ![Warning](https://placehold.it/15/FFE860/000000?text=+) Scratch location is /tmp/scratch
| VMhost | IPv6Enabled | true / false | Highlights VMHosts which do not have IPv6 enabled | ![Warning](https://placehold.it/15/FFE860/000000?text=+) IPv6 disabled
| VMhost | UpTimeDays | true / false | Highlights VMHosts with uptime days greater than 9 months | ![Warning](https://placehold.it/15/FFE860/000000?text=+) 9 - 12 months<br> ![Critical](https://placehold.it/15/FFB38F/000000?text=+)  >12 months
| VMhost | Licensing | true / false | Highlights VMHosts which are using production evaluation licenses | ![Warning](https://placehold.it/15/FFE860/000000?text=+) Product evaluation license in use
| VMhost | Services | true / false | Highlights status of important VMHost services | ![Warning](https://placehold.it/15/FFE860/000000?text=+) TSM / TSM-SSH service enabled
| VMhost | TimeConfig | true / false | Highlights if the NTP service has stopped on a VMHost | ![Critical](https://placehold.it/15/FFB38F/000000?text=+)  NTP service stopped
| VMhost | VUMCompliance | true / false | Highlights VMHosts which are not compliant with VMware Update Manager software packages | ![Warning](https://placehold.it/15/FFE860/000000?text=+) Unknown<br> ![Critical](https://placehold.it/15/FFB38F/000000?text=+)  Incompatible

#### vSAN
The **vSAN** sub-schema is used to configure health checks for vSAN.

Currently there are no vSAN health checks defined.

#### Datastore
The **Datastore** sub-schema is used to configure health checks for Datastores.

| Schema | Sub-Schema | Setting | Description | Highlight |
| ------ | ---------- | ------- | ----------- | --------- |
| Datastore | CapacityUtilization | true / false | Highlights datastores with storage capacity utilization over 75% | ![Warning](https://placehold.it/15/FFE860/000000?text=+) 75 - 90% utilized<br> ![Critical](https://placehold.it/15/FFB38F/000000?text=+) >90% utilized

#### DSCluster
The **DSCluster** sub-schema is used to configure health checks for Datastore Clusters.

| Schema | Sub-Schema | Setting | Description | Highlight |
| ------ | ---------- | ------- | ----------- | --------- |
| DSCluster | SDRSAutomationLevel | true / false | Enables/Disables checking the Datastore Cluster SDRS Automation Level
| DSCluster | SDRSAutomationLevelSetting | Off / Manual / PartiallyAutomated / FullyAutomated | Highlights Datastore Clusters which do not match the specified SDRS Automation Level | ![Warning](https://placehold.it/15/FFE860/000000?text=+) Does not match specified SDRS Automation Level
| DSCluster | CapacityUtilization | true / false | Highlights datastore clusters with storage capacity utilization over 75% | ![Warning](https://placehold.it/15/FFE860/000000?text=+) 75 - 90% utilized<br> ![Critical](https://placehold.it/15/FFB38F/000000?text=+) >90% utilized

#### VM
The **VM** sub-schema is used to configure health checks for virtual machines.

| Schema | Sub-Schema | Setting | Description | Highlight |
| ------ | ---------- | ------- | ----------- | --------- |
| VM | PowerState | true / false | Enables/Disables checking the VM power state
<<<<<<< HEAD
| VM | PowerStateSetting | PoweredOn / PoweredOff | Highlights virtual machines which do not match the specified VM power state
=======
| VM | PowerStateSetting | PoweredOn / PoweredOff | Highlights virtual machines which do not match the specified VM power state | ![Warning](https://placehold.it/15/FFE860/000000?text=+) Highlights VMs which do not match the specified VM power state
>>>>>>> refs/remotes/origin/dev
| VM | VMTools | true / false | Highlights Virtual Machines which do not have VM Tools installed or are out of date | ![Warning](https://placehold.it/15/FFE860/000000?text=+) VM Tools not installed or out of date
| VM | VMSnapshots | true / false | Highlights Virtual Machines which have snapshots older than 7 days | ![Warning](https://placehold.it/15/FFE860/000000?text=+) VM Snapshot age >= 7 days<br> ![Critical](https://placehold.it/15/FFB38F/000000?text=+) VM Snapshot age >= 14 days

## Examples 
- Generate HTML & Word reports with Timestamp
<<<<<<< HEAD
Generate a vSphere As-Built report for vCenter Server 'vcenter-01.corp.local' using specified credentials. Export report to HTML & DOC formats. Use default report style. Append timestamp to report filename. Save reports to 'C:\Users\Tim\Documents'

     .\New-AsBuilt-Report.ps1 -Target 'vcenter-01.corp.local' -Username 'administrator@vsphere.local' -Password 'VMware1!' -Type vSphere -Format Html,Word -Path 'C:\Users\Tim\Documents' -Timestamp

- Generate HTML & Text reports with Health Checks
Generate a vSphere As-Built report for vCenter Server 'vcenter-01.corp.local' using stored credentials. Export report to HTML & Text formats. Use default report style. Highlight environment issues within the report. Save reports to 'C:\Users\Tim\Documents'

     .\New-AsBuilt-Report.ps1 -Target 'vcenter-01.corp.local' -Credentials $Creds -Type vSphere -Format Html,Text -Path 'C:\Users\Tim\Documents' -Healthchecks

- Generate report with multiple vCenter Servers using Custom Style
Generate a single vSphere As-Built report for vCenter Servers 'vcenter-01.corp.local' and 'vcenter-02.corp.local' using specified credentials. Report exports to DOC format by default. Apply custom style to the report. Reports are saved to the script folder by default.

     .\New-AsBuilt-Report.ps1 -Target "vcenter-01.corp.local,vcenter-02.corp.local" -Username 'administrator@vsphere.local' -Password 'VMware1!' -Type vSphere -StyleName 'MyCustomStyle'

- Generate HTML & Word reports, attach and send reports via e-mail
Generate a vSphere As-Built report for vCenter Server 'vcenter-01.corp.local' using specified credentials. Export report to HTML & DOC formats. Use default report style. Reports are saved to the script folder by default. Attach and send reports via e-mail.

     .\New-AsBuilt-Report.ps1 -Target vcenter-01.corp.local -Username 'administrator@vsphere.local' -Password 'VMware1!' -Type vSphere -Format Html,Word -Path C:\Users\Tim\Documents -SendEmail

## Samples
### Sample Report 1 - Default Style
Sample vSphere As-Built report with health checks, using default report style.
=======
Generate a vSphere As Built report for vCenter Server 'vcenter-01.corp.local' using specified credentials. Export report to HTML & DOC formats. Use default report style. Append timestamp to report filename. Save reports to 'C:\Users\Tim\Documents'

    `.\New-AsBuilt-Report.ps1 -Target 'vcenter-01.corp.local' -Username 'administrator@vsphere.local' -Password 'VMware1!' -Type vSphere -Format Html,Word -Path 'C:\Users\Tim\Documents' -Timestamp`

- Generate HTML & Text reports with Health Checks
Generate a vSphere As Built report for vCenter Server 'vcenter-01.corp.local' using stored credentials. Export report to HTML & Text formats. Use default report style. Highlight environment issues within the report. Save reports to 'C:\Users\Tim\Documents'

    `.\New-AsBuilt-Report.ps1 -Target 'vcenter-01.corp.local' -Credentials $Creds -Type vSphere -Format Html,Text -Path 'C:\Users\Tim\Documents' -Healthchecks`

- Generate report with multiple vCenter Servers using Custom Style
Generate a single vSphere As Built report for vCenter Servers 'vcenter-01.corp.local' and 'vcenter-02.corp.local' using specified credentials. Report exports to DOC format by default. Apply custom style to the report. Reports are saved to the script folder by default.

    `.\New-AsBuilt-Report.ps1 -Target "vcenter-01.corp.local,vcenter-02.corp.local" -Username 'administrator@vsphere.local' -Password 'VMware1!' -Type vSphere -StyleName 'MyCustomStyle'`

- Generate HTML & Word reports, attach and send reports via e-mail
Generate a vSphere As Built report for vCenter Server 'vcenter-01.corp.local' using specified credentials. Export report to HTML & DOC formats. Use default report style. Reports are saved to the script folder by default. Attach and send reports via e-mail.

    `.\New-AsBuilt-Report.ps1 -Target vcenter-01.corp.local -Username 'administrator@vsphere.local' -Password 'VMware1!' -Type vSphere -Format Html,Word -Path C:\Users\Tim\Documents -SendEmail`

## Samples
### Sample Report 1 - Default Style
Sample vSphere As Built report with health checks, using default report style.
>>>>>>> refs/remotes/origin/dev

![Sample vSphere Report 1](https://github.com/tpcarman/As-Built-Report/blob/dev/Reports/vSphere/Samples/Sample_vSphere_Report_1.png "Sample vSphere Report 1")


### Sample Report 2 - Custom Style
<<<<<<< HEAD
Sample vSphere As-Built report with health checks, using custom report style.
=======
Sample vSphere As Built report with health checks, using custom report style.
>>>>>>> refs/remotes/origin/dev

![Sample vSphere Report 2](https://github.com/tpcarman/As-Built-Report/blob/dev/Reports/vSphere/Samples/Sample_vSphere_Report_2.png "Sample vSphere Report 2")

# Release Notes
## 0.2.0
### What's New
- Requires PScribo module 0.7.24
- Added regions/endregions to all sections of script
- Formatting improvements
- Added Resource Pool summary information
- Added vSAN summary information
- Added vCenter Server mail settings health check
- Datastore Clusters now has it's own dedicated section
- Added DSCluster health checks
- Added VM Power State health check
- Renamed Storage section to Datastores
- Renamed Storage health checks section to Datastore
- Added support for NSX-V reporting

### Known Issues
- Verbose script errors when connecting to vCenter with a Read-Only user account

- In HTML documents, word-wrap of table cell contents is not working, causing the following issues;
  - Cell contents may overflow table columns
  - Tables may overflow page margin
  - [PScribo Issue #83](https://github.com/iainbrighton/PScribo/issues/83)

- In Word documents, some tables are not sized proportionately. To prevent cell overflow issues in HTML documents, most tables are auto-sized, this causes some tables to be out of proportion.
    
    - [PScribo Issue #83](https://github.com/iainbrighton/PScribo/issues/83)
