import 'package:ext_storage/ext_storage.dart';
import 'package:flutter/material.dart';
import 'package:ioteggincubatorapp/mqtt.dart';
import 'package:ioteggincubatorapp/pages/drawer.dart';
import 'package:ioteggincubatorapp/utils/database_helper.dart';
import 'package:csv/csv.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class About extends StatefulWidget {
  About({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyAboutPageState createState() => _MyAboutPageState();
}
// class and contruct to store data
class Row {
  final int id;
  final String time;
  final double temperature;
  final double humidity;

  Row({
    @required this.id,
    @required this.time,
    @required this.temperature,
    @required this.humidity,
  });
}

class _MyAboutPageState extends State<About> {
  final Color primaryColor = Color(0xff99cc33);
  //DatabaseHelper databaseHelper = DatabaseHelper();

  @override
  Widget build(BuildContext context) {
    final logo = Hero(
      tag: 'hero',
      child: CircleAvatar(
        backgroundColor: Colors.transparent,
        radius: 90.0,
        child: Image.asset('assets/images/egg.jpg'),
      ),
    );
    Future<void> _showMyDialog() async {
      return showDialog<void>(
        context: context,
        barrierDismissible: true, // user must tap button!
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Reset App Data?'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text(
                      'This will delete all the data collected so far with the app.'),
                  Text(' Are you sure?'),
                ],
              ),
            ),
            actions: <Widget>[
              FlatButton(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              FlatButton(
                child: Text('Reset'),
                onPressed: () {
                  DatabaseHelper().deleteAll();
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
// function to create CSV
    getCsv() async {
      DatabaseHelper().getReadalldataList().then((data) async {
        List<List<dynamic>> rowdata = List<List<dynamic>>();

        // Add headers for various columns
        rowdata.add(['ID', 'Time', 'Temperature', 'Humidity']);

        final List<Row> rows = [];

        for (Map map in data) {
          rows.add(Row(
              id: map['id'],
              time: map['time'],
              temperature: double.tryParse('${map['temperature']}'),
              humidity: double.tryParse('${map['humidity']}')));
        }

        for (int i = 0; i < rows.length; i++) {
//row refer to each column of a row in csv file and rows refer to each row in a file
          List<dynamic> rowconvert = List();
          rowconvert.add(rows[i].id);
          rowconvert.add(rows[i].time);
          rowconvert.add(rows[i].temperature);
          rowconvert.add(rows[i].humidity);
          rowdata.add(rowconvert);
        }

        Directory directory;

        if (Platform.isIOS) {
          directory = await getExternalStorageDirectory();
        } else if (Platform.isAndroid) {
          String path = await ExtStorage.getExternalStoragePublicDirectory(
              ExtStorage.DIRECTORY_DOWNLOADS);
          directory = Directory(path);
        }

        print(directory.path);
// getting current data and time
        String moment =
            "${DateTime.now().year}.${DateTime.now().month}.${DateTime.now().day}_${DateTime.now().hour}.${DateTime.now().minute}";

        File f = new File('${directory.path}/Incubator Data_$moment.csv');
        String incubatorDatabse = const ListToCsvConverter().convert(rowdata);
        await f.writeAsString(incubatorDatabse);
        print('data downloaded');
        print("File Path: ${f.path}");
        print(rowdata);
        await OpenFile.open(f.path);
      });
    }
// function to check permission
    Future<bool> checkPermission() async {
      var status = await Permission.storage.status;

      if (status.isUndetermined || status.isDenied) {
        // Don't have permission yet
        if (await Permission.storage.shouldShowRequestRationale) {
          return await Permission.storage.request().isGranted;
        } else {
          return await Permission.storage.request().isGranted;
        }
      } else {
        return status.isGranted;
      }
    }
//function to download dattabase
    Future<void> _datadownload() async {
      return showDialog<void>(
        context: context,
        barrierDismissible: true, // user must tap button!
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Downloading'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text(
                      'This will download app database into the download folder.'),
                  SizedBox(height: 16),
                  Text('Are you sure?'),
                ],
              ),
            ),
            actions: <Widget>[
              FlatButton(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              FlatButton(
                child: Text('Download'),
                onPressed: () async {
                  if (await checkPermission()) {
                    getCsv();
                  } else {
                    print('No permission');
                  }
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
    //function to publish in a topic
    void publish(String value) {
      Mqttwrapper().publish(value);
    }
//function to download incubator data
    Future<void> _incudatadownload() async {
      return showDialog<void>(
        context: context,
        barrierDismissible: true, // user must tap button!
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Downloading'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text(
                      'This will download incubator data from the SD card.'),
                  SizedBox(height: 16),
                  Text('Are you sure?'),
                ],
              ),
            ),
            actions: <Widget>[
              FlatButton(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              FlatButton(
                child: Text('Download'),
                onPressed: () { publish('getdata');
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }

//function to delete incubator data
    Future<void> _incudatadelete() async {
      return showDialog<void>(
        context: context,
        barrierDismissible: true, // user must tap button!
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Deleting'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text(
                      'This will delete the incubator data from the SD card.'),
                  SizedBox(height: 16),
                  Text('Are you sure?'),
                ],
              ),
            ),
            actions: <Widget>[
              FlatButton(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              FlatButton(
                child: Text('delete'),
                onPressed: () { publish('delete');
                Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }

//function to call about project dialog
    Future<void> _aboutProjet() async {
      return showDialog<void>(
        context: context,
        barrierDismissible: true, // user must tap button!
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Project Detail'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text(
                      'Basically, the IoT Automatic Egg Incubator is similar to the type of incubator which can be used as a substitute of poultry chicken to incubate the chicken eggs automatically.'
                      ' It will be helpful for the farmers to incubate the eggs automatically without the need of human intervention, by keeping the physical quantities such as temperature and humidity at required level,'
                      ' so that the fetuses inside them will grow and incubates without the presence of mother.'),
                  SizedBox(height: 16),
                  Text('Visit IoTDev Lab for more detail.'),
                ],
              ),
            ),
            actions: <Widget>[
              FlatButton(
                child: Text('Ok! Got it'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
//function to call about student dialog
    Future<void> _aboutStudent() async {
      return showDialog<void>(
        context: context,
        barrierDismissible: true, // user must tap button!
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Student Details'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text(
                      'Joshua Lartey is a final year student of UCC. He is very passionate about the development of IoT system, hene the came about of this project'),
                  SizedBox(height: 16),
                  Text('Call Joshua on 0249643365'),
                ],
              ),
            ),
            actions: <Widget>[
              FlatButton(
                child: Text('Ok! Got it'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
//function to ccall contact us dialog
    Future<void> _contactUs() async {
      return showDialog<void>(
        context: context,
        barrierDismissible: true, // user must tap button!
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Contact Us'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text(
                      'We are located on the Campus of UCC Science Block on the second floor.'),
                  SizedBox(height: 16),
                  Text('Call Us on 0249643365'),
                ],
              ),
            ),
            actions: <Widget>[
              FlatButton(
                child: Text('Ok! Got it'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
//function to call about IoTDev Lab dialog
    Future<void> _aboutIoTDevLab() async {
      return showDialog<void>(
        context: context,
        barrierDismissible: true, // user must tap button!
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('About IoT Dev Lab'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text(
                      'This is a well establish and well purpose lab under the Department of Computer science'
                      ' and Information technology for learning and development of embedded system and IoT Solutions'),
                  SizedBox(height: 16),
                  Text('Visit IoTDev Lab for more detail'),
                ],
              ),
            ),
            actions: <Widget>[
              FlatButton(
                child: Text('Ok! Got it'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
//function to rescaffold ui
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            'About',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
//        elevation: 0.5,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
          children: <Widget>[
            logo,
            SizedBox(
              height: 2.0,
            ),
            createButton(Colors.deepOrange, _aboutProjet, 'About Project'),
            SizedBox(
              height: 3.0,
            ),
            createButton(
                Colors.deepOrange, _aboutIoTDevLab, 'About IoTDev Lab'),
            SizedBox(
              height: 3.0,
            ),
            createButton(Colors.deepOrange, _aboutStudent, 'About Student'),
            SizedBox(
              height: 3.0,
            ),
            createButton(Colors.deepOrange, _contactUs, 'Contact Us'),
            SizedBox(
              height: 3.0,
            ),
            createButton(
              Colors.deepOrange,
              _datadownload,
              'Download App Data',
            ),
            SizedBox(
              height: 3.0,
            ),
            createButton(
              Colors.deepOrange,
              _incudatadownload,
              'Download Incubator Data',
            ),
            SizedBox(
              height: 3.0,
            ),
            createButton(
              Colors.deepOrange,
              _incudatadelete,
              'Delete Incubator Data',
            ),
            SizedBox(
              height: 3.0,
            ),
            createButton(
              Colors.deepOrange,
              _showMyDialog,
              'Reset App Data',
            )
          ],
        ),
        drawer: Drawer(
          child: drawer,
        ));
  }
}
// button to call the various function
RaisedButton createButton(
  Color color,
  Future<void> Function() perform,
  String text,
) {
  return RaisedButton(
    color: color,
    onPressed: () async => perform(),
    textColor: Colors.white,
    child: Center(
      child: Text(text),
    ),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
  );
}
