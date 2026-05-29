/// Configuration centralisée de l'API Django.
///
/// Modifier [baseUrl] selon l'environnement :
///   - Émulateur Android : http://10.0.2.2:8000
///   - Simulateur iOS    : http://localhost:8000
///   - Appareil physique : http://IP-LAN:8000
abstract final class ApiConfig {
  /// URL de base du serveur Django.
  static const String baseUrl = 'http://10.0.2.2:8000';

  // ── Auth / Utilisateurs ──────────────────────────────────────────────
  static const String login    = '/api/users/login/';
  static const String register = '/api/users/register/';
  static const String profil   = '/api/users/profil/';
  static const String listeUsers = '/api/users/liste/';

  // ── Montures ─────────────────────────────────────────────────────────
  static const String montures = '/api/montures/';
  static String montureDetail(int id) => '/api/montures/$id/';

  // ── Ordonnances ──────────────────────────────────────────────────────
  static const String ordonnances        = '/api/ordonnances/';
  static const String ajouterOrdonnance  = '/api/ordonnances/ajouter/';
  static const String scannerOrdonnance  = '/api/ordonnances/scanner/';
  static String ordonnanceDetail(int id) => '/api/ordonnances/$id/';
  static String validerOrdonnance(int id) => '/api/ordonnances/$id/valider/';

  // ── Commandes ────────────────────────────────────────────────────────
  static const String commandes      = '/api/commandes/';
  static const String passerCommande = '/api/commandes/passer/';
  static String commandeDetail(int id) => '/api/commandes/$id/';
  static String gererCommande(int id) => '/api/commandes/$id/gerer/';

  // ── Essai virtuel ────────────────────────────────────────────────────
  static const String essayerMonture = '/api/essai/essayer/';
}
