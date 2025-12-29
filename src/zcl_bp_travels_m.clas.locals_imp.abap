CLASS lhc_ZI_TRAVEL_TRY_M DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys
                  REQUEST requested_authorizations
                  FOR zi_travel_try_m
      RESULT    result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR zi_travel_try_m RESULT result.

*-------------- Action methods -------------------------------------------

    METHODS accepttravel FOR MODIFY
      IMPORTING keys FOR ACTION zi_travel_try_m~accepttravel RESULT result.

    METHODS copytravel FOR MODIFY
      IMPORTING keys FOR ACTION zi_travel_try_m~copytravel.

    METHODS recalctotprice FOR MODIFY
      IMPORTING keys FOR ACTION zi_travel_try_m~recalctotprice.

    METHODS rejecttravel FOR MODIFY
      IMPORTING keys FOR ACTION zi_travel_try_m~rejecttravel RESULT result.



    METHODS earlynumbering_cba_booking FOR NUMBERING
      IMPORTING entities
                  FOR CREATE zi_travel_try_m\_booking.

    METHODS earlynumbering_create FOR NUMBERING
      IMPORTING entities
                  FOR CREATE zi_travel_try_m.
*-------------------------------------------------------------------------

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

            nr_range_nr       =  '01'
            object            = '/DMO/TRV_M'
            quantity          = CONV #( lines( lt_entities ) )
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

      LOOP AT entities ASSIGNING FIELD-SYMBOL(<ls_entities>)
                          USING KEY entity
                          WHERE TravelId = <ls_group_entity>-TravelId.

        LOOP AT <ls_group_entity>-%target ASSIGNING FIELD-SYMBOL(<ls_booking>).

          APPEND CORRESPONDING #( <ls_booking> ) TO mapped-zi_booking_try_m
          ASSIGNING FIELD-SYMBOL(<ls_new_map_book>).
          IF <ls_booking>-BookingId IS INITIAL.
            lv_max_booking += 1.

            <ls_new_map_book>-BookingId = lv_max_booking.

          ENDIF.

        ENDLOOP.

      ENDLOOP.

    ENDLOOP.

  ENDMETHOD.

*--------------------- Accept Method implementation ----------------------

  METHOD acceptTravel.

    MODIFY ENTITIES OF zi_travel_try_m IN LOCAL MODE
    ENTITY zi_travel_try_m
    UPDATE FIELDS ( OverallStatus )
    WITH VALUE #( FOR ls_keys IN keys ( %tky = ls_keys-%tky
                                        OverallStatus = 'A' ) ).

    READ ENTITIES OF zi_travel_try_m IN LOCAL MODE
    ENTITY zi_travel_try_m
    ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT DATA(lt_result).

    result = VALUE #( FOR ls_result IN lt_result ( %tky = ls_result-%tky
                                               %param = ls_result ) ).
  ENDMETHOD.

*--------------------- COPY Method implementation ----------------------
  METHOD copyTravel.

    DATA : it_travel        TYPE TABLE FOR CREATE zi_travel_try_m,
           it_booking_cba   TYPE TABLE FOR CREATE zi_travel_try_m\_Booking,
           it_booksuppl_cba TYPE TABLE FOR CREATE zi_booking_try_m\_BookingSupp.

    READ TABLE keys ASSIGNING FIELD-SYMBOL(<ls_without_cid>) WITH KEY %cid = ''.
    ASSERT <ls_without_cid> IS NOT ASSIGNED.

    READ ENTITIES OF zi_travel_try_m IN LOCAL MODE
        ENTITY zi_travel_try_m
        ALL FIELDS WITH CORRESPONDING #( keys )
        RESULT DATA(lt_travel_r)
        FAILED DATA(lt_failed).

    READ ENTITIES OF zi_travel_try_m IN LOCAL MODE
        ENTITY zi_travel_try_m BY \_Booking
        ALL FIELDS WITH CORRESPONDING #( lt_travel_r )
        RESULT DATA(lt_booking_r).

    READ ENTITIES OF zi_travel_try_m IN LOCAL MODE
        ENTITY zi_booking_try_m BY \_BookingSupp
        ALL FIELDS WITH CORRESPONDING #( lt_booking_r )
        RESULT DATA(lt_booksupp_r).

    LOOP AT lt_travel_r ASSIGNING FIELD-SYMBOL(<ls_travel_r>).

      APPEND VALUE #( %cid = keys[ KEY entity TravelId = <ls_travel_r>-TravelId ]-%cid
                      %data = CORRESPONDING #( <ls_travel_r> EXCEPT TravelId ) )
                TO it_travel ASSIGNING FIELD-SYMBOL(<ls_travel>).

      <ls_travel>-BeginDate = cl_abap_context_info=>get_system_date(  ).
      <ls_travel>-EndDate = cl_abap_context_info=>get_system_date(  ) + 30.

      <ls_travel>-OverallStatus = 'O'.

      APPEND VALUE #( %cid_ref = <ls_travel>-%cid )
        TO it_booking_cba ASSIGNING FIELD-SYMBOL(<it_booking>).

      LOOP AT lt_booking_r ASSIGNING FIELD-SYMBOL(<ls_booking_r>)
                           USING KEY entity
                           WHERE TravelID =  <ls_travel_r>-TravelId.

        APPEND VALUE #( %cid = <ls_travel>-%cid && <ls_booking_r>-BookingId
                        %data = CORRESPONDING #( <ls_booking_r> EXCEPT TravelId ) )
                 TO <it_booking>-%target ASSIGNING FIELD-SYMBOL(<ls_booking_n>).
        <ls_booking_n>-BookingStatus = 'N'.


        APPEND VALUE #( %cid_ref = <ls_booking_n>-%cid )
               TO it_booksuppl_cba ASSIGNING FIELD-SYMBOL(<ls_booksupp>).

        LOOP AT lt_booksupp_r ASSIGNING FIELD-SYMBOL(<ls_booksupp_r>)
                                USING KEY entity
                                WHERE travelId = <ls_travel_r>-TravelId
                                AND bookingId = <ls_booking_r>-BookingId.

          APPEND VALUE #( %cid = <ls_travel>-%cid && <ls_booking_r>-BookingId && <ls_booksupp_r>-BookingSupplementId
                             %data = CORRESPONDING #( <ls_booksupp_r> EXCEPT TravelId BookingId ) )
                     TO <ls_booksupp>-%target.
        ENDLOOP.
      ENDLOOP.
    ENDLOOP.

    MODIFY ENTITIES OF zi_travel_try_m IN LOCAL MODE
           ENTITY zi_travel_try_m
           CREATE FIELDS ( AgencyId CustomerId BeginDate EndDate BookingFee TotalPrice CurrencyCode OverallStatus Description )
           WITH it_travel

           ENTITY zi_travel_try_m
           CREATE BY \_booking
           FIELDS ( BookingId BookingDate CustomerId CarrierId ConnectionId FlightDate FlightPrice currencyCode BookingStatus )
           WITH it_booking_cba

           ENTITY zi_booking_try_m
           CREATE BY \_BookingSupp
           FIELDS ( BookingSupplementId SupplementId Price CurrencyCode )
           WITH it_booksuppl_cba
           MAPPED DATA(it_mapped).

    mapped-zi_travel_try_m = it_mapped-zi_travel_try_m.


  ENDMETHOD.
*-------------------ReCalc_Price Method implementation------------------

  METHOD reCalcTotPrice.

  ENDMETHOD.

*---------------------REJECT Method implementation----------------------

  METHOD rejectTravel.

    MODIFY ENTITIES OF zi_travel_try_m IN LOCAL MODE
    ENTITY zi_travel_try_m
    UPDATE FIELDS ( OverallStatus )
    WITH VALUE #( FOR ls_keys IN keys ( %tky = ls_keys-%tky
                                        OverallStatus = 'X' ) ).

    READ ENTITIES OF zi_travel_try_m IN LOCAL MODE
    ENTITY zi_travel_try_m
    ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT DATA(lt_result).

    result = VALUE #( FOR ls_result IN lt_result ( %tky = ls_result-%tky
                                               %param = ls_result ) ).
  ENDMETHOD.

ENDCLASS.
