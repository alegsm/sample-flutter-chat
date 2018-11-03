import 'package:flutter/material.dart';

class GiphyResponse
{
  String id;
  String type;
  List<ResponseImage> images;
  GiphyPagination pagination;
  GiphyMeta meta;

  GiphyResponse({this.id, this.type, this.images});

  GiphyResponse.parse(Map<String, dynamic> response)
  {
    images = [];
    if(response['data'] != null && response['data'] is List) {
      var list = response['data'] as List;
      list.forEach(
        (raw)
        {
          if(raw is Map<String, dynamic> && raw['images'] is Map<String, dynamic>)
            images.add(new ResponseImage(raw['images']));
        }
      );
    }
    if(response['pagination'] != null) {
      pagination = new GiphyPagination.parse(response['pagination']);
    }
    if(response['meta'] != null) {
      meta = new GiphyMeta.parse(response['meta']);
    }
  }
}

class ResponseImage
{
  Map<String, dynamic> images;

  ResponseImage(this.images);

  GiphyImage get fixedWidth
  {
    if(images != null  && images['fixed_width'] != null)
      return new GiphyImage.parse(images['fixed_width']);
    else
      return null;
  }
}

class GiphyImage
{
  String url;
  String width;
  String height;

  GiphyImage({this.url, this.width, this.height});

  GiphyImage.parse(Map<String, dynamic> data)
  {
    url = data['url'];
    width = data['width'];
    height = data['height'];
  }

  Widget createGridItem({VoidCallback onTap})
  {
    return new Material(
      color: Colors.grey,
      borderRadius: new BorderRadius.circular(5.0),
      child: new InkWell(
          onTap: onTap,
          child: new Stack(
            fit: StackFit.expand,
            children: <Widget>[
              new Image.network(url, fit: BoxFit.fill)
            ],
          )
      ),
    );
  }
}

class GiphyPagination
{
  int totalCount;
  int count;
  int offset;

  GiphyPagination({this.totalCount, this.count, this.offset});
  GiphyPagination.parse(Map<String, dynamic> data)
  {
    totalCount = data['total_count'];
    count = data['count'];
    offset = data['offset'];
  }
}

class GiphyMeta
{
  int status;
  String msg;
  String responseId;

  GiphyMeta({this.status, this.msg, this.responseId});
  GiphyMeta.parse(Map<String, dynamic> data)
  {
    status = data['status'];
    msg = data['msg'];
    responseId = data['response_id'];
  }
}

