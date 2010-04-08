/*
 * SCEmailLoginPanelControllerTest.j
 * SCAuth
 *
 * Created by Saikat Chakrabarti on April 7, 2010.
 *
 * See LICENSE file for license information.
 * 
 */

@import "../LoginProviders/SCEmailLoginPanelController.j"
@import <AppKit/AppKit.j>

@implementation SCEmailLoginPanelControllerTest : OJTestCase
{ 
    SCEmailLoginPanelController testPanelController;
}
- (void)setUp
{
    [CPApplication sharedApplication];
    testPanelController = [SCEmailLoginPanelController newLoginPanelController];
}

- (void)tearDown
{
    CPApp = nil;
}

- (void)testThatPanelGetsCreated
{
    [self assertTrue:!!testPanelController];
}

- (void)testThatUserLabelIsChangedToEmail
{
    // Load the window
    [testPanelController window];
    [self assertTrue:([testPanelController._userLabel stringValue] === "Email:")];
}
@end
