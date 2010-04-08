@import <Foundation/CPObject.j>
@import <Foundation/CPURLConnection.j>
@import <Foundation/CPUserSessionManager.j>
@import "LoginProviders/SCLoginPanelController.j"

var SCDefaultSessionManager = nil;


@implementation SCUserSessionManager : CPUserSessionManager
{ 
    id _loginDelegate;
    id _loginProvider @accessors(property=loginProvider);
    CPURLConnection _loginConnection;
    CPURLConnection _logoutConnection;
    CPURLConnection _sessionSyncConnection;
}

- (id)init
{
    self = [super init];
    if (self) {
        _loginDelegate = nil;
        _userIdentifier = nil;
        [self setLoginProvider:[SCLoginPanelController defaultController]];
    }
    return self;
}

+ (SCUserSessionManager)defaultManager
{
    if (!SCDefaultSessionManager) 
        SCDefaultSessionManager = [[SCUserSessionManager alloc] init];
    return SCDefaultSessionManager;
}

- (void)syncSession:(id)delegate
{
    var request = [CPURLRequest requestWithURL:[[CPBundle mainBundle] objectForInfoDictionaryKey:@"SCAuthSyncURL"] || @"/session/"];
    [request setHTTPMethod:@"GET"];

    _sessionSyncConnection = [CPURLConnection connectionWithRequest:request
                                                           delegate:self];
    _sessionSyncConnection.delegate = delegate;
}

- (void)logout:(id)delegate
{
    var request = [CPURLRequest requestWithURL:[[CPBundle mainBundle] objectForInfoDictionaryKey:@"SCAuthLogoutURL"] || @"/session/"];
    [request setHTTPMethod:@"DELETE"];

    _logoutConnection = [CPURLConnection connectionWithRequest:request
                                                      delegate:self];
    _logoutConnection.delegate = delegate
}

- (void)login:(id)delegate
{
    // Login is already in progress
    if (_loginDelegate)
        return;

    [_loginProvider loginWithDelegate:self callback:@selector(_loginFinishedWithCode:)];
}

- (CPString)userDisplayName
{
    return [self userIdentifier];
}

- (void)_loginFinishedWithCode:(unsigned)returnCode
{
    var selectorToPerform = nil;
    if (returnCode === SCLoginSucceeded) 
    {
        [self _setCurrentUser:[_loginProvider username]];
        selectorToPerform = @selector(loginSucceeded:);
    }
    else
        selectorToPerform = @selector(loginFailed:);

    if (selectorToPerform && _loginDelegate && [_loginDelegate respondsToSelector:selectorToPerform])
        [_loginDelegate performSelector:selectorToPerform withObject:self];
    _loginDelegate = nil;
}

- (void)_setCurrentUser:(CPString)aUser
{
    if (!aUser) 
    {
        [self setStatus:CPUserSessionLoggedOutStatus];
        [self setUserIdentifier:nil];
    }
    else
    {
        [self setStatus:CPUserSessionLoggedInStatus];
        [self setUserIdentifier:aUser];
    }
}

- (void)connection:(CPURLConnection)aConnection didReceiveResponse:(CPURLResponse)aResponse
{
    var delegate = aConnection.delegate;
    if (![aResponse isKindOfClass:[CPHTTPURLResponse class]]) {
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

    if (aConnection === _sessionSyncConnection) 
    {
        if (statusCode === 200)
            return;
        if (statusCode === 404) {
            if (delegate && [delegate respondsToSelector:@selector(sessionSyncDidSucceed:)]) {
                [self _setCurrentUser:nil];
                [delegate sessionSyncDidSucceed:self];
            }
        }
    }
    else if (aConnection === _logoutConnection) {
        [aConnection cancel];
        if (statusCode === 200) {
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
    var responseBody = [data objectFromJSON];

    if (aConnection === _sessionSyncConnection) {
        var delegate = aConnection.delegate;
        [self _setCurrentUser:responseBody.username];
        if (delegate && [delegate respondsToSelector:@selector(sessionSyncDidSucceed:)])
            [delegate sessionSyncDidSucceed:self];
    }
}

- (void)connectionDidReceiveAuthenticationChallenge:(CPURLConnection)aConnection
{
    _loginConnection = aConnection;
    [self login:self];
}

- (void)loginFailed:(id)sender
{
    [[_loginConnection delegate] connection:_loginConnection didFailWithError: [_loginConnection _XMLHTTPRequest].responseText];
    _loginConnection = nil;
}

- (void)loginSucceeded:(id)sender
{
    [_loginConnection cancel];
    [_loginConnection start];
    _loginConnection = nil;
}
@end

[CPURLConnection setClassDelegate:[SCUserSessionManager defaultManager]];
