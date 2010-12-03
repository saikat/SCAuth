/*
 * SCUserSessionManagerTest.j
 * SCAuth
 *
 * Created by Saikat Chakrabarti on April 7, 2010.
 *
 * See LICENSE file for license information.
 *
 */

@import "../SCUserSessionManager.j"

@implementation SCUserSessionManagerTest : OJTestCase
{
    SCUserSessionManager sessionManager;
}

- (void)setUp
{
    sessionManager = [SCUserSessionManager defaultManager];
}

/* TODO: Actually write these tests
- (void)testThatSyncSessionSendsCorrectInformationToBackend
{}
- (void)testSyncingSessionWhenLoggedOut
{}
- (void)testSuccessfulLogout
{}
- (void)testLogout
{}
*/
@end
