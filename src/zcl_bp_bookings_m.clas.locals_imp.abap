CLASS lhc_zi_booking_try_m DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS earlynumbering_cba_Bookingsupp FOR NUMBERING
      IMPORTING entities FOR CREATE ZI_BOOKING_TRY_M\_Bookingsupp.

ENDCLASS.

CLASS lhc_zi_booking_try_m IMPLEMENTATION.

  METHOD earlynumbering_cba_Bookingsupp.
  ENDMETHOD.

ENDCLASS.

*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations
