const pool = require('../config/db');

// Aquest model agrupa les consultes agregades específiques per a la pantalla
// d'estadístiques. Es manté separat dels models de domini (peakStatus, ascent)
// perquè aquí hi viuen JOINs i agregacions que no tenen lloc en cap d'aquells
// recursos individuals i que servirien només a aquesta vista.
const StatsModel = {

  // Retorna l'altitud màxima entre els cims que l'usuari ha marcat com a
  // assolits. Es resol amb una sola query agregada per evitar carregar la
  // taula sencera de peaks al servidor d'aplicació. Si l'usuari encara no
  // ha completat cap cim, retorna null perquè el servei pugui distingir
  // aquest cas i no enviar un zero ambigu al client.
  async getHighestCompletedAltitude(userId) {
    const sql = `
      SELECT MAX(p.altitude) AS highest_altitude
      FROM peak_status ps
      INNER JOIN peaks p ON p.id = ps.peak_id
      WHERE ps.user_id = ? AND ps.is_completed = 1
    `;

    const [rows] = await pool.execute(sql, [userId]);
    const value = rows[0] ? rows[0].highest_altitude : null;
    return value === null ? null : Number(value);
  },
};

module.exports = StatsModel;
