import "dart:html"; 
import "dart:convert";

void main() { 
  
  InputElement loginUsername = querySelector("#login_username");
  InputElement loginPassword = querySelector("#login_password");
  ButtonElement sendLoginBtn = querySelector("#send_login");
  
  InputElement newUsername = querySelector("#new_username");
  InputElement newPassword = querySelector("#new_password");
  ButtonElement sendNewUserBtn = querySelector("#send_new_user");
  
  ButtonElement sendLogoutBtn = querySelector("#logout");
  
  sendLoginBtn.onClick.listen((_) {
    sendLogin(loginUsername.value, loginPassword.value);
  });
  
  sendNewUserBtn.onClick.listen((_) {
    sendNewUser(newUsername.value, newPassword.value);
  });
  
  sendLogoutBtn.onClick.listen((_) {
    sendLogout();
  });
}

sendLogin(String username, String password) {
  if (username.trim().isEmpty || password.trim().isEmpty) {
    return;
  }
  
  var user = {"username": username, "password": password};
  
  HttpRequest.request("/services/login", method: "POST", 
      requestHeaders: {"content-type": "application/json"}, 
      sendData: JSON.encode(user)).then((request) {
    if (JSON.decode(request.response)["success"]) {
      window.location.href = "user/page.html";
    } else {
      window.alert(request.response);
    }
  });
}

sendNewUser(String username, String password) {
  if (username.trim().isEmpty || password.trim().isEmpty) {
    return;
  }
  
  var user = {"username": username, "password": password};
  
  HttpRequest.request("/services/newuser", method: "POST", 
      requestHeaders: {"content-type": "application/json"}, 
      sendData: JSON.encode(user)).then((request) {
    window.alert(request.response);
  });
}

sendLogout() {
  HttpRequest.getString("/services/logout").then((result) => window.alert(result));
}
