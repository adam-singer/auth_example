import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:redstone/server.dart' as app;
import 'package:crypto/crypto.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:di/di.dart';

class DbConnManager {

  String uri;

  DbConnManager(String this.uri);

  Future<Db> connect() {
    Db conn = new Db(uri);
    return conn.open().then((_) => conn);
  }

  void close(Db conn) {
    conn.close();
  }

}

@app.Interceptor(r'/services/.+')
createConn(DbConnManager connManager) {
  connManager.connect().then((Db dbConn) {
    app.request.attributes['dbConn'] = dbConn;
    app.chain.next(() => connManager.close(dbConn));
  }).catchError((e) {
    app.chain.interrupt(statusCode: HttpStatus.INTERNAL_SERVER_ERROR, 
        response: {"error": "DATABASE_UNAVAILABLE"});
  });
}

@app.Interceptor(r'/user/.+')
authenticationFilter() {
  if (app.request.session["username"] == null) {
    app.chain.interrupt(statusCode: HttpStatus.UNAUTHORIZED, response: {"error": "NOT_AUTHENTICATED"});
  } else {
    app.chain.next();
  }
}

@app.Route("/services/login", methods: const[app.POST])
login(@app.Attr() Db dbConn, @app.Body(app.JSON) Map body) {
  var userCollection = dbConn.collection("user");
  if (body["username"] == null || body["password"] == null) {
    return {"success": false, "error": "WRONG_USER_OR_PASSWORD"};
  }
  var pass = encryptPassword(body["password"].trim());
  return userCollection.findOne({"username": body["username"], "password": pass})
      .then((user) {
        if (user == null) {
          return {
            "success": false,
            "error": "WRONG_USER_OR_PASSWORD"
          };
        }
        
        var session = app.request.session;
        session["username"] = user["username"];
        session["admin"] = user["admin"];
        
        return {"success": true};
      });
}

@app.Route("/services/logout")
logout() {
  app.request.session.destroy();
  return {"success": true};
}

@app.Route("/services/newuser", methods: const[app.POST])
addUser(@app.Attr() Db dbConn, @app.Body(app.JSON) Map json) {
  
  String username = json["username"];
  String password = json["password"];
  
  username = username.trim();
  
  var userCollection = dbConn.collection("user");
  return userCollection.findOne({"username": username}).then((value) {
    if (value != null) {
      return {"success": false, "error": "USER_EXISTS"};
    }
    
    var user = {
      "username": username,
      "password": encryptPassword(password)
    };
    
    return userCollection.insert(user).then((resp) => {"success": true});
  });
}

String encryptPassword(String pass) {
  var toEncrypt = new SHA1();
  toEncrypt.add(UTF8.encode(pass));
  return CryptoUtils.bytesToHex(toEncrypt.close());
}

main() {

  app.setupConsoleLog();

  var dbUri = "mongodb://localhost/auth_example";

  app.addModule(new Module()
      ..bind(DbConnManager, toValue: new DbConnManager(dbUri)));

  app.start(followLinks: true, jailRoot: false);

}