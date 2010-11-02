Introduction
============

SCAuth gives you a simple way to manage sessions in your Cappuccino applications.  SCAuth lets your users login and logout using a built-in login dialog (that can easily be switched out).  SCAuth also looks for unauthorized requests made by your application and deals with making sure your user is authenticated before letting the request go through.

Installation
============

Copy the entire SCAuth folder into your Frameworks folder, or any directory that you add using `OBJJ_INCLUDE_PATHS`.

Example
=======

You can find the soure code and instructions on how to run an example of SCAuth at [http://github.com/saikat/SCAuthExample](http://github.com/saikat/SCAuthExample).  You can see an example of SCAuth in production at [Mockingbird](http://gomockingbird.com/).

How to use
==========

### Using what's already there ###
Include the session manager in your code with `@import <SCAuth/SCUserSessionManager.j>`.  As soon as you do this, SCAuth will begin checking the response on every CPURLConnection your application makes for return codes of 401 (the HTTP response code for Unauthorized).  If your backend returns an HTTP response with status code 401, SCAuth will show a login dialog to the user.  The session manager will send `- (void)sessionManagerDidInterceptAuthenticationChallenge:(SCUserSessionManager)aSessionManager forConnection:(CPURLConnection)aConnection` to the original connection's delegate once the login dialog appears - you can use this hook to set your own state on the login provider or session manager (if you are using the default login dialog, you can call setSubheadingText in this method to set a message in the login dialog).  If the user logs in, the original request will be completed - otherwise, the original request will fail.  You can also display the login dialog manually by calling `- [SCUserSessionManager login:]`.  Look at SCUserSessionManager.j for other API methods to access and modify the user's current session.

SCAuth also relies on your backend responding to certain URLs.  To specify the URLs used by SCAuth, you need to specify values for the following keys in your application's Info.plist:

*	SCAuthForgotPasswordURL
  	* Defaults to nil, which doesn't show a forgot password link in the login dialog
  	* Backend just needs to handle a GET request to this URL properly by displaying a statick page where the user can change his password
*	SCAuthLoginURL
	* Used for login
	* Defaults to "/session/"
	* Called with POST HTTP Method
	* Sends data as JSON, where the json object has a username and a password property
	* Expects backend to send HTTP response with status 200 for success, or 403 for invalid username/password.
*	SCAuthRegistrationURL
	* Used for regstration
	* Defaults to "/user/"
	* Called with POST HTTP Method
	* Sends data as JSON, where the json object has a username and a password property
	* Expects backend to send HTTP response with status 200 for success, or 409 if the username is already registered
*	SCAuthUserCheckURL
	* Used to check the existence of a specified username
	* Defaults to "/user/"
	* Called with GET HTTP Method
	* Sends a URL parameter that is the checked username - so the actual request is sent to SCAuthUserCheckURL/<username>
	* Expects backend to send HTTP response with status 200 if the username is found, or 404 if the username is not found
*	SCAuthSyncURL
	* Used to get the current session information
	* Defaults to "/session/"
	* Called with GET HTTP Method
	* Sends no other data
	* Expects backend to send HTTP response with status 200 and a JSON object with a username property specifying the currently logged in user if the current user is logged in.  Otherwise, the backend should send a 404.
*	SCAuthLogoutURL (defaults to "/session/" - called with DELETE)
	* Used to logout the current user
	* Defaults to "/session/"
	* Called with DELETE HTTP Method
	* Sends no other data
	* Expects backend to send HTTP response with status 200 if successful.

### Changing the login dialog ###
If you don't like the default login dialog, you can make your own and have SCUserSessionManager use it.  Your custom login dialog's controller will need to adhere to the following:

*	Have the method `- (void)loginWithDelegate:callback:`.  Your controller must then call the specified callback on the specified delegate when the dialog closes, passing the callback an argument of either 0 (for successful login) or 1 (for a failed or cancelled login).
*	Have the method `- (CPString)username` that returns the username the user has entered in the login dialog.

Once you make a a custom login dialog and controler, you can call `[[SCUserSessionManager defaultManager] setLoginProvider:customLoginController]` to use it.

You can also change the methods used by the login dialog to validate inputted usernames and passwords.  You can make your own account validator (as long as it implements all the methods that are in SCAuth/AccountValidators/SCAccountValidator.j), and then have your controller use it with `[customLoginController setAccountValidator:customAccountValidator]`.

The future
==========

The user session manager should be able to manage more than just the login state and current user's username.  In the future, there will be various login providers (like facebook connect, or OAuth) that can be dropped in using the setLoginProvider call on SCUserSessionManager.