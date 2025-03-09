import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:datingapp/services/authentification.dart';
import 'package:datingapp/values/colors.dart';
import 'package:datingapp/values/dimensions.dart';
import 'package:datingapp/widgets/images.dart';
import 'package:datingapp/values/themes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'create_user.dart';
import '../main.dart';

class LoginPage extends StatefulWidget {
  LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() {
    return new _LoginPageState();
  }
}

class _LoginPageState extends State<LoginPage> {
  bool _isShowingRegister = true;
  bool _isCheckingUserExists = false;
  TapGestureRecognizer _termsConditionRecognizer = TapGestureRecognizer();
  TapGestureRecognizer _privacyPolicyRecognizer = TapGestureRecognizer();
  bool _isShowingCheckBoxHint = false;
  bool _hasAcceptedTermsOfUse = false;
  bool _hasAcceptedPrivacy = false;

  String _email = "", _password = "", _confirmPassword = "";
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
    _termsConditionRecognizer = TapGestureRecognizer()
      ..onTap = () {
        /*Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => PageTermsOfUse(),
        ));*/
      };
    _privacyPolicyRecognizer = TapGestureRecognizer()
      ..onTap = () {
        /*Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => PrivacyPage(),
        ));*/
      };
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, theme, _) => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: logo_custom(
            size: 50,
            color: (theme.themeMode == "dark") ? mainRed : mainRed,
          ),
        ),
        body: Padding(
          padding: EdgeInsets.symmetric(
              vertical: 10, horizontal: standardPadding * 3),
          child: Center(
            child: (!_isCheckingUserExists)
                ? ListView(
                    children: <Widget>[
                      SizedBox(
                        height: standardPadding * 3,
                      ),
                      buildRegisterSwitch(),
                      buildEmailTextForm(),
                      SizedBox(
                        height: standardPadding,
                      ),
                      buildPasswordForm(),
                      (_isShowingRegister)
                          ? buildSecondPasswordForm()
                          : forgotPasswordButton(),
                      SizedBox(
                        height: standardPadding,
                      ),
                      buildSignUpButton(),
                      (_errorMessage != "")
                          ? Center(child: Text(_errorMessage))
                          : Container(),
                      SizedBox(
                        height: standardPadding * 2,
                      ),
                      _signInButtons(theme),
                      SizedBox(
                        height: standardPadding * 2,
                      ),
                      (_isShowingRegister)
                          ? buildAcceptCheckBox(context)
                          : Container(),
                    ],
                  )
                : Center(
                    child: CircularProgressIndicator(),
                  ),
          ),
        ),
      ),
    );
  }

  Container buildAcceptCheckBox(BuildContext context) {
    return Container(
      decoration: (_isShowingCheckBoxHint)
          ? BoxDecoration(
              border: Border.all(color: mainRed, width: 3),
              color:
                  (_isShowingCheckBoxHint) ? Theme.of(context).cardColor : null,
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Checkbox(
                value: _hasAcceptedTermsOfUse,
                onChanged: (bool? boolValue) {
                  setState(() {
                    _hasAcceptedTermsOfUse = boolValue!;
                    if (_hasAcceptedTermsOfUse && _hasAcceptedPrivacy) {
                      _isShowingCheckBoxHint = false;
                    }
                  });
                },
              ),
              Flexible(
                  child: RichText(
                      text: TextSpan(style: TextStyle(height: 1.0), children: [
                TextSpan(
                    text: "Ich habe die ",
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .copyWith(fontSize: 11)),
                TextSpan(
                    text: "Nutzungsbedingungen",
                    recognizer: _termsConditionRecognizer,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontSize: 11, decoration: TextDecoration.underline)),
                TextSpan(
                    text: " gelesen und akzeptiere diese",
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .copyWith(fontSize: 11)),
              ])))
            ],
          ),
          Row(
            children: <Widget>[
              Checkbox(
                value: _hasAcceptedPrivacy,
                onChanged: (bool? boolValue) {
                  setState(() {
                    _hasAcceptedPrivacy = boolValue!;
                    if (_hasAcceptedTermsOfUse && _hasAcceptedPrivacy) {
                      _isShowingCheckBoxHint = false;
                    }
                  });
                },
              ),
              Flexible(
                  child: RichText(
                      text: TextSpan(style: TextStyle(height: 1.0), children: [
                TextSpan(
                    text: "Ich habe die ",
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .copyWith(fontSize: 11)),
                TextSpan(
                    text: "Datenschutzerklärung",
                    recognizer: _privacyPolicyRecognizer,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontSize: 11, decoration: TextDecoration.underline)),
                TextSpan(
                    text: " gelesen und akzeptiere diese",
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .copyWith(fontSize: 11)),
              ])))
            ],
          )
        ],
      ),
    );
  }

  ElevatedButton buildSignUpButton() {
    return ElevatedButton(
      child: Text((_isShowingRegister) ? 'Registieren' : 'Login'),
      onPressed: () {
        _onSignInWithEmailTapped(_email, _password, _confirmPassword);
      },
    );
  }

  Row buildRegisterSwitch() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        ElevatedButton(
          child: Text('Account erstellen'),
          onPressed: () {
            setState(() {
              _isShowingRegister = true;
            });
          },
        ),
        SizedBox(
          width: standardPadding,
        ),
        ElevatedButton(
          child: Text('Login'),
          onPressed: () {
            setState(() {
              _isShowingRegister = false;
            });
          },
        ),
      ],
    );
  }

  Widget forgotPasswordButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
            onPressed: () {},
            child: Text(
              "Passwort vergessen?",
              style: Theme.of(context).textTheme.bodyMedium,
            )),
      ],
    );
  }

  Widget buildSecondPasswordForm() {
    return Material(
      elevation: 5,
      child: TextFormField(
        autofocus: false,
        initialValue: '',
        obscureText: true,
        decoration: InputDecoration(
          filled: true,
          fillColor: Theme.of(context).cardColor,
          hintText: 'Passwort erneut eingeben',
          hintStyle: TextStyle(),
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        ),
        validator: (input) {
          if (input == "") {
            return 'Bitte gib dein Passwort erneut ein.';
          } else {
            return null;
          }
        },
        onChanged: (input) => _confirmPassword = input,
      ),
    );
  }

  Widget buildPasswordForm() {
    return Material(
      elevation: 5,
      child: TextFormField(
        autofocus: false,
        initialValue: '',
        obscureText: true,
        decoration: InputDecoration(
          fillColor: Theme.of(context).cardColor,
          filled: true,
          hintText: 'Passwort',
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        ),
        validator: (input) {
          if (input == "") {
            return 'Bitte gib ein Passwort ein.';
          } else {
            return null;
          }
        },
        onChanged: (input) => _password = input,
      ),
    );
  }

  Widget buildEmailTextForm() {
    return Material(
      elevation: 5,
      child: TextFormField(
        keyboardType: TextInputType.emailAddress,
        autofocus: false,
        initialValue: '',
        decoration: InputDecoration(
          fillColor: Theme.of(context).cardColor,
          filled: true,
          hintText: 'E-Mail',
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        ),
        validator: (input) {
          if (input == "") {
            return 'Bitte gib eine Email ein.';
          } else {
            return null;
          }
        },
        onChanged: (input) => _email = input,
      ),
    );
  }

  Widget _signInButtons(ThemeNotifier themeNotifier) {
    return Column(
      children: [
        Text("oder weiter mit:"),
        SizedBox(
          height: standardPadding,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            (Theme.of(context).platform == TargetPlatform.iOS)
                ? GestureDetector(
                    onTap: _onSignInWithAppleTapped,
                    child: SizedBox(
                      width: 60,
                      height: 60,
                      child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: (themeNotifier.themeMode == "dark")
                              ? Image.asset(appleLogoWhitePath)
                              : Image.asset(appleLogoBlackPath)),
                    ),
                  )
                : Container(),
            (Theme.of(context).platform == TargetPlatform.iOS)
                ? SizedBox(
                    width: 20.0,
                  )
                : Container(),
            GestureDetector(
              onTap: _onSignInWithGoogleTapped,
              child: SizedBox(
                width: 72,
                height: 72,
                child: Image.asset(googleLogoPath),
              ),
            ),
            SizedBox(
              height: 20.0,
            ),
            //(_isShowingCheckBoxHint) ? Text("Deine Einstimmung wird noch benötigt", style: termsWarningTextStyle,) : Container(),
          ],
        ),
      ],
    );
  }

  void _onSignInWithGoogleTapped() {
    if (_hasAcceptedPrivacy && _hasAcceptedTermsOfUse || !_isShowingRegister) {
      setState(() {
        _isCheckingUserExists = true;
      });
      Authentication.signInWithGoogle().whenComplete(() {
        Navigator.of(context).pop();
        if (FirebaseAuth.instance.currentUser != null) {
          _checkIfUserExistsAfterLogin();
        }
      });
    } else {
      setState(() {
        _isShowingCheckBoxHint = true;
      });
    }
  }

  void _onSignInWithAppleTapped() {
    if (_hasAcceptedPrivacy && _hasAcceptedTermsOfUse || !_isShowingRegister) {
      setState(() {
        _isCheckingUserExists = true;
      });
      Authentication.signInWithApple().whenComplete(() {
        if (FirebaseAuth.instance.currentUser != null) {
          _checkIfUserExistsAfterLogin();
        }
      });
    } else {
      setState(() {
        _isShowingCheckBoxHint = true;
      });
    }
  }

  void _onSignInWithEmailTapped(
      String email, String password, String confirmPassword) async {
    if (!_isShowingRegister) {
      try {
        UserCredential userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password);
        print(userCredential);
        _checkIfUserExistsAfterLogin();
      } catch (error) {
        String errorMsg = "";
        switch (error) {
          case "ERROR_USER_NOT_FOUND":
            errorMsg = "Kein Benutzer unter dieser Email";
            break;
          case "ERROR_INVALID_EMAIL":
            if (_email.contains(' ')) {
              errorMsg = "Email Adresse enthält Leerzeichen";
            } else {
              errorMsg = "Email Adresse hat falsches Format";
            }
            break;
          case "ERROR_WRONG_PASSWORD":
            errorMsg = "Falsches Passwort";
            break;
          default:
            errorMsg = error.toString();
            print(error);
            break;
        }
        setState(() {
          _errorMessage = errorMsg;
        });
      }
    } else {
      if (password != confirmPassword) {
        setState(() {
          _errorMessage = "Passwörter stimmen nicht überein";
        });
      } else {
        try {
          print("Try Register with Email");
          var result = await FirebaseAuth.instance
              .createUserWithEmailAndPassword(email: email, password: password);
          if (!result.user!.emailVerified) {
            await FirebaseAuth.instance.currentUser!.sendEmailVerification();
            _checkIfUserExistsAfterLogin();
          } else {
            _checkIfUserExistsAfterLogin();
          }
        } catch (error) {
          String errorMsg;
          switch (error) {
            case "ERROR_WEAK_PASSWORD":
              errorMsg = "Bitte gib ein stärkeres Passwort ein";
              break;
            case "ERROR_INVALID_EMAIL":
              if (_email.contains(' ')) {
                errorMsg = "Email Adresse enthält Leerzeichen";
              } else {
                errorMsg = "Email Adresse hat falsches Format";
              }
              break;
            case "ERROR_EMAIL_ALREADY_IN_USE":
              errorMsg = "Es existiert bereits ein Konto unter dieser Email";
              break;
            default:
              errorMsg = error.toString();
              break;
          }
          setState(() {
            _errorMessage = errorMsg;
          });
        }
      }
    }
  }

  void _checkIfUserExistsAfterLogin() async {
    User? fbuser = FirebaseAuth.instance.currentUser;
    String uid = fbuser!.uid;
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection("users").doc(uid).get();
    setState(() {
      _isCheckingUserExists = false;
    });
    if (userDoc.exists) {
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => MyApp()),
          (Route<dynamic> route) => false);
      //Provider.of<CurrUser>(context, listen: true).updateCurrentUser(uid);
    } else {
      bool successUserCreation = await Navigator.push(
          context, MaterialPageRoute(builder: (context) => CreateUserPage()));
      if (successUserCreation) {
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => MyApp()),
            (Route<dynamic> route) => false);
        //Provider.of<CurrUser>(context, listen: true).updateCurrentUser(uid);
      }
    }
    setState(() {
      _isCheckingUserExists = false;
    });
  }
}
