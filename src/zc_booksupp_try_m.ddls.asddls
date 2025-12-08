@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Booking supp projection view managed'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true

define view entity ZC_BOOKSUPP_TRY_M
  as projection on ZI_BOOKSUPP_TRY_M
{
  key TravelId,
  key BookingId,
  key BookingSupplementId,
      @ObjectModel.text.element: [ 'SupplimentDesc' ]
      SupplementId,
      _SuppText.Description as SupplimentDesc : localized,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      Price,
      CurrencyCode,
      LastChangedAt,
      /* Associations */
      _Bookingsup : redirected to parent ZC_BOOKING_TRY_M,
      _Suppl,
      _SuppText,
      _Travel     : redirected to ZC_TRAVEL_TR_M
}
