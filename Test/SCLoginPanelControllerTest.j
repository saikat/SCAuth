@import "../LoginProviders/SCLoginPanelController.j"
@import <OJMoq/OJMoq.j>
@import <AppKit/AppKit.j>

// Uncomment the following line to turn on backtraces
// objj_msgSend_decorate(objj_backtrace_decorator);
// Run these tests with objj -I/Path/to/frameworks/ `which ojtest` Test/*.j

// TODO I need this definition, or [CPPanel orderOut:] fails.  This shouldn't, ideally, be the case.
function CPWindowObjectList()
{
    return [];
}
@implementation SCLoginPanelControllerTest : OJTestCase
{ 
    OJMoq platformWindowMock;
    SCLoginPanelControllerTest testController;
}

- (void)setUp
{
    [CPApplication sharedApplication];
    testController = [SCLoginPanelController newLoginPanelController];
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

- (void)testThatPanelGetsCreated
{
    [self assertTrue:!!testController];
}

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
    [self assertTrue:([[testController loginButton] title] === @"Login/Register")];
    [self assertTrue:[[testController passwordConfirmLabel] isHidden]];
    [self assertTrue:[[testController passwordConfirmField] isHidden]];
    [self assertTrue:[[testController passwordConfirmField] stringValue] === ""];
    [self checkInitialHiddenSettings];
}

- (void)checkThatDialogIsInLoginMode
{
    [self assertTrue:([[testController loginButton] title] === @"Login")];
    [self assertTrue:[[testController passwordConfirmLabel] isHidden]];
    [self assertTrue:[[testController passwordConfirmField] isHidden]];
    [self assertTrue:[[testController passwordConfirmField] stringValue] === ""];
    [self checkInitialHiddenSettings];
}

- (void)checkThatDialogIsInRegisterMode
{
    [self assertTrue:([[testController loginButton] title] === @"Register")];
    [self assertFalse:[[testController passwordConfirmLabel] isHidden]];
    [self assertFalse:[[testController passwordConfirmField] isHidden]];
    [self checkInitialHiddenSettings];
}

- (void)testInitialStateOfPanel
{
    var delegateMock = moq();
    [testController loginWithDelegate:delegateMock callback:@selector(didFinishSelector:)];
    [self assertTrue:([[testController passwordField] stringValue] === "")];
    [self assertTrue:([[testController passwordConfirmField] stringValue] === "")];
    [self assertTrue:([[testController window] firstResponder] === [testController userField])];
    [self assertTrue:[[testController forgotPasswordLink] isHidden]];
    [self checkThatDialogIsInLoginOrRegisterMode];
}

- (void)testInitialStateOfPanelWhenForgotPasswordInformationExists
{
    var delegateMock = moq();
    [testController loginWithDelegate:delegateMock callback:@selector(didFinishSelector:)];
    [self assertTrue:([[testController passwordField] stringValue] === "")];
    [self assertTrue:([[testController passwordConfirmField] stringValue] === "")];
    [self assertTrue:([[testController window] firstResponder] === [testController userField])];
    [self checkThatDialogIsInLoginOrRegisterMode];
}

- (void)testClosingPanel
{
    var delegateMock = moq();
    [delegateMock selector:@selector(didFinishSelector:) times:1 arguments:[SCLoginFailed]];
    [testController loginWithDelegate:delegateMock callback:@selector(didFinishSelector:)];
    [[testController window] performClose:self];
    [delegateMock verifyThatAllExpectationsHaveBeenMet];
}

/*
- (void)testClickingForgotPasswordLink
{
}

- (void)testClickingTryAgainButton
{}

- (void)testClickingCancel
{}

- (void)testClickingRegisterInRegisterMode
{}

- (void)testClickingLoginInLoginMode
{}

- (void)testClickingLoginInLoginOrRegisterMode
{}

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

- (void)testSettingPanelToLoginMode
{}

- (void)testSettingPanelToRegisterMode
{}

- (void)testSettingPanelToLoginOrRegisterMode
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

- (void)testThatEscapeClosesPanel
{}

- (void)testEnteringUsernameAndClickingCancelAndReopeningPanel
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
