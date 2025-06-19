CLASS zcl_03_eml DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun .

    CONSTANTS c_agency_id TYPE /dmo/agency_id VALUE '070003'.
    CONSTANTS c_travel_id TYPE /dmo/travel_id VALUE '00004153'.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_03_eml IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.

    DATA travels TYPE TABLE FOR READ RESULT z03_r_travel.
    DATA travels_in TYPE TABLE FOR READ IMPORT z03_r_travel.
    DATA travels_up TYPE TABLE FOR UPDATE z03_r_travel.

    travels_in = VALUE #( ( AgencyId = c_agency_id TravelId = c_travel_id )
                          ( AgencyId = '070003' TravelId = '00004154' ) ).

    READ ENTITY z03_r_travel
    ALL FIELDS
    WITH travels_in
    RESULT travels
    FAILED DATA(failed)
    REPORTED DATA(reported).

    IF failed IS NOT INITIAL.
      out->write( 'Error retrieving record' ).
    ELSE.

      travels_up = VALUE #( ( AgencyId = c_agency_id
                              TravelId = c_travel_id
                              Description = 'Test update 03 train' )
                              ( AgencyId = '070003' TravelId = '00004154' Description = 'Test update 03 train 2' ) ).

      MODIFY ENTITIES OF z03_r_travel
      ENTITY Travel
      UPDATE FIELDS ( Description )
      WITH travels_up
      FAILED failed.

      IF failed IS INITIAL.
        COMMIT ENTITIES. out->write( `Description successfully updated` ).
      ELSE.
        ROLLBACK ENTITIES. out->write( `Error updating the description` ).
      ENDIF.

    ENDIF.


  ENDMETHOD.
ENDCLASS.
