const express = require('express');
const router = express.Router();

// Aquesta expressió valida el format del token de recuperació.
// Evita utilitzar valors inesperats dins de la pàgina de restabliment de contrasenya.
const TOKEN_FORMAT_REGEX = /^[a-f0-9]{64}$/;

// Aquest middleware adapta la política de seguretat només per a aquesta pàgina.
// Permet que el formulari HTML funcioni sense afectar la configuració general de l’API.
function allowInlineScriptsForResetPage(req, res, next) {
  res.setHeader(
    'Content-Security-Policy',
    "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; base-uri 'self'; form-action 'self'",
  );
  next();
}

// Aquesta ruta serveix la pàgina de restabliment de contrasenya.
// El token arriba per la URL i permet associar el formulari amb la sol·licitud de recuperació.
router.get('/', allowInlineScriptsForResetPage, (req, res) => {
  const { token } = req.query;

  // Aquesta validació rebutja enllaços sense token o amb un format incorrecte.
  // Això evita mostrar un formulari de recuperació quan l’enllaç no és vàlid.
  if (!token || typeof token !== 'string' || !TOKEN_FORMAT_REGEX.test(token)) {
    return res.status(400).send(`
      <!DOCTYPE html>
      <html lang="ca">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Enllaç no vàlid — CiMS</title>
        <style>
          body { font-family: Arial, sans-serif; display: flex; justify-content: center; align-items: center; min-height: 100vh; margin: 0; background: #f5f5f5; }
          .card { background: white; border-radius: 8px; padding: 40px; max-width: 400px; width: 100%; text-align: center; }
          h1 { color: #1a1a2e; font-size: 20px; margin-bottom: 12px; }
          p { color: #666; font-size: 14px; line-height: 1.6; }
        </style>
      </head>
      <body>
        <div class="card">
          <h1>Enllaç no vàlid</h1>
          <p>Aquest enllaç de recuperació no és vàlid o ha caducat. Sol·licita un nou enllaç des de l'aplicació.</p>
        </div>
      </body>
      </html>
    `);
  }

  // Si el token té un format vàlid, es mostra el formulari per definir la nova contrasenya.
  res.send(`
    <!DOCTYPE html>
    <html lang="ca">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Restablir contrasenya — CiMS</title>
      <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body { font-family: Arial, sans-serif; background: #f5f5f5; display: flex; justify-content: center; align-items: center; min-height: 100vh; }
        .card { background: white; border-radius: 8px; padding: 40px; max-width: 420px; width: 100%; margin: 20px; }
        .header { margin-bottom: 32px; }
        .header h1 { color: #1a1a2e; font-size: 22px; font-weight: 600; margin-bottom: 4px; }
        .header p { color: #888; font-size: 13px; }
        label { display: block; font-size: 13px; color: #444; margin-bottom: 6px; }
        input { width: 100%; padding: 12px 14px; border: 1px solid #ddd; border-radius: 6px; font-size: 14px; margin-bottom: 16px; outline: none; transition: border 0.2s; }
        input:focus { border-color: #1a1a2e; }
        button { width: 100%; padding: 14px; background: #1a1a2e; color: white; border: none; border-radius: 6px; font-size: 15px; font-weight: 600; cursor: pointer; }
        button:hover { background: #2d2d4e; }
        .message { margin-top: 16px; padding: 12px; border-radius: 6px; font-size: 14px; text-align: center; display: none; }
        .message.success { background: #eafaf1; color: #1e8449; display: block; }
        .message.error { background: #fdecea; color: #c0392b; display: block; }
      </style>
    </head>
    <body>
      <div class="card">
        <div class="header">
          <h1>Restablir contrasenya</h1>
          <p>Introdueix la teva nova contrasenya</p>
        </div>

        <label for="newPassword">Nova contrasenya</label>
        <input type="password" id="newPassword" placeholder="Mínim 8 caràcters" />

        <label for="confirmPassword">Confirma la contrasenya</label>
        <input type="password" id="confirmPassword" placeholder="Repeteix la contrasenya" />

        <button onclick="handleSubmit()">Restablir contrasenya</button>

        <div id="message" class="message"></div>
      </div>

      <script>
        const TOKEN = '${token}';

        // Aquesta URL relativa envia la nova contrasenya al mateix backend que serveix el formulari.
        // Això permet que la pàgina funcioni igual en local i en producció.
        const API_URL = '/api/auth/reset-password';

        async function handleSubmit() {
          const newPassword = document.getElementById('newPassword').value;
          const confirmPassword = document.getElementById('confirmPassword').value;
          const messageEl = document.getElementById('message');

          messageEl.className = 'message';
          messageEl.textContent = '';

          if (!newPassword || !confirmPassword) {
            messageEl.className = 'message error';
            messageEl.textContent = 'Omple tots els camps.';
            return;
          }

          if (newPassword.length < 8) {
            messageEl.className = 'message error';
            messageEl.textContent = 'La contrasenya ha de tenir mínim 8 caràcters.';
            return;
          }

          if (newPassword !== confirmPassword) {
            messageEl.className = 'message error';
            messageEl.textContent = 'Les contrasenyes no coincideixen.';
            return;
          }

          try {
            const response = await fetch(API_URL, {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({ token: TOKEN, newPassword }),
            });

            const data = await response.json();

            if (response.ok) {
              messageEl.className = 'message success';
              messageEl.textContent = 'Contrasenya restablerta correctament. Ja pots iniciar sessió.';
            } else {
              messageEl.className = 'message error';
              messageEl.textContent = data.error || 'Hi ha hagut un error. Torna-ho a provar.';
            }
          } catch {
            messageEl.className = 'message error';
            messageEl.textContent = 'No s\'ha pogut connectar amb el servidor.';
          }
        }
      </script>
    </body>
    </html>
  `);
});

module.exports = router;