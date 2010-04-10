/*
 * SCLoginPanelController.j
 * SCAuth
 *
 * Created by Saikat Chakrabarti on April 7, 2010.
 *
 * See LICENSE file for license information.
 * 
 */

@import <AppKit/CPWindowController.j>
@import "../AccountValidators/SCAccountValidator.j"

var DefaultLoginPanelController = nil,
    DefaultLoginTitle = @"Login/Register",
    LoginTitle = @"Login",
    RegisterTitle = @"Register",
    UserCheckErrorMessage = @"Error finding user - are you online?",
    GenericErrorMessage = @"Something went wrong. Try again in a few seconds.";

SCLoginSucceeded = 0;
SCLoginFailed = 1;

/*! 
    @class SCLoginPanelController

    This is the controller for the default login panel built-in to SCAuth.
*/

@implementation SCLoginPanelController : CPWindowController
{
    unsigned _panelReturnCode;
    CPString _username @accessors(readonly, property=username);
    id _delegate @accessors(property=delegate);
    SEL _callback;
    CPURLConnection _userCheckConnection;
    CPURLConnection _loginConnection;
    CPURLConnection _registrationConnection;
    id _accountValidator @accessors(property=accountValidator);
    // I use this for dependency injection in the tests
    CPObject _connectionClass @accessors(property=connectionClass);

    @outlet CPButton _tryAgainButton @accessors(property=tryAgainButton);
    @outlet CPTextField _subheading @accessors(property=subheading);
    @outlet CPTextField _userLabel @accessors(property=userLabel);
    @outlet CPTextField _userField @accessors(property=userField);
    @outlet CPTextField _passwordLabel @accessors(property=passwordLabel);
    @outlet CPTextField _passwordField @accessors(property=passwordField);
    @outlet CPTextField _passwordConfirmLabel @accessors(property=passwordConfirmLabel);
    @outlet CPTextField _passwordConfirmField @accessors(property=passwordConfirmField);
    @outlet CPTextField _errorMessage @accessors(property=errorMessage);
    @outlet CPButton _loginButton @accessors(property=loginButton);
    @outlet CPButton _cancelButton @accessors(property=cancelButton);
    @outlet CPTextField _registeringProgressLabel @accessors(property=registeringProgressLabel);
    @outlet CPTextField _loggingInProgressLabel @accessors(property=loggingInProgressLabel);
    @outlet CPImageView _progressSpinner @accessors(property=progressSpinner);
    @outlet CPImageView _userCheckSpinner @accessors(property=userCheckSpinner);
    @outlet CPButton _forgotPasswordLink @accessors(property=forgotPasswordLink);
    @outlet CPView _formFieldContainer @accessors(property=formFieldContainer);
}

- (void)awakeFromCib
{
    _accountValidator = SCAccountValidator;
    _connectionClass = CPURLConnection;
    [_window setAutorecalculatesKeyViewLoop:NO];
    [_window setDefaultButton:_loginButton];
    [_userLabel sizeToFit];
    [_passwordLabel sizeToFit];
    [_registeringProgressLabel sizeToFit];
    [_loggingInProgressLabel sizeToFit];

    [_userField setDelegate:self];

    [_subheading setLineBreakMode:CPLineBreakByWordWrapping];
    [_subheading setBackgroundColor:[CPColor colorWithCalibratedRed:103.0 / 255.0 green:154.0 / 255.0 blue:205.0 / 255.0 alpha:1.0]];
    [_subheading setTextColor:[CPColor whiteColor]];
    var border = [[CPView alloc] initWithFrame:CPRectMake(0,CPRectGetHeight([_subheading bounds])-1,CPRectGetWidth([_subheading bounds]),1)];
    [border setAutoresizingMask: CPViewWidthSizable | CPViewMinYMargin];
    [border setBackgroundColor:[CPColor grayColor]];
    [_subheading addSubview:border];
    [_subheading setValue:CGInsetMake(9.0, 9.0, 9.0, 9.0) forThemeAttribute:@"content-inset"];

    [_tryAgainButton setFont:[CPFont fontWithName:[[_tryAgainButton font] familyName] size:10.0]];
    [_tryAgainButton setTheme:nil];
    [_tryAgainButton setTextColor:[CPColor colorWithCalibratedRed:103.0 / 255.0 green:154.0 / 255.0 blue:205.0 / 255.0 alpha:1.0]];
    [_tryAgainButton sizeToFit];
    if (_tryAgainButton._DOMElement)
        _tryAgainButton._DOMElement.className = "hover";

    [_forgotPasswordLink setFont:[CPFont fontWithName:[[_forgotPasswordLink font] familyName] size:10.0]];
    [_forgotPasswordLink setTheme:nil];
    [_forgotPasswordLink setTextColor:[CPColor colorWithCalibratedRed:103.0 / 255.0 green:154.0 / 255.0 blue:205.0 / 255.0 alpha:1.0]];
    [_forgotPasswordLink sizeToFit];
    [_forgotPasswordLink sizeToFit];
    [_forgotPasswordLink setFrameOrigin:CGPointMake([_passwordField frame].origin.x + [_passwordField frame].size.width - [_forgotPasswordLink frame].size.width,
                                                    [_passwordField frame].origin.y + [_passwordField frame].size.height)];
    if (_forgotPasswordLink._DOMElement)
        _forgotPasswordLink._DOMElement.className = "hover";

    [_passwordField setSecure:YES];
    [_passwordConfirmField setSecure:YES];

    [_errorMessage setFont:[CPFont fontWithName:[[_errorMessage font] familyName] size:10.0]];
    [_errorMessage setLineBreakMode:CPLineBreakByWordWrapping];
    [_errorMessage setAlignment:CPRightTextAlignment];
    [_errorMessage setTextColor:[CPColor colorWithHexString:"993333"]];
    [_window setShowsResizeIndicator:NO];

    [[CPNotificationCenter defaultCenter]
        addObserver:self
           selector:@selector(_loginPanelClosed:)
               name:CPWindowWillCloseNotification
             object:_window];
}

/* @ignore */
- (void)_loginPanelClosed:(CPNotification)aNotification
{
    [CPApp stopModalWithCode:CPRunStoppedResponse];  
    if (_delegate && [_delegate respondsToSelector:_callback])
        [_delegate performSelector:_callback withObject:_panelReturnCode];
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
    _panelReturnCode = SCLoginFailed;
    [_window close];
}

- (@action)login:(id)sender
{
    [self _setErrorMessageText:nil];
    if ([_loginButton title] === RegisterTitle) 
    {
        var passwordError = [_accountValidator validatePassword:[_passwordField stringValue]
                                            withConfirmPassword:[_passwordConfirmField stringValue]];
        if (passwordError) 
            [self _setErrorMessageText:passwordError];
        else 
        {
            var userIsValid = [_accountValidator validateUsername:[_userField stringValue]];
            if (!userIsValid) 
                [self _setErrorMessageText:[[CPBundle mainBundle] objectForInfoDictionaryKey:@"SCAuthUserCheckErrorMessage"] || @"Please enter a valid username."];
            else 
            {
                [self _registerUser:[_userField stringValue] password:[_passwordField stringValue]];
                [_registeringProgressLabel setHidden:NO];
                [_progressSpinner setHidden:NO];
                [_loginButton setHidden:YES];
            }
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
- (void)_loginFailedWithError:(CPString)errorMessageText
{
    [self _setPanelModeToLogin];
    [self _setErrorMessageText:errorMessageText];
    [_window makeFirstResponder:_passwordField];
    [_passwordField selectText:self];
}

/* @ignore */
- (void)_registrationFailedWithError:(CPString)errorMessageText
{
    [self _setPanelModeToRegister];
    [self _setErrorMessageText:errorMessageText];
}

/* @ignore */
- (void)_loginUser:(CPString)username password:(CPString)password
{
    var loginObject = {'username' : username,
                       'password' : password},
        request = [CPURLRequest requestWithURL:[[CPBundle mainBundle] objectForInfoDictionaryKey:@"SCAuthLoginURL"] || @"/session/"];

        [request setHTTPMethod:@"POST"];
        [request setHTTPBody:[CPString JSONFromObject:loginObject]];
        _loginConnection = [_connectionClass connectionWithRequest:request
                                                         delegate:self];
        _loginConnection.username = username;
}

/* @ignore */
- (void)_registerUser:(CPString)username password:(CPString)password
{
    var registerObject = {'username' : username,
                          'password' : password},
        request = [CPURLRequest requestWithURL:[[CPBundle mainBundle] objectForInfoDictionaryKey:@"SCAuthRegistrationURL"] || @"/user/"];

        [request setHTTPMethod:@"POST"];
        [request setHTTPBody:[CPString JSONFromObject:registerObject]];
        _registrationConnection = [_connectionClass connectionWithRequest:request
                                                                delegate:self];
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
    if ([_subheading isHidden])
        [_formFieldContainer setFrameOrigin:CGPointMake(16, 0)];
    else
        [_formFieldContainer setFrameOrigin:CGPointMake(16, [_subheading frame].origin.y + [_subheading frame].size.height + 5.0)];
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
    [self _setErrorMessageText:nil];

    var request = [CPURLRequest requestWithURL:([[CPBundle mainBundle] objectForInfoDictionaryKey:@"SCAuthUserCheckURL"] || @"/user/") + [_userField stringValue]];
  
    [request setHTTPMethod:@"GET"];
    _userCheckConnection = [_connectionClass connectionWithRequest:request
                                                         delegate:self];
}

/* @ignore */
- (void)_setErrorMessageText:(CPString)anErrorMessage
{
    if (!anErrorMessage) 
    {
        [_errorMessage setHidden:YES];
        [_tryAgainButton setHidden:YES];
    }
    else 
    {
        [_errorMessage setHidden:NO];
        [_errorMessage setStringValue:anErrorMessage];
        var frameToUse = [_passwordConfirmField frame];
        if ([_passwordConfirmField isHidden]) 
            frameToUse = [_passwordField frame];
        var yOrigin = frameToUse.origin.y + frameToUse.size.height,
            height = [anErrorMessage sizeWithFont:[_errorMessage font] inWidth:108].height + 5.0;
        [_errorMessage setFrame:CGRectMake(frameToUse.origin.x - 5.0 - 108,
                                           yOrigin,
                                           108, 
                                           height)];

        if (anErrorMessage === UserCheckErrorMessage) 
        {
            [_tryAgainButton setHidden:NO];
            [_tryAgainButton setFrameOrigin:CGPointMake([_errorMessage frame].origin.x + [_errorMessage frame].size.width - [_tryAgainButton frame].size.width - 2.0,
                                                        [_errorMessage frame].origin.y + [_errorMessage frame].size.height - 2.0)];
        }
        else
            [_tryAgainButton setHidden:YES];
    }
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
- (void)_setPanelModeToLogin
{
    [self _setDefaultHiddenSettings];
    [_loginButton setTitle:LoginTitle];
    [_passwordConfirmLabel setHidden:YES];
    [_passwordConfirmField setHidden:YES];
    [_passwordConfirmField setStringValue:""];    
    [self _displayForgotPasswordLink];
    [self _layout];
}

/* @ignore */
- (void)_setPanelModeToRegister
{
    [self _setDefaultHiddenSettings];
    [_loginButton setTitle:RegisterTitle];
    [_passwordConfirmLabel setHidden:NO];
    [_passwordConfirmField setHidden:NO];
    [_forgotPasswordLink setHidden:YES];
    [self _layout];
}

/* @ignore */
- (void)_setPanelModeToLoginOrRegister
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
    Creates a new login panel and run it modally.  The login panel can be used to either
    log a user in or register a new user.  It expects the backend to respond to certain
    URLs correctly - see README.markdown.
    @param aDelegate - Should implement aCallback, which will get called with either 
           SCLoginSucceeded or SCLoginFailed when the dialog closes
    @param aCallback - Gets called on panel close
 */
- (void)loginWithDelegate:(id)aDelegate callback:(SEL)aCallback
{
    [CPApp runModalForWindow:[self window]];
    _username = nil;
    _delegate = aDelegate;
    _callback = aCallback;
    _panelReturnCode = SCLoginFailed;
    [self _setPanelModeToLoginOrRegister];
    [_passwordField setStringValue:""];
    [_passwordConfirmField setStringValue:""];
    [_window makeFirstResponder:_userField];
}

/*!
    Add a subheading to the login panel explaining why the login panel appeared.
 */
- (void)setSubheadingText:(CPString)aSubheading
{
    if (!aSubheading) 
        [_subheading setHidden:YES];
    else 
    {
        [_subheading setStringValue:aSubheading];
        [_subheading setHidden:NO];
        var fieldFrame = [_formFieldContainer frame],
            size = [aSubheading sizeWithFont:[_subheading font]
                                     inWidth:fieldFrame.size.width + 16.0];
        [_subheading setFrame:CGRectMake(0, 0, size.width, size.height + 18.0)];
    }
    [self _sizeAndPositionFormFieldContainer];
    [self _sizeWindowToFit];
}

/*!
    Creates a new login panel controller
 */
+ (SCLoginPanelController)newLoginPanelController
{
    return [[self alloc] initWithWindowCibName:@"SCLoginPanel"];
}

/*!
    Returns a default controller singleton
 */
+ (SCLoginPanelController)defaultController
{
    if (!DefaultLoginPanelController) 
        DefaultLoginPanelController = [self newLoginPanelController];
    return DefaultLoginPanelController;
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
    [self _checkUser];
}

/* @ignore */
- (void)_userCheckFailed
{
    [self _setPanelModeToLoginOrRegister];
    [self _setErrorMessageText:UserCheckErrorMessage];
}

- (void)connection:(CPURLConnection)aConnection didFailWithError:(CPException)anException
{
    if (connection === _loginConnection) 
        [self _loginFailedWithError:GenericErrorMessage];
    else if (connection === _registrationConnection) 
        [self _registerFailedWithError:GenericErrorMessage];
    else if (connection === _userCheckConnection) 
    {
        [self _userCheckFailed];
    }
}

- (void)connection:(CPURLConnection)aConnection didReceiveResponse:(CPURLResponse)aResponse
{
    [aConnection cancel];
    if (![aResponse isKindOfClass:[CPHTTPURLResponse class]]) 
    {
        switch (aConnection) 
        {
        case _userCheckConnection:
            [self _userCheckFailed];
            break;
            
        case _loginConnection:
        case _registrationConnection:
        default:
            [self _setErrorMessageText:GenericErrorMessage];
        }
        return;
    }
  
    var statusCode = [aResponse statusCode];
    switch(aConnection) 
    {
    case _userCheckConnection:
        if (statusCode === 200) 
            [self _setPanelModeToLogin];
        else if (statusCode == 404) 
            [self _setPanelModeToRegister];
        else 
        {
            [self _setPanelModeToLoginOrRegister];
            [self _setErrorMessageText:UserCheckErrorMessage];
        }
        break;

    case _loginConnection:
        if (statusCode === 200)  
        {
            _panelReturnCode = SCLoginSucceeded;
            _username = _loginConnection.username;
            [_window close];
        }
        else 
        {
            if (statusCode === 403) 
                [self _loginFailedWithError:@"Invalid username and/or password."];
            else
                [self _loginFailedWithError:GenericErrorMessage];
        }
        break;

    case _registrationConnection:
        if (statusCode === 200) 
        {
            _panelReturnCode = SCLoginSucceeded;
            _username = _registrationConnection.username;
            [_window close];
        }
        else 
        {
            if (statusCode === 409) 
                [self _registrationFailedWithError:@"That username is already registered!"];
            else
                [self _registrationFailedWithError:GenericErrorMessage];
        }
    }
}
@end
