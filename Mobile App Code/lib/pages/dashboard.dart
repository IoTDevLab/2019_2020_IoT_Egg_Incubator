import 'package:flutter/material.dart';
import 'package:ioteggincubatorapp/mqtt.dart';
import 'package:ioteggincubatorapp/pages/drawer.dart';

class DashBoard extends StatefulWidget {
  DashBoard({Key key, this.title}) : super(key: key);
  final String title;
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<DashBoard> {
  //DatabaseHelper databaseHelper = DatabaseHelper();
//declaration
  final Color primaryColor = Color(0xff99cc33);
  bool _isLoading = false;
  double _temp = 0.0;
  double _hum = 0.0;

  @override
  void initState() {
    super.initState();
    Mqttwrapper().mqttController.stream.listen(listenToClient); //construct to listen to stream control
  }

//  @override
//  void dispose() {
//
//  }
//function to grab data from stream control
  void listenToClient(Map data) {
    if (this.mounted) {
      setState(() {
        print("I am coming from the iot device $data");
//     databaseHelper.InsertDatareading(Datareading.fromJson(data));
        double t = double.parse(data["temperature"].toString());
        double h = double.parse(data["humidity"].toString());

        _isLoading = true;
        _temp = t;
        _hum = h;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
//refresh ui
   final refreshed =  FlatButton.icon(
      icon: Icon(
        Icons.refresh,
        color: Colors.white,
      ),
      label: Text(
        "Refresh",
        style: TextStyle(
          color: Colors.white,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      splashColor: Colors.deepPurple,
      onPressed: () async {
        publish('refreshed');
        });

//control ui
    final control = Center(
      child: Card(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const ListTile(
              leading: IconButton(
                icon: Icon(Icons.control_point),
                onPressed: null,
              ),
              title: Text(
                'Control Panel',
                style: TextStyle(
                    color: Colors.deepOrange, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: IconButton(
                icon: Icon(Icons.lightbulb_outline),
                onPressed: null,
              ),
              title: Row(
                children: [
                  Text('Heat Control'),
                  Spacer(),
                  ButtonBar(
                    children: <Widget>[
                      RaisedButton(
                        color: Colors.green,
                        child: const Text(
                          'On',
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed: () { publish('heaton');},
                      ),
                      RaisedButton(
                        color: Colors.red,
                        child: const Text(
                          'Off',
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed: () { publish('heatoff');},
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ListTile(
              leading: IconButton(
                icon: Icon(Icons.all_out),
                onPressed: null,
              ),
              title: Row(
                children: [
                  Text('Air Control'),
                  Spacer(),
                  ButtonBar(
                    children: <Widget>[
                      RaisedButton(
                        color: Colors.green,
                        child: const Text(
                          'On',
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed: () { publish('airon');},
                      ),
                      RaisedButton(
                        color: Colors.red,
                        child: const Text(
                          'Off',
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed: () { publish('airoff');
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
//        elevation: 0.5,
          actions: <Widget>[
            refreshed
          ]
      ),
      body: ListView(
        children: <Widget>[
          SizedBox(
            height: 10.0,
          ),
          _createListTile(
            "Temperature",
            _temp.toString(),
            "C",
          ),
          SizedBox(
            height: 5.0,
          ),
          _createListTile(
            "Humidity",
            _hum.toString(),
            "%",
          ),
          SizedBox(
            height: 5.0,
          ),
          control
        ],
      ),
      drawer: drawer,
    );
  }
  //MQTT finction to publish message
  void publish(String value) {
    Mqttwrapper().publish(value);
  }
  //displaying humidity and temperature Ui
  _createListTile(String title, String value, String initials) {
    return Padding(
      padding: const EdgeInsets.only(left: 5.0, bottom: 5.0, right: 5.0),
      child: Card(
        elevation: 0.5,
        child: Container(
          height: 130.0,
          child: ListTile(
            trailing: Container(
              alignment: Alignment.center,
              height: 40.0,
              width: 30.0,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(30.0),
              ),
              child: Text(
                initials,
                style:
                    TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              title,
              style: TextStyle(
                  color: Colors.black87,
                  fontSize: 30.0,
                  fontWeight: FontWeight.bold),
            ),
            subtitle: !_isLoading
                ? Text(
                    value,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 48.0,
                        color: Colors.black),
                  )
                : Center(
                    child: CircularProgressIndicator(
                    strokeWidth: 1.0,
                  )),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
