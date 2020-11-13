import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_device_type/flutter_device_type.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'dart:collection';
import 'package:intl/intl.dart';

import 'convert.dart';
import 'error.dart';
import 'api_service.dart';
import 'package:currencies_wallet_calculator/Select_cur.dart';

final RouteObserver<PageRoute> routeObserver = new RouteObserver<PageRoute>();

void main() => runApp(CurrencyWallet());

class CurrencyWallet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.white,
        accentColor: Colors.teal,
      ),
      home: new StartPage(),
      navigatorObservers: [routeObserver],
    );
  }
}

class StartPage extends StatefulWidget {
  @override
  _StartPageState createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> with RouteAware{

  dynamic preferences = SharedPreferences;

  var _isConvertionLoading = true;
  var _isRatesLoading = true;
  var _isSearchOpened = false;
  var _isKeyEntered = false;

  var service = new APIService();

  var keyIndices = new List();
  var searchIndices = new List();

  var convertion = new Convert();
  var rates = new LinkedHashMap();

  var currentValue = 1;
  var convertedValue = 0.0;

  EdgeInsets _getEdgeInsets() {
    if (Device.get().isIos && Device.get().isTablet) {
      return new EdgeInsets.fromLTRB(24.0, 36.0, 24.0, 0.0);
    }
    else if (Device.get().isTablet) {
      return new EdgeInsets.fromLTRB(24.0, 36.0, 24.0, 0.0);
    }
    else {
      return new EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 0.0);
    }
  }

  MainAxisAlignment _getAxisAlignment() {
    if (Device.get().isIos && Device.get().isTablet) {
      return MainAxisAlignment.spaceEvenly;
    }
    else if (Device.get().isTablet) {
      return MainAxisAlignment.spaceEvenly;
    }
    else {
      return MainAxisAlignment.spaceBetween;
    }
  }

  void _initPreferences() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    if (!(preferences.getKeys().contains('currencyParam')) && !(preferences.getKeys().contains('toParam'))) {
      await preferences.setString('currnecyParam', 'USD');
      await preferences.setString('toParam', 'PHP');
      print('Initialized User Defaults');
    }
    else {
      print('Instanciated');
    }
    setState(() {
      this.preferences = preferences;
      _isRatesLoading = true;
      _isConvertionLoading = true;
      _getRates();
    });
  }

  String _getImageName(String index) {
    return 'assets/' + index +'.png';
  }

  String _getCurrency() {
    final currencyParam = preferences.getString('currencyParam') ?? '';
    return currencyParam;
  }

  String _getTo() {
    final toParam = preferences.getString('toParam') ?? '';
    return toParam;
  }

  String _getDate() {
    DateTime now = new DateTime.now();
    var dateFormatter = new DateFormat('MMMM dd, yyyy');
    return dateFormatter.format(now);
  }

  dynamic _getRates() async {
    final response = await service.getRates();
    if (response is Map) {
      this.keyIndices.clear();
      for (var key in response.keys) {
        keyIndices.add(key);
      }

      setState(() {
        this.searchIndices = this.keyIndices;
        this.rates = response;
        _isRatesLoading = false;
        _getConvertion();
      });
    }
    else if (response is Error) {
      _showDialog('Error', response.error);
    }
  }

  String _getFromSymbol() {
    return convertion.convertionRates[0]['symbol'].toString();
  }
  String _getFormattedCurrent() {
    RegExp reg = new RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    Function mathFunc = (Match match) => '${match[1]},';

    return currentValue.toString().replaceAllMapped(reg, mathFunc);
  }

  String _getToRate() {
    RegExp reg = new RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    Function mathFunc = (Match match) => '${match[1]},';

    var toRate = this.currentValue * this.convertedValue;

    if (toRate.toString().length > 13) {
      toRate = double.parse(toRate.toString().substring(0, 13));
    }

    var convertedRate = (convertion.convertionRates[1]["symbol"].toString() + toRate.toStringAsFixed(2));

    return convertedRate.replaceAllMapped(reg, mathFunc);
  }

  void _getConvertion() async {
    final response = await service.getConvertion();
    if (response is Convert) {
      setState(() {
        this.convertion = response;

        this.currentValue = 1;
        this.convertedValue = response.rate;

        _isKeyEntered = false;
        _isConvertionLoading = false;
      });
    }
    else if (response is Error) {
      _showDialog("Error", response.error);
    }
  }

  void _updateRate(int value) {
    if (!_isKeyEntered && currentValue == 1 && value != 0) {
      setState(() {
        this.currentValue = value;
        _isKeyEntered = true;
      });
    }
    else {
      var rateString = currentValue.toString();
      rateString = rateString += value.toString();

      if (rateString.length > 10) {
        rateString = rateString.substring(0, 10);
      }

      setState(() {
        this.currentValue = int.parse(rateString);
        _isKeyEntered = true;
      });
    }
  }

  void _removeRate() {
    if (_isKeyEntered) {
      var rateString = currentValue.toString();
      rateString = rateString.substring(0, rateString.length - 1);
      setState(() {
        if (rateString == "") {
          this.currentValue = 1;
          this._isKeyEntered = false;
        }
        else {
          this.currentValue = int.parse(rateString);
        }
      });
    }
  }

  void _showDialog(String title, String content) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: new Text(title),
            content: new Text(content),
            actions: <Widget>[
              new FlatButton(
                child: new Text("Close"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        }
    );
  }

  @override
  void initState() {
    super.initState();
    _initPreferences();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context));
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPush() {
  }

  @override
  void didPopNext() {
    setState(() {
      _isRatesLoading = true;
      _isConvertionLoading = true;
    });
    _getRates();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          bottom: TabBar(tabs: [
            Tab(child: Text('Convert', style: TextStyle(
              fontSize: 13.0,
            ),),),
            Tab(child: Text('Rates', style: TextStyle(
              fontSize: 13.0,
            ),),),
          ],),
          title: Text(_getDate(), style: TextStyle(
            fontSize: 15.0,
          ),),
          actions: <Widget>[
            IconButton(
                icon: Icon(Icons.refresh),
                onPressed: () {
                  setState(() {
                    _isRatesLoading = true;
                    _isConvertionLoading = true;
                  });
                  _getRates();
                },)
          ],
        ),
        body: TabBarView(children: [
          _isConvertionLoading ? Center(
            child: CircularProgressIndicator(),
          ) :
              Column(
                children: <Widget>[
                  Padding(padding: EdgeInsets.fromLTRB(25.0, 25.0, 25.0, 0.0),
                  child: Container(
                    color: Colors.transparent,
                    child: Container(
                      padding: EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.all(Radius.circular(10.0),),
                        boxShadow: <BoxShadow> [
                          BoxShadow(
                            color: Colors.grey,
                            offset: Offset(1.0, 1.0),
                            blurRadius: 3.0,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Column(
                          children: <Widget>[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => SelectCurrencyScreen(this.keyIndices, this.rates, 1),),);
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: <Widget>[
                                      Image(image: AssetImage(
                                        _getImageName(_getTo())),
                                        width: 24.0,
                                        height: 24.0,
                                      ),
                                      Container(
                                        width: 6.0,
                                      ),
                                      Text(_getTo(), style: TextStyle(
                                        fontSize: 17.0,
                                      ),),
                                      Icon(Icons.arrow_forward_ios,color: Colors.grey, size: 13.0,),
                                    ],
                                  ),
                                ),
                                Text(_getToRate(), style: new TextStyle(
                                  fontSize: 17.0,
                                ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  ),
                  new Expanded(
                    flex: 1,
                    child: new ListView(
                      physics: new ClampingScrollPhysics(),
                      children: <Widget>[
                        new Padding(
                            padding: _getEdgeInsets(),
                            child: new Column(
                              children: <Widget>[
                                new Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: _getAxisAlignment(),
                                  children: <Widget>[
                                    new RawMaterialButton(
                                      onPressed: () {
                                        _updateRate(7);
                                      },
                                      child: new Text("7", style: new TextStyle(
                                        fontSize: 24.0,
                                        color: Color.fromARGB(153, 0, 0, 0),
                                      ),
                                      ),
                                      shape: new CircleBorder(),
                                      elevation: 4.0,
                                      fillColor: Colors.white,
                                      padding: new EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 16.0),
                                    ),
                                    new RawMaterialButton(
                                      onPressed: () {
                                        _updateRate(8);
                                      },
                                      child: new Text("8", style: new TextStyle(
                                        fontSize: 24.0,
                                        color: Color.fromARGB(153, 0, 0, 0),
                                      ),
                                      ),
                                      shape: new CircleBorder(),
                                      elevation: 4.0,
                                      fillColor: Colors.white,
                                      padding: new EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 16.0),
                                    ),
                                    new RawMaterialButton(
                                      onPressed: () {
                                        _updateRate(9);
                                      },
                                      child: new Text("9", style: new TextStyle(
                                        fontSize: 24.0,
                                        color: Color.fromARGB(153, 0, 0, 0),
                                      ),
                                      ),
                                      shape: new CircleBorder(),
                                      elevation: 4.0,
                                      fillColor: Colors.white,
                                      padding: new EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 16.0),
                                    ),
                                  ],
                                ),
                              ],
                            )
                        ),
                        new Padding(
                            padding: _getEdgeInsets(),
                            child: new Column(
                              children: <Widget>[
                                new Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: _getAxisAlignment(),
                                  children: <Widget>[
                                    new RawMaterialButton(
                                      onPressed: () {
                                        _updateRate(4);
                                      },
                                      child: new Text("4", style: new TextStyle(
                                        fontSize: 24.0,
                                        color: Color.fromARGB(153, 0, 0, 0),
                                      ),
                                      ),
                                      shape: new CircleBorder(),
                                      elevation: 4.0,
                                      fillColor: Colors.white,
                                      padding: new EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 16.0),
                                    ),
                                    new RawMaterialButton(
                                      onPressed: () {
                                        _updateRate(5);
                                      },
                                      child: new Text("5", style: new TextStyle(
                                        fontSize: 24.0,
                                        color: Color.fromARGB(153, 0, 0, 0),
                                      ),
                                      ),
                                      shape: new CircleBorder(),
                                      elevation: 4.0,
                                      fillColor: Colors.white,
                                      padding: new EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 16.0),
                                    ),
                                    new RawMaterialButton(
                                      onPressed: () {
                                        _updateRate(6);
                                      },
                                      child: new Text("6", style: new TextStyle(
                                        fontSize: 24.0,
                                        color: Color.fromARGB(153, 0, 0, 0),
                                      ),
                                      ),
                                      shape: new CircleBorder(),
                                      elevation: 4.0,
                                      fillColor: Colors.white,
                                      padding: new EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 16.0),
                                    ),
                                  ],
                                ),
                              ],
                            )
                        ),
                        new Padding(
                            padding: _getEdgeInsets(),
                            child: new Column(
                              children: <Widget>[
                                new Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: _getAxisAlignment(),
                                  children: <Widget>[
                                    new RawMaterialButton(
                                      onPressed: () {
                                        _updateRate(1);
                                      },
                                      child: new Text("1", style: new TextStyle(
                                        fontSize: 24.0,
                                        color: Color.fromARGB(153, 0, 0, 0),
                                      ),
                                      ),
                                      shape: new CircleBorder(),
                                      elevation: 4.0,
                                      fillColor: Colors.white,
                                      padding: new EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 16.0),
                                    ),
                                    new RawMaterialButton(
                                      onPressed: () {
                                        _updateRate(2);
                                      },
                                      child: new Text("2", style: new TextStyle(
                                        fontSize: 24.0,
                                        color: Color.fromARGB(153, 0, 0, 0),
                                      ),
                                      ),
                                      shape: new CircleBorder(),
                                      elevation: 4.0,
                                      fillColor: Colors.white,
                                      padding: new EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 16.0),
                                    ),
                                    new RawMaterialButton(
                                      onPressed: () {
                                        _updateRate(3);
                                      },
                                      child: new Text("3", style: new TextStyle(
                                        fontSize: 24.0,
                                        color: Color.fromARGB(153, 0, 0, 0),
                                      ),
                                      ),
                                      shape: new CircleBorder(),
                                      elevation: 4.0,
                                      fillColor: Colors.white,
                                      padding: new EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 16.0),
                                    ),
                                  ],
                                ),
                              ],
                            )
                        ),
                        new Padding(
                            padding: _getEdgeInsets(),
                            child: new Column(
                              children: <Widget>[
                                new Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: _getAxisAlignment(),
                                  children: <Widget>[
                                    new RawMaterialButton(
                                      onPressed: () {
                                      },
                                      child: new Text("", style: new TextStyle(
                                        fontSize: 24.0,
                                      ),
                                      ),
                                      shape: new CircleBorder(),
                                      elevation: 0.0,
                                      fillColor: Colors.transparent,
                                      padding: new EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 16.0),
                                    ),
                                    new RawMaterialButton(
                                      onPressed: () {
                                        _updateRate(0);
                                      },
                                      child: new Text("0", style: new TextStyle(
                                        fontSize: 24.0,
                                        color: Color.fromARGB(153, 0, 0, 0),
                                      ),
                                      ),
                                      shape: new CircleBorder(),
                                      elevation: 4.0,
                                      fillColor: Colors.white,
                                      padding: new EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 16.0),
                                    ),
                                    new RawMaterialButton(
                                      onPressed: () {
                                        _removeRate();
                                      },
                                      child: new Icon(
                                        Icons.backspace,
                                        size: 24.0,
                                        color: Colors.white,
                                      ),
                                      shape: new CircleBorder(),
                                      elevation: 4.0,
                                      fillColor: Color.fromRGBO(75, 214, 145, 1.0),
                                      padding: new EdgeInsets.fromLTRB(22.0, 20.0, 24.0, 20.0),
                                    ),
                                  ],
                                ),
                              ],
                            )
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          _isRatesLoading ?  new Center(
            child: new CircularProgressIndicator(),
          ) : new NestedScrollView(
            headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
              return <Widget>[
              ];
            },
            body: new Column(
              children: <Widget>[
                new Padding(
                  padding: new EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 0.0),
                  child: new Container(
                    color: Colors.transparent,
                    child: new Container(
                      padding: new EdgeInsets.fromLTRB(12.0, 0.0, 12.0, 0.0),
                      decoration: new BoxDecoration(
                        color: Colors.white,
                        borderRadius: new BorderRadius.all(const Radius.circular(10.0)),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: Colors.grey,
                            offset: Offset(1.0, 1.0),
                            blurRadius: 3.0,
                          ),
                        ],
                      ),
                      child: new Center(
                        child: new Container(
                          child: new TextField(
                            decoration: new InputDecoration(
                              icon: Icon(Icons.search),
                              hintText: "Search (ex. USD, EUR, GBP)",
                              border: InputBorder.none,
                            ),
                            style: new TextStyle(
                              color: Colors.black,
                              fontSize: 12.0,
                              fontFamily: "Futura",
                            ),
                            onChanged: (text) {
                              setState(() {
                                _isSearchOpened = true;
                              });
                            },
                            onSubmitted: (text) {
                              var searchIndices = List();
                              if (text.isEmpty) {
                                searchIndices = this.keyIndices;
                              }
                              else {
                                searchIndices = keyIndices.where((item) => item.toString().contains(text.trim().toUpperCase())).toList();
                              }
                              setState(() {
                                this.searchIndices = searchIndices;
                                this.rates = this.rates;
                                _isSearchOpened = false;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                new Padding(
                  padding: new EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 0.0),
                  child: new Container(
                    color: Colors.transparent,
                    child: new GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SelectCurrencyScreen(this.keyIndices, this.rates, 0)),
                        );
                      },
                      child: new Container(
                        padding: new EdgeInsets.all(12.0),
                        decoration: new BoxDecoration(
                          color: Colors.white,
                          borderRadius: new BorderRadius.all(const Radius.circular(10.0)),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: Colors.grey,
                              offset: Offset(1.0, 1.0),
                              blurRadius: 3.0,
                            ),
                          ],
                        ),
                        child: new Center(
                          child: new Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              new Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: <Widget>[
                                  new Image(image: new AssetImage(
                                      _getImageName(_getCurrency())),
                                      width: 18.0,
                                      height: 18.0),
                                  new Container(
                                    width: 6.0,
                                  ),
                                  new Text(_getCurrency()),
                                ],
                              ),
                              new Icon(Icons.arrow_forward_ios,
                                color: Colors.grey,
                                size: 14.0,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                new Expanded(
                  flex: 1,
                  child: new Padding(
                    padding: new EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 0.0),
                    child: new Container(
                      color: Colors.transparent,
                      child: new Container(
                        padding: new EdgeInsets.all(12.0),
                        decoration: new BoxDecoration(
                          color: Colors.white,
                          borderRadius: new BorderRadius.all(const Radius.circular(10.0)),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: Colors.grey,
                              offset: Offset(1.0, 1.0),
                              blurRadius: 3.0,
                            ),
                          ],
                        ),
                        child: new Center(
                          child: _isSearchOpened ? new Center(
                            child: new CircularProgressIndicator(),
                          ) : new ListView.builder(
                              itemCount: this.rates != null ? this.searchIndices.length : 0,
                              itemBuilder: (context, index) {
                                final rate = rates[this.searchIndices[index]];
                                return new Container(
                                  height: 42.0,
                                  child: new Column(
                                    children: <Widget>[
                                      new Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: <Widget>[
                                          new Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                            children: <Widget>[
                                              new Image(image: new AssetImage(
                                                  _getImageName(searchIndices[index])),
                                                  width: 18.0,
                                                  height: 18.0),
                                              new Container(
                                                width: 6.0,
                                              ),
                                              new Text(searchIndices[index]),
                                            ],
                                          ),
                                          new Text(rate["symbol"] + rate["value"].toStringAsFixed(2)),
                                        ],
                                      ),
                                      new Divider(),
                                    ],
                                  ),
                                );
                              }
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }
}