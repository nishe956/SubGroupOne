class ApiEndpoints {
  static const String baseUrl = 'http://192.168.152.156:8000/api';
  
  // Auth
  static const String login = '/users/login/';
  static const String register = '/users/register/';
  static const String profile = '/users/profile/';
  
  // Products
  static const String getProducts = '/montures/';
  static String productDetail(int id) => '/montures/$id/';
  
  // OCR
  static const String scanPrescription = '/ordonnances/scanner/';
  static const String listPrescriptions = '/ordonnances/';
  
  // Orders
  static const String createOrder = '/commandes/';
  static const String myOrders = '/commandes/';
  
  // Try On
  static const String tryOn = '/essai-virtuel/creer/';
  // Admin Management
  static const String adminUsers = '/users/manage/';
  static String adminUserDetail(int id) => '/users/manage/$id/';
  static const String adminOrders = '/commandes/all/';
  static String adminOrderDetail(int id) => '/commandes/all/$id/';
  static const String adminPrescriptions = '/ordonnances/all/';
}
