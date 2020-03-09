import 'dart:convert';

import "package:googleapis_auth/auth_io.dart";
import 'package:http/http.dart' as http;
import 'package:html/dom.dart' hide Text;
import 'package:html/parser.dart' as parser;

class ResponseHandler{
  bool canAcceptRequests;
  DateTime _lastUpdate;
  List<SpotifyTrack> _tracks;

  ResponseHandler(){
    this.canAcceptRequests = false;
    this._lastUpdate = DateTime.now();

    SpotifyTrackFactory.generateTracks().then((value) {
      this._tracks = value;
      this.canAcceptRequests = true;
    });
  }

  Future<String> handle() async{
    if(_tracks == null){
      this._tracks = await SpotifyTrackFactory.generateTracks();
    }

    var now = DateTime.now();
    if(now.day != _lastUpdate.day){
      this._tracks = await SpotifyTrackFactory.generateTracks();
      this._lastUpdate = now;
    }

    return json.encode(_tracks);
  }
}

class SpotifyTrack{
  String id;
  String title;
  String artist;
  String imageUrl;
  SpotifyTrack(this.id, this.title, this.artist, this.imageUrl);

  Map<String, dynamic> toJson() => {
    'id' : id,
    'title': title,
    'artist': artist,
    'imageUrl': imageUrl,
  };
}

class YoutubeContainer{
  List<YoutubeTrack> items;

  YoutubeContainer.fromJson(Map<String, dynamic> json){
    Iterable iterable = json['items'];
    this.items = iterable.map((e) => YoutubeTrack.fromJson(e)).toList();
  }
}

class YoutubeTrack{
  YoutubeVideoID id;
  YoutubeTrack.fromJson(Map<String, dynamic> json){
    this.id = YoutubeVideoID.fromJson(json['id']);
  }
}

class YoutubeVideoID{
  String videoId;
  YoutubeVideoID.fromJson(Map<String, dynamic> json){
    this.videoId = json['videoId'];
  }
}

class SpotifyTrackFactory{
  static var client = clientViaApiKey('AIzaSyD0DE9PZHpthQR-A4QxPMYdEUj97lL2wjA');
  static Future<List<SpotifyTrack>> generateTracks() async {
    var response = await http.get("https://spotifycharts.com/regional/");

    var document = parser.parse(response.body);
    var chart = document.getElementsByClassName("chart-table")[0];
    var body = chart.getElementsByTagName("tbody")[0];

    List<SpotifyTrack> list = [];
    for(int x = 0; x < 20; x++){
      Element element = body.children[x];
      var url = element.children[0].children[0].outerHtml;

      RegExp exp = new RegExp(r'(?:(?:https?|ftp):\/\/)?[\w/\-?=%.]+\.[\w/\-?=%.]+');
      var match = exp.allMatches(url).first;

      var parsedUrl = url.substring(match.start, match.end);

      var spotify = await http.get(parsedUrl);
      Document spotifyDocument = parser.parse(spotify.body);

      var imageUrl = spotifyDocument.getElementsByClassName("cover-art-image")[0].outerHtml.replaceAll('<div class="cover-art-image" style="background-image:url(//', '');
      var end = imageUrl.indexOf('),');

      imageUrl = imageUrl.substring(0, end);

      var container = element.children[3];

      var title = container.children[0].text;
      var artist = container.children[1].text;
      var id = await _getResultsFromYoutube('$title $artist audio');

      list.add(SpotifyTrack(id, title, artist, "https://" + imageUrl));
    }

    return list;
  }

  static Future<String> _getResultsFromYoutube(String query) async{
    var res = await http.get(Uri.encodeFull('https://www.googleapis.com/youtube/v3/search?part=snippet&maxResults=1&q="$query"&type=video&videoCategoryId=10&key=YOURKEY'));

    print(res.body);
    return YoutubeContainer.fromJson(json.decode(res.body)).items.first.id.videoId;
  }
}