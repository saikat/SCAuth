@import "../LoginProviders/SCEmailLoginPanelController.j"
@import <AppKit/AppKit.j>

// TODO This kind of sucks to run all these tests in one shared application.  

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
