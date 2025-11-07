CLASS lsc_Z15_R_TRAVEL DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.

    METHODS save_modified REDEFINITION.

    METHODS cleanup_finalize REDEFINITION.

ENDCLASS.

CLASS lhc_item DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS /lrn/validateclass FOR VALIDATE ON SAVE
      IMPORTING keys FOR item~ZZvalidateClass.

ENDCLASS.


CLASS lsc_Z15_R_TRAVEL IMPLEMENTATION.

  METHOD save_modified.


    LOOP AT update-item ASSIGNING FIELD-SYMBOL(<item>)
         WHERE %control-ZZClassZ15 = if_abap_behv=>mk-on.

      UPDATE z15_tritem
        SET zzclassz15 = @<item>-ZZClassZ15
        WHERE item_uuid = @<item>-ItemUuid.

    ENDLOOP.


        LOOP AT create-item ASSIGNING <item>
         WHERE %control-ZZClassZ15 = if_abap_behv=>mk-on.

      UPDATE z15_tritem
        SET zzclassz15 = @<item>-ZZClassZ15
        WHERE item_uuid = @<item>-ItemUuid.

    ENDLOOP.

  ENDMETHOD.

  METHOD cleanup_finalize.
  ENDMETHOD.

ENDCLASS.


CLASS lhc_item IMPLEMENTATION.

  METHOD /lrn/validateclass.

    CONSTANTS c_area TYPE string VALUE `CLASS`.

    READ ENTITIES OF z15_r_travel IN LOCAL MODE
      ENTITY item
      FIELDS ( agencyid travelid ZZClassZ15 )
      WITH CORRESPONDING #( keys )
      RESULT DATA(items).

    LOOP AT items ASSIGNING FIELD-SYMBOL(<item>).

      APPEND VALUE #( %tky = <item>-%tky
                      %state_area = c_area
                     )
          TO reported-item.

      IF <item>-ZZClassZ15 IS INITIAL.

        APPEND VALUE #(  %tky = <item>-%tky )
            TO failed-item.

        APPEND VALUE #( %tky = <item>-%tky
                        %msg = NEW /lrn/cm_s4d437(
                                     /lrn/cm_s4d437=>field_empty
                                   )
                        %element-ZZClassZ15 = if_abap_behv=>mk-on
                        %state_area = c_area
                        %path-travel = CORRESPONDING #( <item> )
                       )
            TO reported-item.
      ELSE.

        SELECT SINGLE
          FROM /lrn/437_i_classstdvh
        FIELDS classid
         WHERE classid = @<item>-ZZClassZ15
          INTO @DATA(dummy).

        IF sy-subrc <> 0.

          APPEND VALUE #(  %tky = <item>-%tky )
              TO failed-item.

          APPEND VALUE #( %tky = <item>-%tky
                          %msg = NEW /lrn/cm_s4d437(
                                       textid   = /lrn/cm_s4d437=>class_not_exist
                                       classid  = <item>-ZZClassZ15
                                     )
                          %element-ZZClassZ15 = if_abap_behv=>mk-on
                          %state_area = c_area
                        %path-travel = CORRESPONDING #( <item> )
                         )
          TO reported-item.

        ENDIF.
      ENDIF.
    ENDLOOP.


  ENDMETHOD.

ENDCLASS.
