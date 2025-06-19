@EndUserText.label: 'Flight Travel (Projection)'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Search.searchable: true
define root view entity Z03_C_TRAVEL 
provider contract transactional_query 
as projection on Z03_R_TRAVEL
{
    key AgencyId,
    key TravelId,
    @Search.defaultSearchElement: true
    Description,
    @Search.defaultSearchElement: true
    @Consumption.valueHelpDefinition: [{ entity: { name: '/DMO/I_Customer_StdVH',
                                                   element: 'CustomerID' } }]
    CustomerId,
    BeginDate,
    EndDate,
    @EndUserText.label: 'Duration (days)'
    Duration,
    Status,
    ChangedAt,
    ChangedBy,
    LocChangedAt,
    
    _TravelItem : redirected to composition child Z03_C_TravelItem
}
