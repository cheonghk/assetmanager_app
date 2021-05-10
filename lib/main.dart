import 'dart:core';
import 'dart:core';
import 'dart:typed_data';



import 'package:assetmanager_app/Item.dart';
import 'package:assetmanager_app/ItemPair.dart';
import 'package:assetmanager_app/SecondPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:convert/convert.dart';
import 'dart:convert';
import 'package:ext_storage/ext_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart';
import 'package:csv/csv.dart';

void main() {
  runApp(MyApp());

}

class MyApp extends StatelessWidget {
  static final String FILE_NAME = 'fixed assets.xlsx';
  static final String FILE_NAME_EDITED = 'fixed_assets_edited.csv';
  static final String TITLE = 'Asset Manager';
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) => MaterialApp(
  title: TITLE,
      theme: ThemeData(
        primaryColor: Colors.blue,
      ),
      home: Scaffold(
    body:Center(
      child: MainPage(title: TITLE),
    ),
    ),
    );

}

class MainPage extends StatefulWidget {
  final String title;
  MainPage({Key key, @required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  _MainPageState createState() => _MainPageState();

}

class _MainPageState extends State<MainPage> {
  List<String> itemId = [];
  List<String> location = [];
  List allItems = [];
  bool permissionGranted = false;
  String _filePath;
  bool _isStart = false;
  List<List<dynamic>> _rows = [];

  final _biggerFont = TextStyle(fontSize: 18.0);
  String test;
  List<List> _viewList = [];
  List _orginList = [];
  Map<String, dynamic> _mp = new Map();
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _getStoragePermission();
    //readExcelFile('fixed assets.xlsx');


  }




  @override
  Widget _buildList() {

    return ListView.separated(
        itemCount: _mp.length,
        separatorBuilder: (BuildContext context, int index) =>
            Divider(height: 1),
        shrinkWrap: true,
        itemBuilder: /*1*/ (context, i) {
          if (i == 0) {
            return Column(
                children: [
                  // The header
                  Container(
                    padding: const EdgeInsets.all(2),
                    color: Colors.amber,
                    child: ListTile(
                      leading: Container(
                        //width:120,
                        child:Text('存放位置',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black
                          ),),),

                    ),
                  ),
                ]
            );
          }
          return _buildRow(_mp.keys.elementAt(i), maniValue(_mp.values.elementAt(i).toString()));

         // return _buildRow(_finalList.keys.elementAt(i), _finalList.values.elementAt(i));
        }
    );
  }


  Widget _buildRow(String key, List<Item> mappedList) {
    return ListTile(
      title: Text(
        key.toString(),
        style: _biggerFont,
      ),
      onTap: () => Navigator.push(this.context, MaterialPageRoute(builder: (context) => SecondPage(categorisedList :mappedList, allItems: allItems, filePath:this._filePath, rows:this._rows))),
    );
  }

  @override
  Widget build(BuildContext context) {
   // readExcelFile('fixed assets.xlsx');
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: _buildList(),
    );
  }

  Future _getStoragePermission() async {
    if (await Permission.storage.request().isGranted) {
      readMobileFile(await _localFile);
      //readFileFromApp('fixed assets.xlsx');
      setState(() {
        permissionGranted = true;
      });
    }
  }

//mobile "Download" folder
  Future<String> get _dlFolder async {
    String path = await ExtStorage.getExternalStoragePublicDirectory(
        ExtStorage.DIRECTORY_DOWNLOADS);
    return path;
  }

//'Android/data' folder
  Future<String> get _extStorage async {
    String path = (await getExternalStorageDirectory()).path;
    return path;
  }

//assets folder defined in the yaml file
  Future<String> get _localPath async {
    Directory _appDocumentsDirectory = await getApplicationDocumentsDirectory();
    return _appDocumentsDirectory.path;
  }

  Future<String> get _localFile async {
    //final path = await _localPath;
    String path;
    String fileName;


    final dlFolderPath = await _dlFolder;
    final extStoragePath = await _extStorage;
    final origFileName = MyApp.FILE_NAME;
    final editedFileName = MyApp.FILE_NAME_EDITED;
   //bool ifFileExist = await File('$extStoragePath/$editedFileName').exists();//for newer version
    bool ifFileExist = await File('$dlFolderPath/$editedFileName').exists();
    if(ifFileExist){
      path = extStoragePath;
      fileName = editedFileName;
    }else{
      path = dlFolderPath;
      fileName = origFileName;
      setState(() {
        this._isStart = true;
      });
    }

    print('Read file from : '+'$path/$fileName');
    setState(() {
      this._filePath = '$path/$fileName';
    });
    return _filePath;
  }


/*
  void readExcelFile(String fileName) async {
    ByteData data = await rootBundle.load("assets/$fileName");
    var bytes = data.buffer.asUint8List(
        data.offsetInBytes, data.lengthInBytes);
    var excel = Excel.decodeBytes(bytes);

    int duplicateCount = 0;
    int countB = 0;
    Map<String, dynamic> mp = new Map();
    final itemPair = <String, dynamic>{};
    List<dynamic> rowList = [];
    List<List<dynamic>> rowsList = [];
    for (var table in excel.tables.keys) {



        for (var i =0; i < excel.tables[table].rows.length;i++) {
          //if(i<22) {//column size
//i[0] == itemId, i[2] == itemName, i[3] == Location

          rowList.add(excel.tables[table].rows[i]);

         // print(rowList[i].toString() + " " + i.toString());
         // print(rowList[j]);

          //j++;


          //if (j > 2) { //content start from i 3
          // if (i[0] == null || i[0] == "")
          //   break;
          // };
          //final item = Item(i[0], i[2], i[3]).toJson();

          //if(mp.containsKey(i[3])){
          //  duplicateCount++;

          //   dynamic tempItem = mp[i[3]];

          //   mp.update(i[3], (value) => '$tempItem'+','+'$item');
          //  }else{
          //    countB++;

          //    mp.putIfAbsent(i[3], ()=> Item(i[0], i[2], i[3]).toJson());}


       // }

          //rowsList.add(rowList);
         // print("rowsList" +rowsList[i].toString() +"   ");
      }

    }
    //print("last test  " + rowList[50][3].toString());
   // print("rowsList "+rowsList.length.toString());
    //print("duplicateCount  "+duplicateCount.toString());
    //print(countB);
     //handleList(rowList);
  }
*/

  /*
  void handleList(List list){
    List aList = list.map((e) => e).toList();
    List bList = list.map((e) => e).toList();

    List<List<List<dynamic>>> newList = [];
    //newList.add(list[2]);//start from index 2
   // tempList.add(list[2]);
   // int i=0;


    //print("newList[0][0] " + newList[0][0].toString());
    //newList[0].add("test");
   // print("newList[0][1] " + newList[0][1].toString());

   // int length = list.length;
    int length = 57;
  int firstRow = 2;
int index =2;


    for(var i = index; i< length;i++) {//i 2 already added
      List<List<dynamic>> tempList = [];
     // int j = 0;

      if(isStart){list[13] = "";}
      tempList.addAll([list[i]]);
      if(index==i){
        newList.add(tempList);
      }
      //print(newList);
      for(var j = i+1; j< length;j++) {
        if(isStart){aList[j][13] = "";}

        print("i " +i.toString()+" j " +j.toString());
      //  print(l2[1]);
        if (aList[i][3].toString().compareTo(bList[j][3].toString())==0){

          print("duplicateeee "+aList[i][3].toString()+"   "+ bList[j][3].toString());
          //tempList.addAll(aList[j]);
          print("i  "+i.toString()+"   " + newList.length.toString());


          for(var k = 0; k<newList.length;k++) {
            for (var l = 0; l < newList[k].length; l++) {
              if (newList[k][l][3].toString().compareTo(
                  aList[i][3].toString()) == 0){


                tempList.addAll([aList[j]]);
                newList[k].add(tempList);}
            }
          }
          bList[j][3] = "del";
          //if(j==length-1){

            //print("j "+j.toString());

         // newList.insert(i-2, list[i]);
          //newList[i-2].addAll(tempList);

          //print(newList[newList.length-1]);
         // continue;
          // }
        }else {
          if (i == firstRow){
            print("normal");
          print(newList.length);

          bool ifExist = false;

          for(var i = 0;i<newList.length;i++){
            for(var j = 0;j<newList[i].length;j++) {
              // print("listttttt  2 " + newList[i][3].toString() +"   " +bList[j][3].toString());
              if (newList[i][j][3].toString() == bList[j][3].toString()) {
                ifExist = true;
                print("ifExist " + ifExist.toString());
              }
            }
          }
            // tempList.addAll(list);
          // newList
            if(!ifExist){

              tempList.addAll([aList[j]]);
          newList.add(tempList);
            }
          //print(list[j].toString());
          //continue;
          //newList.insert(newList.length, tempList);
        }
        }
     //   j++;

     }

      //i++;
    }


    print(newList.length.toString());
    for(var i = 0;i<newList.length;i++){
      print(i.toString()+"   " +newList.toString());
    }
    setState(() {
      this._orginList.addAll(list);
      this._viewList.addAll(newList);
    });
  }*/

  /*
  void readFileFromApp(String fileName)async{
    ByteData data = await rootBundle.load("assets/$fileName");
    readByteData(data, this._filePath);
  }*/

  void readMobileFile(String fileName)async{
    File(fileName).openRead().listen((list) {
      ByteData data = Uint8List.fromList(list).buffer.asByteData(); // do something with 'data'
      readByteData(data, this._filePath);
    });
  }

  Future<Excel> initExcel(String filePath)async{
    print('initExcel');
    var bytes = File(filePath).readAsBytesSync();
    var excel = Excel.decodeBytes(bytes);
    List<List<dynamic>> rows = [];
    for (var table in excel.tables.keys) {

      int i=0;
      for (var row in excel.tables[table].rows) {
        List<dynamic> storeRow = [];

          for(var j = 0;j<row.length;j++){
            if(j==13 && i>1){
              row[j] = "";
            }
          storeRow.add(row[j]);}
          rows.add(storeRow);
          excel.updateCell(
              '工作表1', CellIndex.indexByColumnRow(columnIndex: 13, rowIndex: i),
              "");

        i++;
      }

    }
    setState(() {
      this._rows = rows;
    });

    var appDocPath2 = (await getExternalStorageDirectory()).path;
    String myPath = appDocPath2+"/"+MyApp.FILE_NAME_EDITED;
    print("Saved file(initialise) to " +myPath);

    String csv = const ListToCsvConverter().convert(rows);

    //excel.encode().then((onValue) {
    File(join(myPath))..createSync(recursive: true)..writeAsStringSync(csv);
   // });

    return excel;
  }

  Future<void> readByteData(ByteData data, String filePath) async{
    Excel excel;
    Map<String, dynamic> mp = new Map();
    List allItems = [];
    if(this._isStart) {
      print('main - isStart  ' + this._isStart.toString());
      excel = await initExcel(this._filePath);

      int duplicateCount = 0;
      int countB = 0;

      for (var table in excel.tables.keys) {
        int j = 0;
        for (var row in excel.tables[table].rows) {
          try {
//row[0] == itemId, row[2] == itemName, row[3] == Location

            if (j > 2) {
              if (_isStart) {
                row[13] = "X";
              }


              if (row[0] == null || row[0] == "")
                break;

              var char = 'X';
              if (row[13].toString().compareTo('ü') == 0) {
                char = 'O';
              };

              final item = Item(row[0], row[2], row[3], char).toJson();

              if (mp.containsKey(row[3])) {
                duplicateCount++;

                dynamic tempItem = mp[row[3]];

                mp.update(row[3], (value) => '$tempItem' + ',' + '$item');
              } else {
                countB++;

                mp.putIfAbsent(
                    row[3], () => Item(row[0], row[2], row[3], char).toJson());
              }
            }
            allItems.add(row[j]);
          } catch (Exception) {

          }
          j++;
        }
      }
    }
    else{

      final input = new File(filePath).openRead();
      final fields = await input.transform(utf8.decoder).transform(new CsvToListConverter()).toList();

      int j = 0;
      for (var row in fields) {
          try {
//row[0] == itemId, row[2] == itemName, row[3] == Location

            if (j > 2 ) {
              if(row[0].toString().compareTo(null)==0 || row[0].toString().length<1){
                print(row[0]);
                break;
              }

              var char = 'X';
              if (row[13].toString().compareTo('ü') == 0) {
                char = 'O';
              }

              final item = Item(row[0], row[2], row[3], char).toJson();

              if (mp.containsKey(row[3])) {

                dynamic tempItem = mp[row[3]];

                mp.update(row[3], (value) => '$tempItem' + ',' + '$item');
              } else {


                mp.putIfAbsent(
                    row[3], () => Item(row[0], row[2], row[3], char).toJson());
              }
            }
            allItems.add(row[j]);
          } catch (Exception) {

          }
          j++;

      }
    }

      setState(() {
        this._mp = mp;
        this.allItems = allItems;
      });
    }

  List<Item> maniValue(String value){

    Iterable i = json.decode(""'['+value+']'"");
    List<Item> list = List<Item>.from(i.map((model)=> Item.fromJson(model)));
  return list;
  }

  }



