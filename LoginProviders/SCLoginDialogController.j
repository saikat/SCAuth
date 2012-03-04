/*
 * SCLoginDialogController.j
 * SCAuth
 *
 * Created by Saikat Chakrabarti on April 7, 2010.
 *
 * See LICENSE file for license information.
 *
 */

@import <AppKit/CPWindowController.j>
@import "../AccountValidators/SCAccountValidator.j"

var DefaultLoginDialogController    = nil,
    DefaultLoginTitle               = @"Login/Register",
    LoginTitle                      = @"Login",
    RegisterTitle                   = @"Register",
    UserCheckErrorMessage           = @"There was an error trying to find your username. Check your internet connection.",
    GenericErrorMessage             = @"Something went wrong. Check your internet connection and try again.",
    ConnectionStatusCode            = -1;

SCLoginSucceeded = 0;
SCLoginFailed = 1;

/*!
    @class SCLoginDialogController

    This is the controller for the default login dialog built-in to SCAuth.
*/
@implementation SCLoginDialogController : CPWindowController
{
            unsigned        _dialogReturnCode;
            CPString        _username                   @accessors(readonly, property=username);
            id              _delegate                   @accessors(property=delegate);
            SEL             _callback;
            CPURLConnection _userCheckConnection;
            CPURLConnection _loginConnection;
            CPURLConnection _registrationConnection;
            id              _accountValidator           @accessors(property=accountValidator);
            // I use this for dependency injection in the tests
            CPObject        _connectionClass            @accessors(property=connectionClass);

    @outlet CPButton        _tryAgainButton             @accessors(property=tryAgainButton);
    @outlet CPTextField     _subheading                 @accessors(property=subheading);
    @outlet CPTextField     _userLabel                  @accessors(property=userLabel);
    @outlet CPTextField     _userField                  @accessors(property=userField);
    @outlet CPTextField     _passwordLabel              @accessors(property=passwordLabel);
    @outlet CPTextField     _passwordField              @accessors(property=passwordField);
    @outlet CPTextField     _passwordConfirmLabel       @accessors(property=passwordConfirmLabel);
    @outlet CPTextField     _passwordConfirmField       @accessors(property=passwordConfirmField);
    @outlet CPTextField     _errorMessage               @accessors(property=errorMessage);
    @outlet CPButton        _loginButton                @accessors(property=loginButton);
    @outlet CPButton        _cancelButton               @accessors(property=cancelButton);
    @outlet CPTextField     _registeringProgressLabel   @accessors(property=registeringProgressLabel);
    @outlet CPTextField     _loggingInProgressLabel     @accessors(property=loggingInProgressLabel);
    @outlet CPImageView     _progressSpinner            @accessors(property=progressSpinner);
    @outlet CPImageView     _userCheckSpinner           @accessors(property=userCheckSpinner);
    @outlet CPButton        _forgotPasswordLink         @accessors(property=forgotPasswordLink);
    @outlet CPCheckBox      _rememberMeButton           @accessors(property=rememberMeButton);
    @outlet CPView          _formFieldContainer         @accessors(property=formFieldContainer);
}

- (void)awakeFromCib
{
    _accountValidator = SCAccountValidator;
    _connectionClass = CPURLConnection;
    [_window setAutorecalculatesKeyViewLoop:NO];
    [_window setDefaultButton:_loginButton];
    if (_window._windowView && _window._windowView._closeButton)
        [_window._windowView._closeButton setHidden:YES];

    [_userLabel sizeToFit];
    [_passwordLabel sizeToFit];
    [_registeringProgressLabel sizeToFit];
    [_loggingInProgressLabel sizeToFit];

    [_userField setDelegate:self];

    [_subheading setLineBreakMode:CPLineBreakByWordWrapping];
    [_subheading setBackgroundColor:[CPColor colorWithCalibratedRed:103.0 / 255.0 green:154.0 / 255.0 blue:205.0 / 255.0 alpha:1.0]];
    [_subheading setTextColor:[CPColor whiteColor]];
    var border = [[CPView alloc] initWithFrame:CPRectMake(0, CPRectGetHeight([_subheading bounds]) - 1,CPRectGetWidth([_subheading bounds]), 1)];
    [border setAutoresizingMask: CPViewWidthSizable | CPViewMinYMargin];
    [border setBackgroundColor:[CPColor grayColor]];
    [_subheading addSubview:border];
    [_subheading setValue:CGInsetMake(9.0, 9.0, 9.0, 9.0) forThemeAttribute:@"content-inset"];

    [_errorMessage setLineBreakMode:CPLineBreakByWordWrapping];
    [_errorMessage setBackgroundColor:[CPColor colorWithHexString:"993333"]];
    [_errorMessage setTextColor:[CPColor whiteColor]];
    var border = [[CPView alloc] initWithFrame:CPRectMake(0, CPRectGetHeight([_errorMessage bounds]) - 1, CPRectGetWidth([_errorMessage bounds]), 1)];
    [border setAutoresizingMask: CPViewWidthSizable | CPViewMinYMargin];
    [border setBackgroundColor:[CPColor grayColor]];
    [_errorMessage addSubview:border];
    [_errorMessage setValue:CGInsetMake(9.0, 9.0, 9.0, 9.0) forThemeAttribute:@"content-inset"];

    [_tryAgainButton setTheme:nil];
    [_tryAgainButton setTextColor:[CPColor colorWithCalibratedRed:159.0 / 255.0 green:201.0 / 255.0 blue:245.0 / 255.0 alpha:1.0]];
    [_tryAgainButton setAlignment:CPLeftTextAlignment];
    [_tryAgainButton setStringValue:"Tryagain."];
    // I have to set the text color like this - otherwise the underline stays black
    if (_tryAgainButton._DOMElement)
    {
        _tryAgainButton._DOMElement.className = "hover";
        _tryAgainButton._DOMElement.style.color = [[CPColor colorWithCalibratedRed:159.0 / 255.0 green:201.0 / 255.0 blue:245.0 / 255.0 alpha:1.0] cssString];
        _tryAgainButton._DOMElement.style.textDecoration = "underline";
    }
    [_tryAgainButton sizeToFit];
    // Without this, the button screws up in FF and wraps.
    [_tryAgainButton setFrameSize:CGSizeMake([_tryAgainButton frame].size.width + 5.0, [_tryAgainButton frame].size.height)];

    [_forgotPasswordLink setFont:[CPFont fontWithName:[[_forgotPasswordLink font] familyName] size:10.0]];
    [_forgotPasswordLink setTheme:nil];
    [_forgotPasswordLink setTextColor:[CPColor colorWithCalibratedRed:103.0 / 255.0 green:154.0 / 255.0 blue:205.0 / 255.0 alpha:1.0]];
    [_forgotPasswordLink sizeToFit];
    [_forgotPasswordLink setFrameOrigin:CGPointMake([_passwordField frame].origin.x + [_passwordField frame].size.width - [_forgotPasswordLink frame].size.width,
                                                    [_passwordField frame].origin.y + [_passwordField frame].size.height)];

    [_rememberMeButton setFont:[CPFont fontWithName:[[_forgotPasswordLink font] familyName] size:[[_passwordLabel font] size]]];
    if (_forgotPasswordLink._DOMElement)
        _forgotPasswordLink._DOMElement.className = "hover";

    [_passwordField setSecure:YES];
    [_passwordConfirmField setSecure:YES];
    [_window setShowsResizeIndicator:NO];

    [[CPNotificationCenter defaultCenter]
        addObserver:self
           selector:@selector(_loginDialogClosed:)
               name:CPWindowWillCloseNotification
             object:_window];
}

/* @ignore */
- (void)_loginDialogClosed:(CPNotification)aNotification
{
    [CPApp stopModalWithCode:CPRunStoppedResponse];
    if (_delegate && [_delegate respondsToSelector:_callback])
        [_delegate performSelector:_callback withObject:_dialogReturnCode];
}

- (@action)forgotPasswordLinkClicked:(id)sender
{
    var forgotPasswordURL = [[CPBundle mainBundle] objectForInfoDictionaryKey:@"SCAuthForgotPasswordURL"];
    if (forgotPasswordURL)
        if (window.open)
            window.open(forgotPasswordURL);
}

- (@action)tryCheckUserAgain:(id)sender
{
    [self _checkUser];
}

- (@action)cancel:(id)sender
{
    _dialogReturnCode = SCLoginFailed;
    [_window close];
}

- (@action)login:(id)sender
{
    if ([_loginButton title] === RegisterTitle)
    {
        var passwordError = [_accountValidator validatePassword:[_passwordField stringValue]
                                            withConfirmPassword:[_passwordConfirmField stringValue]];
        if (passwordError)
            [self _setErrorMessageText:passwordError];
        else
        {
            if ([_accountValidator validateUsername:[_userField stringValue]])
            {
                [self _registerUser:[_userField stringValue] password:[_passwordField stringValue]];
                [_registeringProgressLabel setHidden:NO];
                [_progressSpinner setHidden:NO];
                [_loginButton setHidden:YES];
            }
            else
                [self _setErrorMessageText:@"Please enter a valid username."];
        }
    }
    else
    {
        [self _loginUser:[_userField stringValue] password:[_passwordField stringValue]];
        [_loggingInProgressLabel setHidden:NO];
        [_progressSpinner setHidden:NO];
        [_loginButton setHidden:YES];
    }
}

/* @ignore */
- (void)_loginFailedWithError:(CPString)errorMessageText statusCode:(int)statusCode
{
    [self _setDialogModeToLogin];
    [self _setErrorMessageText:errorMessageText];
    [_window makeFirstResponder:_passwordField];
    [_passwordField selectText:self];
}

/* @ignore */
- (void)_registrationFailedWithError:(CPString)errorMessageText statusCode:(int)statusCode
{
    [self _setDialogModeToRegister];
    [self _setErrorMessageText:errorMessageText];
}

/* @ignore */
- (void)_loginUser:(CPString)username password:(CPString)password
{
    var shouldRemember  = ([_rememberMeButton state] === CPOnState),
        loginObject     = {'username' : username, 'password' : password, 'remember' : shouldRemember},
        request         = [CPURLRequest requestWithURL:[[CPBundle mainBundle] objectForInfoDictionaryKey:@"SCAuthLoginURL"] || @"/session/"];

    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:[CPString JSONFromObject:loginObject]];
    _loginConnection = [_connectionClass connectionWithRequest:request delegate:self];
    _loginConnection.username = username;
}

/* @ignore */
- (void)_registerUser:(CPString)username password:(CPString)password
{
    var shouldRemember  = ([_rememberMeButton state] === CPOnState),
        registerObject  = {'username' : username, 'password' : password, 'remember' : shouldRemember},
        request         = [CPURLRequest requestWithURL:[[CPBundle mainBundle] objectForInfoDictionaryKey:@"SCAuthRegistrationURL"] || @"/user/"];

    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:[CPString JSONFromObject:registerObject]];
    _registrationConnection = [_connectionClass connectionWithRequest:request delegate:self];
    _registrationConnection.username = username;
}

/* @ignore */
- (CGPoint)_setButtonOrigins
{
    var frameToUse = [_passwordConfirmField frame];
    if ([_passwordConfirmField isHidden])
    {
        if ([_forgotPasswordLink isHidden])
            frameToUse = [_passwordField frame];
        else
            frameToUse = [_forgotPasswordLink frame];
    }
    [_loginButton setFrameOrigin:CGPointMake(frameToUse.origin.x + frameToUse.size.width - [_loginButton frame].size.width - 3.0,
                                             frameToUse.origin.y + frameToUse.size.height + 5.0)];
    var loginFrame = [_loginButton frame];
    [_cancelButton setFrameOrigin:CGPointMake(loginFrame.origin.x - [_cancelButton frame].size.width - 8.0,
                                              loginFrame.origin.y)];
    [_rememberMeButton setFrameOrigin:CGPointMake(0, loginFrame.origin.y + loginFrame.size.height / 2 - [_rememberMeButton frame].size.height / 2)];
    [_progressSpinner setFrameOrigin:CGPointMake(loginFrame.origin.x,
                                                 loginFrame.origin.y + loginFrame.size.height / 2.0 - [_progressSpinner frame].size.height / 2.0)];
    var spinnerFrame = [_progressSpinner frame];
    [_registeringProgressLabel setFrameOrigin:CGPointMake(spinnerFrame.origin.x + spinnerFrame.size.width + 5.0,
                                                          spinnerFrame.origin.y + spinnerFrame.size.height / 2.0 - [_registeringProgressLabel frame].size.height / 2.0)];
    [_loggingInProgressLabel setFrameOrigin:CGPointMake(spinnerFrame.origin.x + spinnerFrame.size.width + 5.0,
                                                        spinnerFrame.origin.y + spinnerFrame.size.height / 2.0 - [_loggingInProgressLabel frame].size.height / 2.0)];
}

/* @ignore */
- (void)_sizeAndPositionFormFieldContainer
{
    if ([_subheading isHidden] && [_errorMessage isHidden])
        [_formFieldContainer setFrameOrigin:CGPointMake(16, 0)];
    else
    {
        if (![_subheading isHidden])
            [_formFieldContainer setFrameOrigin:CGPointMake(16, [_subheading frame].origin.y + [_subheading frame].size.height + 5.0)];
        else if (![_errorMessage isHidden])
            [_formFieldContainer setFrameOrigin:CGPointMake(16, [_errorMessage frame].origin.y + [_errorMessage frame].size.height + 5.0)];
    }
    [_formFieldContainer setFrameSize:CGSizeMake([_loginButton frame].origin.x + [_loginButton frame].size.width + 16.0,
                                                 [_loginButton frame].origin.y + [_loginButton frame].size.height + 10.0)];
}

/* @ignore */
- (void)_setKeyViews
{
    if ([_passwordConfirmField isHidden])
    {
        [_userField setNextKeyView:_passwordField];
        [_passwordField setNextKeyView:_userField];
    }
    else
    {
        [_userField setNextKeyView:_passwordField];
        [_passwordField setNextKeyView:_passwordConfirmField];
        [_passwordConfirmField setNextKeyView:_userField];
    }
}

/* @ignore */
- (void)_sizeWindowToFit
{
    var fieldFrame = [_formFieldContainer frame];
    [_window setFrameSize:CGSizeMake(fieldFrame.origin.x + fieldFrame.size.width,
                                     fieldFrame.origin.y + fieldFrame.size.height + 30.0)];
}

/* @ignore */
- (void)_checkUser
{
    [_userCheckSpinner setHidden:NO];

    var request = [CPURLRequest requestWithURL:([[CPBundle mainBundle] objectForInfoDictionaryKey:@"SCAuthUserCheckURL"] || @"/user/") + [_userField stringValue]];

    [request setHTTPMethod:@"GET"];
    _userCheckConnection = [_connectionClass connectionWithRequest:request delegate:self];
}

- (void)_setMessage:(CPString)aMessage inTextBox:(CPTextField)textBox
{
    if (aMessage)
    {
        [textBox setStringValue:aMessage];
        [textBox setHidden:NO];
        var size = [aMessage sizeWithFont:[textBox font] inWidth:[_formFieldContainer frame].size.width + 16.0];
        [textBox setFrame:CGRectMake(0, 0, size.width, size.height + 18.0)];
    }
    else
    {
        [textBox setStringValue:""];
        [textBox setHidden:YES];
    }
}

/*!
    Add a subheading to the login dialog explaining why the login dialog appeared.
 */
- (void)setSubheadingText:(CPString)aSubheading
{
    [self _setMessage:aSubheading inTextBox:_subheading];
    if (![_errorMessage isHidden] && ![_subheading isHidden])
        [_errorMessage setHidden:YES];
    [self _sizeAndPositionFormFieldContainer];
    [self _sizeWindowToFit];
}

/* @ignore */
- (void)_setErrorMessageText:(CPString)anErrorMessage
{
    [_tryAgainButton setHidden:YES];
    [self _setMessage:anErrorMessage inTextBox:_errorMessage];
    if (![_errorMessage isHidden] && ![_subheading isHidden])
        [_subheading setHidden:YES];
    [self _sizeAndPositionFormFieldContainer];
    [self _sizeWindowToFit];
}

/* @ignore */
- (void)_displayForgotPasswordLink
{
    if ([[CPBundle mainBundle] objectForInfoDictionaryKey:@"SCAuthForgotPasswordURL"])
        [_forgotPasswordLink setHidden:NO];
    else
        [_forgotPasswordLink setHidden:YES];
}

/* @ignore */
- (void)_setDefaultHiddenSettings
{
    [_userLabel setHidden:NO];
    [_userField setHidden:NO];
    [_passwordLabel setHidden:NO];
    [_passwordField setHidden:NO];
    [_loginButton setHidden:NO];
    [_cancelButton setHidden:NO];
    [_rememberMeButton setHidden:NO];
    [_registeringProgressLabel setHidden:YES];
    [_loggingInProgressLabel setHidden:YES];
    [_progressSpinner setHidden:YES];
    [_userCheckSpinner setHidden:YES];
    [_formFieldContainer setHidden:NO];
    [_tryAgainButton setHidden:YES];
    [self _setErrorMessageText:nil];
    [self setSubheadingText:nil];
}

/* @ignore */
- (void)_setDialogModeToLogin
{
    var currentErrorMessage = ([_errorMessage isHidden] ? nil : [_errorMessage stringValue]);
    [self _setDefaultHiddenSettings];
    if ([_loginButton title] === LoginTitle && currentErrorMessage)
        [self _setErrorMessageText:currentErrorMessage];
    [_loginButton setTitle:LoginTitle];
    [_passwordConfirmLabel setHidden:YES];
    [_passwordConfirmField setHidden:YES];
    [_passwordConfirmField setStringValue:""];
    [self _displayForgotPasswordLink];
    [self _layout];
}

/* @ignore */
- (void)_setDialogModeToRegister
{
    var currentErrorMessage = ([_errorMessage isHidden] ? nil : [_errorMessage stringValue]);
    [self _setDefaultHiddenSettings];
    [self setSubheadingText:"Welcome! Looks like you're a new user. Just choose a password to register."];
    if ([_loginButton title] === RegisterTitle && currentErrorMessage)
        [self _setErrorMessageText:currentErrorMessage];
    [_loginButton setTitle:RegisterTitle];
    [_passwordConfirmLabel setHidden:NO];
    [_passwordConfirmField setHidden:NO];
    [_forgotPasswordLink setHidden:YES];
    [self _layout];
}

/* @ignore */
- (void)_setDialogModeToLoginOrRegister
{
    [self _setDefaultHiddenSettings];
    [_loginButton setTitle:DefaultLoginTitle];
    [_passwordConfirmLabel setHidden:YES];
    [_passwordConfirmField setHidden:YES];
    [_passwordConfirmField setStringValue:""];
    [self _displayForgotPasswordLink];
    [self _layout];
}

/* @ignore */
- (void)_layout
{
    [self _setButtonOrigins];
    [self _sizeAndPositionFormFieldContainer];
    [self _setKeyViews];
    [self _sizeWindowToFit];
}

/*!
    Creates a new login dialog and run it modally.  The login dialog can be used to either
    log a user in or register a new user.  It expects the backend to respond to certain
    URLs correctly - see README.markdown.
    @param aDelegate - Should implement aCallback, which will get called with either
           SCLoginSucceeded or SCLoginFailed when the dialog closes
    @param aCallback - Gets called on dialog close
 */
- (void)loginWithDelegate:(id)aDelegate callback:(SEL)aCallback
{
    [CPApp runModalForWindow:[self window]];
    _username = nil;
    _delegate = aDelegate;
    _callback = aCallback;
    _dialogReturnCode = SCLoginFailed;
    [self _setDialogModeToLoginOrRegister];
    [_passwordField setStringValue:""];
    [_passwordConfirmField setStringValue:""];
    [_window makeFirstResponder:_userField];
}

/*!
    Creates a new login dialog controller
 */
+ (SCLoginDialogController)newLoginDialogController
{
    return [[self alloc] initWithWindowCibName:@"SCLoginDialog"];
}

/*!
    Returns a default controller singleton
 */
+ (SCLoginDialogController)defaultController
{
    if (!DefaultLoginDialogController)
        DefaultLoginDialogController = [self newLoginDialogController];
    return DefaultLoginDialogController;
}

- (void)loadWindow
{
    if (_window)
        return;

    [[CPBundle bundleForClass:[_cibOwner class]] loadCibFile:[self windowCibPath] externalNameTable:[CPDictionary dictionaryWithObject:_cibOwner forKey:CPCibOwner]];
}

- (CPString)windowCibPath
{
    if (_windowCibPath)
        return _windowCibPath;

    return [[CPBundle bundleForClass:[_cibOwner class]] pathForResource:_windowCibName + @".cib"];
}

- (void)controlTextDidBlur:(CPNotification)aNotification
{
    if ([aNotification object] !== _userField)
        return;

    if ([_cancelButton isHighlighted])
    {
        [_window makeFirstResponder:_userField];
        return;
    }
    
    if ([[CPBundle mainBundle] objectForInfoDictionaryKey:@"SCAuthUserCheckURL"])
        [self _checkUser];
}

/* @ignore */
- (void)_userCheckFailedWithStatusCode:(int)statusCode
{
    [self _setDialogModeToLoginOrRegister];
    [self _setErrorMessageText:UserCheckErrorMessage];
    [_tryAgainButton setHidden:NO];
    [_tryAgainButton setFrameOrigin:CGPointMake([_errorMessage frame].origin.x + 9.0,
                                                [_errorMessage frame].origin.y + [_errorMessage frame].size.height - 8.0)];
    [_errorMessage setFrameSize:CGSizeMake([_errorMessage frame].size.width,
                                           [_tryAgainButton frame].origin.y + [_tryAgainButton frame].size.height + 9.0)];
    [self _sizeAndPositionFormFieldContainer];
    [self _sizeWindowToFit];
}

- (void)connection:(CPURLConnection)aConnection didFailWithError:(CPException)anException
{
    if (connection === _loginConnection)
        [self _loginFailedWithError:GenericErrorMessage statusCode:ConnectionStatusCode];
    else if (connection === _registrationConnection)
        [self _registrationFailedWithError:GenericErrorMessage statusCode:ConnectionStatusCode];
    else if (connection === _userCheckConnection)
        [self _userCheckFailedWithStatusCode:ConnectionStatusCode];
}

- (void)_registrationSucceededWithUsername:(CPString)username
{
    _dialogReturnCode = SCLoginSucceeded;
    _username = username;
    [_window close];
}

- (void)_loginSucceededWithUsername:(CPString)username
{
    _dialogReturnCode = SCLoginSucceeded;
    _username = username;
    [_window close];
}

- (void)connection:(CPURLConnection)aConnection didReceiveResponse:(CPURLResponse)aResponse
{
    if (![aResponse isKindOfClass:[CPHTTPURLResponse class]])
    {
        switch (aConnection)
        {
        case _userCheckConnection:
            [self _userCheckFailedWithStatusCode:ConnectionStatusCode];
            break;

        case _loginConnection:
            [self _loginFailedWithError:GenericErrorMessage statusCode:ConnectionStatusCode];
            break;
        case _registrationConnection:
            [self _registrationFailedWithError:GenericErrorMessage statusCode:ConnectionStatusCode];
            break;
        default:
            [self _setErrorMessageText:GenericErrorMessage];
        }
        return;
    }

    var statusCode = [aResponse statusCode];
    switch (aConnection)
    {
        case _userCheckConnection:
            if (statusCode === 200)
                return;
            else if (statusCode == 404)
                [self _setDialogModeToRegister];
            else
                [self _userCheckFailedWithStatusCode:statusCode];
            break;

        case _loginConnection:
            if (statusCode === 200)
                return;
            else
            {
                if (statusCode === 403)
                {
                    // Between clicking login and the response, the dialog switched to register mode
                    // so we no longer care about this login error
                    if ([_loginButton title] !== RegisterTitle)
                        [self _loginFailedWithError:@"Incorrect username or password." statusCode:statusCode];
                }
                else
                    [self _loginFailedWithError:GenericErrorMessage statusCode:statusCode];
            }
            break;

        case _registrationConnection:
            if (statusCode === 200)
                return;
            else
            {
                if (statusCode === 409)
                    [self _setDialogModeToLogin];
                else
                    [self _registrationFailedWithError:GenericErrorMessage statusCode:statusCode];
            }
    }
    [aConnection cancel];
}

- (void)connection:(CPURLConnection)aConnection didReceiveData:(CPString)data
{
    [aConnection cancel];
    switch (aConnection)
    {
        case _userCheckConnection:
            [self _setDialogModeToLogin];
            break;
        case _loginConnection:
            [self _loginSucceededWithUsername:_loginConnection.username];
            break;
        case _registrationConnection:
            [self _registrationSucceededWithUsername:_registrationConnection.username];
    }
}

@end
