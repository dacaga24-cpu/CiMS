const app = require('./app');
const testDb = require('./src/config/testDb');
require('dotenv').config();

const PORT = process.env.PORT || 3000;

app.listen(PORT, async () => {
  console.log(`Server running on port ${PORT}`);
  await testDb();
});
