# HOTEL WEBSITE — MASTER PLAN
## Public Hotel Website + Booking Engine + Reservation Intake

> **Document Type:** Product, UX, Functional & Engineering Plan  
> **Version:** 1.0  
> **Scope:** WEBSITE ONLY  
> **Status:** Execution Baseline  
> **Primary Objective:** Build a production-ready hotel website that presents the hotel professionally, allows guests to discover rooms and facilities, checks room availability, completes reservations smoothly, generates reliable booking confirmations, and provides the foundation for future integration with the hotel operational system and guest application.

---

# 0. SCOPE LOCK — READ THIS FIRST

This PLAN.md is intentionally restricted to the **hotel website and its booking-facing capabilities**.

The website is the first stage of the larger hotel platform.

The website must be able to take a person from:

```text
Discover Hotel
    ↓
Understand Hotel
    ↓
Explore Rooms
    ↓
Check Dates
    ↓
See Availability
    ↓
Choose Room
    ↓
Enter Guest Details
    ↓
Review Reservation
    ↓
Choose Payment Method / Pay
    ↓
Confirm Reservation
    ↓
Receive Confirmation
    ↓
Receive Booking Document
    ↓
Look Up Reservation
    ↓
Manage Eligible Reservation Actions
```

The website MUST NOT attempt to become the full hotel operating application.

---

# 1. WEBSITE-ONLY BOUNDARY

## 1.1 IN SCOPE

This project includes:

- Public hotel website.
- Home page.
- About hotel.
- Rooms and room types.
- Room detail pages.
- Amenities.
- Gallery.
- Facilities.
- Offers.
- Hotel policies.
- Location and contact.
- Frequently asked questions.
- Booking search.
- Availability display.
- Room selection.
- Rate display.
- Reservation form.
- Guest details.
- Booking summary.
- Payment method selection.
- Payment integration where selected.
- Reservation creation.
- Confirmation page.
- Booking confirmation number.
- Confirmation document/PDF.
- Email/WhatsApp confirmation integrations where configured.
- Reservation lookup.
- Eligible reservation modification/cancellation workflow.
- Public-facing notifications/messages.
- Basic content management.
- Basic website analytics/SEO foundations.
- Accessibility and responsive design.
- Arabic RTL and localization foundation.
- Website security.
- Error handling.
- Website testing.
- Production deployment readiness.

---

## 1.2 OUT OF SCOPE

The website must NOT include the full implementation of:

- Guest mobile application.
- Guest in-stay service request system.
- Guest-to-reception chat.
- Housekeeping operations.
- Maintenance operations.
- Reception dashboard.
- Full PMS.
- Check-in workflow.
- Check-out workflow.
- Room transfer workflow.
- Internal room-status management.
- Internal staff task management.
- Internal accounting system.
- Full hotel ERP.
- Staff role management beyond what is required to operate website content.
- Advanced CRM.
- Loyalty program.
- Multi-property management.
- Full OTA/channel manager.
- Restaurant POS.
- Spa management.
- Laundry management.
- Procurement.
- Payroll.
- AI concierge.

These may be built later as separate plans and modules.

---

# 2. PURPOSE OF THE WEBSITE

The website has five primary jobs:

## Job 1 — Sell the hotel

The visitor must understand:

- What the hotel is.
- Where it is.
- What rooms are available.
- Why they should stay.
- What facilities exist.
- What the price/value proposition is.

## Job 2 — Reduce booking friction

The guest should be able to:

```text
Search → Select → Enter Data → Review → Confirm
```

without unnecessary steps.

## Job 3 — Create reliable reservations

A successful booking must create a real reservation record that can later be consumed by the future PMS/application.

## Job 4 — Confirm the reservation clearly

The guest should leave the booking process knowing:

- Booking number.
- Hotel.
- Room.
- Dates.
- Guests.
- Price.
- Payment state.
- Policies.
- Contact details.

## Job 5 — Become the public digital front door of the hotel

The website should remain useful even when a visitor is not ready to book yet.

---

# 3. CORE PRODUCT PRINCIPLE

The website is not merely a visual brochure.

It is a:

```text
Hotel Marketing Experience
        +
Booking Experience
        +
Reservation Intake System
```

The public website must be beautiful, fast, trustworthy, understandable, and operationally reliable.

---

# 4. PRIMARY USER JOURNEY

The canonical website journey is:

```text
Visitor
  ↓
Home
  ↓
Explore Rooms
  ↓
Select Dates
  ↓
Check Availability
  ↓
Compare Available Options
  ↓
Select Room
  ↓
Enter Guest Information
  ↓
Review Booking
  ↓
Payment / Payment Method
  ↓
Reservation Created
  ↓
Confirmation
  ↓
Booking Document
  ↓
WhatsApp / Email Confirmation
```

This path must work end-to-end.

---

# 5. SECONDARY USER JOURNEYS

The website must also support:

## Journey A — Browse without booking

```text
Home
 ↓
Rooms
 ↓
Room Details
 ↓
Amenities
 ↓
Policies
 ↓
Contact
```

## Journey B — Return to existing booking

```text
Website
 ↓
Manage Booking
 ↓
Enter Booking Reference + Verification Data
 ↓
Reservation Summary
```

## Journey C — Modify eligible booking

```text
Manage Booking
 ↓
Reservation
 ↓
Modify
 ↓
Recalculate
 ↓
Confirm Changes
 ↓
Updated Confirmation
```

## Journey D — Cancel eligible booking

```text
Manage Booking
 ↓
Reservation
 ↓
Cancellation Policy
 ↓
Confirm Cancellation
 ↓
Reservation Cancelled
 ↓
Confirmation
```

---

# 6. INFORMATION ARCHITECTURE

Primary navigation:

```text
Home
Rooms
Offers
Facilities
Gallery
About
Location
Contact
Manage Booking
Book Now
```

The navigation may be simplified based on actual hotel needs.

The most important CTA is:

```text
BOOK NOW
```

It should remain visually discoverable without becoming intrusive.

---

# 7. HOME PAGE

## 7.1 Hero Section

The hero must communicate immediately:

- Hotel identity.
- Hotel location.
- Main value proposition.
- High-quality visual.
- Booking CTA.

Recommended structure:

```text
Hotel Name
Short value proposition

[ Check Availability / Book Now ]
```

## 7.2 Booking Widget

The booking widget is the most important interactive element.

Fields:

- Check-in.
- Check-out.
- Adults.
- Children if supported.
- Rooms if supported.

Validation must be immediate and understandable.

---

## 7.3 Featured Rooms

Display selected room types:

- Image.
- Name.
- Short description.
- Occupancy.
- Key amenities.
- Price/from-price where appropriate.
- View details.
- Book.

---

## 7.4 Hotel Highlights

Examples:

- Location.
- Wi-Fi.
- Parking.
- Breakfast.
- Reception.
- Air conditioning.
- Security.
- Other real facilities.

Only show facilities actually configured for the hotel.

---

## 7.5 Gallery Preview

Show selected images and link to full gallery.

---

## 7.6 Guest Confidence Section

Can contain:

- Clear cancellation policy.
- Secure payment indicator.
- Contact options.
- Hotel location.
- Booking support.

Avoid fake trust signals.

---

## 7.7 Footer

Include:

- Hotel name.
- Address.
- Phone.
- WhatsApp.
- Email.
- Navigation.
- Policies.
- Social links.
- Copyright.
- Legal links.

---

# 8. ROOMS PAGE

The rooms page is the primary product catalog.

Each room type card should show:

- Room image.
- Room name.
- Brief description.
- Occupancy.
- Bed type.
- Amenities summary.
- Price/from-price if configured.
- CTA.

Examples of room types:

```text
Single Room
Double Room
Deluxe Room
Suite
```

Actual room types are hotel-configurable.

---

# 9. ROOM DETAIL PAGE

The room detail page must answer:

> What exactly am I booking?

Include:

## Identity

- Room type name.
- Description.
- Main image.
- Image gallery.

## Capacity

- Maximum guests.
- Adults.
- Children policy where applicable.

## Physical details

- Size.
- Bed configuration.
- Bathroom.
- Floor information if useful.

## Amenities

- Wi-Fi.
- Air conditioning.
- TV.
- Refrigerator.
- Safe.
- etc.

## Commercial details

- Starting price where applicable.
- Included items.
- Payment rules.
- Cancellation rules.

## Booking

A prominent:

```text
Check Availability
```

button.

---

# 10. FACILITIES PAGE

Show the hotel experience:

- Reception.
- Wi-Fi.
- Parking.
- Restaurant if applicable.
- Cafe if applicable.
- Laundry if actually offered.
- Other facilities.

Each item can have:

- Name.
- Description.
- Image.
- Availability/hours where relevant.

---

# 11. ABOUT PAGE

Should communicate:

- Hotel story.
- Identity.
- Service philosophy.
- Location advantages.
- Important information.

Avoid unnecessary text.

---

# 12. GALLERY

Gallery should support:

- Categories.
- Hotel exterior.
- Rooms.
- Facilities.
- Surroundings.

Technical requirements:

- Optimized images.
- Responsive images.
- Lazy loading.
- Accessible alt text.
- Thumbnail/preview strategy.

Never load massive original files unnecessarily.

---

# 13. OFFERS PAGE

Offers are optional but supported.

Offer may include:

- Name.
- Description.
- Dates.
- Eligibility.
- Discount.
- Applicable room types.
- Terms.
- CTA.

An expired offer must not remain bookable.

---

# 14. POLICIES PAGE

Must support hotel-configurable policies:

- Check-in time.
- Check-out time.
- Cancellation policy.
- No-show policy.
- Payment policy.
- Children policy.
- Extra guest policy.
- Identification policy.
- Smoking policy.
- Pets policy where applicable.
- Other hotel rules.

Policies shown during booking must be consistent with the policy version used for that reservation.

---

# 15. CONTACT PAGE

Include:

- Phone.
- WhatsApp.
- Email.
- Address.
- Map/location.
- Reception contact.
- Emergency contact only if intentionally published.

Provide clear CTAs.

---

# 16. LOCATION PAGE

Include:

- Hotel location.
- Map.
- Address.
- Nearby points where useful.
- Directions.
- Major landmarks.

The map must not expose sensitive private information.

---

# 17. FAQ

Possible categories:

- Booking.
- Check-in.
- Check-out.
- Cancellation.
- Payment.
- Rooms.
- Facilities.
- Location.
- General hotel information.

FAQ content should be configurable.

---

# 18. BOOKING ENGINE

The booking engine is the functional core of the website.

It must perform:

```text
Date Input
 ↓
Availability Calculation
 ↓
Rate Selection
 ↓
Guest Input
 ↓
Reservation Validation
 ↓
Payment Method
 ↓
Reservation Creation
 ↓
Confirmation
```

---

# 19. BOOKING SEARCH

Inputs:

- Check-in date.
- Check-out date.
- Adults.
- Children if enabled.
- Number of rooms if enabled.

## Validation

Must reject:

- Checkout before check-in.
- Same-day dates if not allowed.
- Past dates where not allowed.
- Invalid occupancy.
- Dates exceeding configured booking horizon.
- Invalid room quantity.

Validation messages must be clear.

---

# 20. AVAILABILITY

Availability must be derived from actual inventory.

The website must consider:

- Existing confirmed reservations.
- Relevant pending holds.
- Active stays if inventory model requires it.
- Rooms unavailable for sale.
- Room blocks.
- Out-of-order inventory.
- Date overlap.
- Room type capacity.

## Critical rule

The website MUST NOT rely only on a front-end calculation to determine final availability.

Final availability must be checked again at reservation creation.

---

# 21. DOUBLE-BOOKING PREVENTION

The booking process must protect inventory against race conditions.

Example:

```text
Guest A sees 1 Deluxe room available
Guest B sees 1 Deluxe room available
Both click Book
```

The system must ensure that only one reservation receives the same inventory.

This requires a transactional or otherwise atomic reservation mechanism appropriate to the chosen backend/database.

Frontend checks are not enough.

---

# 22. ROOM TYPE VS PHYSICAL ROOM

The website may sell at the room-type level.

Example:

```text
Deluxe Room
Inventory = 6 rooms
```

Guest can reserve:

```text
1 Deluxe Room
```

The website does not need to expose room 204 or room 305 to the public unless the hotel explicitly chooses that feature.

Physical room assignment belongs to the later operational/PMS stage.

Therefore:

```text
Website Booking
    ↓
Room Type Inventory

Future PMS
    ↓
Physical Room Assignment
```

This separation is important.

---

# 23. RATE MODEL

Website should support a clean base rate structure.

Minimum rate data:

- Rate plan.
- Room type.
- Date/range.
- Currency.
- Base price.
- Occupancy rule.
- Conditions.

Possible future capabilities:

- Seasonal rates.
- Weekend rates.
- Promotional rates.
- Corporate rates.
- Length-of-stay discounts.
- Non-refundable rate.
- Flexible rate.

Do not build advanced revenue management in the first website version.

---

# 24. PRICE CALCULATION

Price calculation should follow a deterministic pipeline:

```text
Base Rate
+
Applicable Extras
+
Applicable Taxes/Fees
-
Discounts
=
Booking Total
```

The exact tax/fee treatment depends on the hotel's jurisdiction and configuration.

All amounts must use proper money handling.

Do not use floating-point arithmetic carelessly for financial values.

---

# 25. PRICE SNAPSHOT

At the moment the reservation is confirmed, store the pricing snapshot used for that booking.

The snapshot should preserve enough information to explain:

- Nightly rate.
- Number of nights.
- Discounts.
- Taxes/fees.
- Total.
- Currency.

A future price change must not silently rewrite a historical confirmed reservation.

---

# 26. BOOKING FLOW

Recommended flow:

```text
1. Dates & Guests
2. Availability
3. Room Selection
4. Guest Details
5. Booking Options
6. Review
7. Payment
8. Confirmation
```

Keep the flow simple.

Do not create unnecessary forms.

---

# 27. STEP 1 — SEARCH

Guest selects:

```text
Check-in
Check-out
Guests
```

System validates and searches.

---

# 28. STEP 2 — AVAILABILITY RESULTS

Each available room type should show:

- Name.
- Image.
- Capacity.
- Main amenities.
- Number available where useful.
- Rate.
- Cancellation condition.
- Payment condition.
- Select button.

Avoid overwhelming the guest with internal inventory details.

---

# 29. STEP 3 — ROOM SELECTION

Guest selects:

```text
Deluxe Room
```

System stores the intended selection but MUST revalidate availability later before confirmation.

---

# 30. STEP 4 — GUEST INFORMATION

Minimum useful fields:

- Full name.
- Phone.
- WhatsApp if used separately.
- Email where available.
- Number of guests.
- Special request where appropriate.

Additional legally required guest fields may be collected later according to hotel/local requirements.

Do not collect unnecessary personal data.

---

# 31. GUEST DATA VALIDATION

Validate:

- Name.
- Phone.
- Email where required.
- Occupancy.
- Required policy agreements.

Phone validation should support the configured country/locale.

---

# 32. SPECIAL REQUEST

Guest may optionally write:

```text
Special Request
```

Example:

> High floor if available.

The website must clearly communicate that a request is not automatically guaranteed unless the hotel explicitly supports guaranteed preferences.

---

# 33. POLICY ACKNOWLEDGMENT

Before confirmation, guest must be able to see:

- Cancellation policy.
- Payment policy.
- Check-in/out times.
- Important hotel rules.

Where required by policy/legal design, guest explicitly acknowledges terms.

Store the relevant policy/version reference with the reservation.

---

# 34. BOOKING SUMMARY

Before final confirmation, show:

```text
Hotel
Room Type
Check-in
Check-out
Nights
Guests
Rate
Taxes/Fees
Discounts
Total
Payment Status
Cancellation Policy
```

The guest must understand the total before confirming.

---

# 35. PAYMENT

The website should support an abstraction for payment methods.

Possible methods:

- Pay online.
- Pay at hotel.
- Deposit.
- Partial payment.
- Manual payment reference where appropriate.

The exact methods depend on the hotel's actual business/payment setup.

---

# 36. PAYMENT INTEGRATION RULE

Never mark a reservation as fully paid solely because the client says payment succeeded.

The payment provider/server-side verification must determine the actual payment result.

Conceptually:

```text
Guest Starts Payment
      ↓
Payment Provider
      ↓
Provider Verification / Webhook
      ↓
Payment Confirmed
      ↓
Reservation Confirmed
```

Where offline/manual payment is supported:

```text
Payment Method = Pay at Hotel
Reservation State = According to configured policy
```

---

# 37. IDEMPOTENCY

Reservation/payment operations must protect against duplicate submissions.

Example:

Guest presses:

```text
Confirm Booking
```

twice.

System must not accidentally create two reservations or charge twice.

Use an appropriate idempotency mechanism on critical server operations.

---

# 38. RESERVATION CREATION

A successful reservation should create at minimum:

```text
Reservation ID
Booking Reference
Guest
Room Type
Dates
Guests
Rate
Currency
Charges/price snapshot
Payment state
Reservation status
Creation timestamp
Source = Website
```

---

# 39. RESERVATION NUMBER

Generate a human-friendly booking reference, for example:

```text
HTL-2026-000421
```

Requirements:

- Unique.
- Stable.
- Non-sensitive.
- Easy to read over phone.
- Not the sole authorization credential for management actions.

---

# 40. RESERVATION STATUS

Website-level states may include:

```text
PENDING
CONFIRMED
PAYMENT_PENDING
CANCELLED
FAILED
EXPIRED
```

Exact states depend on payment/reservation design.

The status model must be explicit.

Do not hide multiple meanings behind one generic "success" state.

---

# 41. PENDING RESERVATIONS / HOLDS

If the system temporarily holds inventory during payment:

It must have:

- Hold creation time.
- Expiration.
- Associated checkout/session.
- Inventory reservation.
- Automatic release.

Expired holds must not block rooms indefinitely.

---

# 42. CONFIRMATION PAGE

After confirmed booking, show clearly:

```text
Booking Confirmed

Reservation:
HTL-2026-000421

Guest:
Mohamed Ahmed

Room:
Deluxe Double

Check-in:
1 September 2026

Check-out:
4 September 2026

Total:
...

Status:
Confirmed
```

Actions:

- Download confirmation.
- Send/re-send confirmation.
- Add to calendar where appropriate.
- Manage booking.
- Contact hotel.

---

# 43. BOOKING CONFIRMATION DOCUMENT

Generate a professional booking confirmation document/PDF.

Include:

- Hotel logo/name.
- Hotel contact.
- Guest name.
- Booking reference.
- Room type.
- Dates.
- Guests.
- Number of nights.
- Price breakdown.
- Payment status.
- Cancellation policy.
- Check-in/out time.
- Hotel address.
- Important instructions.
- QR/reference code where useful.

Do not expose internal administrative data.

---

# 44. WHATSAPP CONFIRMATION

Where WhatsApp is configured:

After reservation confirmation, the system should send a confirmation message to the guest.

Recommended message structure:

```text
Your reservation is confirmed.

Hotel: [Hotel Name]
Booking: [Reference]
Guest: [Name]
Room: [Room Type]
Check-in: [Date]
Check-out: [Date]
Total: [Amount]
Status: Confirmed

Your booking confirmation document is attached/linked where supported.
```

The actual provider integration must follow the provider's current API requirements.

---

# 45. EMAIL CONFIRMATION

Where email is provided and enabled:

Send:

- Confirmation email.
- Confirmation document.
- Important booking details.

Email is a secondary channel; database state remains authoritative.

---

# 46. NOTIFICATION FAILURE RULE

If WhatsApp/email fails after a successful reservation:

```text
Reservation remains successful.
```

Notification failure must not roll back a confirmed reservation unless the business process explicitly requires that behavior.

The system should:

- Record the notification failure.
- Mark it for retry.
- Expose operational status where appropriate.

---

# 47. MANAGE BOOKING

Public website should provide a controlled reservation lookup.

Typical inputs:

```text
Booking Reference
+
Verification Value
```

For example:

- Booking reference.
- Phone or email verification.

Never allow access based only on a guessable booking reference.

---

# 48. RESERVATION LOOKUP

Guest can view eligible:

- Guest name.
- Hotel.
- Room type.
- Dates.
- Guests.
- Status.
- Amount.
- Payment status.
- Policy.

Sensitive internal information must remain hidden.

---

# 49. RESERVATION MODIFICATION

Where hotel policy allows it, website may permit:

- Date modification.
- Guest count modification.
- Room type modification.
- Contact detail update.

Every modification must:

1. Revalidate availability.
2. Recalculate price.
3. Show difference.
4. Show policies.
5. Require confirmation.
6. Update reservation.
7. Generate updated confirmation.
8. Notify guest.
9. Preserve history.

---

# 50. RESERVATION CANCELLATION

Guest selects:

```text
Cancel Booking
```

System shows:

- Cancellation policy.
- Refund expectation if applicable.
- Charges/penalties if configured.
- Final confirmation.

Then:

```text
Reservation → Cancelled
Inventory → Released where applicable
Payment → Refund workflow where applicable
Notification → Sent
Audit → Recorded
```

---

# 51. BOOKING MODIFICATION HISTORY

Do not simply overwrite all old values.

Preserve enough history to answer:

- What was originally booked?
- What changed?
- When?
- By whom?
- Why, where required?

---

# 52. WEBSITE CMS / CONTENT MANAGEMENT

The website needs configurable content.

Minimum manageable content:

### Hotel Information
- Name.
- Logo.
- Description.
- Contact.
- Address.

### Rooms
- Room types.
- Images.
- Descriptions.
- Amenities.
- Capacity.

### Facilities
- Names.
- Descriptions.
- Images.

### Policies
- Rules.
- Check-in/out.
- Cancellation.

### Offers
- Promotional content.

### Gallery
- Images.
- Categories.

### FAQ
- Questions.
- Answers.

---

# 53. CONTENT SAFETY

Content changes must not silently break booking logic.

For example:

Changing the text:

```text
"Deluxe Room"
```

is a content operation.

Changing:

```text
Inventory
Rate
Occupancy
Cancellation Policy
```

is a business operation and must use the appropriate controlled configuration.

---

# 54. ADMIN CONTENT AREA

Because this PLAN is website-only, the website's administrative content panel may be limited to:

- Website content.
- Rooms and room-type presentation data.
- Facilities.
- Gallery.
- Policies.
- Offers.
- Basic booking settings.

It must NOT become the full PMS admin.

---

# 55. WEBSITE SETTINGS

Core configurable settings:

### Branding
- Logo.
- Favicon.
- Colors/theme.
- Hotel name.

### Contact
- Phone.
- WhatsApp.
- Email.
- Address.

### Booking
- Booking horizon.
- Check-in time.
- Check-out time.
- Minimum stay if supported.
- Maximum stay if supported.
- Guest limits.
- Payment methods.

### Communication
- WhatsApp provider.
- Email provider.
- Notification templates.

---

# 56. DESIGN SYSTEM

The website should use one coherent design system.

Define:

- Typography.
- Spacing.
- Border radius.
- Buttons.
- Inputs.
- Cards.
- Alerts.
- Modals.
- Tables where needed.
- Status badges.
- Navigation.
- Footer.
- Loading states.
- Empty states.

Do not build each page visually from scratch.

---

# 57. RESPONSIVE DESIGN

Required targets:

- Mobile.
- Tablet.
- Desktop.

Mobile booking is a first-class use case.

The booking flow must remain easy on small screens.

Avoid:

- Tiny form fields.
- Horizontal overflow.
- Complex tables on mobile.
- Hidden essential information.
- Sticky elements that block controls.

---

# 58. ACCESSIBILITY

The website should target practical accessibility compliance.

Must include:

- Keyboard accessibility.
- Proper labels.
- Visible focus states.
- Semantic HTML where applicable.
- Alt text.
- Sufficient contrast.
- Accessible error messages.
- Screen-reader-friendly form semantics.
- Logical focus order.

---

# 59. ARABIC RTL

Arabic is a first-class requirement.

Support:

- RTL layouts.
- Arabic text.
- English localization where needed.
- Localized dates.
- Localized numbers according to product decision.
- RTL navigation.
- RTL forms.
- RTL dialogs.
- RTL booking summaries.

The design must not rely on simply mirroring every icon; directional icons must be semantically reviewed.

---

# 60. INTERNATIONALIZATION

Architecture should support multiple languages even if the first release launches in Arabic only.

Possible languages:

```text
Arabic
English
```

Translation strings must not be scattered hard-coded across components.

---

# 61. SEO

Public pages must be indexable where appropriate.

Core SEO elements:

- Proper title.
- Meta description.
- Canonical URLs.
- Structured headings.
- Search-friendly room pages.
- Descriptive image alt text.
- Open Graph metadata.
- Sitemap.
- Robots policy.

Booking transaction pages containing guest-specific information must not be indexed.

---

# 62. HOTEL / ROOM STRUCTURED DATA

Where appropriate, implement schema/structured metadata for:

- Hotel.
- Rooms/products.
- Offers where accurate.
- Location/business identity.

Do not publish structured data that contradicts actual availability or pricing.

---

# 63. PERFORMANCE

Target:

- Fast first load.
- Optimized images.
- Lazy loading.
- Cache static assets.
- Minimize JavaScript/bundle where applicable.
- Efficient API calls.
- Avoid unnecessary third-party scripts.

Booking pages should remain fast even on slower mobile connections.

---

# 64. IMAGE MANAGEMENT

Images should have:

- Optimized dimensions.
- Compressed formats.
- Responsive variants.
- Alt text.
- Stable ordering.
- Focal point/cropping support if needed.

Do not upload one huge original and use it everywhere.

---

# 65. WEBSITE ERROR STATES

The website must handle:

### Availability error
> We couldn't check availability right now.

### Payment error
> Your payment could not be completed.

### Booking conflict
> This room is no longer available. Please select another option.

### Network failure
> Please check your connection and try again.

### Reservation lookup failure
> We could not verify this booking.

Never show technical stack traces to guests.

---

# 66. LOADING STATES

Important operations need explicit feedback:

- Searching availability.
- Loading room details.
- Recalculating price.
- Processing payment.
- Creating reservation.
- Loading booking.
- Modifying reservation.

Do not leave the user wondering whether a button worked.

---

# 67. DOUBLE-SUBMIT PROTECTION

After critical action:

```text
Confirm Booking
```

the UI should prevent accidental duplicate clicks while the request is being processed.

This is UX protection only; backend idempotency remains mandatory.

---

# 68. SECURITY

The website must enforce:

- HTTPS in production.
- Secure sessions.
- CSRF protection where applicable.
- Authentication controls for admin.
- Authorization.
- Input validation.
- Output encoding.
- Secure file handling.
- Rate limiting.
- Anti-abuse controls.
- Secure secrets.
- No sensitive secrets in client code.

---

# 69. PUBLIC RESERVATION SECURITY

The public website must not expose:

- Internal database IDs.
- Internal room IDs unless intentionally public.
- Internal user IDs.
- Internal notes.
- Internal staff information.
- Payment secrets.
- Admin endpoints without authorization.

---

# 70. BOT / ABUSE PROTECTION

Public booking endpoints may attract automated traffic.

Consider:

- Rate limiting.
- Bot detection where appropriate.
- CAPTCHA/challenge only when necessary.
- Request throttling.
- Abuse monitoring.

Do not make normal guests solve unnecessary challenges.

---

# 71. PRIVACY

Collect only necessary data.

The website should explain:

- Why data is collected.
- How it is used.
- Contact/support options.
- Relevant privacy policy.

Sensitive identity information should only be collected when actually required by the hotel/legal workflow.

---

# 72. TERMS

The website should provide:

- Privacy Policy.
- Terms.
- Booking Terms.
- Cancellation Policy.

The booking process should make important terms accessible before confirmation.

---

# 73. DATA MODEL — WEBSITE CORE

Suggested entities:

```text
Hotel
RoomType
RoomTypeImage
Amenity
RoomTypeAmenity
Facility
FacilityImage
GalleryItem
Offer
Policy
FAQ
RatePlan
Rate
Guest
Reservation
ReservationGuest
ReservationItem
ReservationPriceSnapshot
Payment
PaymentAttempt
Notification
BookingDocument
BookingModification
BookingCancellation
AuditLog
WebsiteSetting
```

---

# 74. IMPORTANT DOMAIN RELATIONSHIPS

```text
Hotel
 ├── Room Types
 │     ├── Images
 │     ├── Amenities
 │     └── Rates
 │
 ├── Facilities
 ├── Policies
 ├── Offers
 ├── Gallery
 └── Reservations

Guest
 └── Reservations

Reservation
 ├── Guest
 ├── Room Type / Reservation Items
 ├── Price Snapshot
 ├── Payments
 ├── Documents
 ├── Notifications
 └── Modification History
```

---

# 75. RESERVATION ENTITY

Minimum conceptual fields:

```text
id
booking_reference
hotel_id
guest_id
status
source
check_in
check_out
adults
children
currency
subtotal
discount_total
tax_total
grand_total
paid_total
payment_status
created_at
updated_at
confirmed_at
cancelled_at
```

Some financial values may be derived from transactional records while snapshots preserve booking-time truth.

---

# 76. RESERVATION ITEM

Useful for supporting one or more room selections.

Fields may include:

```text
reservation_item_id
reservation_id
room_type_id
quantity
rate_plan_id
check_in
check_out
nightly_snapshot
subtotal
discount
tax
total
```

---

# 77. GUEST ENTITY

Minimum:

```text
id
full_name
phone
email
country_code
created_at
updated_at
```

Additional legally required information should be added only when needed.

---

# 78. PAYMENT ENTITY

Conceptual fields:

```text
id
reservation_id
provider
method
amount
currency
status
provider_reference
idempotency_key
created_at
completed_at
failed_at
```

Never store sensitive card data unless the selected payment architecture explicitly requires it and is compliant with applicable requirements.

Prefer hosted/tokenized payment flows.

---

# 79. BOOKING DOCUMENT ENTITY

Should track:

```text
id
reservation_id
document_type
file_reference
generated_at
version
```

Regenerating a document must not cause inconsistent booking information.

---

# 80. NOTIFICATION ENTITY

Track:

```text
id
reservation_id
channel
type
status
recipient
attempt_count
provider_reference
created_at
sent_at
failed_at
```

This enables retries and diagnostics.

---

# 81. API / APPLICATION USE CASES

The website should be built around explicit use cases.

Core:

```text
GetHotelContent
GetRoomTypes
GetRoomDetails
SearchAvailability
GetRates
CalculateBookingPrice
CreateReservation
InitializePayment
VerifyPayment
ConfirmReservation
GenerateBookingConfirmation
SendBookingNotification
LookupReservation
ModifyReservation
CancelReservation
DownloadBookingDocument
```

---

# 82. AVAILABILITY USE CASE

Input:

```text
dates
occupancy
room quantity
```

Output:

```text
available room types
rates
conditions
```

The availability response must not become stale truth.

Reservation creation must revalidate.

---

# 83. PRICE CALCULATION USE CASE

Input:

```text
room type
rate plan
dates
occupancy
offer/discount context
```

Output:

```text
nightly breakdown
subtotal
discount
tax
fees
total
currency
conditions
```

The calculation must be deterministic and testable independently of the UI.

---

# 84. CREATE RESERVATION USE CASE

The server-side sequence should conceptually be:

```text
Validate Request
      ↓
Resolve Hotel
      ↓
Validate Dates
      ↓
Validate Occupancy
      ↓
Recheck Availability
      ↓
Calculate Final Price
      ↓
Create Reservation
      ↓
Create Price Snapshot
      ↓
Create Payment State / Payment Attempt
      ↓
Commit
      ↓
Generate Confirmation
      ↓
Trigger Notifications
```

The exact transaction boundaries depend on the backend/payment design.

---

# 85. PAYMENT-FIRST VS RESERVATION-FIRST

The architecture may support one of two controlled patterns:

### Pattern A — Reservation after verified payment

```text
Checkout
 ↓
Payment
 ↓
Verification
 ↓
Reservation
```

### Pattern B — Temporary reservation / hold

```text
Checkout
 ↓
Create Pending Hold
 ↓
Payment
 ↓
Verification
 ↓
Confirm Reservation
```

The final approach must be chosen based on inventory/payment behavior.

Do NOT mix the patterns inconsistently.

---

# 86. WEBHOOKS

Payment providers often communicate final payment state asynchronously.

Webhook processing must:

- Verify authenticity.
- Be idempotent.
- Handle retries.
- Update payment state.
- Update reservation state according to rules.
- Record provider reference.
- Log failures.

A webhook must not create duplicate reservations.

---

# 87. COMMUNICATION TEMPLATES

Website should support templates such as:

```text
Booking Received
Booking Confirmed
Payment Pending
Payment Failed
Booking Modified
Booking Cancelled
Pre-Arrival Reminder
```

Templates should use placeholders safely:

```text
{{guest_name}}
{{booking_reference}}
{{hotel_name}}
{{room_type}}
{{check_in}}
{{check_out}}
{{total}}
```

---

# 88. WHATSAPP PROVIDER ABSTRACTION

Implement:

```text
NotificationService
   ├── WhatsAppProvider
   ├── EmailProvider
   └── PushProvider (future)
```

The booking domain must not depend directly on a specific provider SDK.

---

# 89. ADMIN / CONTENT SECURITY

Website content administration must require authenticated users with appropriate permissions.

At minimum:

```text
Content Manager
Website Admin
```

can be represented through permissions even if only one administrative role exists initially.

---

# 90. ADMIN AUDIT

Audit:

- Room type changes.
- Rate changes.
- Policy changes.
- Offer changes.
- Content publishing.
- Reservation administrative actions.
- Payment state changes.
- Cancellation policy changes.

---

# 91. VERSIONING OF IMPORTANT CONFIGURATION

Important reservation-affecting configuration should be versionable or historically traceable:

- Rates.
- Cancellation policy.
- Major booking terms.

A guest's confirmed reservation must remain explainable later.

---

# 92. ANALYTICS

Basic analytics may track:

- Page views.
- Room detail views.
- Booking search starts.
- Availability searches.
- Booking starts.
- Checkout starts.
- Successful bookings.
- Booking abandonment.

Do not send sensitive guest/payment information to analytics tools.

---

# 93. CONVERSION FUNNEL

Measure:

```text
Visitor
 ↓
Room View
 ↓
Search
 ↓
Availability Result
 ↓
Room Selection
 ↓
Guest Form
 ↓
Payment
 ↓
Confirmed Booking
```

This helps identify booking friction.

---

# 94. ACCESSIBLE BOOKING FUNNEL

Each step should expose:

- Current step.
- What is required.
- Validation errors.
- What happens next.
- Back navigation without accidental data loss where reasonable.

---

# 95. BOOKING UX RULES

The booking flow MUST:

- Show clear totals.
- Avoid surprise fees.
- Keep important policies visible.
- Preserve entered information when safe.
- Explain unavailable options.
- Provide recovery after errors.
- Never imply success before server confirmation.

---

# 96. MOBILE BOOKING UX

On mobile:

- One-column layout.
- Sticky summary where useful.
- Large touch targets.
- Native-friendly date selection.
- Easy guest quantity controls.
- Clear payment state.
- Minimal typing.

---

# 97. SEO + BOOKING SEPARATION

Public informational pages can be indexed.

Reservation/account-specific pages should generally use appropriate no-index protections.

Examples of pages likely indexable:

```text
Home
Rooms
Room Details
Facilities
About
Location
Offers
FAQ
```

Examples not intended for indexing:

```text
My Booking
Confirmation
Payment Return
Guest-private management pages
```

---

# 98. CACHING

Cache:

- Static hotel content.
- Room descriptions.
- Amenities.
- Gallery.
- Non-dynamic policy content.

Do NOT treat cached availability as authoritative for reservation creation.

---

# 99. TIME ZONE

Hotel booking dates must be interpreted in the hotel's configured local time zone.

Do not rely blindly on the user's phone/browser time zone.

Date calculations must avoid accidental day shifts.

---

# 100. CURRENCY

The website should have a configured base currency.

Optional future support:

- Display currency conversion.
- Multiple currencies.

The booking's actual financial currency must be stored explicitly.

Displayed converted values must not be confused with the charged currency.

---

# 101. DATE/TIME RULES

The website must clearly display:

- Check-in date.
- Check-out date.
- Number of nights.
- Hotel local time where time matters.

The number of nights must be calculated from date boundaries, not arbitrary timestamps.

---

# 102. CONTENT QUALITY RULES

No placeholder content in production.

No fake:

- Reviews.
- Awards.
- Facilities.
- Room photos.
- Availability.
- Ratings.

Every public statement should reflect actual hotel configuration.

---

# 103. IMAGE AND CONTENT FALLBACKS

If a room has no gallery:

Use a controlled placeholder.

Do not break page layout.

If a facility has no image:

Use text-first presentation.

---

# 104. URL STRUCTURE

Public URLs should be stable and readable.

Examples:

```text
/
 /rooms
 /rooms/deluxe-room
 /facilities
 /gallery
 /offers
 /about
 /location
 /contact
 /booking
 /manage-booking
```

Avoid leaking internal database IDs into public URLs where not necessary.

---

# 105. BOOKING REFERENCE LOOKUP SECURITY

The system should apply rate limits to reservation lookup.

Repeated failed attempts may trigger temporary throttling.

Do not expose whether a specific booking exists in ways that help enumeration attacks.

---

# 106. EMAIL / WHATSAPP OPT-IN

Where required, communication preferences should be captured clearly.

Essential transactional booking communication must be handled according to the applicable legal/business requirements.

Marketing communication should remain distinct from transactional communication.

---

# 107. LEGAL / COMPLIANCE NOTE

The implementation must be reviewed against:

- Applicable privacy requirements.
- Local hotel/guest registration requirements.
- Payment provider requirements.
- Applicable tax rules.
- WhatsApp provider/business messaging rules.

This PLAN defines product/engineering behavior, not legal advice.

---

# 108. TESTING STRATEGY

Testing must validate the complete booking journey.

## Unit Tests

Test:

- Date calculations.
- Number of nights.
- Occupancy validation.
- Availability calculations.
- Pricing.
- Discounts.
- Fees.
- Policy evaluation.
- Reservation state transitions.

---

# 109. INTEGRATION TESTS

Test:

```text
Search → Availability
Availability → Selection
Selection → Price
Price → Reservation
Reservation → Payment
Payment → Confirmation
Confirmation → Notification
```

---

# 110. END-TO-END TESTS

Mandatory scenarios:

## Scenario 1 — Successful booking

```text
Home
→ Search
→ Room
→ Guest data
→ Review
→ Pay/Confirm
→ Confirmation
```

## Scenario 2 — Room becomes unavailable

Guest sees room.

Another booking consumes the remaining inventory.

First guest attempts confirmation.

System must reject or offer alternatives safely.

## Scenario 3 — Payment failure

Payment fails.

Reservation must not become falsely confirmed.

## Scenario 4 — Double click

Repeated confirm action must not duplicate reservation.

## Scenario 5 — Expired hold

Inventory returns to availability after hold expiration.

## Scenario 6 — Cancellation

Guest cancels according to policy.

System produces correct status/financial workflow.

## Scenario 7 — Modification

Guest changes dates.

System rechecks availability and recalculates.

---

# 111. SECURITY TESTS

Test:

- Unauthorized admin access.
- Guest booking lookup isolation.
- Request tampering.
- Price tampering.
- Room type tampering.
- Hidden field manipulation.
- Duplicate submissions.
- Webhook spoofing.
- Replay of payment callbacks.
- Enumeration attempts.
- Rate limiting.

---

# 112. FAILURE RECOVERY TESTS

Simulate:

- Payment provider timeout.
- Notification provider outage.
- Database connection failure.
- Availability timeout.
- Partial external integration failure.

The website should fail gracefully and preserve core data integrity.

---

# 113. OBSERVABILITY

Monitor:

- Booking failures.
- Payment failures.
- Availability errors.
- Notification failures.
- Server errors.
- Slow API endpoints.
- Webhook failures.
- Reservation conflicts.

---

# 114. LOGGING

Logs should identify:

- Request ID.
- Operation.
- Result.
- Error classification.
- Relevant non-sensitive identifiers.

Never log:

- Passwords.
- Access tokens.
- Card data.
- Payment secrets.
- Unnecessary personal information.

---

# 115. BACKUP

Production data requires:

- Scheduled backup.
- Retention policy.
- Restore verification.
- Disaster recovery procedure.

---

# 116. DEPLOYMENT

Production deployment must include:

- Secure environment variables.
- HTTPS.
- Correct domain.
- Database configuration.
- Storage configuration.
- Email/WhatsApp provider configuration.
- Payment provider configuration where used.
- Error monitoring.
- Backup.
- Rollback procedure.

---

# 117. ENVIRONMENT SEPARATION

Use at least:

```text
Development
Staging
Production
```

Do not use live payment credentials in development.

Do not use production guest data in test environments unless properly protected and intentionally approved.

---

# 118. PRODUCTION DOMAIN FLOW

Recommended conceptual flow:

```text
User Browser
      ↓
CDN / Web Server
      ↓
Website Application
      ↓
API / Application Layer
      ↓
Database
      ├── Reservation
      ├── Guest
      ├── Inventory
      ├── Payment State
      └── Content
      ↓
External Providers
      ├── Payment
      ├── WhatsApp
      └── Email
```

---

# 119. FUTURE INTEGRATION CONTRACT

This website must be designed so the future hotel PMS and guest app can consume the same reservation without rebuilding the booking domain.

Future integration should expect data such as:

```text
Reservation
Guest
Room Type
Dates
Guests
Payment State
Price Snapshot
Confirmation
```

After future check-in:

```text
Reservation
   ↓
Stay
   ↓
Room
   ↓
Guest App Access
```

The website does not implement that later workflow in this phase.

---

# 120. FUTURE GUEST APP BOUNDARY

When the guest app is built later, it must consume the reservation/stay context produced by this website/backend.

The website should therefore avoid creating a proprietary booking format that only the website understands.

Use stable API/domain contracts.

---

# 121. FUTURE PMS BOUNDARY

The website should not assume that:

```text
Room Type = Physical Room
```

because future PMS logic may assign:

```text
Reservation:
Deluxe Room

PMS:
Room 204
```

The website only needs to sell valid room-type inventory unless explicit room selection is intentionally enabled.

---

# 122. MUST / SHOULD / MUST NOT

## MUST

- Make booking possible from start to finish.
- Protect inventory.
- Revalidate availability at final confirmation.
- Use deterministic pricing.
- Preserve booking-time price information.
- Generate unique booking references.
- Confirm booking only after valid server-side business confirmation.
- Prevent duplicate booking/payment operations.
- Generate a booking confirmation.
- Provide secure booking lookup.
- Support Arabic RTL.
- Support responsive design.
- Log important booking/payment state changes.
- Test end-to-end flows.

## SHOULD

- Support WhatsApp.
- Support email.
- Support downloadable PDF.
- Support offers.
- Support reservation modification.
- Support reservation cancellation.
- Provide analytics.
- Provide content administration.
- Support multiple languages.

## MUST NOT

- Treat frontend availability as authoritative.
- Trust client-provided prices.
- Trust client-provided totals.
- Confirm payment from frontend alone.
- Expose internal database IDs unnecessarily.
- Allow booking lookup using a guessable identifier alone.
- Create a full PMS inside the website phase.
- Mix guest-app functionality into this website PLAN.
- Use fake content in production.
- Build advanced hotel modules before booking is stable.
- Declare the website production-ready because it only looks good.

---

# 123. DEFINITION OF DONE — WEBSITE

The website is not complete until a real test user can:

```text
1. Open the website
2. Understand the hotel
3. Browse rooms
4. Select dates
5. See actual availability
6. Select a room type
7. Enter guest information
8. Review exact price
9. Confirm payment/method
10. Receive a real reservation reference
11. See confirmation page
12. Download/open confirmation document
13. Receive configured notification
14. Retrieve the booking through Manage Booking
15. Perform allowed modification/cancellation
```

And the hotel/backend side must show the corresponding reservation correctly.

---

# 124. WEBSITE RELEASE PHASES

## PHASE 1 — FOUNDATION

Build:

- Project setup.
- Design system.
- Routing.
- Localization.
- RTL.
- Theme.
- Environment configuration.
- Error handling.
- Logging foundation.

Deliverable:

Stable website shell.

---

## PHASE 2 — PUBLIC CONTENT

Build:

- Home.
- About.
- Rooms.
- Room details.
- Facilities.
- Gallery.
- Offers.
- Policies.
- FAQ.
- Contact.
- Location.

Deliverable:

Complete public hotel website.

---

## PHASE 3 — BOOKING SEARCH

Build:

- Booking widget.
- Dates.
- Guests.
- Availability API.
- Room results.
- Rate display.

Deliverable:

Guest can search real availability.

---

## PHASE 4 — RESERVATION CHECKOUT

Build:

- Guest information.
- Special requests.
- Policy acceptance.
- Price breakdown.
- Booking summary.
- Reservation creation.

Deliverable:

Guest can create a pending/confirmed reservation according to payment strategy.

---

## PHASE 5 — PAYMENT

Build:

- Payment abstraction.
- Provider integration.
- Payment verification.
- Webhooks.
- Idempotency.
- Failure recovery.

Deliverable:

Real payment-enabled booking flow where supported.

---

## PHASE 6 — CONFIRMATION

Build:

- Confirmation page.
- Booking reference.
- PDF.
- Email.
- WhatsApp.

Deliverable:

Guest receives verifiable booking confirmation.

---

## PHASE 7 — MANAGE BOOKING

Build:

- Secure lookup.
- Reservation details.
- Modification.
- Cancellation.
- Updated confirmation.

Deliverable:

Guest can manage eligible reservations.

---

## PHASE 8 — ADMIN CONTENT

Build:

- Content management.
- Room presentation data.
- Facilities.
- Gallery.
- Policies.
- Offers.
- Website settings.

Deliverable:

Hotel can maintain public website content without code changes for ordinary content updates.

---

## PHASE 9 — SEO / PERFORMANCE / HARDENING

Build:

- SEO.
- Structured data.
- Performance optimization.
- Caching.
- Security hardening.
- Observability.
- Backups.

Deliverable:

Production-ready website.

---

# 125. IMPLEMENTATION ORDER

Do not build randomly.

Required order:

```text
Foundation
 ↓
Design System
 ↓
Hotel Content
 ↓
Room Catalog
 ↓
Availability
 ↓
Pricing
 ↓
Reservation
 ↓
Payment
 ↓
Confirmation
 ↓
Notifications
 ↓
Manage Booking
 ↓
Content Admin
 ↓
SEO / Performance
 ↓
Security / Production Hardening
```

---

# 126. AI CODING AGENT EXECUTION RULES

If this PLAN.md is provided to an AI coding agent:

## RULE 1

Read the entire PLAN.md before writing or modifying code.

## RULE 2

Do not implement the guest app.

## RULE 3

Do not implement the PMS.

## RULE 4

Do not create housekeeping/maintenance workflows.

## RULE 5

Do not create internal reception dashboards unless explicitly required for integration/testing.

## RULE 6

Do not invent payment behavior.

## RULE 7

Do not trust client-side prices or availability.

## RULE 8

Do not mark a reservation confirmed without valid business confirmation.

## RULE 9

Do not create duplicate reservation logic in multiple screens.

## RULE 10

All critical business logic belongs in domain/application/backend services, not UI widgets.

## RULE 11

Every critical feature requires tests.

## RULE 12

Do not delete working functionality to make compilation easier.

## RULE 13

Do not replace a real integration with fake success responses and call the feature complete.

## RULE 14

If an external provider is not configured, build the integration boundary cleanly and use an explicit development/staging mode rather than pretending it is live.

## RULE 15

After each implementation phase:

```text
Build
Test
Review
Fix
Re-test
```

before moving forward.

---

# 127. UI QUALITY RULES

The website should feel like a real hotel website, not an admin dashboard.

Avoid:

- Excessive cards.
- Excessive borders.
- Tiny text.
- Crowded screens.
- Technical terminology.
- Long forms.
- Unnecessary popups.

Prioritize:

- Photography.
- Clear hierarchy.
- Trust.
- Price clarity.
- Booking CTA.
- Fast navigation.

---

# 128. BOOKING QUALITY RULES

The booking engine must feel:

```text
Fast
Clear
Predictable
Trustworthy
```

A guest should always know:

- Where they are.
- What they selected.
- How much it costs.
- What happens next.
- Whether the booking succeeded.

---

# 129. DATA INTEGRITY RULES

The following relationships must remain valid:

```text
Reservation → Guest
Reservation → Room Type
Reservation → Dates
Reservation → Price Snapshot
Reservation → Payment State
Reservation → Confirmation
```

A reservation should never exist with impossible dates or invalid room type references.

---

# 130. BUSINESS INVARIANTS

## Availability

A confirmed reservation cannot exceed available inventory.

## Pricing

The final reservation amount must be generated by trusted business logic.

## Payment

A failed payment cannot be represented as successful.

## Confirmation

A booking reference must point to exactly one reservation.

## Cancellation

A cancelled reservation must follow configured cancellation behavior.

## Modification

Changes must be validated against current availability and policies.

---

# 131. AUDIT REQUIREMENTS

At minimum, record:

- Reservation creation.
- Reservation confirmation.
- Reservation cancellation.
- Reservation modification.
- Payment events.
- Notification attempts.
- Important configuration changes.

---

# 132. EXTERNAL SERVICE FAILURE POLICY

If:

### Payment provider fails

Do not invent success.

### WhatsApp fails

Keep reservation state intact; retry notification.

### Email fails

Keep reservation state intact; retry notification.

### Analytics fails

Booking must continue.

### Map provider fails

Website should still show address/contact information.

External integrations should fail independently wherever possible.

---

# 133. GRACEFUL DEGRADATION

The website must prioritize core booking integrity over optional integrations.

Priority order:

```text
Reservation Integrity
    ↓
Payment Integrity
    ↓
Guest Confirmation
    ↓
Communication
    ↓
Analytics / Optional Enhancements
```

---

# 134. FUTURE EXTENSIONS

After this website is stable, the next planned artifact can be a separate:

```text
PLAN.md — GUEST APP
```

That plan can define:

- Guest activation.
- Current stay.
- Room.
- Requests.
- Reception communication.
- Housekeeping requests.
- Maintenance.
- Extension.
- Room change.
- Billing.
- Checkout.
- Notifications.

Later, a separate plan can define:

```text
PLAN.md — HOTEL PMS / RECEPTION
```

The separation is intentional.

---

# 135. FINAL CANONICAL WEBSITE STORY

The final website must support this story:

> A person discovers the hotel online and enters the official website. The website immediately presents the hotel's identity, rooms, facilities, location, policies, and booking option in a professional and easy-to-understand experience.
>
> The visitor chooses the desired dates and number of guests. The booking engine checks current inventory and shows available room types with their applicable prices and conditions.
>
> The guest selects a room, enters the required guest information, reviews the stay dates, room, number of nights, policies, charges, discounts, taxes/fees, and total amount.
>
> The guest chooses an available payment method. The system performs the required server-side validation and payment verification. If the booking is successfully confirmed, the system creates one authoritative reservation with a unique booking reference and a preserved price snapshot.
>
> The website immediately displays a confirmation page and makes a professional booking confirmation document available. Configured communication channels such as WhatsApp and email send the same authoritative booking information.
>
> Later, the guest can securely use the Manage Booking feature to retrieve the reservation, view its details, and perform only the modifications or cancellation actions allowed by the hotel's rules.
>
> At no point should the website claim a successful reservation when availability, payment, or server-side confirmation has not actually succeeded.
>
> The website therefore functions as the hotel's public digital front door and the controlled entry point into the larger hotel platform that will be built in later phases.

---

# 136. FINAL ARCHITECTURAL BOUNDARY

This website is:

```text
PUBLIC EXPERIENCE
+
BOOKING ENGINE
+
RESERVATION INTAKE
+
CONFIRMATION
+
PUBLIC BOOKING MANAGEMENT
```

It is NOT:

```text
FULL PMS
FULL RECEPTION SYSTEM
GUEST IN-STAY APP
HOUSEKEEPING SYSTEM
MAINTENANCE SYSTEM
FULL ACCOUNTING SYSTEM
```

The future application and PMS must integrate with the reservation domain created here.

---

# 137. FINAL NON-NEGOTIABLE PRINCIPLE

Build the website as a serious commercial booking platform, not as a collection of pretty screens.

The core success condition is:

```text
Real Guest
    ↓
Real Website
    ↓
Real Availability
    ↓
Real Booking
    ↓
Real Payment State
    ↓
Real Reservation
    ↓
Real Confirmation
```

Every screen exists to support that journey.

Every booking must be explainable.

Every price must be reproducible.

Every inventory decision must be safe.

Every critical state must be auditable.

And the entire implementation must remain small enough in scope to finish reliably before expanding into the separate guest application and hotel operations system.
