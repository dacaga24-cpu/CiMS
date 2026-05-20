const pool = require('../config/db');

// Aquest model centralitza l'accés a les dades dels cims.
// La seva funció és recuperar cims, aplicar filtres del catàleg
// i unir-los amb les comarques a les quals pertanyen.

// Aquesta constant defineix el bucket utilitzat per a les fotos públiques del catàleg.
// Si existeix PEAK_PHOTOS_BUCKET_NAME, s'utilitza aquest bucket específic.
// Si no existeix, es fa servir GCS_BUCKET_NAME com a compatibilitat amb la configuració actual.
const peakPhotosBucketName = process.env.PEAK_PHOTOS_BUCKET_NAME || process.env.GCS_BUCKET_NAME;

// Aquesta constant defineix com es recupera la imatge pública d'un cim.
// Es fa amb una subconsulta per obtenir una única foto per cim i evitar
// duplicats si en el futur s'afegeixen diverses imatges a peak_photos.
const PEAK_PHOTO_JOIN = `
    LEFT JOIN (
        SELECT pp.peak_id, pp.storage_path
        FROM peak_photos pp
        INNER JOIN (
            SELECT peak_id, MIN(id) AS id
            FROM peak_photos
            GROUP BY peak_id
        ) first_photo ON first_photo.id = pp.id
    ) pp ON pp.peak_id = p.id
`;

// Construeix una URL pública a partir de la ruta interna guardada a la base
// de dades. La base de dades només manté el storage_path, per exemple
// peaks/02_pedraforca.jpg, i el bucket es defineix per variable d'entorn.
function buildPublicImageUrl(storagePath) {
    if (!storagePath || !peakPhotosBucketName) {
        return null;
    }

    const encodedPath = storagePath
        .split('/')
        .map(encodeURIComponent)
        .join('/');

    return `https://storage.googleapis.com/${peakPhotosBucketName}/${encodedPath}`;
}

// Normalitza una fila de base de dades al format que consumeix el frontend.
// També transforma el storage_path de la foto en una URL pública preparada
// per mostrar-se directament amb Image.network o equivalent.
function mapPeakRow(row) {
    return {
        id: row.id,
        name: row.name,
        altitude: row.altitude,
        latitude: row.latitude,
        longitude: row.longitude,
        description: row.description,
        imageUrl: buildPublicImageUrl(row.photo_storage_path),
    };
}

// Construeix el fragment WHERE i els paràmetres associats per als filtres
// del catàleg. S'extreu en una funció pròpia perquè els tres punts d'entrada
// (llista paginada, vista de mapa, comptador) han d'aplicar exactament el
// mateix conjunt de filtres i mantenir una única font de veritat evita
// divergències quan se n'afegeixin de nous.
function buildPeakFilters({ regionId, minAltitude, maxAltitude, search } = {}) {
    const conditions = [];
    const params = [];
    let join = '';

    if (regionId !== undefined && regionId !== null) {
        join = ' INNER JOIN peak_regions pr ON pr.peak_id = p.id ';
        conditions.push('pr.region_id = ?');
        params.push(regionId);
    }

    if (minAltitude !== undefined && minAltitude !== null) {
        conditions.push('p.altitude >= ?');
        params.push(minAltitude);
    }

    if (maxAltitude !== undefined && maxAltitude !== null) {
        conditions.push('p.altitude <= ?');
        params.push(maxAltitude);
    }

    if (search) {
        conditions.push('p.name LIKE ?');
        params.push(`%${search}%`);
    }

    const where = conditions.length > 0 ? ' WHERE ' + conditions.join(' AND ') : '';
    return { join, where, params };
}

// Adjunta a una llista de cims les seves comarques associades en una sola
// query agrupada per peak_id. Així s'evita el patró N+1 que faria una
// consulta per cada cim. Si la llista d'entrada és buida, no es fa cap
// query i es retorna directament.
async function attachRegionsToPeaks(peaks) {
    if (peaks.length === 0) {
        return peaks;
    }

    const peakIds = peaks.map((peak) => peak.id);
    const placeholders = peakIds.map(() => '?').join(', ');
    const sql = `
        SELECT pr.peak_id, r.id, r.name
        FROM peak_regions pr
        INNER JOIN regions r ON r.id = pr.region_id
        WHERE pr.peak_id IN (${placeholders})
        ORDER BY r.name ASC
    `;

    const [rows] = await pool.execute(sql, peakIds);

    const regionsByPeakId = new Map();
    for (const row of rows) {
        if (!regionsByPeakId.has(row.peak_id)) {
            regionsByPeakId.set(row.peak_id, []);
        }
        regionsByPeakId.get(row.peak_id).push({ id: row.id, name: row.name });
    }

    for (const peak of peaks) {
        peak.regions = regionsByPeakId.get(peak.id) || [];
    }

    return peaks;
}

const PeakModel = {

    // Aquest mètode retorna la llista paginada de cims que compleixen els
    // filtres rebuts. La paginació és offset-based: limit defineix la mida
    // de la pàgina i offset des de quin element començar. Tots els filtres
    // són opcionals i es combinen amb AND.
    //
    // L'ordre per altitud descendent + nom ascendent és estable, condició
    // imprescindible per a la paginació: sense un ORDER BY determinístic,
    // dues pàgines consecutives podrien repetir o saltar-se cims si MySQL
    // canvia l'ordre intern entre crides.
    async findAll({ regionId, minAltitude, maxAltitude, search, limit, offset } = {}) {
        const { join, where, params } = buildPeakFilters({
            regionId, minAltitude, maxAltitude, search,
        });

        let sql = `
            SELECT DISTINCT
                p.id,
                p.name,
                p.altitude,
                p.latitude,
                p.longitude,
                p.description,
                pp.storage_path AS photo_storage_path
            FROM peaks p
            ${PEAK_PHOTO_JOIN}
            ${join}
            ${where}
            ORDER BY p.altitude DESC, p.name ASC
        `;

        // LIMIT i OFFSET s'interpolen directament a la cadena perquè
        // pool.execute() (statements preparats) tracta aquestes clàusules
        // com a strings i MySQL les rebutja; pool.query() les acceptaria
        // però perdríem la resta de paràmetres preparats. Els valors es
        // validen al servei (peakService.getPage) i, com a defensa local,
        // aquí es comprova que siguin enters dins del rang esperat abans
        // d'incloure'ls al SQL.
        //
        // Si el caller passa offset sense limit, l'OFFSET s'ignora perquè
        // SQL standard requereix LIMIT per acceptar OFFSET. Aquesta restricció
        // és intencionada: la paginació sempre ha de venir acompanyada de
        // mida de pàgina, i així el comportament és predictible.
        if (Number.isInteger(limit) && limit > 0) {
            sql += ` LIMIT ${limit}`;
            if (offset !== undefined) {
                if (!Number.isInteger(offset) || offset < 0) {
                    throw new Error(`Invalid offset: must be a non-negative integer (received ${offset})`);
                }
                if (offset > 0) {
                    sql += ` OFFSET ${offset}`;
                }
            }
        }

        const [rows] = await pool.execute(sql, params);
        return attachRegionsToPeaks(rows.map(mapPeakRow));
    },

    // Compta el nombre total de cims que coincideixen amb els filtres.
    // S'utilitza des del servei per omplir el camp totalItems de la resposta
    // paginada perquè el frontend pugui calcular quantes pàgines hi ha
    // disponibles i mostrar el comptador "X cims trobats" als filtres.
    //
    // S'usa SELECT COUNT(DISTINCT p.id) perquè el JOIN amb peak_regions pot
    // duplicar files quan un cim pertany a més d'una comarca i això inflaria
    // el comptador respecte als resultats reals que retorna findAll.
    async count({ regionId, minAltitude, maxAltitude, search } = {}) {
        const { join, where, params } = buildPeakFilters({
            regionId, minAltitude, maxAltitude, search,
        });

        const sql = `
            SELECT COUNT(DISTINCT p.id) AS total
            FROM peaks p
            ${join}
            ${where}
        `;

        const [rows] = await pool.execute(sql, params);
        return Number(rows[0].total);
    },

    // Retorna tots els cims que coincideixen amb els filtres amb els camps
    // necessaris per pintar-los al mapa: id, nom, coordenades, altitud,
    // imatge pública i les comarques associades. Les comarques s'inclouen
    // perquè la targeta del cim seleccionat al mapa les mostra; sense aquest
    // camp el frontend no té manera de saber a quina comarca pertany cada
    // cim sense fer una petició addicional per cada selecció.
    // Aquest endpoint no té límit de resultats: és la vista que ha de mostrar
    // sempre el conjunt complet de cims que casen amb els filtres.
    async findAllForMap({ regionId, minAltitude, maxAltitude, search } = {}) {
        const { join, where, params } = buildPeakFilters({
            regionId, minAltitude, maxAltitude, search,
        });

        const sql = `
            SELECT DISTINCT
                p.id,
                p.name,
                p.altitude,
                p.latitude,
                p.longitude,
                NULL AS description,
                pp.storage_path AS photo_storage_path
            FROM peaks p
            ${PEAK_PHOTO_JOIN}
            ${join}
            ${where}
            ORDER BY p.altitude DESC, p.name ASC
        `;

        const [rows] = await pool.execute(sql, params);
        return attachRegionsToPeaks(rows.map(mapPeakRow));
    },

    // Aquest mètode busca un cim pel seu identificador i hi afegeix la
    // llista de comarques a les quals pertany. Retorna les comarques en
    // una única resposta perquè el consumidor (vista de detall) tingui
    // tota la informació sense haver de fer una segona crida.
    async findById(id) {
        const sqlPeak = `
        SELECT
            p.id,
            p.name,
            p.altitude,
            p.latitude,
            p.longitude,
            p.description,
            pp.storage_path AS photo_storage_path
        FROM peaks p
        ${PEAK_PHOTO_JOIN}
        WHERE p.id = ?
        LIMIT 1
        `;

        const [peakRows] = await pool.execute(sqlPeak, [id]);
        const peak = peakRows[0] ? mapPeakRow(peakRows[0]) : null;

        if (!peak) {
            return null;
        }

        // Les comarques es consulten en una segona query separada per no
        // duplicar files quan un cim pertany a més d'una comarca: si es fes
        // amb un JOIN a la consulta principal, MySQL retornaria una fila per
        // cada parella (cim, comarca) i caldria desduplicar a codi.
        const sqlRegions = `
        SELECT r.id, r.name
        FROM regions r
        INNER JOIN peak_regions pr ON pr.region_id = r.id
        WHERE pr.peak_id = ?
        ORDER BY r.name ASC
        `;

        const [regionRows] = await pool.execute(sqlRegions, [id]);
        peak.regions = regionRows;

        return peak;
    },
};

module.exports = PeakModel;