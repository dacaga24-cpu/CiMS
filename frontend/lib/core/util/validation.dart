// Aquest fitxer concentra les constants de validació compartides entre
// pantalles. Les mantenim alineades amb els límits de la base de dades i
// del backend per evitar discrepàncies que podrien fer fallar peticions
// que des del client semblen vàlides.

// Llargada màxima del nom i dels cognoms d'un usuari. Coincideix amb
// `VARCHAR(30)` a `users.first_name` / `users.last_name` i amb les
// constants `MAX_FIRST_NAME_LENGTH` / `MAX_LAST_NAME_LENGTH` als
// controladors d'autenticació i d'usuari del backend.
const int kMaxUserNameLength = 30;
