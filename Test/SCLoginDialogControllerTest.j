/*
 * SCLoginDialogControllerTest.j
 * SCAuth
 *
 * Created by Saikat Chakrabarti on April 7, 2010.
 *
 * See LICENSE file for license information.
 *
 */

@import "../LoginProviders/SCLoginDialogController.j"
@import <OJMoq/OJMoq.j>
@import <AppKit/AppKit.j>

// Uncomment the following line to turn on backtraces
objj_msgSend_decorate(objj_backtrace_decorator);

// Run these tests with objj -I/Path/to/frameworks/ `which ojtest` Test/*.j if you have custom test or Cappuccino frameworks

// TODO I need this definition, or [CPDialog orderOut:] fails.  This shouldn't, ideally, be the case.
function CPWindowObjectList()
{
    return [];
}
@implementation SCLoginDialogControllerTest : OJTestCase
{
    OJMoq platformWindowMock;
    SCLoginDialogControllerTest testController;
}

- (void)setUp
{
    [CPApplication sharedApplication];
    testController = [SCLoginDialogController newLoginDialogController];
    var windowBase = [testController window],
        platformWindowBase = [windowBase platformWindow];

    // TODO really I shouldn't need mocks here.  Cappuccino should allow these
    // methods to run safely in a testing context, but it seems like, for now,
    // Cappuccino is expecting a DOM for these methods.
    platformWindowMock = moq(platformWindowBase);
    [platformWindowMock selector:@selector(setContentRect:) returns:nil];
    [platformWindowMock selector:@selector(orderOut:) returns:nil];
    [platformWindowMock selector:@selector(orderFront:) returns:nil];
    [platformWindowMock selector:@selector(order:window:relativeTo:) returns:nil];
    [windowBase setPlatformWindow:platformWindowMock];
}

- (void)tearDown
{
    CPApp = nil;
}

// /* Helpers */
- (void)checkInitialHiddenSettings
{
    [self assertTrue:[[testController registeringProgressLabel] isHidden]];
    [self assertTrue:[[testController loggingInProgressLabel] isHidden]];
    [self assertTrue:[[testController progressSpinner] isHidden]];
    [self assertTrue:[[testController userCheckSpinner] isHidden]];
    [self assertTrue:[[testController tryAgainButton] isHidden]];
    [self assertTrue:[[testController subheading] isHidden]];
    [self assertTrue:[[testController errorMessage] isHidden]];
}

- (void)checkThatDialogIsInLoginOrRegisterMode
{
    [self assert:[[testController loginButton] title] equals:@"Login/Register"];
    [self assertTrue:[[testController passwordConfirmLabel] isHidden]];
    [self assertTrue:[[testController passwordConfirmField] isHidden]];
    [self assert:[[testController passwordConfirmField] stringValue] equals:""];
    [self checkInitialHiddenSettings];
}

- (void)checkThatDialogIsInLoginMode
{
    [self assert:[[testController loginButton] title] equals:@"Login"];
    [self assertTrue:[[testController passwordConfirmLabel] isHidden]];
    [self assertTrue:[[testController passwordConfirmField] isHidden]];
    [self assert:[[testController passwordConfirmField] stringValue] equals:""];
    [self checkInitialHiddenSettings];
}

- (void)checkThatDialogIsInRegisterMode
{
    [self assert:[[testController loginButton] title] equals:@"Register"];
    [self assertFalse:[[testController passwordConfirmLabel] isHidden]];
    [self assertFalse:[[testController passwordConfirmField] isHidden]];
    [self checkInitialHiddenSettings];
}

- (void)checkThatURLIsHit:(CPString)URL withMethod:(CPString)HTTPMethod withBody:(CPString)aBody whenControlIsClicked:(CPControl)aControl
{
    var mockConnectionClass = moq(),
        madeRequest = nil;

    [mockConnectionClass selector:@selector(connectionWithRequest:delegate:) callback:(function(args) {madeRequest = args[0];})];
    [mockConnectionClass selector:@selector(connectionWithRequest:delegate:) returns:{}];
    [mockConnectionClass selector:@selector(connectionWithRequest:delegate:) times:1];

    [testController setConnectionClass:mockConnectionClass];
    [aControl performClick:self];
    [mockConnectionClass verifyThatAllExpectationsHaveBeenMet];
    [self assert:[[madeRequest URL] relativeString] equals:URL];
    [self assert:[madeRequest HTTPMethod] equals:HTTPMethod];
    [self assert:[madeRequest HTTPBody] equals:aBody];
}

- (void)startDialogWithStub
{
    var delegateMock = moq();
    [testController loginWithDelegate:delegateMock callback:@selector(didFinishSelector:)];
}

/* Tests */

- (void)testThatDialogGetsCreated
{
    [self assertTrue:!!testController];
}

- (void)testInitialStateOfDialog
{
    [self startDialogWithStub];
    [self assert:[[testController passwordField] stringValue] equals:""];
    [self assert:[[testController passwordConfirmField] stringValue] equals:""];
    [self assert:[[testController window] firstResponder] equals:[testController userField]];
    [self assertTrue:[[testController forgotPasswordLink] isHidden]];
    [self checkThatDialogIsInLoginOrRegisterMode];
}

- (void)testInitialStateOfDialogWhenForgotPasswordInformationExists
{
    var mainBundle = [CPBundle mainBundle];
    mainBundle._bundle.valueForInfoDictionaryKey = function(aKey)
    {
        if(aKey === "SCAuthForgotPasswordURL")
            return "forgot_password_url";
        return nil;
    }
    [self startDialogWithStub];
    [self assert:[[testController passwordField] stringValue] equals:""];
    [self assert:[[testController passwordConfirmField] stringValue] equals:""];
    [self assert:[[testController window] firstResponder] equals:[testController userField]];
    [self checkThatDialogIsInLoginOrRegisterMode];
    [self assertFalse:[[testController forgotPasswordLink] isHidden]];
}

- (void)testClosingDialog
{
    var delegateMock = moq();
    [delegateMock selector:@selector(didFinishSelector:) times:1 arguments:[SCLoginFailed]];
    [testController loginWithDelegate:delegateMock callback:@selector(didFinishSelector:)];
    [[testController window] performClose:self];
    [delegateMock verifyThatAllExpectationsHaveBeenMet];
}


// This test doesn't actually do anything.  Just checking for exceptions.
- (void)testClickingForgotPasswordLink
{
    [self startDialogWithStub];
    var mainBundle = [CPBundle mainBundle];
    mainBundle._bundle.valueForInfoDictionaryKey = function(aKey)
    {
        if(aKey === "SCForgotPasswordURL")
            return "forgot_password_url";
        return nil;
    }

    [testController forgotPasswordLinkClicked:self];
}

- (void)testThatClickingTryAgainButtonAsksBackendForTheUser
{
    [self startDialogWithStub];
    [[testController userField] setStringValue:@"test@test.com"];
    [testController _userCheckFailedWithStatusCode:-1];
    [self assert:[[testController errorMessage] stringValue] notEqual:""];
    [self assertFalse:[[testController tryAgainButton] isHidden]];

    [self checkThatURLIsHit:@"/user/test@test.com" withMethod:@"GET" withBody:@"" whenControlIsClicked:[testController tryAgainButton]];

    [self assertFalse:[[testController userCheckSpinner] isHidden]];
}

- (void)testClickingCancel
{
    var delegateMock = moq();
    [delegateMock selector:@selector(didFinishSelector:) times:1 arguments:[SCLoginFailed]];
    [testController loginWithDelegate:delegateMock callback:@selector(didFinishSelector:)];
    [[testController cancelButton] performClick:self];
    [delegateMock verifyThatAllExpectationsHaveBeenMet];
}

- (void)testThatClickingRegisterInRegisterModeAsksBackendToRegister
{
    [self startDialogWithStub];
    [testController _setDialogModeToRegister];
    [[testController userField] setStringValue:@"test@test.com"];
    [[testController passwordField] setStringValue:@"test"];
    [[testController passwordConfirmField] setStringValue:@"test"];
    [[testController rememberMeButton] performClick:self];

    var body = [CPString JSONFromObject:{'username' : 'test@test.com', 'password' : 'test', 'remember' : NO}];
    [self checkThatURLIsHit:@"/user/" withMethod:@"POST" withBody:body whenControlIsClicked:[testController loginButton]];
}

- (void)testThatClickingLogininLoginModeAsksBackendToLogin
{
    [self startDialogWithStub];
    [testController _setDialogModeToLogin];
    [[testController userField] setStringValue:@"test@test.com"];
    [[testController passwordField] setStringValue:@"test"];
    [[testController passwordConfirmField] setStringValue:@""];
    [[testController rememberMeButton] performClick:self];

    var body = [CPString JSONFromObject:{'username' : 'test@test.com', 'password' : 'test', 'remember' : NO}];
    [self checkThatURLIsHit:@"/session/" withMethod:@"POST" withBody:body whenControlIsClicked:[testController loginButton]];
}

- (void)testClickingLoginInLoginOrRegisterModeAsksBackendToLogin
{
    [self startDialogWithStub];
    [testController _setDialogModeToLoginOrRegister];
    [[testController userField] setStringValue:@"test@test.com"];
    [[testController passwordField] setStringValue:@"test"];
    [[testController passwordConfirmField] setStringValue:@""];
    [[testController rememberMeButton] performClick:self];

    var body = [CPString JSONFromObject:{'username' : 'test@test.com', 'password' : 'test', 'remember' : NO}];
    [self checkThatURLIsHit:@"/session/" withMethod:@"POST" withBody:body whenControlIsClicked:[testController loginButton]];
}

- (void)testClickingLoginWithRememberMeOn
{
    [self startDialogWithStub];
    [testController _setDialogModeToLogin];
    [[testController userField] setStringValue:@"test@test.com"];
    [[testController passwordField] setStringValue:@"test"];
    [[testController passwordConfirmField] setStringValue:@""];

    [self assert:[[testController rememberMeButton] state] equals:CPOnState];
    var body = [CPString JSONFromObject:{'username' : 'test@test.com', 'password' : 'test', 'remember' : YES}];
    [self checkThatURLIsHit:@"/session/" withMethod:@"POST" withBody:body whenControlIsClicked:[testController loginButton]];
}

- (void)testClickingRegisterWithRememberMeOn
{
    [self startDialogWithStub];
    [testController _setDialogModeToRegister];
    [[testController userField] setStringValue:@"test@test.com"];
    [[testController passwordField] setStringValue:@"test"];
    [[testController passwordConfirmField] setStringValue:@"test"];

    [self assert:[[testController rememberMeButton] state] equals:CPOnState];
    var body = [CPString JSONFromObject:{'username' : 'test@test.com', 'password' : 'test', 'remember' : YES}];
    [self checkThatURLIsHit:@"/user/" withMethod:@"POST" withBody:body whenControlIsClicked:[testController loginButton]];
}

- (void)testClickingRegisterWithMismatchedPasswords
{
    [self startDialogWithStub];
    [testController _setDialogModeToRegister];
    [[testController userField] setStringValue:@"test@test.com"];
    [[testController passwordField] setStringValue:@"test"];
    [[testController passwordConfirmField] setStringValue:@"test1"];

    var mockConnectionClass = moq();
    [mockConnectionClass selector:@selector(connectionWithRequest:delegate:) times:0];
    [testController setConnectionClass:mockConnectionClass];
    [[testController loginButton] performClick:self];
    [mockConnectionClass verifyThatAllExpectationsHaveBeenMet];
    [self assertFalse:[[testController errorMessage] isHidden]];
    [self assert:[[testController errorMessage] stringValue] notEqual:@""];
}

/*
- (void)testHittingEnterInConfirmPasswordField
{}

- (void)testHittingEnterInPasswordField
{}

- (void)testAftermathOfLoginSucceeding
{}

- (void)testAftermathOfLoginFailing
{}

- (void)testAftermathOfRegistrationSucceeding
{}

- (void)testAftermathOfRegistrationFailing
{}

- (void)testThatLoginUserSendsCorrectInformationToBackend
{}

- (void)testThatRegisterUserSendsCorrectInformationToBackend
{}

- (void)testSettingDialogToLoginMode
{}

- (void)testSettingDialogToRegisterMode
{}

- (void)testSettingDialogToLoginOrRegisterMode
{}

- (void)testThatCheckUserSendsCorrectInformationToBackend
{}

- (void)testSettingSubheadingText
{}

- (void)testSettingErrorMessage
{}

- (void)testSettingErrorMessageToHaveTryAgainButton
{}

- (void)testThatForgotPasswordLinkDisplaysWhenBundleInfoIsThere
{}

- (void)testThatDefaultControllerIsCached
{}

- (void)testThatSwitchingFromUsernameToPasswordFieldChecksUsername
{}

- (void)testThatEscapeClosesDialog
{}

- (void)testEnteringUsernameAndClickingCancelAndReopeningDialog
{}

- (void)testFailedConnectionWhenAttemptingToLogin
{}

- (void)testFailedConnectionWhenAttemptingToRegister
{}

- (void)testFailedConnectionWhenCheckingUsername
{}

- (void)testSuccessfulLogin
{}

- (void)testInvalidUsernameOrPasswordOnLogin
{}

- (void)testSuccessfulRegistration
{}

- (void)testConflictOnRegistration
{}

- (void)testFoundUsernameOnUsernameCheck
{}

- (void)testNotFoundUsernameOnUsernameCheck
{}
*/
@end
