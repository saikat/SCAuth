/*
 * SCEmailLoginDialogControllerTest.j
 * SCAuth
 *
 * Created by Saikat Chakrabarti on April 7, 2010.
 *
 * See LICENSE file for license information.
 *
 */

@import "../LoginProviders/SCEmailLoginDialogController.j"
@import <AppKit/AppKit.j>

@implementation SCEmailLoginDialogControllerTest : OJTestCase
{
    SCEmailLoginDialogController testDialogController;
}
- (void)setUp
{
    [CPApplication sharedApplication];
    testDialogController = [SCEmailLoginDialogController newLoginDialogController];
}

- (void)tearDown
{
    CPApp = nil;
}

- (void)testThatDialogGetsCreated
{
    [self assertTrue:!!testDialogController];
}

- (void)testThatUserLabelIsChangedToEmail
{
    // Load the window
    [testDialogController window];
    [self assertTrue:([testDialogController._userLabel stringValue] === "E-mail:")];
}
@end
