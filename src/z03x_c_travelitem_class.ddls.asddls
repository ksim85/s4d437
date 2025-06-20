extend view entity Z03_C_TravelItem with {
    
    @Consumption.valueHelpDefinition: [{ entity: { name: '/LRN/437_I_ClassStdVH',
                                                   element: 'ClassID'  } } ]
    Item.ZZClassZ03
}
