const AuthService = {
  async register(userData) {
    return { message: 'Register service ready', data: userData };
  },

  async login(credentials) {
    return { message: 'Login service ready', data: credentials };
  },
};

module.exports = AuthService;