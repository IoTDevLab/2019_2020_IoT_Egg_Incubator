//creating database class
class Datareading {
  int id;
  DateTime time;
  double temperature;
  double humidity;
  Datareading({this.id, this.time, this.temperature,  this.humidity}); // creating database constructors

  //mapping data
  Datareading.fromJson(Map<String, dynamic> map) :
        temperature = double.tryParse("${map['temperature']}"),
        humidity =double.tryParse("${map['humidity']}");

  Map<String, dynamic> toJson()=> {
    'temperature':temperature,
    'humidity':humidity,
  };
}