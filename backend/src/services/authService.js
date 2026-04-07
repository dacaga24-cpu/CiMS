  const bcrypt = require('bcrypt');

  const SALT_ROUNDS = 10;

  const AuthService = {

    async hashPassword(password) {
      return await bcrypt.hash(password, SALT_ROUNDS);
    },

    async comparePassword(plainPassword, hashedPassword) {
      return await bcrypt.compare(plainPassword, hashedPassword);
    },
  };

  module.exports = AuthService;