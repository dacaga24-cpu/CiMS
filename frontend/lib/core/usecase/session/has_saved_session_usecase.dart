// Aquest cas d’ús encapsula la comprovació d’una sessió guardada.
// La seva funció és oferir un punt únic on, en el futur, es podrà consultar
// si l’usuari ja té una sessió persistent i pot entrar directament a l’aplicació.
class HasSavedSessionUseCase {
  const HasSavedSessionUseCase();

  // Aquest mètode retorna si actualment hi ha una sessió guardada.
  // De moment queda preparat com a punt d’extensió fins que s’implementi
  // el sistema real de persistència de sessió.
  Future<bool> execute() async {
    // TODO: substituir per la comprovació real de sessió guardada
    return false;
  }
}
