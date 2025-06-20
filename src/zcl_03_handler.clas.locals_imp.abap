*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations
class lcl_handler definition INHERITING FROM cl_abap_behavior_event_handler.


  private section.
    METHODS on_travel_created FOR ENTITY EVENT
        IMPORTING new_travels
        FOR Travel~TravelCreated.

endclass.

class lcl_handler implementation.

  method on_travel_created.
*    DATA log TYPE TABLE FOR CREATE /lrn/437_i_travellog.
*
*    log = VALUE #( FOR t IN new_travels ( AgencyID = t-AgencyId
*                                          TravelID = t-TravelId
*                                          Origin = 'Z03_R_TRAVEL' ) ).
    MODIFY ENTITIES OF /LRN/437_I_TravelLog
    ENTITY TravelLog
    CREATE AUTO FILL CID
    FIELDS ( AgencyID TravelID Origin )
    WITH CORRESPONDING #( new_travels ).

  endmethod.

endclass.
