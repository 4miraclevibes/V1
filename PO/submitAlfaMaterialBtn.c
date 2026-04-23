If(
    IsBlank(inputMnPo.Text) || IsBlank(inputAnPo.Text),
    Notify("Material No dan Alfa No wajib diisi!", NotificationType.Warning),
    With(
        {
            result: POWERAPPS1.dboSPAlfamartMaterialInsert(
                {
                    material_no: inputMnPo.Text,
                    ALFAMART_no: inputAnPo.Text,
                    material_desc: inputMdPo.Text,
                    ALFAMART_desc: inputAdPo.Text
                }
            )
        },
        Notify("Data Alfa berhasil disimpan", NotificationType.Success);
        Reset(inputMnPo);
        Reset(inputAnPo);
        Reset(inputMdPo);
        Reset(inputAdPo)
    )
)