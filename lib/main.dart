import 'package:angel_framework/angel_framework.dart';
import 'package:angel_framework/http.dart';
import 'package:rebeat_backend_server/handler.dart';

void main() async {
  var app = Angel();
  var http = AngelHttp(app);

  var handler = ResponseHandler();
  app.get('/chart', (req, res) async{
    print("Request!");
    if(!handler.canAcceptRequests){
      res.write("Fetching data, please wait!");
      return;
    }

    res.write(await handler.handle());
  });

  await http.startServer("192.168.1.30", 8080);
}