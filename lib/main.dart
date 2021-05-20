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
  final int countAllItemsScanned;
  MainPage({Key key, @required this.title, @required this.countAllItemsScanned}) : super(key: key);

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

class _MainPageState extends State<MainPage> with WidgetsBindingObserver{
  List<String> itemId = [];
  List<String> location = [];
  //List<dynamic> _allItems = [];
  bool permissionGranted = false;
  String _filePath;
  bool _isStart = false;
  List<List<dynamic>> _rows = [];
  var _countAllItemsScanned;
  final _biggerFont = TextStyle(fontSize: 18.0);
  String test;
  List<List> _viewList = [];
  List _orginList = [];
  Map<String, dynamic> _mp = new Map();
  @override
  void initState() {

    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _getStoragePermissionAndReadFile();
    _getCountAllItemsScanned();
    if(widget.countAllItemsScanned!=null){
    this._countAllItemsScanned = widget.countAllItemsScanned;}
    //readExcelFile('fixed assets.xlsx');
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }


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
                      /*trailing: Container(
                        child: Text("總數 : "+ _countAllItemsScanned.toString() + "/"+_rows.length.toString(),
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black
                          )
                      ),

                    ),*/
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
      onTap: () => Navigator.push(this.context, MaterialPageRoute(builder: (context) => SecondPage(categorisedList :mappedList, filePath:this._filePath, rows:this._rows))),
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

  Future _getStoragePermissionAndReadFile() async {
    if (await Permission.storage.request().isGranted) {
      readMobileFile(await _localFile);
      //readFileFromApp('fixed assets.xlsx');
      setState(() {
        permissionGranted = true;
      });
    }
  }

  void _getCountAllItemsScanned() {
    int count=0;
    _rows.forEach((e) {
      if (e[13].toString().compareTo("O") == 0) {
        count++;
      }
    });
setState(() {
  this._countAllItemsScanned = count;
});
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
   bool ifFileExist = await File('$extStoragePath/$editedFileName').exists();//for newer version
    //bool ifFileExist = await File('$dlFolderPath/$editedFileName').exists();
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

  void readMobileFile(String fileName)async{
    File(fileName).openRead().listen((list) {
      //ByteData data = Uint8List.fromList(list).buffer.asByteData(); // do something with 'data'
      readByteData(this._filePath);
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
            if(row[j]== null){
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

    File(join(myPath))..writeAsStringSync(csv);
   // });

    return excel;
  }

  Future<void> readByteData(String filePath) async{
    Excel excel;
    Map<String, dynamic> mp = new Map();
    List<List<dynamic>> tempRows =[];
    //List allItems = [];
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

            if (j > 0) {
              if (_isStart) {
                row[13] = "X";
              }


              if (row[0] == null || row[0] == "" || row[0].toString().length==0)
                break;

              var char = 'X';
              if (row[13].toString().compareTo('O') == 0) {
                char = 'O';
              }

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
          //  allItems.add(row[j]);
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
        tempRows.add(row);
          try {
//row[0] == itemId, row[2] == itemName, row[3] == Location

            if (j > 0) {

              if (row[0] == null || row[0] == "" || row[0].toString().length==0)
                break;

              var char = 'X';
              if (row[13].toString().compareTo('O') == 0) {
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
          //  allItems.add(row[j]);
          } catch (Exception) {

          }
          j++;
      }

      setState(() {
        this._rows = tempRows;
      });
    }


      setState(() {
        this._mp = mp;
       // this._allItems = allItems;
      });
    }

  List<Item> maniValue(String value){

    Iterable i = json.decode(""'['+value+']'"");
    List<Item> list = List<Item>.from(i.map((model)=> Item.fromJson(model)));
  return list;
  }

  }



