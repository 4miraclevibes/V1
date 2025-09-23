//base pallete color
If(
    ThisItem.top50 = true,
    RGBA(156, 220, 79, 1),  // Hijau jika true
    RGBA(249, 83, 109, 1)   // Merah jika false
)

//on select

Patch(
    MP_CUSTOMER,
    LookUp(MP_CUSTOMER, id = ThisItem.customer_id),
    {
        top50: !ThisItem.top50
    }
);

