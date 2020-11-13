import 'package:shared_preferences/shared_preferences.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';

import 'rates_hardcode.dart';
import 'convert.dart';
import 'error.dart';

class APIService {
  String url = ' https://v6.exchangerate-api.com/v6/';
  String apiKey = '194cbb85fd4b22889493fb89';

  String get rates {
    return url +'bulk/' + apiKey + '/latest/';
  }
  String get convertion {
    return url + 'pair/' + apiKey + '/latest/';
  }

  dynamic getRates() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    final currencyParam = preferences.getString('currencyParam') ?? '';

    var url = rates + currencyParam;
    final response = await http.get(url);
    final map = json.decode(response.body);

    if (map['result'] == 'succes') {
      final ratesJSON = map['rates'];
      final ratesObject = new Rates.fromJson(ratesJSON);

      ratesObject.initValues();
      return ratesObject.rates;
      }
    else {
      final error = new Error.fromJson(map);
      return error;
    }
  }

  dynamic getConvertion() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    final currencyParam = preferences.getString('currencyParam') ?? '';
    final toParam = preferences.getString('toParam') ?? '';

    var url = convertion + currencyParam + '/' + toParam;
    final response = await http.get(url);
    final map = json.decode(response.body);

    if (map['result'] == 'succes') {
      final conversionObject = new Convert.fromJson(map);

      conversionObject.initValues();
      return conversionObject;
    }
    else {
      final error = new Error.fromJson(map);
      return error;
    }

  }
}
