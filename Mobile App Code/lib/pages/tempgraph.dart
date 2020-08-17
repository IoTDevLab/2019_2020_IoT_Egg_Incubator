
import 'package:flutter/material.dart';
import 'package:ioteggincubatorapp/mqtt.dart';
import 'package:ioteggincubatorapp/pages/drawer.dart';
import 'package:ioteggincubatorapp/utils/database_helper.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class  TempGraph extends StatefulWidget {
  TempGraph({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyTempGraphPageState createState() => _MyTempGraphPageState();
}
class SubscriberSeries {
  final String time;
  final double temperature;

  SubscriberSeries(
      {@required this.time,
        @required this.temperature,});
}

class SubscriberChart extends StatelessWidget {
  final List<SubscriberSeries> data;
  SubscriberChart({@required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
        height: 400,
        padding: EdgeInsets.all(10),
        child:
        Card(
            child: Padding(
                padding: const EdgeInsets.all(8.0),
                child:Column(
                    children: <Widget>[
                      Text(
                        " Temperature",
                        style: Theme.of(context).textTheme.bodyText1,
                      ),
                      Expanded(
                          child:
                          SfCartesianChart(
                              primaryXAxis: CategoryAxis(
//                                  maximumLabels: 5,
                                  labelPlacement: LabelPlacement.onTicks,
                                  labelRotation: 90,
                                  title: AxisTitle(
                                      text: 'TIME',
                                      textStyle: ChartTextStyle(
                                        color: Colors.black,
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
                                    borderWidth: 5,
                                    xValueMapper: (SubscriberSeries sales, _) => sales.time,
                                    yValueMapper: (SubscriberSeries sales, _) => sales.temperature

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

class _MyTempGraphPageState extends State< TempGraph> {
//  DatabaseHelper databaseHelper = DatabaseHelper();
  final Color primaryColor = Color(0xff99cc33);
  bool _isLoading = false;
  double _temp = 0.0;
  final List<SubscriberSeries> temppoints= [];

  @override
  void initState(){
    super.initState();
  Mqttwrapper().mqttController.stream.listen(listenToClient);
   fetchValues();
  }

 fetchValues() {
    DatabaseHelper().getReadingTemList().then((data) {
      for (Map map in data) {
        temppoints.add(SubscriberSeries(
          time: map['time'],
          temperature: double.tryParse('${map['temperature']}'),
        ));
        print('time: ${map['time']}\ttemperature: ${double.tryParse('${map['temperature']}')}');
      }
      setState((){});
    });
  }


  Future myTypedFuture() async {
    await Future.delayed(Duration(seconds: 4));
    fetchValues();
  }

  void listenToClient(final data) {
    if (this.mounted) {
      setState(() {
        print("I am coming from the iot device $data");
        double t = double.parse(data["temperature"].toString());
//      databaseHelper.InsertDatareading(Datareading.fromJson(data));

        _isLoading = true;
        _temp = t;
        temppoints.clear();
        print('List removed');
        myTypedFuture();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Temperature Graph', style: TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold),),
        centerTitle: true,
//        elevation: 0.5,
      ),
      body:ListView(children: <Widget>[
        SizedBox(height: 4.0,),
        _createListTile("Temperature",  _temp.toString(), "C",),
        SizedBox(height: 5.0,),
        SubscriberChart(
          data: temppoints,
        )]),
      drawer: Drawer(child: drawer),
    );
  }


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
              child: Text(initials, style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold ),),
            ),

            title:  Text(title, style: TextStyle(
                color: Colors.black87,
                fontSize: 30.0,
                fontWeight: FontWeight.bold
            ),) ,
            subtitle: !_isLoading ? Text(value, style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 48.0, color: Colors.black),) : Center(child:CircularProgressIndicator(strokeWidth: 1.0,)),
          ),
        ),
      ),
    );
  }
  @override
  void dispose(){
    super.dispose();
  }
}








