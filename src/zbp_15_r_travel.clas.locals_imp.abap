CLASS lsc_z15_r_travel DEFINITION INHERITING FROM cl_abap_behavior_saver.

  PROTECTED SECTION.

    METHODS save_modified REDEFINITION.

  PRIVATE SECTION.
    METHODS map_message
      IMPORTING
        i_msg        TYPE symsg
      RETURNING
        VALUE(r_msg) TYPE REF TO if_abap_behv_message.

ENDCLASS.

CLASS lsc_z15_r_travel IMPLEMENTATION.

  METHOD save_modified .

    DATA(model) = NEW /lrn/cl_s4d437_tritem( i_table_name = 'Z15_TRITEM' ).

    LOOP AT delete-item ASSIGNING FIELD-SYMBOL(<item_d>).
*      model->delete_item( i_uuid = <item_d>-itemuuid ).

      DATA(msg_d) = model->delete_item( <item_d>-itemuuid ).

      IF msg_d IS NOT INITIAL.
        APPEND VALUE #( %tky-itemuuid = <item_d>-itemuuid
                        %msg = map_message( msg_d ) )
            TO reported-item.
      ENDIF.

    ENDLOOP.

    LOOP AT create-item ASSIGNING FIELD-SYMBOL(<item_c>).
*      model->create_item( i_item = CORRESPONDING #( <item_c> MAPPING FROM ENTITY ) ).

      DATA(msg_c) = model->create_item( CORRESPONDING #( <item_c> MAPPING FROM ENTITY ) ).

      IF msg_c IS NOT INITIAL.
        APPEND VALUE #( %tky-itemuuid = <item_c>-itemuuid
                        %msg = map_message( msg_c ) )
            TO reported-item.
      ENDIF.

    ENDLOOP.


    LOOP AT update-item ASSIGNING FIELD-SYMBOL(<item_u>).
*      model->update_item( i_item    = CORRESPONDING #( <item_u> MAPPING FROM ENTITY )
*                          i_itemx   = CORRESPONDING #( <item_u> MAPPING FROM ENTITY USING CONTROL )
*                        ).

      DATA(msg_u) = model->update_item( i_item  = CORRESPONDING #( <item_u> MAPPING FROM ENTITY )
                                        i_itemx = CORRESPONDING #( <item_u> MAPPING FROM ENTITY USING CONTROL ) ).

      IF msg_u IS NOT INITIAL.
        APPEND VALUE #( %tky-itemuuid = <item_u>-itemuuid
                        %msg = map_message( msg_u ) )
            TO reported-item.
      ENDIF.
    ENDLOOP.

    IF create-travel IS NOT INITIAL.
*        RAISE ENTITY EVENT Z15_R_Travel~TravelCreated
*            FROM CORRESPONDING #( create-travel ) .
      DATA event_in TYPE TABLE FOR EVENT Z15_R_Travel~TravelCreated.

      LOOP AT create-travel ASSIGNING FIELD-SYMBOL(<new_travel>) .
        APPEND VALUE #(
            AgencyId = <new_travel>-AgencyId
            TravelId = <new_travel>-TravelId
            origin = 'Z15_R_TRAVEL' )
           TO event_in.
      ENDLOOP.

      RAISE ENTITY EVENT Z15_R_Travel~TravelCreated FROM event_in.

    ENDIF.

  ENDMETHOD.

  METHOD map_message.

    DATA(severity) = SWITCH #( i_msg-msgty
            WHEN 'S' THEN if_abap_behv_message=>severity-success
            WHEN 'I' THEN if_abap_behv_message=>severity-information
            WHEN 'W' THEN if_abap_behv_message=>severity-warning
            WHEN 'E' THEN if_abap_behv_message=>severity-error
            ELSE          if_abap_behv_message=>severity-none ).

    r_msg = new_message(
                id       = i_msg-msgid
                number   = i_msg-msgno
                severity = severity
                v1       = i_msg-msgv1
                v2       = i_msg-msgv2
                v3       = i_msg-msgv3
                v4       = i_msg-msgv4 ).


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

  METHOD validateFlightDate .

    CONSTANTS c_area TYPE string VALUE `FLIGHTDATE`.

    READ ENTITIES OF Z15_R_Travel IN LOCAL MODE
        ENTITY Item
        FIELDS ( AgencyId TravelId FlightDate )
        WITH CORRESPONDING #( keys )
        RESULT DATA(items).
    LOOP AT items ASSIGNING FIELD-SYMBOL(<item>).
      APPEND VALUE #(
            %tky = <item>-%tky
            %state_area = c_area )
        TO reported-item.
      IF <item>-FlightDate IS INITIAL.
        APPEND VALUE #(
                %tky = <item>-%tky )
            TO failed-item.
        APPEND VALUE #(
                %tky = <item>-%tky
                %msg = NEW /lrn/cm_s4d437( /lrn/cm_s4d437=>field_empty )
                %element-FlightDate = if_abap_behv=>mk-on
                %state_area = c_area
                %path-travel = CORRESPONDING #( <item> ) )
            TO reported-item.

      ELSEIF <item>-FlightDate < cl_abap_context_info=>get_system_date( ).

        APPEND VALUE #(
                %tky = <item>-%tky )
            TO failed-item.
        APPEND VALUE #(
                %tky = <item>-%tky
                %msg = NEW /lrn/cm_s4d437( /lrn/cm_s4d437=>flight_date_past )
                %element-FlightDate = if_abap_behv=>mk-on
                %state_area = c_area
                %path-travel = CORRESPONDING #( <item> ) )
            TO reported-item.

      ENDIF.

    ENDLOOP.


  ENDMETHOD.

  METHOD determineTravelDates.

    READ ENTITIES OF Z15_R_Travel IN LOCAL MODE
      ENTITY Item
      FIELDS ( FlightDate )
      WITH CORRESPONDING #( keys )
      RESULT DATA(items)

      BY \_Travel
      FIELDS ( BeginDate EndDate )
      WITH CORRESPONDING #( keys )
      RESULT DATA(travels)
      LINK DATA(link)
      .

    LOOP AT items ASSIGNING FIELD-SYMBOL(<item>).
* 3 possibilities to get the same result
*1st
*   READ TABLE travels
*       ASSIGNING FIELD-SYMBOL(<travel>)
*       WITH KEY %tky = link[ source-%tky = <item>-%tky ]-target-%tky.
*2nd
      ASSIGN travels[
          KEY id %tky = link[
              KEY id source-%tky = <item>-%tky ]-target-%tky ]
          TO FIELD-SYMBOL(<travel>).
*3rd
*      ASSIGN travels[
*              %tky = link[ source-%tky = <item>-%tky ]-target-%tky ]
*          TO FIELD-SYMBOL(<travel>).
      IF <travel>-EndDate < <item>-FlightDate.
        <travel>-EndDate = <item>-FlightDate.
      ENDIF.

      IF <item>-FlightDate > cl_abap_context_info=>get_system_date( )
          AND <item>-FlightDate < <travel>-BeginDate.
        <travel>-BeginDate = <item>-FlightDate.
      ENDIF.

    ENDLOOP.

    MODIFY ENTITIES OF Z15_R_Travel IN LOCAL MODE
        ENTITY Travel
        UPDATE FIELDS ( BeginDate EndDate )
        WITH CORRESPONDING #( travels ).


  ENDMETHOD.

ENDCLASS.

CLASS lhc_travel DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR travel RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR travel RESULT result.

    METHODS cancel_travel FOR MODIFY
      IMPORTING keys FOR ACTION travel~cancel_travel.
    METHODS validatedescription FOR VALIDATE ON SAVE
      IMPORTING keys FOR travel~validatedescription.
    METHODS validatecustomer FOR VALIDATE ON SAVE
      IMPORTING keys FOR travel~validatecustomer.
    METHODS determinestatus FOR DETERMINE ON MODIFY
      IMPORTING keys FOR travel~determinestatus.
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR travel RESULT result.
    METHODS determineduration FOR DETERMINE ON SAVE
      IMPORTING keys FOR travel~determineduration.
    METHODS earlynumbering_create FOR NUMBERING
      IMPORTING entities FOR CREATE travel.

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

    READ ENTITIES OF Z15_R_Travel
      IN LOCAL MODE ENTITY Travel
       ALL FIELDS
       WITH CORRESPONDING #( keys )
       RESULT DATA(travels).

    LOOP AT travels INTO DATA(travel).

      IF travel-status <> 'C'.
        MODIFY ENTITIES OF Z15_R_Travel IN LOCAL MODE
           ENTITY Travel
           UPDATE
           FIELDS ( status )
           WITH VALUE #( ( %tky = travel-%tky status = 'C' ) ).
      ELSE.
        APPEND VALUE #( %tky = travel-%tky ) TO failed-travel.
        APPEND VALUE #( %tky = travel-%tky
                        %msg = NEW /lrn/cm_s4d437(
                                    textid = /lrn/cm_s4d437=>already_canceled ) )
               TO reported-travel.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD validateDescription .

    CONSTANTS c_area TYPE string VALUE `DESC`.

    READ ENTITIES OF Z15_R_Travel IN LOCAL MODE
    ENTITY Travel
    FIELDS ( Description )
    WITH CORRESPONDING #( keys )
     RESULT DATA(travels).
    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).

      APPEND VALUE #(
          %tky = <travel>-%tky
          %state_area = c_area )
      TO reported-travel.

      IF <travel>-Description IS INITIAL.

        APPEND VALUE #( %tky = <travel>-%tky ) TO failed-travel.

*        APPEND VALUE #( %tky = <travel>-%tky
*            %msg = NEW /lrn/cm_s4d437( /lrn/cm_s4d437=>field_empty )
*            %element-Description = if_abap_behv=>mk-on )
*        TO reported-travel.
        APPEND VALUE #(
                %tky = <travel>-%tky
                %msg = NEW /lrn/cm_s4d437( /lrn/cm_s4d437=>field_empty )
                %element-Description = if_abap_behv=>mk-on
                %state_area = c_area )
            TO reported-travel.


      ENDIF.
    ENDLOOP.

  ENDMETHOD.



  METHOD validateCustomer .

    CONSTANTS c_area TYPE string VALUE `CUST`.

    READ ENTITIES OF Z15_R_Travel IN LOCAL MODE
        ENTITY Travel
        FIELDS ( CustomerId )
        WITH CORRESPONDING #( keys )
        RESULT DATA(travels).

    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).

      APPEND VALUE #(
              %tky = <travel>-%tky
              %state_area = c_area )
          TO reported-travel.

      IF <travel>-CustomerId IS INITIAL.
        APPEND VALUE #( %tky = <travel>-%tky )
            TO failed-travel.
*        APPEND VALUE #(
*                %tky = <travel>-%tky
*                %msg = NEW /lrn/cm_s4d437( /lrn/cm_s4d437=>field_empty )
*                %element-CustomerId = if_abap_behv=>mk-on )
*            TO reported-travel.

        APPEND VALUE #(
                %tky = <travel>-%tky
                %msg = NEW /lrn/cm_s4d437( /lrn/cm_s4d437=>field_empty )
                %element-CustomerId = if_abap_behv=>mk-on
                %state_area = c_area )
            TO reported-travel.

      ELSE.
        SELECT SINGLE FROM /dmo/i_customer
            FIELDS CustomerID
            WHERE CustomerID = @<travel>-CustomerId INTO @DATA(dummy).
        IF sy-subrc <> 0.
          APPEND VALUE #( %tky = <travel>-%tky ) TO failed-travel.
*          APPEND VALUE #(
*                  %tky = <travel>-%tky
*                  %msg = NEW /lrn/cm_s4d437(
*                      textid = /lrn/cm_s4d437=>customer_not_exist
*                      customerid = <travel>-CustomerId )
*                  %element-CustomerId = if_abap_behv=>mk-on )
*              TO reported-travel.

          APPEND VALUE #(
                  %tky = <travel>-%tky
                  %msg = NEW /lrn/cm_s4d437(
                      textid = /lrn/cm_s4d437=>customer_not_exist
                      customerid = <travel>-CustomerId )
                  %element-CustomerId = if_abap_behv=>mk-on
                  %state_area = c_area )
              TO reported-travel.
        ENDIF.
      ENDIF.
    ENDLOOP.


  ENDMETHOD.

  METHOD earlynumbering_create .

    DATA(agencyid) = /lrn/cl_s4d437_model=>get_agency_by_user( ) .

    mapped-travel = CORRESPONDING #( entities ).

    LOOP AT mapped-travel ASSIGNING FIELD-SYMBOL(<mapping>).

      <mapping>-AgencyId = agencyid.
      <mapping>-TravelId = /lrn/cl_s4d437_model=>get_next_travelid( ).

    ENDLOOP.

  ENDMETHOD.

  METHOD determineStatus.

    READ ENTITIES OF Z15_R_Travel IN LOCAL MODE
      ENTITY Travel
      FIELDS ( Status )
      WITH CORRESPONDING #( keys )
      RESULT DATA(travels) .

    DELETE travels WHERE Status IS NOT INITIAL.
    CHECK travels IS NOT INITIAL.

    MODIFY ENTITIES OF Z15_R_Travel IN LOCAL MODE
      ENTITY Travel
      UPDATE
      FIELDS ( Status )
      WITH VALUE #( FOR key IN travels (
              %tky = key-%tky Status = 'N' )
               )
      REPORTED DATA(update_reported).
    reported = CORRESPONDING #( DEEP update_reported ).

  ENDMETHOD.

  METHOD get_instance_features.

    READ ENTITIES OF Z15_R_Travel IN LOCAL MODE
      ENTITY Travel
      FIELDS ( Status BeginDate EndDate )
      WITH CORRESPONDING #( keys )
      RESULT DATA(travels).
    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).

      APPEND CORRESPONDING #( <travel> ) TO result
      ASSIGNING FIELD-SYMBOL(<result>).

      IF <travel>-%is_draft = if_abap_behv=>mk-on.
        READ ENTITIES OF Z15_R_Travel IN LOCAL MODE
            ENTITY Travel
            FIELDS ( BeginDate EndDate )
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

*      IF <travel>-Status = 'C' OR
*      ( <travel>-EndDate IS NOT INITIAL AND
*          <travel>-EndDate < cl_abap_context_info=>get_system_date( ) ).
*
*        <result>-%update = if_abap_behv=>fc-o-disabled.
*        <result>-%action-cancel_travel = if_abap_behv=>fc-o-disabled.
*      ELSE.
*        <result>-%update = if_abap_behv=>fc-o-enabled.
*        <result>-%action-cancel_travel = if_abap_behv=>fc-o-enabled.
*      ENDIF.
*
*      IF <travel>-BeginDate IS NOT INITIAL AND
*          <travel>-BeginDate < cl_abap_context_info=>get_system_date( ).
*
*        <result>-%field-CustomerId = if_abap_behv=>fc-f-read_only.
*        <result>-%field-BeginDate = if_abap_behv=>fc-f-read_only.
*
*      ELSE.
*        <result>-%field-CustomerId = if_abap_behv=>fc-f-mandatory.
*        <result>-%field-BeginDate = if_abap_behv=>fc-f-mandatory.
*
*      ENDIF.


    ENDLOOP.

  ENDMETHOD.

  METHOD determineDuration .

    READ ENTITIES OF Z15_R_Travel IN LOCAL MODE
        ENTITY Travel
        FIELDS ( BeginDate EndDate )
        WITH CORRESPONDING #( keys )
        RESULT DATA(travels).
    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).
      <travel>-Duration = <travel>-EndDate - <travel>-BeginDate.
    ENDLOOP.
    MODIFY ENTITIES OF Z15_R_Travel IN LOCAL MODE
        ENTITY Travel
        UPDATE FIELDS ( Duration )
        WITH CORRESPONDING #( travels ).

  ENDMETHOD.

ENDCLASS.
