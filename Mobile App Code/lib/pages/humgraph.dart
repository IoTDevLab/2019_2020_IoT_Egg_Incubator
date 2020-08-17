
import 'package:flutter/material.dart';
import 'package:ioteggincubatorapp/mqtt.dart';
import 'package:ioteggincubatorapp/pages/drawer.dart';
import 'package:ioteggincubatorapp/utils/database_helper.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class HumGraph extends StatefulWidget {
  HumGraph({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHumGraphPageState createState() => _MyHumGraphPageState();
}
//class to parse data into charts
class SubscriberSeries {
  final String time;
  final double humidity;

  SubscriberSeries(
      {@required this.time,
        @required this.humidity,});
}

class SubscriberChart extends StatelessWidget {
  final List<SubscriberSeries> data;
  SubscriberChart({@required this.data});
//chart ui
  @override
  Widget build(BuildContext context) {
    return Container(
        height: 400,
        padding: EdgeInsets.all(15),
        child:
        Card(
            child: Padding(
                padding: const EdgeInsets.all(8.0),
                child:Column(
                    children: <Widget>[
                      Text(
                        " Humidity",
                        style: Theme.of(context).textTheme.bodyText1,
                      ),
                      Expanded(
                          child:
                          SfCartesianChart(
                              primaryXAxis: CategoryAxis(
                                  labelRotation: 90,
                                  labelPlacement: LabelPlacement.onTicks,
                                  title: AxisTitle(
                                      text: 'TIME',
                                      textStyle: ChartTextStyle(
                                        color: Colors.deepOrange,
                                        fontFamily: 'Roboto',
                                        fontSize: 16,
                                        fontStyle: FontStyle.italic,
                                        fontWeight: FontWeight.w300,
                                      )
                                  )
                              ),

                              series: <ChartSeries>[
                                // Renders line chart
                                AreaSeries<SubscriberSeries, String>(
                                    dataSource: data,
                                    color: Colors.deepOrange,
                                    borderColor: Colors.deepOrange,
                                    xValueMapper: (SubscriberSeries sales, _) => sales.time,
                                    yValueMapper: (SubscriberSeries sales, _) => sales.humidity
                                )
                              ]
                          )
                      )
                    ]
                )
            )
        )
    );
  }
}

class _MyHumGraphPageState extends State<HumGraph> {
  DatabaseHelper databaseHelper = DatabaseHelper();
  final Color primaryColor = Color(0xff99cc33);
  bool _isLoading = false;
  double _hum = 0.0;
  List<SubscriberSeries> humpoints = [];

  @override
  void initState() {
    super.initState();
    Mqttwrapper().mqttController.stream.listen(listenToClient);
    fetchValues();
  }
//function to update graph
  fetchValues() {
    DatabaseHelper().getReadinghumidityList().then((data) {
      for (Map map in data) {
        humpoints.add(SubscriberSeries(
          time:map['time'],
          humidity: double.tryParse('${map['humidity']}'),
        ));
        print('time: ${map['time']}\tHumidity: ${double.tryParse('${map['humidity']}')}');
      }
      setState((){});
    });
  }
  Future myTypedFuture() async {
    await Future.delayed(Duration(seconds: 4));
    fetchValues();
  }
//function to listen stream controller from MQTT and refresh ui
  void listenToClient(final data) {
    if (this.mounted) {
      setState(() {
        print("I am coming from the iot device $data");
//      databaseHelper.InsertDatareading(Datareading.fromJson(data));
        double h = double.parse(data["humidity"].toString());
        _isLoading = true;
        _hum = h;
        humpoints.clear();
        print('List removed');
        myTypedFuture();
        _isLoading = false;
      });
    }
  }
//main ui
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
            'Humidity Graph',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
//        elevation: 0.5,
        ),
        body: ListView(children: <Widget>[
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
          SubscriberChart(
            data: humpoints,
          )
        ]),
        drawer: Drawer(
          child: drawer,
        ));
  }
//humidity displaying ui
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
              height: 50.0,
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
  void dispose() {
    super.dispose();
  }
}
