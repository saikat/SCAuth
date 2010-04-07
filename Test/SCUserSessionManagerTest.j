@import "../SCUserSessionManager.j"

@implementation SCUserSessionManagerTest : OJTestCase
{ 
    SCUserSessionManager sessionManager;
}

- (void)setUp
{
    sessionManager = [SCUserSessionManager defaultManager];
}

- (void)testThatSyncSessionSendsCorrectInformationToBackend
{
    var connectionMock = moq()
}

- (void)testSyncingSessionWhenLoggedOut
{}
- (void)testSuccessfulLogout
{}
- (void)testLogout
{}
@end
