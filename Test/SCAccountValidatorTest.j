/*
 * SCAccountValidatorTest.j
 * SCAuth
 *
 * Created by Saikat Chakrabarti on April 7, 2010.
 *
 * See LICENSE file for license information.
 *
 */

@import "../AccountValidators/SCAccountValidator.j"

@implementation SCAccountValidatorTest : OJTestCase
{ }

- (void)testThatUsernamesValidate
{
    var isValid = [SCAccountValidator validateUsername:"test_username"];
    [self assertTrue:isValid];
}

- (void)testThatBlankPasswordDoesNotValidate
{
    var errorMsg = [SCAccountValidator validatePassword:""
                                    withConfirmPassword:""];
    [self assertFalse:(errorMsg === nil)];
}

- (void)testThatShortPasswordDoesNotValidate
{
    var errorMsg = [SCAccountValidator validatePassword:"abc"
                                   withConfirmPassword:"abc"];
    [self assertFalse:(errorMsg === nil)];
}

- (void)testThatMismatchedPasswordsDoNotValidate
{
    var errorMsg = [SCAccountValidator validatePassword:"testpass"
                                   withConfirmPassword:"testpasS"];
    [self assertFalse:(errorMsg === nil)];
}

- (void)testThatValidPasswordValidates
{
    var errorMsg = [SCAccountValidator validatePassword:"test_password080ABC"
                                   withConfirmPassword:"test_password080ABC"];
    [self assertTrue:(errorMsg === nil)];
}
@end
