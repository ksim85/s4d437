@AbapCatalog.viewEnhancementCategory: [#PROJECTION_LIST]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Extension of travel item'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
@AbapCatalog.extensibility: {extensible: true, allowNewDatasources: false, dataSources: [ 'Item' ], elementSuffix: 'Z03'}
define view entity Z03_E_TRAVELITEM as select from z03_tritem as Item
{
    key item_uuid as ItemUuid
}
