CLASS lhc_item DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS ZZValidateClass FOR VALIDATE ON SAVE
      IMPORTING keys FOR Item~ZZValidateClass.

ENDCLASS.

CLASS lhc_item IMPLEMENTATION.

  METHOD ZZValidateClass.
    CONSTANTS c_area TYPE string VALUE 'CLASS'.

    READ ENTITIES OF z03_r_travel IN LOCAL MODE
      ENTITY item
      FIELDS ( agencyid travelid ZZClassZ03 )
      WITH CORRESPONDING #( keys )
      RESULT DATA(items).

    LOOP AT items ASSIGNING FIELD-SYMBOL(<item>).

      APPEND VALUE #( %tky = <item>-%tky
                      %state_area = c_area
                     )
          TO reported-item.

      IF <item>-ZZClassZ03 IS INITIAL.

        APPEND VALUE #(  %tky = <item>-%tky )
            TO failed-item.

        APPEND VALUE #( %tky = <item>-%tky
                        %msg = NEW /lrn/cm_s4d437(
                                     /lrn/cm_s4d437=>field_empty
                                   )
                        %element-ZZClassZ03 = if_abap_behv=>mk-on
                        %state_area = c_area
                        %path-travel = CORRESPONDING #( <item> )
                       )
            TO reported-item.
      ELSE.

        SELECT SINGLE
          FROM /lrn/437_i_classstdvh
        FIELDS classid
         WHERE classid = @<item>-ZZClassZ03
          INTO @DATA(dummy).

        IF sy-subrc <> 0.

          APPEND VALUE #(  %tky = <item>-%tky )
              TO failed-item.

          APPEND VALUE #( %tky = <item>-%tky
                          %msg = NEW /lrn/cm_s4d437(
                                       textid   = /lrn/cm_s4d437=>class_not_exist
                                       classid  = <item>-ZZClassZ03
                                     )
                          %element-ZZClassZ03 = if_abap_behv=>mk-on
                          %state_area = c_area
                        %path-travel = CORRESPONDING #( <item> )
                         )
          TO reported-item.

        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.

CLASS lsc_Z03_R_TRAVEL DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.

    METHODS save_modified REDEFINITION.

    METHODS cleanup_finalize REDEFINITION.

ENDCLASS.

CLASS lsc_Z03_R_TRAVEL IMPLEMENTATION.

  METHOD save_modified.
    LOOP AT update-item ASSIGNING FIELD-SYMBOL(<item_u>)
            WHERE %control-ZZClassZ03 = if_abap_behv=>mk-on.
        UPDATE z03_tritem
            SET zzclassz03 = @<item_u>-ZZClassZ03
            WHERE item_uuid = @<item_u>-ItemUuid.

    ENDLOOP.
    LOOP AT create-item ASSIGNING FIELD-SYMBOL(<item_c>)
            WHERE %control-ZZClassZ03 = if_abap_behv=>mk-on.
        UPDATE z03_tritem
            SET zzclassz03 = @<item_c>-ZZClassZ03
            WHERE item_uuid = @<item_c>-ItemUuid.

    ENDLOOP.
  ENDMETHOD.

  METHOD cleanup_finalize.
  ENDMETHOD.

ENDCLASS.
