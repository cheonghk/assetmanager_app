import 'package:assetmanager_app/Item.dart';

class ItemPair {
  final String itemLoc;
   Map<String, dynamic> items = Map();


  ItemPair(this.itemLoc, this.items);

  ItemPair.fromJson(Map<String, dynamic> json)
      : itemLoc = json['itemLoc'],
        items = json;

  Map<String, dynamic> toJson() => {
    'itemLoc': itemLoc,
    'items': items,
  };
}