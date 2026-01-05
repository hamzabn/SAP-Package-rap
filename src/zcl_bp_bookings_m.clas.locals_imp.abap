CLASS lhc_zi_booking_try_m DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS earlynumbering_cba_Bookingsupp FOR NUMBERING
      IMPORTING entities FOR CREATE zi_booking_try_m\_Bookingsupp.

    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR ZI_BOOKING_TRY_M RESULT result.

ENDCLASS.

CLASS lhc_zi_booking_try_m IMPLEMENTATION.

  METHOD earlynumbering_cba_Bookingsupp.

    DATA: max_booking_suppl_id TYPE /dmo/booking_supplement_id.

    "Reading long form
    READ ENTITIES OF  zi_travel_try_m IN LOCAL MODE
        ENTITY zi_booking_try_m BY \_BookingSupp
        FROM CORRESPONDING #( entities )
        LINK DATA(booking_supplements).

    "Loop over all unique tky(travelID + BookingID)
    "%tky transactional key

    LOOP AT entities ASSIGNING FIELD-SYMBOL(<booking_group>) GROUP BY <booking_group>-%tky.

      "Get highest bookingsupplement_id from booking belonging to booking
      max_booking_suppl_id = REDUCE #( INIT max = CONV /dmo/booking_supplement_id( '0' )
                                       FOR booksuppl IN booking_supplements USING KEY entity
                                                                             WHERE ( source-TravelId = <booking_group>-TravelId
                                                                                    AND source-BookingId = <Booking_group>-BookingId )
                                       NEXT max = COND /dmo/booking_supplement_id( WHEN booksuppl-target-bookingsupplementid > max
                                                                                   THEN booksuppl-target-bookingsupplementid
                                                                                   ELSE max )
                                      ).
      "Get highest assigned bookingsupplement_id from incoming entities
      max_booking_suppl_id = REDUCE #( INIT max = max_booking_suppl_id
                                      FOR entity IN entities USING KEY entity
                                                              WHERE (  TravelId = <booking_group>-TravelId
                                                                      AND bookingId = <booking_group>-BookingId )
                                      FOR target IN entity-%target
                                      NEXT max = COND /dmo/booking_supplement_id( WHEN target-bookingsupplementid > max
                                                                                   THEN target-bookingsupplementid
                                                                                   ELSE max )
                                      ).

      "LOOP over all entries in entities with the same TravelId and BookingId
      LOOP AT entities ASSIGNING FIELD-SYMBOL(<booking>) USING KEY entity WHERE TravelId = <booking_group>-TravelId
                                                                          AND BookingId = <booking_group>-BookingId.

       "Assign new booking_supplement_id
       LOOP AT <booking>-%target ASSIGNING FIELD-SYMBOL(<booksuppl_wo_numbers>).
            APPEND CORRESPONDING #( <booksuppl_wo_numbers> ) TO mapped-zi_booksupp_try_m ASSIGNING FIELD-SYMBOL(<mapped_booksuppl>).
            IF <booksuppl_wo_numbers>-BookingSupplementId IS INITIAL.
            max_booking_suppl_id += 1.
            <mapped_booksuppl>-BookingSupplementId = max_booking_suppl_id .
            ENDIF.
            ENDLOOP.

            ENDLOOP.


    ENDLOOP.


  ENDMETHOD.

  METHOD get_instance_features.
  ENDMETHOD.

ENDCLASS.

*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations
