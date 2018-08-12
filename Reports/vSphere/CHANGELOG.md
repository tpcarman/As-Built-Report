# VMware vSphere As-Built Report Changelog

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

- In Word documents, some tables are not sized proportionately. To prevent cell overflow issues in HTML documents, most tables are auto-sized, this causes some tables to be out of proportion.