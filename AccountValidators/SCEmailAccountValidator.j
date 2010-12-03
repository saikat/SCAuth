/*
 * SCEmailAccountValidator.j
 * SCAuth
 *
 * Created by Saikat Chakrabarti on April 7, 2010.
 *
 * See LICENSE file for license information.
 *
 */

@import <Foundation/CPObject.j>
@import "SCAccountValidator.j"

@implementation SCEmailAccountValidator : SCAccountValidator
{
}

+ (BOOL)validateUsername:(CPString)username
{
    var reg = new RegExp("^[-a-zA-Z0-9+._]+@[-a-zA-Z0-9.]+\\.[a-zA-Z]{2,4}$");
    return reg.test(username);
}

@end
