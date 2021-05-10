class Item {
   String itemId;
   String itemName;
   String itemLoc;
   String status;

  Item(this.itemId, this.itemName, this.itemLoc, this.status);

  Item.fromJson(Map<String, dynamic> json)
      : itemId = json['itemId'],
        itemName = json['itemName'],
        itemLoc = json['itemLoc'],
  status = json['status'];

  Map<String, dynamic> toJson() => {
    '"itemId"': '"'+itemId+'"',
    '"itemName"': '"'+itemName+'"',
    '"itemLoc"' : '"'+itemLoc+'"',
    '"status"' : '"'+status+'"',
  };
}