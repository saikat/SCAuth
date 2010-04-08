# Introduction
SCAuth gives you a simple way to manage sessions and do authentication in your Cappuccino applications.  SCAuth has methods to let your users login, logout, and sync their sessions, using a built-in login panel that can be switched out.  SCAuth also looks for unauthorized requests made by your application, dealing with making sure your user is authenticated before letting the request go through.

# Installation
Copy the entire SCAuth folder into your Frameworks folder, or any directory that you add using `OBJJ_INCLUDE_PATHS`.

# How to use

## Using what's already there
Include the session manager in your code with `SCAuth/SCUserSessionManager.j`.  As soon as you do this, SCAuth will begin checking the response on every CPURLConnection your application makes for return codes of 401 (the HTTP response code for Unauthorized).  If your backend returns a 401, SCAuth will show a login panel to the user, and once the user logs in, the original request will be completed.  You can also cause this login panel to appear by manually calling `- [SCUserSessionManager login:]`.  Look at SCUserSessionManager.j for other API methods.

## Changing the login dialog
If you don't like the default login panel, you can make your own.  Your custom login panel's controller will need to adhere to the following:
* Have the method `- (void)loginWithDelegate:callback:` and call the callback on the delegate when the panel closes with either 0 (for successful login) or 1 (for a failed or cancelled login).
* Have the method `- (CPString)username` that returns the username the user has entered in the login panel.

Once you make a login panel and controller that adhere to this contract, in your application, you can call `[[SCUserSessionManager defaultManager] setLoginProvider:customLoginController]`.

You can also change the methods used by the login panel to validate inputted usernames and passwords.  You can make your own account validator (as long as it implements all the methods that are in SCAuth/AccountValidators/SCAccountValidator.j), and then have your controller use it with `[customLoginController setAccountValidator:customAccountValidator]`.

# The future
The user session manager should be able to manage more than just the login state and current user's username.  In the future, there will be various login providers (like facebook connect, or OAuth) that can be dropped in using the setLoginProvider call on SCUserSessionManager.