@AbapCatalog.viewEnhancementCategory: [#PROJECTION_LIST]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'extension'
@Metadata.ignorePropagatedAnnotations: true
@AbapCatalog.extensibility: {
        extensible: true,
        allowNewDatasources: false,
        dataSources: ['Item' ],
        elementSuffix: 'Z15'
}
define view entity Z15_E_TravelItem
  as select from z15_tritem as Item
{
  key item_uuid as ItemUuid
}
