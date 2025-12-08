CLASS lhc_ZI_TRAVEL_TRY_M DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys
                  REQUEST requested_authorizations
                  FOR zi_travel_try_m
      RESULT    result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR zi_travel_try_m RESULT result.


    METHODS earlynumbering_cba_booking FOR NUMBERING
      IMPORTING entities
                  FOR CREATE zi_travel_try_m\_booking.

    METHODS earlynumbering_create FOR NUMBERING
      IMPORTING entities
                  FOR CREATE zi_travel_try_m.

ENDCLASS.

CLASS lhc_ZI_TRAVEL_TRY_M IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD get_global_authorizations.

  ENDMETHOD.

  METHOD earlynumbering_create.

    DATA(lt_entities) = entities.
    DELETE lt_entities WHERE TravelId IS NOT INITIAL.
    TRY.
        cl_numberrange_runtime=>number_get(
          EXPORTING
*            ignore_buffer     =
            nr_range_nr       =  '01'
            object            = '/DMO/TRV_M'
            quantity          = CONV #( lines( lt_entities ) )
*            subobject         =
*            toyear            =
             IMPORTING
             number            = DATA(lv_latest_num)
             returncode        = DATA(lv_code)
          returned_quantity = DATA(lv_qty)
        ).
      CATCH cx_nr_object_not_found.
      CATCH cx_number_ranges INTO DATA(lo_error).

        LOOP AT lt_entities  INTO DATA(ls_entities).
          APPEND VALUE #( %cid =  ls_entities-%cid
                         %key = ls_entities-%key )
                           TO failed-zi_travel_try_m.

          APPEND VALUE #( %cid =  ls_entities-%cid
                          %key = ls_entities-%key
                          %msg =  lo_error )
                            TO reported-zi_travel_try_m.
        ENDLOOP.
        EXIT.
    ENDTRY.
    ASSERT lv_qty = lines( lt_entities ).
    DATA:lt_TRAVEL_TRY_M TYPE TABLE FOR MAPPED EARLY zi_travel_try_m,
         ls_travel_try_m LIKE LINE OF lt_TRAVEL_TRY_M.
    DATA(lv_curr_num) = lv_latest_num - lv_qty.

    LOOP AT lt_entities  INTO ls_entities.
      lv_curr_num += lv_curr_num + 1 .
      ls_travel_try_m = VALUE #( %cid =  ls_entities-%cid TravelId = lv_curr_num ).
      APPEND ls_travel_try_m TO mapped-zi_travel_try_m.
    ENDLOOP.

  ENDMETHOD.

  METHOD earlynumbering_cba_Booking.

    DATA : lv_max_booking TYPE /dmo/booking_id.

    READ ENTITIES OF zi_travel_try_m IN LOCAL MODE
        ENTITY zi_travel_try_m BY \_Booking
        FROM CORRESPONDING #( entities )
        LINK DATA(lt_link_data).


    LOOP AT entities ASSIGNING FIELD-SYMBOL(<ls_group_entity>)
                                GROUP BY <ls_group_entity>-TravelId .

    lv_max_booking = REDUCE #( INIT lv_max = CONV /dmo/booking_id( '0' )
                               FOR ls_link IN lt_link_data USING KEY entity
                                    WHERE ( source-TravelId = <ls_group_entity>-TravelId  )
                               NEXT  lv_max = COND  /dmo/booking_id( WHEN lv_max < ls_link-target-BookingId
                                                                     THEN ls_link-target-BookingId
                                                                      ELSE lv_max ) ).

      lv_max_booking = REDUCE #(  INIT lv_max = lv_max_booking
                                  FOR ls_entity IN entities USING KEY entity
                                  WHERE (  TravelId = <ls_group_entity>-TravelId )
                                  FOR ls_booking IN ls_entity-%target
                                  NEXT lv_max = COND /dmo/booking_id( WHEN lv_max < ls_booking-BookingId
                                                                  THEN ls_booking-BookingId
                                                                  ELSE lv_max )
    ).

    Loop at entities assigning FIELD-SYMBOL(<ls_entities>)
                        USING KEY entity
                        WHERE TravelId = <ls_group_entity>-TravelId.

    loop at <ls_group_entity>-%target assigning FIELD-SYMBOL(<ls_booking>).
    if <ls_booking>-BookingId is INITIAL.
        lv_max_booking += 10.
        APPEND CORRESPONDING #( <ls_booking> ) to mapped-zi_booking_try_m
        ASSIGNING FIELD-SYMBOL(<ls_new_map_book>).

        <ls_new_map_book>-BookingId = lv_max_booking.


    ENDIF.

    ENDLOOP.

    ENDLOOP.

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
