@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Booking supp interface view managed'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity ZI_BOOKSUPP_TRY_M
  as select from zbooksupp_try_m
  association        to parent ZI_BOOKING_TRY_M as _Bookingsup on  $projection.TravelId  = _Bookingsup.TravelId
                                                               and $projection.BookingId = _Bookingsup.BookingId
  association [1..1] to ZI_TRAVEL_TRY_M     as _Travel on $projection.TravelId = _Travel.TravelId
  association [1..1] to /DMO/I_Supplement       as _Suppl      on  $projection.SupplementId = _Suppl.SupplementID
  association [1..*] to /DMO/I_SupplementText   as _SuppText   on  $projection.SupplementId = _SuppText.SupplementID
{
  key travel_id             as TravelId,
  key booking_id            as BookingId,
  key booking_supplement_id as BookingSupplementId,
      supplement_id         as SupplementId,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      price                 as Price,
      currency_code         as CurrencyCode,
      @Semantics.systemDateTime.localInstanceLastChangedAt:true
      last_changed_at       as LastChangedAt,
      // Association ----
      _Suppl,
      _Bookingsup,
      _SuppText,
      _Travel
}
 