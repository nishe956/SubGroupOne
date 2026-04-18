class AppNotification {
  final int id;
  final String titre;
  final String message;
  final bool isRead;
  final String typeNotif;
  final DateTime timestamp;
  final int? relatedId;

  AppNotification({
    required this.id,
    required this.titre,
    required this.message,
    required this.isRead,
    required this.typeNotif,
    required this.timestamp,
    this.relatedId,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      titre: json['titre'],
      message: json['message'],
      isRead: json['is_read'],
      typeNotif: json['type_notif'],
      timestamp: DateTime.parse(json['timestamp']),
      relatedId: json['related_id'],
    );
  }
}
