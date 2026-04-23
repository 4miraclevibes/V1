If(
    IsBlank(inputSoldNoPo.Text) || IsBlank(inputShipNoPo.Text) || IsBlank(inputAlfaSoldNoPo.Text),
    Notify("SOLD TO, SHIP TO, dan Alfa Sold No wajib diisi!", NotificationType.Warning),
    With(
        {
            result: POWERAPPS1.dboSPAlfamartCustomerInsert(
                {
                    SOLD_TO_NO: inputSoldNoPo.Text,
                    SHIP_TO_NO: inputShipNoPo.Text,
                    ALFAMART_SOLD_NO: inputAlfaSoldNoPo.Text,
                    DESCRIPTION: inputDescPo.Text,
                    TEXT: inputTextPo.Text,
                    STATUS: inputStatusPo.Text
                }
            )
        },
        Notify("Data Alfa Customer berhasil disimpan", NotificationType.Success);
        Reset(inputSoldNoPo);
        Reset(inputShipNoPo);
        Reset(inputAlfaSoldNoPo);
        Reset(inputDescPo);
        Reset(inputTextPo);
        Reset(inputStatusPo)
    )
)

