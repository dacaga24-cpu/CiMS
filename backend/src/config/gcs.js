// Aquest fitxer centralitza la connexió amb Google Cloud Storage.
// Permet reutilitzar el bucket de fotos d’ascensions des de diferents parts del backend.
const { Storage } = require('@google-cloud/storage');

const bucketName = process.env.GCS_BUCKET_NAME;

// Aquesta validació assegura que el backend coneix el bucket abans d’iniciar-se.
// Si falta la configuració, l’error es mostra de manera clara i immediata.
if (!bucketName) {
  throw new Error(
    'GCS_BUCKET_NAME is not defined. Set it as an environment variable ' +
      'in Cloud Run or in the local .env file.'
  );
}

// Aquest client utilitza l’autenticació configurada a Google Cloud o a l’entorn local.
// A partir del nom del bucket, prepara l’accés on es guardaran les imatges.
const storage = new Storage();
const bucket = storage.bucket(bucketName);

module.exports = {
  bucket,
  bucketName,
};