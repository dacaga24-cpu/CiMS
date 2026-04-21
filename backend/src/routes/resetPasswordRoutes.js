const express = require('express');
const router = express.Router();

// Aquesta expressió valida el format del token de recuperació.
// El token es genera amb crypto.randomBytes(32).toString('hex'),
// de manera que sempre ha de ser una cadena de 64 caràcters hexadecimals.
// Comprovar-ho abans d'incrustar-lo a l'HTML és una defensa en profunditat
// contra possibles atacs XSS si mai canviés la generació del token o si
// algú intentés manipular el valor per query string.
const TOKEN_FORMAT_REGEX = /^[a-f0-9]{64}$/;

// Aquesta ruta serveix la pàgina HTML de restabliment de contrasenya.
// Rep el token per query string i el passa al formulari perquè l'usuari
// pugui introduir la nova contrasenya.
router.get('/', (req, res) => {
  const { token } = req.query;

  // Es rebutja qualsevol petició sense token o amb un format que no coincideixi
  // amb el patró esperat. Si el token arriba amb caràcters inesperats, es
  // tracta com un enllaç no vàlid i ni tan sols s'interpola a la resposta.
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

  // Si el token existeix, es serveix el formulari per introduir la nova contrasenya.
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
        const API_URL = 'https://cims-backend-639822259289.europe-southwest1.run.app/api/auth/reset-password';

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