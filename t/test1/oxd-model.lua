return {
    {
        expect = "/setup-client",
        required_fields = {
            "scope",
            "op_host",
            "authorization_redirect_uri",
            "client_name",
            "grant_types",
            -- "bla-bla", -- uncomment and check that test fail
        },
        response = {
            status = "ok",
            data = {
                oxd_id = "bcad760f-91ba-46e1-a020-05e4281d91b6",
                client_id_of_oxd_id = "@!1736.179E.AA60.16B2!0001!8F7C.B9AB!0008!A2BB.9AE6.AAA4",
                op_host = "https://example.com",
                setup_client_oxd_id = "qwerty",
                client_id = "@!1736.179E.AA60.16B2!0001!8F7C.B9AB!0008!A2BB.9AE6.5F14.B387",
                client_secret = "f436b936-03fc-433f-9772-53c2bc9e1c74",
                client_registration_access_token = "d836df94-44b0-445a-848a-d43189839b17",
                client_registration_client_uri = "https://<op-hostname>/oxauth/restv1/register?client_id=@!1736.179E.AA60.16B2!0001!8F7C.B9AB!0008!A2BB.9AE6.5F14.B387",
            },
        },
        response_callback = function(response)
            response.data.client_id_issued_at = ngx.now()
            response.data.client_secret_expires_at = ngx.now() + 60*60
            return response
        end,
    },
}