-- Migració CIMS-332: reduïm els límits dels noms i cognoms dels usuaris
-- de 100/150 a 30/30 caracters. El client ja valida aquests límits abans
-- d'enviar la petició; aquesta migració alinea la base de dades.
--
-- Important: si hi ha usuaris existents amb noms o cognoms més llargs de
-- 30 caràcters, el MODIFY petarà amb data truncation. Si en prod en queda
-- algun, primer caldria truncar manualment amb un UPDATE controlat:
--
--   UPDATE users SET first_name = LEFT(first_name, 30) WHERE CHAR_LENGTH(first_name) > 30;
--   UPDATE users SET last_name  = LEFT(last_name, 30)  WHERE CHAR_LENGTH(last_name)  > 30;
--
-- Comprovem primer quants registres es veurien afectats:
--   SELECT COUNT(*) FROM users WHERE CHAR_LENGTH(first_name) > 30 OR CHAR_LENGTH(last_name) > 30;

ALTER TABLE users
  MODIFY first_name VARCHAR(30) NOT NULL,
  MODIFY last_name  VARCHAR(30) NOT NULL;
