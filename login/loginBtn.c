If(
    !IsBlank(usernameInputForm.Value) && !IsBlank(passwordInputForm.Value),
    With(
        {
            // Execute stored procedure seperti di SQL
            result: POWERAPPS1.dboLoginUserFSS(
                {
                    Username: usernameInputForm.Value,
                    Password: passwordInputForm.Value
                }
            )
        },
        // Cek apakah ada data yang dikembalikan
        If(
            CountRows(result.ResultSets.Table1) > 0,
            // Login berhasil
            Set(
                currentUser,
                {
                    username: Text(First(result.ResultSets.Table1).username),
                    status: "active",
                    role: Text(First(result.ResultSets.Table1).role),
                    distributor: Text(First(result.ResultSets.Table1).distributor)
                }
            );
            Set(
                userRole,
                First(result.ResultSets.Table1).role
            );
            Navigate(
                CostumerScreen,
                ScreenTransition.Fade
            );
            Notify(
                "Login berhasil!",
                NotificationType.Success
            ),
            // Login gagal
            Notify(
                "Username atau password salah!",
                NotificationType.Error
            )
        )
    ),
    Notify(
        "Username dan password harus diisi!",
        NotificationType.Warning
    )
)