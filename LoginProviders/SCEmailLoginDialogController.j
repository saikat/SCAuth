/*
 * SCEmailLoginDialogController.j
 * SCAuth
 *
 * Created by Saikat Chakrabarti on April 7, 2010.
 *
 * See LICENSE file for license information.
 *
 */

@import <AppKit/CPWindowController.j>
@import "../AccountValidators/SCEmailAccountValidator.j"
@import "SCLoginDialogController.j"

var DefaultLoginDialogController = nil;
@implementation SCEmailLoginDialogController : SCLoginDialogController{ }

- (void)awakeFromCib
{
    [super awakeFromCib];
    _accountValidator = SCEmailAccountValidator;
    [_userLabel setStringValue:"E-mail:"];
    [_userLabel sizeToFit];
    [_userLabel setFrameOrigin:CGPointMake([_userField frame].origin.x - 4.0 - [_userLabel frame].size.width,
                                           [_userField frame].origin.y + 4.0)];
    [_userCheckSpinner setFrameOrigin:CGPointMake([_userLabel frame].origin.x - [_userCheckSpinner frame].size.width - 3.0,
                                                  [_userLabel frame].origin.y + 2.0)];
}

- (void)_setErrorMessageText:(CPString)anErrorMessage
{
    anErrorMessage = [anErrorMessage stringByReplacingOccurrencesOfString:@"username" withString:@"e-mail address"];
    anErrorMessage = [anErrorMessage stringByReplacingOccurrencesOfString:@"Username" withString:@"E-mail address"];
    [super _setErrorMessageText:anErrorMessage];
}

+ (SCLoginDialogController)defaultController
{
    if (!DefaultLoginDialogController)
        DefaultLoginDialogController = [self newLoginDialogController];
    return DefaultLoginDialogController;
}
@end
