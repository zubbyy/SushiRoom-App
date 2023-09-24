import 'package:sushi_room/models/user.dart';

class Plate {
  String id;
  String quantity;
  User orderedBy;
  bool arrived;

  Plate({
    required this.id,
    required this.quantity,
    required this.orderedBy,
    required this.arrived,
  });

  factory Plate.fromJson(Map<String, dynamic> json) {
    return Plate(
      id: json['id'],
      quantity: json['quantity'],
      orderedBy: User.fromJson(json['orderedBy']),
      arrived: json['arrived'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quantity': quantity,
      'orderedBy': orderedBy.toJson(),
      'arrived': arrived,
    };
  }
}