/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/05/2017
 * Copyright :  S.Hamblett
 */

import 'dart:async';
import 'dart:io';
import 'package:ioteggincubatorapp/models/readings.dart';
import 'package:ioteggincubatorapp/utils/database_helper.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';
import 'package:csv/csv.dart';
import 'package:ext_storage/ext_storage.dart';
import 'package:open_file/open_file.dart';
import 'dart:async';
import 'dart:io';

//creating mqtt class
class Mqttwrapper {
  StreamController<Map<String, dynamic>> mqttController =
      StreamController.broadcast();
  static final Mqttwrapper instance = Mqttwrapper._internal();

  factory Mqttwrapper() => instance;

  String email;
  String password;

  Mqttwrapper._internal();

  var value = 'Hello MQTT';

  DatabaseHelper databaseHelper = DatabaseHelper();

  /// An annotated simple subscribe/publish usage example for mqtt_client. Please read in with reference
  /// to the MQTT specification. The example is runnable, also refer to test/mqtt_client_broker_test...dart
  /// files for separate subscribe/publish tests.
  MqttClient client;
  String clientIdentifier = 'android';
//function to connect MQTT
  Future<MqttClient> initializemqtt({String email, String password}) async {
    this.email = email;
    this.password = password;

    final MqttClient client = MqttClient("mqtt.dioty.co", "");
    client.port = 1883;
    client.logging(on: false);
    client.keepAlivePeriod = 30;
    client.onConnected = _onConnect;
    client.onDisconnected = _onDisconnect;
    client.onSubscribed = onSubscribed;
    final MqttConnectMessage connMess = new MqttConnectMessage()
        .withClientIdentifier(clientIdentifier)
        .startClean()
        .keepAliveFor(60);
    print("EXAMPLE::MQTT client connecting....");
    client.connectionMessage = connMess;
    try {
      await client.connect(email, password);
    } catch (e) {
      print("EXAMPLE::client exception - $e");
      client.disconnect();
      return client;
    }

    /// Check we are connected
    if (client.connectionStatus.state == MqttConnectionState.connected) {
      print("EXAMPLE::MQTT client connected");

      /// Ok, lets try a subscription
      final String topic = "/${this.email}/commands"; // Not a wildcard topic
      client.subscribe(topic, MqttQos.atMostOnce);
      final String topictwo =
          "/${this.email}/SensorData"; // Not a wildcard topic
      client.subscribe(topictwo, MqttQos.atMostOnce);
      final String topicthree =
          "/${this.email}/incubatordata"; // Not a wildcard topic
      client.subscribe(topicthree, MqttQos.atMostOnce);

      /// The client has a change notifier object(see the Observable class) which we then listen to to get
      /// notifications of published updates to each subscribed topic.
      client.updates.listen((List<MqttReceivedMessage> c) {
        final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
        final String pt =
            MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
        print(
            "EXAMPLE::Change notification:: topic is <${c[0].topic}>, payload is <-- $pt -->");
        print("");
        final String topicSensor = "/${this.email}/SensorData";
        if (("${c[0].topic}") == (topicSensor)) {
          final datasensor = json.decode(pt);
          mqttController.add(datasensor);
          print(datasensor['temperature']);
          databaseHelper.InsertDatareading(Datareading.fromJson(datasensor));
        }

        final String incubator = "/${this.email}/incubatordata";
        if (("${c[0].topic}") == (incubator)) {
          dynamic incudata=pt;
          print(incudata);
           // checkPermission();
           getincuCsv(incudata);
        }
//        else {
//        print('No permission');
//        }


      });
    } else {
      print(
          "EXAMPLE::ERROR Mosquitto client connection failed - disconnecting, state is ${client.connectionStatus.state}");
      client.disconnect();
      exit(-1);
    }
    this.client = client;
    return client;
  }
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

  Future<bool> _connectToClient() async {
    if (client != null &&
        client.connectionStatus.state == MqttConnectionState.connected) {
    } else {
      client = await initializemqtt(email: this.email, password: this.password);
      if (client == null) {
        return false;
      }
    }
    return true;
  }
//function to publish in a topic"command"
  Future<void> publish(String value) async {
    if (await _connectToClient() == true) {
      print("EXAMPLE::Publishing our topic");
      final String pubTopic = "/${this.email}/commands";
      final MqttClientPayloadBuilder builder = new MqttClientPayloadBuilder();
      builder.addString(value);
      client.publishMessage(pubTopic, MqttQos.atMostOnce, builder.payload);
      client.subscribe(pubTopic, MqttQos.atMostOnce);
    }
  }
}

/// The subscribed callback
void onSubscribed(String topic) {
  print("EXAMPLE::Subscription confirmed for topic $topic");
}

/// The unsolicited disconnect callback
void onDisconnected() {
  print("EXAMPLE::OnDisconnected client callback - Client disconnection");
  exit(-1);
}
//connecting MQTT
_onConnect() {
  print("mqtt connected");
}
//disconnecting MQTT
_onDisconnect() {
  print("mqtt disconnected");
}
//geting data from SD card in incubator
getincuCsv(dynamic incudata) async {
  List<List<dynamic>> csvTable = CsvToListConverter().convert(incudata);
  print(csvTable);
  Directory directory;
  if (Platform.isIOS) {
    directory = await getExternalStorageDirectory();
  } else if (Platform.isAndroid) {
    String path = await ExtStorage.getExternalStoragePublicDirectory(
        ExtStorage.DIRECTORY_DOWNLOADS);
    directory = Directory(path);
  }

  print(directory.path);
//function to get curent time and date
  String moment =
      "${DateTime
      .now()
      .year}.${DateTime
      .now()
      .month}.${DateTime
      .now()
      .day}_${DateTime
      .now()
      .hour}.${DateTime
      .now()
      .minute}";
//creating file and generating CSV
  File f = new File('${directory.path}/Incubator raw_$moment.csv');
  String incubatorDatabase = const ListToCsvConverter().convert(csvTable);
  await f.writeAsString(incubatorDatabase);
  print('data downloaded');
  print("File Path: ${f.path}");
  print(csvTable);
  await OpenFile.open(f.path);
}

@override
void dispose() {
  Mqttwrapper().mqttController.close();
}
