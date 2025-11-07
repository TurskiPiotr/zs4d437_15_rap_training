@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Piotr''s Flight Travel'
@Metadata.ignorePropagatedAnnotations: true
@Search.searchable: true
@Metadata.allowExtensions: true
define root view entity Z15_C_TRAVEL
  provider contract transactional_query
  as projection on Z15_R_TRAVEL
{
  key AgencyId,
  key TravelId,

      @Search.defaultSearchElement: true
      Description,

      @Search.defaultSearchElement: true
      //   @Consumption.valueHelpDefinition: [
      //       { entity: {
      //        name: '/DMO/I_Customer_StdVH',
      //       element: 'CustomerID' } }
      //                                       ]
      @Consumption.valueHelpDefinition: [
          { entity: {
            name: '/DMO/I_Customer_StdVH',
            element: 'CustomerID' },
           additionalBinding: [{
                localElement: 'Description',
                element: 'FirstName',
                usage:   #RESULT                 }]
                                       }  ]
      CustomerId,

      BeginDate,
      EndDate,

      @EndUserText.label: 'Duration (days)'
      Duration,

      Status,
      ChangedAt,
      ChangedBy,
      LocChangedAt,
      _TravelItem : redirected to composition child Z15_C_TRAVELITEM
      
}
