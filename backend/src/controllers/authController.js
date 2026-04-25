const AuthService = require('../services/authService');
const UserModel = require('../models/userModel');

// Aquesta expressió serveix per fer una comprovació del format del correu electrònic
// abans d’intentar registrar o validar un usuari. La validació definitiva l'ha de fer
// l'enviament real del correu, però aquesta primera barrera bloqueja entrades
// clarament invàlides com cadenes sense @, sense domini o amb caràcters prohibits.
// Es requereix:
//   - una part local amb caràcters habituals (lletres, dígits, punt i alguns símbols)
//   - exactament una @
//   - un domini amb almenys un punt i una extensió de dues lletres com a mínim
// Aquesta forma cobreix la gran majoria de correus reals sense intentar implementar
// l'estàndard RFC 5322 complet, que requeriria una llibreria dedicada.
const EMAIL_REGEX = /^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/;
const MIN_EMAIL_LENGTH = 5;

// Aquestes constants defineixen els límits de longitud acceptats als camps del registre.
// Coincideixen amb els tipus definits a la base de dades per evitar errors d'inserció
// i protegeixen l'aplicació davant de valors desmesuradament llargs.
// El màxim de contrasenya és especialment rellevant perquè bcrypt és lent per disseny
// i hashear contrasenyes molt grans pot convertir-se en un vector d'atac de CPU.
const MAX_FIRST_NAME_LENGTH = 100;
const MAX_LAST_NAME_LENGTH = 150;
const MAX_EMAIL_LENGTH = 255;
const MIN_PASSWORD_LENGTH = 8;
const MAX_PASSWORD_LENGTH = 128;

// Aquest mètode crea un error de validació amb codi 400.
// S’utilitza quan falten dades o quan el format rebut no és correcte.
function badRequest(message) {
  const error = new Error(message);
  error.statusCode = 400;
  return error;
}

// Aquest controlador gestiona les peticions relacionades amb l’autenticació i el perfil d’usuari.
// La seva funció és rebre les dades de la petició, validar les més bàsiques,
// delegar la feina al servei corresponent i enviar la resposta HTTP.
const AuthController = {

  // Aquest mètode gestiona el registre d’un nou usuari.
  // Comprova que arribin totes les dades necessàries, valida el correu i la longitud mínima
  // de la contrasenya i, si tot és correcte, crea el compte a través del servei.
  async register(req, res, next) {
    try {
      const { firstName, lastName, email, password } = req.body || {};
      if (!firstName || !lastName || !email || !password) {
        throw badRequest('Missing required fields: firstName, lastName, email, password');
      }

      // Aquestes comprovacions de longitud eviten que es puguin enviar valors
      // més grans del que la base de dades accepta i protegeixen el servidor
      // davant de peticions amb camps desmesuradament llargs.
      if (firstName.length > MAX_FIRST_NAME_LENGTH) {
        throw badRequest(`First name must be at most ${MAX_FIRST_NAME_LENGTH} characters long`);
      }
      if (lastName.length > MAX_LAST_NAME_LENGTH) {
        throw badRequest(`Last name must be at most ${MAX_LAST_NAME_LENGTH} characters long`);
      }
      if (email.length < MIN_EMAIL_LENGTH) {
        throw badRequest(`Email must be at least ${MIN_EMAIL_LENGTH} characters long`);
      }
      if (email.length > MAX_EMAIL_LENGTH) {
        throw badRequest(`Email must be at most ${MAX_EMAIL_LENGTH} characters long`);
      }
      if (!EMAIL_REGEX.test(email)) {
        throw badRequest('Invalid email format');
      }
      if (password.length < MIN_PASSWORD_LENGTH) {
        throw badRequest(`Password must be at least ${MIN_PASSWORD_LENGTH} characters long`);
      }

      // El límit superior de la contrasenya protegeix contra peticions que intenten
      // saturar el servidor enviant contrasenyes molt llargues per fer patir bcrypt.
      if (password.length > MAX_PASSWORD_LENGTH) {
        throw badRequest(`Password must be at most ${MAX_PASSWORD_LENGTH} characters long`);
      }

      const { id } = await AuthService.register({ firstName, lastName, email, password });
      res.status(201).json({ message: 'User created', userId: id });
    } catch (error) {
      next(error);
    }
  },

  // Aquest mètode gestiona l’inici de sessió.
  // Rep el correu i la contrasenya, comprova que s’hagin enviat
  // i delega al servei la validació de les credencials.
  async login(req, res, next) {
    try {
      const { email, password } = req.body || {};
      if (!email || !password) {
        throw badRequest('Missing required fields: email, password');
      }

      const result = await AuthService.login({ email, password });
      res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  },

  // Aquest mètode inicia el procés de restabliment de contrasenya.
  // Només necessita el correu de l’usuari per començar el flux de recuperació.
  async requestPasswordReset(req, res, next) {
    try {
      const { email } = req.body || {};
      if (!email) {
        throw badRequest('Missing required field: email');
      }

      const result = await AuthService.requestPasswordReset(email);
      res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  },

  // Aquest mètode aplica el canvi de contrasenya.
  // Rep el token de recuperació i la nova contrasenya, comprova que siguin vàlids
  // i delega al servei l’actualització final.
  async resetPassword(req, res, next) {
    try {
      const { token, newPassword } = req.body || {};

      if (!token || !newPassword) {
        throw badRequest('Missing required fields: token, newPassword');
      }
      if (newPassword.length < MIN_PASSWORD_LENGTH) {
        throw badRequest(`Password must be at least ${MIN_PASSWORD_LENGTH} characters long`);
      }

      // Es reutilitza el mateix límit superior que al registre per evitar que
      // una recuperació de contrasenya es pugui fer servir per saturar bcrypt.
      if (newPassword.length > MAX_PASSWORD_LENGTH) {
        throw badRequest(`Password must be at most ${MAX_PASSWORD_LENGTH} characters long`);
      }

      const result = await AuthService.resetPassword({ token, newPassword });
      res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  },

  // Aquest mètode retorna el perfil de l’usuari que ja ha iniciat sessió.
  // L’identificador de l’usuari arriba informat des del sistema d’autenticació
  // i es fa servir per recuperar les seves dades.
  async getProfile(req, res, next) {
    try {
      const userId = req.userId; // Valor establert pel middleware d'autenticació
      const user = await UserModel.findById(userId);

      if (!user) {
        const error = new Error('User not found');
        error.statusCode = 404;
        throw error;
      }

      // El model ja retorna les dades preparades per a la resposta
      // i exclou la contrasenya per motius de seguretat.
      res.status(200).json(user);
    } catch (error) {
      next(error);
    }
  },
};

module.exports = AuthController;
