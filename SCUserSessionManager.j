/*
 * SCUserSessionManager.j
 * SCAuth
 *
 * Created by Saikat Chakrabarti on April 7, 2010.
 *
 * See LICENSE file for license information.
 *
 */

@import <Foundation/CPObject.j>
@import <Foundation/CPURLConnection.j>
@import <Foundation/CPUserSessionManager.j>
@import "LoginProviders/SCLoginDialogController.j"

var SCDefaultSessionManager = nil;

/*!
    @class SCUserSessionManager

    This class manages a user's session data. It is also responsible for dealing with 401
    response codes from the backend and will automatically deal with these by using its
    login provider to attempt to log the user in.
*/

@implementation SCUserSessionManager : CPUserSessionManager
{
    id              _loginDelegate;
    id              _loginProvider          @accessors(property=loginProvider);
    CPURLConnection _loginConnection;
    CPURLConnection _logoutConnection;
    CPURLConnection _sessionSyncConnection;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        [self setLoginProvider:[SCLoginDialogController defaultController]];
    }
    return self;
}

/*!
    Returns a SCUserSessionManager singleton that can be used app-wide.
 */
+ (SCUserSessionManager)defaultManager
{
    if (!SCDefaultSessionManager)
        SCDefaultSessionManager = [[SCUserSessionManager alloc] init];
    return SCDefaultSessionManager;
}

/*!
    Synchronizes the session manager's data with the backend.  Expects the backend to either send
    a 404 HTTP Response (which indicates that there is no session currently) or a 200 HTTP response
    with a JSON object for the HTTP body that has the property username on it, specifying the
    username of the currently logged in user.
    @param delegate - Can implement - (void)sessionSyncDidFail:(CPUserSessionManager)sessionManager
           which is called when the session sync fails. Can also implement
           - (void)sessionSyncDidFail:(CPUserSessionManager)sessionManager which is called when the
           session sync succeeds.
 */
- (void)syncSession:(id)delegate
{
    var request = [CPURLRequest requestWithURL:[[CPBundle mainBundle] objectForInfoDictionaryKey:@"SCAuthSyncURL"] || @"/session/"];
    [request setHTTPMethod:@"GET"];

    _sessionSyncConnection = [CPURLConnection connectionWithRequest:request delegate:self];
    _sessionSyncConnection.delegate = delegate;
}

/*!
    Logs out the current user. Expects the backend to send a 200 HTTP Response to indicate that
    the log out succeeded.
    @param delegate - Can implement - (void)logoutDidFail:(CPUserSessionManager)sessionManager
           which is called when the logout fails. Can also implement
           - (void)logoutDidSucceed:(CPUserSessionManager)sessionManager which is called when the
           logout succeeds.
 */
- (void)logout:(id)delegate
{
    var request = [CPURLRequest requestWithURL:[[CPBundle mainBundle] objectForInfoDictionaryKey:@"SCAuthLogoutURL"] || @"/session/"];
    [request setHTTPMethod:@"DELETE"];

    _logoutConnection = [CPURLConnection connectionWithRequest:request delegate:self];
    _logoutConnection.delegate = delegate
}

/*!
    Attempts to perform a login using the _loginProvider.
    @param delegate - Can implement - (void)loginDidFail:(CPUserSessionManager)sessionManager
           which is called when the login fails. Can also implement
           - (void)loginDidSucceed:(CPUserSessionManager)sessionManager which is called when the
           login succeeds.
 */
- (void)login:(id)delegate
{
    // Login is already in progress
    if (_loginDelegate)
        return;

    _loginDelegate = delegate;
    [_loginProvider loginWithDelegate:self callback:@selector(_loginFinishedWithCode:)];
}

/*!
    Returns the current user identifier as a readable string.
 */
- (CPString)userDisplayName
{
    return [self userIdentifier];
}

/* @ignore */
- (void)_loginFinishedWithCode:(unsigned)returnCode
{
    var selectorToPerform;
    if (returnCode === SCLoginSucceeded)
    {
        [self _setCurrentUser:[_loginProvider username]];
        selectorToPerform = @selector(loginDidSucceed:);
    }
    else
        selectorToPerform = @selector(loginDidFail:);

    if (selectorToPerform && _loginDelegate && [_loginDelegate respondsToSelector:selectorToPerform])
        [_loginDelegate performSelector:selectorToPerform withObject:self];

    _loginDelegate = nil;
}

/* @ignore */
- (void)_setCurrentUser:(CPString)aUser
{
    if (aUser)
    {
        [self setStatus:CPUserSessionLoggedInStatus];
        [self setUserIdentifier:aUser];
    }
    else
    {
        [self setStatus:CPUserSessionLoggedOutStatus];
        [self setUserIdentifier:nil];
    }
}

- (void)connection:(CPURLConnection)aConnection didFailWithError:(CPException)anException
{
    var delegate = aConnection.delegate;
    if (aConnection === _sessionSyncConnection)
    {
        if (delegate && [delegate respondsToSelector:@selector(sessionSyncDidFail:)])
            [delegate sessionSyncDidFail:self];
    }
    else if (aConnection === _logoutConnection)
        if (delegate && [delegate respondsToSelector:@selector(logoutDidFail:)])
            [delegate logoutDidFail:self];
}

- (void)connection:(CPURLConnection)aConnection didReceiveResponse:(CPURLResponse)aResponse
{
    var delegate = aConnection.delegate;
    if (![aResponse isKindOfClass:[CPHTTPURLResponse class]])
    {
        [aConnection cancel];
        if (aConnection === _sessionSyncConnection)
        {
            if (delegate && [delegate respondsToSelector:@selector(sessionSyncDidFail:)])
                [delegate sessionSyncDidFail:self];
        }
        else if (aConnection === _logoutConnection)
            if (delegate && [delegate respondsToSelector:@selector(logoutDidFail:)])
                [delegate logoutDidFail:self];
        return;
    }

    var statusCode = [aResponse statusCode];

    if (aConnection !== _sessionSyncConnection || statusCode !== 200)
        [aConnection cancel];

    if (aConnection === _sessionSyncConnection)
    {
        if (statusCode === 200)
            return;
        if (statusCode === 404)
        {
            [self _setCurrentUser:nil];
            if (delegate && [delegate respondsToSelector:@selector(sessionSyncDidSucceed:)])
                [delegate sessionSyncDidSucceed:self];
        }
    }
    else if (aConnection === _logoutConnection)
    {
        [aConnection cancel];
        if (statusCode === 200)
        {
            [self _setCurrentUser:nil];
            if (delegate && [delegate respondsToSelector:@selector(logoutDidSucceed:)])
                [delegate logoutDidSucceed:self];
        }
        else
            if (delegate && [delegate respondsToSelector:@selector(logoutDidFail:)])
                [delegate logoutDidFail:self];
    }
}

- (void)connection:(CPURLConnection)aConnection didReceiveData:(CPString)data
{
    if (!data || aConnection != _sessionSyncConnection)
        return;

    var responseBody = [data objectFromJSON],
        delegate = aConnection.delegate;

    if (responseBody.username)
        [self _setCurrentUser:responseBody.username];
    if (delegate && [delegate respondsToSelector:@selector(sessionSyncDidSucceed:)])
        [delegate sessionSyncDidSucceed:self];
}

/* @ignore */
- (void)connectionDidReceiveAuthenticationChallenge:(CPURLConnection)aConnection
{
    _loginConnection = aConnection;
    [_loginConnection cancel];
    [self _setCurrentUser:nil];
    [self login:self];
    if ([[_loginConnection delegate] respondsToSelector:@selector(sessionManagerDidInterceptAuthenticationChallenge:forConnection:)])
        [[_loginConnection delegate] sessionManagerDidInterceptAuthenticationChallenge:self forConnection:aConnection];

}

/* @ignore */
- (void)loginDidFail:(id)sender
{
    if ([[_loginConnection delegate] respondsToSelector:@selector(connectionDidFailAuthentication:)])
        [[_loginConnection delegate] connectionDidFailAuthentication:_loginConnection];
    _loginConnection = nil;
}

/* @ignore */
- (void)loginDidSucceed:(id)sender
{
    [_loginConnection start];
    _loginConnection = nil;
}

@end

[CPURLConnection setClassDelegate:[SCUserSessionManager defaultManager]];
