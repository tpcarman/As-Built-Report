# VMware NSX-V As-Built Report
The VMware NSX-V As-Built report is generated as a section within the VMware vSphere As-Built Report.

# Getting Started
Below are the instructions on how to enable and NSX-V reporting.

## Pre-requisites
The following PowerShell modules are required to enable NSX-V reporting.

Each of these modules can be easily downloaded and installed via the PowerShell Gallery 

- [PScribo Module](https://www.powershellgallery.com/packages/PScribo/)
- [VMware PowerCLI Module](https://www.powershellgallery.com/packages/VMware.PowerCLI/)
- [VMware PowerNSX Module](https://github.com/vmware/powernsx)

### Module Installation

Open a Windows PowerShell terminal window and install each of the required modules as follows;

    install-module PScribo

    install-module VMware.PowerCLI

    install-module PowerNSX

## Configuration
VMware NSX-V reporting is confgigured via the JSON configuration file (vSphere.json) for the VMware vSphere As-Built Report.

The following provides information of how to configure the NSX schema within the vSphere As-Built report's JSON file.

### InfoLevel
The **InfoLevel** sub-schema allows configuration of each section of the report at a granular level. The NSX InfoLevel must be set to >= 1 to enable NSX-V reporting.

| Schema | Sub-Schema | Default Setting | Desired Setting |
| ------ | ---------- | --------------- | --------------|
| InfoLevel | NSX | 0 | >= 1

## Sample Report
Below is an example of a vSphere As-Built report which includes NSX-V reporting.