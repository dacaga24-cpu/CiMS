// Connexió compartida amb Google Cloud Storage.
//
// Autenticació automàtica: a Cloud Run la Service Account associada al
// servei està disponible sense variables extra. En local cal definir
// GOOGLE_APPLICATION_CREDENTIALS apuntant a un JSON de SA amb permisos
// Storage Object Admin sobre el bucket i Service Account Token Creator
// sobre si mateixa (necessari per signar URLs).
const { Storage } = require('@google-cloud/storage');

const bucketName = process.env.GCS_BUCKET_NAME;

// Si la variable falta, parem l'arrencada amb un missatge clar per no
// detectar l'error tard al primer intent de pujada.
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
