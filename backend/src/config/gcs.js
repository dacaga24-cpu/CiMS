// Aquest fitxer prepara la connexió compartida amb Google Cloud Storage.
// La seva funció és centralitzar la inicialització del client i exposar el
// bucket on es guarden les fotos d'ascensions perquè la resta del backend
// no hagi de saber d'on surten les credencials ni el nom concret del bucket.
//
// L'autenticació amb GCP es resol automàticament per la llibreria. A Cloud
// Run, la Service Account associada al servei està disponible sense cap
// variable extra. En desenvolupament local, cal definir la variable
// GOOGLE_APPLICATION_CREDENTIALS apuntant al fitxer JSON de la clau d'una
// Service Account amb permisos Storage Object Admin sobre el bucket i
// Service Account Token Creator sobre si mateixa (necessari per signar URLs).
const { Storage } = require('@google-cloud/storage');

const bucketName = process.env.GCS_BUCKET_NAME;

// El backend necessita saber a quin bucket ha de pujar i llegir. Si la variable
// no està definida, es para l'arrencada amb un missatge clar perquè no es
// detecti l'error tard, en mig del primer intent de pujada.
if (!bucketName) {
  throw new Error(
    'GCS_BUCKET_NAME is not defined. Set it as an environment variable ' +
      'in Cloud Run or in the local .env file.'
  );
}

const storage = new Storage();
const bucket = storage.bucket(bucketName);

module.exports = {
  bucket,
  bucketName,
};
