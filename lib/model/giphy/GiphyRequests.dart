import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class GiphyRequester {
  final _baseUri = "api.giphy.com";
  String _apiKey;

  GiphyRequester(this._apiKey);

  Future<dynamic> search(Map<String, String> params){
    params['api_key'] = _apiKey;
    return _apiRequest('search', params);
  }

  Future<dynamic> trending(Map<String, String> params){
    params['api_key'] = _apiKey;
    return _apiRequest('trending', params);
  }

  Future _apiRequest(String method, Map<String, String> parameters) {
    return http.get(_buildUri(method, parameters).toString()).then(
      (response) {
        if(response.body != null && response.body.isNotEmpty) {
          return json.decode(response.body);
        }
        else
          return null;
      }
    );
  }

  Uri _buildUri(String method, Map<String, String> queryParameters){
    var uri = new Uri.http(_baseUri, 'v1/gifs/'+ method, queryParameters);
    return uri;
  }
}