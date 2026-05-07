const sgMail = require('@sendgrid/mail');

// Servei d'enviament de correus via SendGrid.
sgMail.setApiKey(process.env.SENDGRID_API_KEY);

const EmailService = {

  // Correu de recuperació de contrasenya. expiryHours es passa com a
  // paràmetre perquè el missatge coincideixi amb la durada real del backend.
  async sendPasswordReset({ to, token, expiryHours }) {
    const resetUrl = `${process.env.APP_URL}/reset-password?token=${token}`;
    const expiryLabel = `${expiryHours} ${expiryHours === 1 ? 'hora' : 'hores'}`;

    const msg = {
      to,
      from: process.env.MAIL_FROM,
      subject: 'Recuperació de contrasenya — CiMS',
      text: `Has sol·licitat recuperar la teva contrasenya. Accedeix a aquest enllaç per restablir-la: ${resetUrl}. L'enllaç caduca en ${expiryLabel}. Si no has fet aquesta sol·licitud, ignora aquest missatge.`,
      html: `
        <!DOCTYPE html>
        <html lang="ca">
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
        </head>
        <body style="margin:0;padding:0;background-color:#f5f5f5;font-family:Arial,sans-serif;">
          <table width="100%" cellpadding="0" cellspacing="0" style="background-color:#f5f5f5;padding:40px 0;">
            <tr>
              <td align="center">
                <table width="600" cellpadding="0" cellspacing="0" style="background-color:#ffffff;border-radius:8px;overflow:hidden;">

                  <tr>
                    <td style="background-color:#1a1a2e;padding:32px 40px;">
                      <h1 style="margin:0;color:#ffffff;font-size:24px;font-weight:600;">CiMS</h1>
                      <p style="margin:4px 0 0;color:#a0a0b0;font-size:13px;">Catàleg de cims de Catalunya</p>
                    </td>
                  </tr>

                  <tr>
                    <td style="padding:40px;">
                      <h2 style="margin:0 0 16px;color:#1a1a2e;font-size:20px;font-weight:600;">Recuperació de contrasenya</h2>
                      <p style="margin:0 0 24px;color:#444444;font-size:15px;line-height:1.6;">
                        Has sol·licitat restablir la contrasenya del teu compte. Fes clic al botó següent per continuar.
                      </p>

                      <table cellpadding="0" cellspacing="0" style="margin:0 0 32px;">
                        <tr>
                          <td style="background-color:#1a1a2e;border-radius:6px;">
                            <a href="${resetUrl}" style="display:inline-block;padding:14px 32px;color:#ffffff;font-size:15px;font-weight:600;text-decoration:none;">
                              Restablir contrasenya
                            </a>
                          </td>
                        </tr>
                      </table>

                      <p style="margin:0 0 8px;color:#888888;font-size:13px;line-height:1.6;">
                        Si el botó no funciona, copia i enganxa aquest enllaç al navegador:
                      </p>
                      <p style="margin:0 0 32px;word-break:break-all;">
                        <a href="${resetUrl}" style="color:#1a1a2e;font-size:13px;">${resetUrl}</a>
                      </p>

                      <table width="100%" cellpadding="0" cellspacing="0">
                        <tr>
                          <td style="border-top:1px solid #eeeeee;padding-top:24px;">
                            <p style="margin:0;color:#888888;font-size:13px;line-height:1.6;">
                              L'enllaç caduca en <strong>${expiryLabel}</strong>.<br>
                              Si no has fet aquesta sol·licitud, pots ignorar aquest missatge.
                            </p>
                          </td>
                        </tr>
                      </table>
                    </td>
                  </tr>

                  <tr>
                    <td style="background-color:#f5f5f5;padding:24px 40px;border-top:1px solid #eeeeee;">
                      <p style="margin:0;color:#aaaaaa;font-size:12px;text-align:center;">
                        © 2025 CiMS · BemenFP
                      </p>
                    </td>
                  </tr>

                </table>
              </td>
            </tr>
          </table>
        </body>
        </html>
      `,
    };

    await sgMail.send(msg);
  },
};

module.exports = EmailService;