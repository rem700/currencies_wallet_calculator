import 'rates_hardcode.dart';

class Convert {
  var ratesObject = new Rates();
  String from = '';
  String to = '';
  double rate;

  var convertionRates = new List();
  Convert();

  void initValues() {
    ratesObject.initValues();
    convertionRates.add(ratesObject.rates[from]);
    convertionRates.add(ratesObject.rates[to]);
  }

  Convert.fromJson(Map<String, dynamic> json):
      from = json['from'], to = json['to'], rate = (json['rate'] != null) ? json['rate'] + 0.0 : 0.0;
}