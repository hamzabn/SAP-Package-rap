CLASS zcl_read_try_practice DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_read_try_practice IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.

*   ------------------------------ Read Short form ----------------------------------
*    READ entity zi_travel_try_m
*    by \_Booking
*    ALL FIELDS
*    WITH VALUE #( ( %key-TravelId = '12345' )
*                  ( %key-TravelId = '8659' )
*)
*    RESULT data(lt_result_short)
*    FAILED data(lt_failed_sort).
*
*    IF lt_failed_sort is NOT INITIAL.
*        out->write( 'read failed' ).
*
*    else.
*    out->write(  lt_result_short ).
*    ENDIF.
*   --------------------------- Read long form ------------------------------------
*    READ ENTITIES OF zi_travel_try_m
*    ENTITY zi_travel_try_m
*    ALL FIELDS
*    WITH VALUE #( ( %key-TravelId = '12345' )
*                  ( %key-TravelId = '8659' )
*)
*    RESULT data(lt_result_Travel)
*
*    ENTITY zi_booking_try_m
*    ALL FIELDS WITH VALUE #( ( %key-TravelId = '12345'
*                                %key-BookingId = '5432' )
*                          )
*    RESULT DATA(lt_result_book)
*
*
*    FAILED data(lt_failed_sort).
*    IF lt_failed_sort is NOT INITIAL.
*        out->write( 'read failed' ).
*
*    else.
*    out->write(  lt_result_Travel ).
*    out->write(  lt_result_book ).
*    ENDIF.
*   --------------------------- Read Dynamic form ------------------------------------

    DATA : it_optab         TYPE abp_behv_retrievals_tab,
           it_travel        TYPE TABLE FOR READ IMPORT zi_travel_try_m,
           it_travel_result TYPE TABLE FOR READ RESULT zi_travel_try_m,
           it_booking       TYPE TABLE FOR READ IMPORT zi_travel_try_m\_Booking,
           it_booking_result TYPE TABLE FOR READ RESULT zi_travel_try_m\_booking.
    it_travel = VALUE #( ( %key-TravelId = '12345'
                           %control = VALUE #( AgencyID = if_abap_behv=>mk-on
                                        customerid = if_abap_behv=>mk-on
                                        begindate = if_abap_behv=>mk-on
                                        totalprice = if_abap_behv=>mk-on
) ) ).
    it_booking = VALUE #( ( %key-TravelId = '8659'
                            %control = VALUE #( bookingDate = if_abap_behv=>mk-on
                                                BookingStatus = if_abap_behv=>mk-on
                                                bookingId = if_abap_behv=>mk-on )
                                   ) ).
    it_optab = VALUE #( ( op = if_abap_behv=>op-r-read
                                entity_name = 'ZI_TRAVEL_TRY_M'
                                instances = REF #( it_travel )
                                results =  REF #( it_travel_result ) )
                                ( op = if_abap_behv=>op-r-read_ba
                                entity_name = 'ZI_TRAVEL_TRY_M'
                                sub_name = '_BOOKING'
                                instances = REF #( it_booking )
                                results =  REF #( it_booking_result )
          ) ).
    READ ENTITIES
        OPERATIONS it_optab
        FAILED DATA(lt_failed_dy).
    IF lt_failed_dy IS NOT INITIAL.
      out->write( 'read failed' ).
    ELSE.
      out->write(  it_travel_result ).
      out->write(  it_booking_result ).
    ENDIF.

  ENDMETHOD.
ENDCLASS.
