import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:convert/convert.dart';

import 'package:udp/udp.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: ''),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);


  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  String LOGTAG="MainScreen";
  var receiver;
  String dataPacket="";



  void startOfflineMode() async
  {

    String localIP=await getLocalIpAddress();
    checkWifiEnabled();
    print(LOGTAG+" inside function->"+localIP.toString());

    var multicastEndpoint = Endpoint.multicast(InternetAddress("239.1.2.3"), port: Port(1234));

    receiver = await UDP.bind(multicastEndpoint);

    receiver.listen((datagram) async {

      print(LOGTAG+""+datagram.toString()+" data->"+datagram.data.toString());

      InternetAddress ipAdd=datagram.address;
      print(LOGTAG+" address->"+ipAdd.address.toString());

      if (datagram != null)
      {
        var convertedStr=String.fromCharCodes(datagram?.data);

        dataPacket=convertedStr+ " and "+ipAdd.address.toString();
        print(convertedStr);
        setState(() {});
      }
    });

  }

  void stopOfflineMode() async
  {
    print(LOGTAG+" stopoffline mode "+receiver.toString());
    if(receiver!=null)
    {
      receiver.close();
    }
  }

  static Future<String> getLocalIpAddress() async
  {
    final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4, includeLinkLocal: true);

    try
    {
      // Try VPN connection first
      NetworkInterface vpnInterface = interfaces.firstWhere((element) => element.name == "tun0");
      return vpnInterface.addresses.first.address;
    }
    on StateError
    {
      // Try wlan connection next
      try
      {
        NetworkInterface interface = interfaces.firstWhere((element) => element.name == "wlan0");
        return interface.addresses.first.address;
      }
      catch (ex)
      {
        // Try any other connection next
        try
        {
          NetworkInterface interface = interfaces.firstWhere((element) => !(element.name == "tun0" || element.name == "wlan0"));
          return interface.addresses.first.address;
        }
        catch (ex)
        {
          return null;
        }
      }
    }
  }


  void checkWifiEnabled() async
  {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.mobile)
    {
      print(LOGTAG+" connected to mobile network");
    }
    else if (connectivityResult == ConnectivityResult.wifi)
    {
      print(LOGTAG+" connected to wifi network");
    }
  }

  @override
  void onDispose(){
    super.dispose();

    print(LOGTAG+" dispose called");

    if(receiver!=null)
    {
      receiver.close();
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(

        title: Text(widget.title),
      ),
      body: Center(

        child: Column(

          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[

            new Text(dataPacket.toString()),
            SizedBox(height:15),
            new Row(
              children: <Widget>[
                Flexible(
                    flex:1,
                    fit:FlexFit.tight,
                    child:GestureDetector(
                        onTap: (){
                          startOfflineMode();
                        },
                        child:new Text("START",textAlign:TextAlign.center)
                    )
                ),
                Flexible(
                    flex:1,
                    fit:FlexFit.tight,
                    child:GestureDetector(
                        onTap: (){

                          stopOfflineMode();

                        },
                        child:new Text("STOP",textAlign:TextAlign.center)
                    )
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
