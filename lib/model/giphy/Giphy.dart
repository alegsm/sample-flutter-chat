import 'dart:async';
import 'package:chat/model/giphy/GiphyRequests.dart';
import 'package:chat/model/giphy/GiphyResponse.dart';

class Giphy
{
  static final Giphy _shared = new Giphy._internal();
  static bool canLoadMore = true;
  static GiphyRequester _requester;
  static String _apiKey;

  init(String apiKey)
  {
    _apiKey = apiKey;
  }

  static Giphy instance()
  {
    return _shared;
  }

  Giphy._internal();

  Future<List<GiphyImage>> search(String query,{int offset, int limit})
  {
    assert(_apiKey != null);

    List<GiphyImage> gifs = [];

    if(_requester == null)
      _requester = new GiphyRequester(_apiKey);

    Map<String, String> params = {};
    if(offset != null)
      params['offset'] = offset.toString();
    if(limit != null)
      params['limit'] = limit.toString();
    params['q'] = query;

    final completer = new Completer<List<GiphyImage>>();

    _requester.search(params).then(
      (raw)
      {
        if(raw != null && raw is Map<String, dynamic>)
        {
          var response = new GiphyResponse.parse(raw);
          print(raw.toString());
          if(response?.images != null)
            response.images.forEach(
              (responseImage)
              {
                gifs.add(responseImage.fixedWidth);
              }
            );
          completer.complete(gifs);
        }
        else
          completer.complete(null);
      }
    );

    return completer.future;
  }

  Future<List<GiphyImage>> getTrending({int offset, int limit})
  {
    assert(_apiKey != null);

    List<GiphyImage> gifs = [];

    if(_requester == null)
      _requester = new GiphyRequester(_apiKey);

    Map<String, String> params = {};
    if(offset != null)
      params['offset'] = offset.toString();
    if(limit != null)
      params['limit'] = limit.toString();

    final completer = new Completer<List<GiphyImage>>();

    _requester.trending(params).then(
      (raw)
      {
        if(raw != null && raw is Map<String, dynamic>)
        {
          var response = new GiphyResponse.parse(raw);
          if(response?.images != null)
            response.images.forEach(
              (responseImage)
              {
                gifs.add(responseImage.fixedWidth);
              }
            );
          completer.complete(gifs);
        }
        else
          completer.complete(null);
      }
    );

    return completer.future;
  }
}