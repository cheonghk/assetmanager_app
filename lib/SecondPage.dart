import 'dart:typed_data';

import 'package:assetmanager_app/main.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:flutter/material.dart';
import 'package:convert/convert.dart';
import 'dart:convert';
import 'package:assetmanager_app/Item.dart';
import 'package:assetmanager_app/ItemPair.dart';
import 'package:ext_storage/ext_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart';
import 'package:path/path.dart';
import 'package:csv/csv.dart';
import 'package:back_button_interceptor/back_button_interceptor.dart';

class SecondPage extends StatefulWidget {

  final List<Item> categorisedList;
final String filePath;
  List<List<dynamic>> rows = [];
  SecondPage({Key key, @required this.categorisedList, @required this.filePath, @required this.rows}) : super(key: key);

  // final dynamic content;
  //SecondPage({Key key, @required this.content}) : super(key: key);
  @override
  _SecondPageState createState() => _SecondPageState();
}

class _SecondPageState extends State<SecondPage> with WidgetsBindingObserver{
  String barcode = '-';

  String _path;
  List<Item> _categorisedList;
  String _filePath;
  List<List<dynamic>> _rows = [];
  var _countItemsScanned = 0;
  var _countAllItemsScanned = 0;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    BackButtonInterceptor.add(myInterceptor);
    //convertDynamicToJson(widget.content);
    this._categorisedList = widget.categorisedList;
    this._filePath = widget.filePath;
    this._rows = widget.rows;

    //this._resultList = widget.allItems;
    WidgetsBinding.instance.addObserver(this);
    initItemScanned();
    initAndUpdateAllItemScanned();
    //initExcel(_filePath);
    //_localFile;

  }

  @override
  void dispose() {
    // TODO: implement dispose
  //  WidgetsBinding.instance.removeObserver(this);
    super.dispose();
    BackButtonInterceptor.remove(myInterceptor);
  }

  bool myInterceptor(bool stopDefaultButtonEvent, RouteInfo info) {
   writeCSV();
   MainPage(countAllItemsScanned: _countAllItemsScanned);
    print("BACK BUTTON!"); // Do some stuff.
    return false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // TODO: implement didChangeAppLifecycleState
    super.didChangeAppLifecycleState(state);
    if(state == AppLifecycleState.paused || state == AppLifecycleState.detached){
      writeCSV();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(MyApp.TITLE),
    ),
    body: Center(
      child: Column(
        //mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text('存放位置 : ' +_categorisedList[0].itemLoc.toString(),
            style: TextStyle(fontSize: 20.0,color: Colors.black,
            fontWeight: FontWeight.bold,),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                alignment: Alignment.topCenter,
                child:Text("數目: "+_countItemsScanned.toString()+"/"+_categorisedList.length.toString(),
                  style: TextStyle(fontSize: 20.0,color: Colors.black,
                    fontWeight: FontWeight.bold,),
                ),
              ),
              SizedBox(width: 10),
              Container(
                alignment: Alignment.topRight,
                child:Text("總數 : "+_countAllItemsScanned.toString()+"/"+_rows.length.toString(),
                  style: TextStyle(fontSize: 20.0,color: Colors.black,
                    fontWeight: FontWeight.bold,),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
              '號碼',
              style: TextStyle(
              fontSize: 20,
              color: Colors.black,

            ),
          ),
          SizedBox(height: 8),
          Text(
            '$barcode',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black
            ),
          ),
          SizedBox(height: 10),
          ElevatedButton(
            child: Text('按此掃瞄'),
            onPressed: scanBarcode,
          ),


        ListView.builder(
          shrinkWrap: true,
            itemCount: 1,
    itemBuilder: (context, index) {
    if (index == 0) {
      return Column(
          children: [
            // The header
            Container(
              padding: const EdgeInsets.all(2),
              color: Colors.amber,
              child: ListTile(
                leading: Container(
                  width:120,
                  child:Text('物品編號',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black
                  ),),),

                title: Container(
                  width:100,
                  child: Text('名稱',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black
                    ),),),
                trailing: Text('盤點狀態',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black
                  ),),
              ),
            ),
          ]
      );
    }
    return itemList();
  }

  ),

          SizedBox(height: 8),
          itemList(),
        ],
      ),
    ),
  );

  Expanded itemList(){
    return Expanded(child: new ListView.separated(
        shrinkWrap:true,
        separatorBuilder: (BuildContext context, int index) => Divider(height: 1),
        itemCount: _categorisedList.length,
        padding: EdgeInsets.all(2),
        itemBuilder: /*1*/ (context, i) {
    return ListTile(
      leading: Container(
        width:120,
        child: Text(_categorisedList[i].itemId.toString(),style: TextStyle(fontSize: 15.0),
          ),
      ),

    title: Container(
          width:100,
          child: Text(_categorisedList[i].itemName.toString(),style: TextStyle(fontSize: 15.0),),
    ),
    trailing: Text(_categorisedList[i].status.toString(),style: TextStyle(fontSize: 15.0),),

    );
    }
          ),
    );
  }

  Future<void> scanBarcode() async {
    try {
      final barcode = await FlutterBarcodeScanner.scanBarcode(
        '#ff6666',
        'Cancel',
        false,
        ScanMode.BARCODE,
      );

      if (!mounted) return;

      checkBarcodeAndUpdateList(barcode);

      setState(() {
        this.barcode = barcode;
      });



    } on PlatformException {
      barcode = 'Failed to get platform version.';
    }
  }

void checkBarcodeAndUpdateList(String barcode){
    var countItemsScanned = 0;
    setState(() {
      this._countItemsScanned=0;
    _categorisedList.forEach((e) {
      if(e.itemId.compareTo(barcode)==0) {
      e.status = "O";
    }
      if(e.status.compareTo("O")==0) {
        this._countItemsScanned++;
      }
    });
  });
    initAndUpdateAllItemScanned();
  }

  void initItemScanned(){
    _categorisedList.forEach((e) {
      if(e.status.compareTo("O")==0) {
        this._countItemsScanned++;
      }
    });
  }

  void initAndUpdateAllItemScanned(){

    setState(() {
      this._countAllItemsScanned = 0;
    _rows.forEach((e) {
      _categorisedList.forEach((e2) {if(e2.itemId.compareTo(e[0].toString())==0 && e2.status.compareTo("O")==0){
          e[13] = "O";

        }});
      });
      _rows.forEach((e) {
        if(e[13].toString().compareTo("O") ==0) {
        this._countAllItemsScanned++;}
    });

  });
        }

  /*
  void convertDynamicToJson (dynamic content) async {
    Iterable l =  json.decode(""'['+content.toString()+']'"");
    List list = List<Item>.from(l.map((model)=> Item.fromJson(model)));
    print('list   '+list.length.toString());
    setState(() {
      this._posts = list;
     // this._itemList = content;

    });
  }*/

  /*void itemContent(int index){
    Iterable l =  json.decode(_itemList.toString());
    setState(() {
      this._posts = List<Item>.from(l.map((model)=> Item.fromJson(model)));
    });
    //List<Item> posts
  }*/



//mobile "Download" folder
  Future<String> get _extStorage async {
    String path = await ExtStorage.getExternalStoragePublicDirectory(
        ExtStorage.DIRECTORY_DOWNLOADS);

    return path;

  }

  Future<String> get _localFile async {
    //final path = await _localPath;
    final path = await _extStorage;
    final fileName = MyApp.FILE_NAME;
    //('$path/$fileName');


    setState(() {
      this._filePath = '$path/$fileName';
 this._path = '$path';
    });
    return _filePath;
  }

//assets folder defined in the yaml file
  Future<String> get _localPath async {
    Directory _appDocumentsDirectory = await getApplicationDocumentsDirectory();
    return _appDocumentsDirectory.path;
  }

  void writeFileToApp(String fileName)async{
    ByteData data = await rootBundle.load("assets/$fileName");
    //writeByteData(data);
  }

  void writeFileToExtDlFolder(String fileName)async{
    File(fileName).openRead().listen((list) {
      ByteData data = Uint8List.fromList(list).buffer.asByteData(); // do something with 'data'
     // writeByteData(data);
    });
  }


  void writeCSV() async {

    List<List<dynamic>> rows = [];
    rows = this._rows;

    //var bytes = File(filePath).readAsBytesSync();
    //var excel = Excel.decodeBytes(bytes);
    // ByteData data = await rootBundle.load("assets/existing_excel_file.xlsx");
    //var bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

    //var excel = Excel.createExcel();
    //var sheet = excel['工作表1'];

/*
    rows.forEach((element) {
      list.forEach((element2) {if(element2.itemId.compareTo(element[0].toString())==0 && element2.status.compareTo("O")==0){
        element[13] = "ü";
      }});
    });
*/

    /*
    for (var table in excel.tables.keys) {
      // print(table); //sheet Name
      //print(excel.tables[table].maxCols);
      // print(excel.tables[table].maxRows);
    int i=0;
      for (var row in excel.tables[table].rows) {
        print("row[13]    "  + row[13].toString());

        list.forEach((element) {
          if (element.itemId.compareTo(row[0].toString()) == 0 && element.status.compareTo('O')==0) {
              print("element.itemId  "+element.itemId+ "   "+ row[0].toString());
              excel.updateCell('工作表1', CellIndex.indexByColumnRow(columnIndex: 13, rowIndex: i), "ü");
            }});
        i++;
      }
    }

    for (var table in excel.tables.keys) {
      // print(table); //sheet Name
      //print(excel.tables[table].maxCols);
      // print(excel.tables[table].maxRows);

      for (var row in excel.tables[table].rows) {
        print("row[13]  2  "  + row[0].toString() + "   " +row[13].toString());
      }
    }

    for (int row = 0; row < sheet.maxRows; row++) {
      sheet.row(row).forEach((cell) {
        if (cell.colIndex == 0) {
          list.forEach((element) {
            try {
              if (element.itemId.compareTo(cell.value).toString() == 0) {
                cell.value = "correct";
              }
            } catch (Exception) {

            };
          }
            //var val = cell.value; //  Value stored in the particular cell


          );
        }
      });
    }*/


    Directory appDocDir = await getApplicationDocumentsDirectory();//app dir

    String appDocPath = await ExtStorage.getExternalStoragePublicDirectory(
        ExtStorage.DIRECTORY_DOWNLOADS);//storage/emulated/0/Download/..

    var appDocPath2 = (await getExternalStorageDirectory()).path;


    String myPath = appDocPath2+"/"+MyApp.FILE_NAME_EDITED;
    print("Saved file to (2) : " +myPath);

    print(rows.length);
    String csv = const ListToCsvConverter().convert(rows);

    //excel.encode().then((onValue) {


    File(join(myPath))..writeAsString(csv);

     // excel.encode().then((onValue) {
    //    File(join(myPath))..createSync(recursive: true)..writeAsBytesSync(onValue);
    //  });

  }
}






