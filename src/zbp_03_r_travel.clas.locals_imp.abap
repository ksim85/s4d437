CLASS lsc_z03_r_travel DEFINITION INHERITING FROM cl_abap_behavior_saver.

  PROTECTED SECTION.

    METHODS save_modified REDEFINITION.

  PRIVATE SECTION.

    METHODS map_message
        IMPORTING i_msg TYPE symsg
        RETURNING VALUE(r_msg) TYPE REF TO if_abap_behv_message.

ENDCLASS.

CLASS lsc_z03_r_travel IMPLEMENTATION.

  METHOD save_modified.

    DATA(model) = NEW /lrn/cl_s4d437_tritem( i_table_name = 'Z03_TRITEM' ).

    LOOP AT delete-item ASSIGNING FIELD-SYMBOL(<item_d>).

        DATA(ret_d) = model->delete_item(  i_uuid = <item_d>-ItemUuid ).

        IF ret_d IS NOT INITIAL.
         reported-item = VALUE #( ( %tky-ItemUuid = <item_d>-ItemUuid
                                    %msg = map_message( ret_d ) ) ).
        ENDIF.
    ENDLOOP.

    LOOP AT create-item ASSIGNING FIELD-SYMBOL(<item_c>).

        DATA(ret_c) = model->create_item(  i_item = CORRESPONDING #( <item_c> MAPPING FROM ENTITY ) ).

        IF ret_c IS NOT INITIAL.
         reported-item = VALUE #( ( %tky-ItemUuid = <item_c>-ItemUuid
                                    %msg = map_message( ret_c ) ) ).
        ENDIF.
    ENDLOOP.

    LOOP AT update-item ASSIGNING FIELD-SYMBOL(<item_u>).

        DATA(ret_u) = model->update_item( i_item = CORRESPONDING #( <item_u> MAPPING FROM ENTITY )
                                          i_itemx = CORRESPONDING #( <item_u> MAPPING FROM ENTITY USING CONTROL ) ).

        IF ret_u IS NOT INITIAL.
         reported-item = VALUE #( ( %tky-ItemUuid = <item_u>-ItemUuid
                                    %msg = map_message( ret_u ) ) ).
        ENDIF.

    ENDLOOP.

    IF create-travel IS NOT INITIAL.
        DATA event_in TYPE TABLE FOR EVENT Z03_R_Travel~TravelCreated.

        event_in = VALUE #( for t in create-travel ( AgencyId = t-AgencyId
                                                     TravelId = t-TravelId
                                                     origin = 'Z03_R_TRAVEL_1' ) ).
        RAISE ENTITY EVENT z03_r_travel~TravelCreated FROM event_in.

    ENDIF.
  ENDMETHOD.

  METHOD map_message.

    DATA severity TYPE if_abap_behv_message=>t_severity.

    CASE i_msg-msgty.
        WHEN 'S'.
            severity = if_abap_behv_message=>severity-success.
        WHEN 'I'.
            severity = if_abap_behv_message=>severity-information.
        WHEN 'W'.
            severity = if_abap_behv_message=>severity-warning.
        WHEN 'E'.
            severity = if_abap_behv_message=>severity-error.
        WHEN OTHERS.
            severity = if_abap_behv_message=>severity-none.
    ENDCASE.

    r_msg = new_message( id = i_msg-msgid
                        number = i_msg-msgno
                        severity = severity
                        v1 = i_msg-msgv1
                        v2 = i_msg-msgv2
                        v3 = i_msg-msgv3
                        v4 = i_msg-msgv4 ).

  ENDMETHOD.

ENDCLASS.

CLASS lhc_item DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS validateFlightDate FOR VALIDATE ON SAVE
      IMPORTING keys FOR Item~validateFlightDate.
    METHODS determineTravelDates FOR DETERMINE ON SAVE
      IMPORTING keys FOR Item~determineTravelDates.

ENDCLASS.

CLASS lhc_item IMPLEMENTATION.

  METHOD validateFlightDate.

    CONSTANTS c_area TYPE string VALUE 'FLIGHTDATE'.

    READ ENTITIES OF z03_r_travel IN LOCAL MODE
    ENTITY Item
    FIELDS ( AgencyId TravelId FlightDate )
    WITH CORRESPONDING #( keys )
    RESULT DATA(items).

    LOOP AT items ASSIGNING FIELD-SYMBOL(<items>).

        reported-item = VALUE #( ( %tky = <items>-%tky %state_area = c_area ) ).

        IF <items>-FlightDate IS INITIAL.

            failed-item = VALUE #( ( %tky = <items>-%tky ) ).

            reported-item = VALUE #( ( %tky = <items>-%tky
                                       %msg = NEW /lrn/cm_s4d437( /lrn/cm_s4d437=>field_empty )
                                       %element-flightdate = if_abap_behv=>mk-on
                                       %state_area = c_area
                                       %path-travel = CORRESPONDING #( <items> ) ) ).
        ELSEIF <items>-FlightDate < cl_abap_context_info=>get_system_date(  ) .


            failed-item = VALUE #( ( %tky = <items>-%tky ) ).

            reported-item = VALUE #( ( %tky = <items>-%tky
                                       %msg = NEW /lrn/cm_s4d437( /lrn/cm_s4d437=>flight_date_past  )
                                       %element-flightdate = if_abap_behv=>mk-on
                                       %state_area = c_area
                                       %path-travel = CORRESPONDING #( <items> ) ) ).

        ENDIF.



    ENDLOOP.
  ENDMETHOD.

  METHOD determineTravelDates.

    CONSTANTS c_area TYPE string VALUE 'FLIGHTDATE'.

    READ ENTITIES OF z03_r_travel IN LOCAL MODE
    ENTITY Item
    FIELDS ( FlightDate )
    WITH CORRESPONDING #( keys )
    RESULT DATA(items)
    BY \_Travel
    FIELDS ( BeginDate EndDate )
    WITH CORRESPONDING #( keys )
    RESULT DATA(travels)
    LINK DATA(link).

    LOOP AT items ASSIGNING FIELD-SYMBOL(<item>).

        ASSIGN travels[ KEY id %tky = link[ KEY id source-%tky = <item>-%tky ]-target-%tky ] TO FIELD-SYMBOL(<travel>).

        IF <travel>-EndDate < <item>-FlightDate.
           <travel>-EndDate = <item>-FlightDate.
        ENDIF.

        IF <item>-FlightDate > cl_abap_context_info=>get_system_date( ) AND
           <item>-FlightDate < <travel>-BeginDate.
           <travel>-BeginDate = <item>-FlightDate.
        ENDIF.

    ENDLOOP.

    MODIFY ENTITIES OF z03_r_travel IN LOCAL MODE
    ENTITY Travel
    UPDATE FIELDS ( BeginDate )
    WITH CORRESPONDING #( travels ).

  ENDMETHOD.

ENDCLASS.

CLASS lhc_travel DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Travel RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Travel RESULT result.
    METHODS cancel_travel FOR MODIFY
      IMPORTING keys FOR ACTION Travel~cancel_travel.
    METHODS issue_message FOR MODIFY
      IMPORTING keys FOR ACTION Travel~issue_message.
    METHODS validateDescription FOR VALIDATE ON SAVE
      IMPORTING keys FOR Travel~validateDescription.
    METHODS validateCustomer FOR VALIDATE ON SAVE
      IMPORTING keys FOR Travel~validateCustomer.
    METHODS validateBeginDAte FOR VALIDATE ON SAVE
      IMPORTING keys FOR Travel~validateBeginDAte.

    METHODS validateEndDAte FOR VALIDATE ON SAVE
      IMPORTING keys FOR Travel~validateEndDAte.
    METHODS validateDateSequence FOR VALIDATE ON SAVE
      IMPORTING keys FOR Travel~validateDateSequence.
    METHODS determineStatus FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Travel~determineStatus.
    METHODS determineStatusSave FOR DETERMINE ON SAVE
      IMPORTING keys FOR Travel~determineStatusSave.
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR Travel RESULT result.
    METHODS determineduration FOR DETERMINE ON SAVE
      IMPORTING keys FOR travel~determineduration.
    METHODS earlynumbering_create FOR NUMBERING
      IMPORTING entities FOR CREATE Travel.

ENDCLASS.

CLASS lhc_travel IMPLEMENTATION.

  METHOD get_instance_authorizations.
    result = CORRESPONDING #( keys ).

    LOOP AT result ASSIGNING FIELD-SYMBOL(<result>).
      DATA(rc) = /lrn/cl_s4d437_model=>authority_check( i_agencyid = <result>-agencyid i_actvt = '02' ).

      IF rc <> 0.
        <result>-%action-cancel_travel = if_abap_behv=>auth-unauthorized.
        <result>-%update = if_abap_behv=>auth-unauthorized.
      ELSE.
        <result>-%action-cancel_travel = if_abap_behv=>auth-allowed.
        <result>-%update = if_abap_behv=>auth-allowed.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD cancel_travel.

    READ ENTITIES OF z03_r_travel IN LOCAL MODE
    ENTITY Travel
    ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT DATA(travels).

    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).
      IF <travel>-Status <> 'C'.
        MODIFY ENTITIES OF z03_r_travel IN LOCAL MODE
        ENTITY Travel
        UPDATE FIELDS ( Status )
        WITH VALUE #( ( %tky = <travel>-%tky Status = 'C' ) ).
      ELSE.
*       issue_message( EXPORTING keys = keys ).
        APPEND VALUE #( %tky =  <travel>-%tky ) TO failed-travel.

        APPEND VALUE #( %tky = <travel>-%tky
                        %msg = NEW /lrn/cm_s4d437(
                        textid = zcm_03_travel=>already_canceled ) )
                        TO reported-travel.
      ENDIF.
    ENDLOOP.


  ENDMETHOD.

  METHOD issue_message.
  ENDMETHOD.

  METHOD validateDescription.

    CONSTANTS c_area TYPE STRING VALUE 'DESC'.

    DATA error TYPE TABLE FOR FAILED LATE z03_r_travel.

    READ ENTITIES OF z03_r_travel IN LOCAL MODE
    ENTITY Travel
    FIELDS ( Description )
    WITH CORRESPONDING #( keys )
    RESULT DATA(travels).


    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travels>).

     reported-travel = VALUE #( ( %tky = <travels>-%tky %state_area = c_area ) ).

     IF <travels>-Description IS INITIAL.

      error = VALUE #( ( %tky = <travels>-%tky ) ).
      failed-travel = error.
      reported-travel = VALUE #( ( %tky = <travels>-%tky
                                   %msg = NEW /lrn/cm_s4d437( /lrn/cm_s4d437=>field_empty )
                                   %element-description = if_abap_behv=>mk-on
                                   %state_area = c_area ) ).
      ENDIF.
    ENDLOOP.


  ENDMETHOD.

  METHOD validateCustomer.

    CONSTANTS c_area TYPE STRING VALUE 'CUST'.

    DATA error TYPE TABLE FOR FAILED LATE z03_r_travel.
    READ ENTITIES OF z03_r_travel IN LOCAL MODE
    ENTITY Travel
    FIELDS ( CustomerId )
    WITH CORRESPONDING #( keys )
    RESULT DATA(travels).

    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travels>).

        reported-travel = VALUE #( ( %tky = <travels>-%tky
                                     %state_area = c_area ) ).

      IF <travels>-CustomerId IS INITIAL.

        error = VALUE #( ( %tky = <travels>-%tky ) ).
        failed-travel = error.
        reported-travel = VALUE #( ( %tky = <travels>-%tky
                                     %msg = NEW /lrn/cm_s4d437( /lrn/cm_s4d437=>field_empty )
                                     %element-customerid = if_abap_behv=>mk-on
                                     %state_area = c_area ) ).

      ELSE.


        SELECT CustomerID
        FROM /DMO/I_Customer
        WHERE CustomerID = @<travels>-CustomerId
        INTO TABLE @DATA(customer).

        IF lines( customer ) = 0.

          error = VALUE #( ( %tky = <travels>-%tky ) ).
          failed-travel = error.
          reported-travel = VALUE #( ( %tky = <travels>-%tky
                                       %msg = NEW /lrn/cm_s4d437( customerid = <travels>-CustomerId
                                                                  textid = /lrn/cm_s4d437=>customer_not_exist )
                                       %element-customerid = if_abap_behv=>mk-on
                                       %state_area = c_area ) ).

        ENDIF.


      ENDIF.
    ENDLOOP.


  ENDMETHOD.

  METHOD validateBeginDAte.

    CONSTANTS c_area TYPE STRING VALUE 'BDATE'.

    DATA error TYPE TABLE FOR FAILED LATE z03_r_travel.
    READ ENTITIES OF z03_r_travel IN LOCAL MODE
    ENTITY Travel
    FIELDS ( BeginDate )
    WITH CORRESPONDING #( keys )
    RESULT DATA(travels).

    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travels>).

       reported-travel = VALUE #( ( %tky = <travels>-%tky
                                    %state_area = c_area ) ).

      IF <travels>-BeginDate IS INITIAL.

        error = VALUE #( ( %tky = <travels>-%tky ) ).
        failed-travel = error.
        reported-travel = VALUE #( ( %tky = <travels>-%tky
                                     %msg = NEW /lrn/cm_s4d437( /lrn/cm_s4d437=>field_empty )
                                     %element-begindate = if_abap_behv=>mk-on
                                     %state_area = c_area ) ).

      ELSE.

        IF <travels>-BeginDate < cl_abap_context_info=>get_system_date( ).

          error = VALUE #( ( %tky = <travels>-%tky ) ).
          failed-travel = error.
          reported-travel = VALUE #( ( %tky = <travels>-%tky
                                       %msg = NEW /lrn/cm_s4d437( begindate = <travels>-BeginDate
                                                                  textid = /lrn/cm_s4d437=>begin_date_past )
                                       %element-begindate = if_abap_behv=>mk-on
                                       %state_area = c_area ) ).

        ENDIF.


      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD validateEndDAte.

  CONSTANTS c_area TYPE STRING VALUE 'EDATE'.

    DATA error TYPE TABLE FOR FAILED LATE z03_r_travel.
    READ ENTITIES OF z03_r_travel IN LOCAL MODE
    ENTITY Travel
    FIELDS ( EndDate )
    WITH CORRESPONDING #( keys )
    RESULT DATA(travels).

    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travels>).

        reported-travel = VALUE #( ( %tky = <travels>-%tky
                                     %state_area = c_area ) ).

      IF <travels>-EndDate IS INITIAL.

        error = VALUE #( ( %tky = <travels>-%tky ) ).
        failed-travel = error.
        reported-travel = VALUE #( ( %tky = <travels>-%tky
                                     %msg = NEW /lrn/cm_s4d437( /lrn/cm_s4d437=>field_empty )
                                     %element-enddate = if_abap_behv=>mk-on
                                     %state_area = c_area ) ).

      ELSE.

        IF <travels>-EndDate < cl_abap_context_info=>get_system_date( ).

          error = VALUE #( ( %tky = <travels>-%tky ) ).
          failed-travel = error.
          reported-travel = VALUE #( ( %tky = <travels>-%tky
                                       %msg = NEW /lrn/cm_s4d437( begindate = <travels>-EndDate
                                                                  textid = /lrn/cm_s4d437=>end_date_past )
                                       %element-enddate = if_abap_behv=>mk-on
                                       %state_area = c_area ) ).

        ENDIF.


      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD validateDateSequence.

  CONSTANTS c_area TYPE STRING VALUE 'DATSEQ'.

    READ ENTITIES OF Z03_R_Travel IN LOCAL MODE
    ENTITY Travel FIELDS ( BeginDate EndDate )
     WITH CORRESPONDING #( keys )
     RESULT DATA(travels).

    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).

        reported-travel = VALUE #( ( %tky = <travel>-%tky
                                     %state_area = c_area ) ).
      IF <travel>-EndDate < <travel>-BeginDate.
        APPEND VALUE #( %tky = <travel>-%tky ) TO failed-travel.
        APPEND VALUE #( %tky = <travel>-%tky
                        %msg = NEW /lrn/cm_s4d437( /lrn/cm_s4d437=>dates_wrong_sequence )
                        %element = VALUE #( BeginDate = if_abap_behv=>mk-on
                                            EndDate = if_abap_behv=>mk-on )
                        %state_area = c_area ) TO reported-travel.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD earlynumbering_create.

    DATA(agencyid) = /lrn/cl_s4d437_model=>get_agency_by_user(  ).

    mapped-travel = CORRESPONDING #( entities ).

    LOOP AT mapped-travel ASSIGNING FIELD-SYMBOL(<mapping>).
        <mapping>-AgencyId = agencyid.
        <mapping>-TravelId = /lrn/cl_s4d437_model=>get_next_travelid(  ).
    ENDLOOP.
  ENDMETHOD.

  METHOD determineStatus.

  READ ENTITIES OF z03_r_travel IN LOCAL MODE
    ENTITY Travel
    FIELDS ( Status )
    WITH CORRESPONDING #( keys )
    RESULT DATA(travels).

    DELETE travels WHERE Status IS NOT INITIAL.
    CHECK travels IS NOT INITIAL.

    MODIFY ENTITIES OF z03_r_travel IN LOCAL MODE
    ENTITY Travel
    UPDATE FIELDS ( Status  )
    WITH VALUE #( for key in travels ( %tky = key-%tky Status = 'N' ) )
    REPORTED DATA(update_reported).

    reported = CORRESPONDING #( DEEP update_reported ).


  ENDMETHOD.

  METHOD determineStatusSave.

  READ ENTITIES OF z03_r_travel IN LOCAL MODE
    ENTITY Travel
    FIELDS ( Status )
    WITH CORRESPONDING #( keys )
    RESULT DATA(travels).

    DELETE travels WHERE Status IS NOT INITIAL.
    CHECK travels IS NOT INITIAL.

    MODIFY ENTITIES OF z03_r_travel IN LOCAL MODE
    ENTITY Travel
    UPDATE FIELDS ( Status  )
    WITH VALUE #( for key in travels ( %tky = key-%tky Status = 'N' ) )
    REPORTED DATA(update_reported).

    reported = CORRESPONDING #( DEEP update_reported ).
  ENDMETHOD.

  METHOD get_instance_features.

    READ ENTITIES OF z03_r_travel IN LOCAL MODE
    ENTITY Travel
    FIELDS ( Status BeginDate EndDate )
    WITH CORRESPONDING #( keys )
    RESULT DATA(travels).

    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).

        APPEND CORRESPONDING #( <travel> ) TO result ASSIGNING FIELD-SYMBOL(<result>).

        IF <travel>-%is_draft = if_abap_behv=>mk-on.
            READ ENTITIES OF Z03_R_Travel IN LOCAL MODE
            ENTITY Travel FIELDS ( BeginDate EndDate )
            WITH VALUE #( ( %key = <travel>-%key ) )
            RESULT DATA(travels_active).

            IF travels_active IS NOT INITIAL.
                <travel>-BeginDate = travels_active[ 1 ]-BeginDate.
                <travel>-EndDate = travels_active[ 1 ]-EndDate.
            ELSE.
                CLEAR <travel>-BeginDate.
                CLEAR <travel>-EndDate.
            ENDIF.
        ENDIF.

        IF <travel>-Status = 'C' OR
           ( <travel>-EndDate IS NOT INITIAL AND <travel>-EndDate < cl_abap_context_info=>get_system_date( ) ).
            <result>-%update = if_abap_behv=>fc-o-disabled.
            <result>-%action-cancel_travel = if_abap_behv=>fc-o-disabled.
        ELSE.
            <result>-%update = if_abap_behv=>fc-o-enabled.
            <result>-%action-cancel_travel = if_abap_behv=>fc-o-enabled.
        ENDIF.

        IF  <travel>-BeginDate IS NOT INITIAL AND <travel>-BeginDate < cl_abap_context_info=>get_system_date( ).
            <result>-%field-BeginDate = if_abap_behv=>fc-f-read_only.
            <result>-%field-CustomerId = if_abap_behv=>fc-f-read_only.
        ELSE.
            <result>-%field-BeginDate = if_abap_behv=>fc-f-mandatory.
            <result>-%field-CustomerId = if_abap_behv=>fc-f-mandatory.
        ENDIF.

        IF ( <travel>-EndDate - <travel>-BeginDate ) > 20.
            <result>-%field-CustomerId = if_abap_behv=>fc-f-read_only.
        ELSE.
            <result>-%field-CustomerId = if_abap_behv=>fc-f-unrestricted.
        ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD determineDuration.

    READ ENTITIES OF z03_r_travel IN LOCAL MODE
    ENTITY Travel
    FIELDS ( BeginDate EndDate )
    WITH CORRESPONDING #( keys )
    RESULT DATA(travels).

    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).
      <travel>-Duration = <travel>-EndDate - <travel>-BeginDate.

    ENDLOOP.

    MODIFY ENTITIES OF z03_r_travel IN LOCAL MODE
    ENTITY Travel
    UPDATE FIELDS ( Duration )
    WITH CORRESPONDING #( travels ).
  ENDMETHOD.

ENDCLASS.
