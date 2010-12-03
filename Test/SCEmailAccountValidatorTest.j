/*
 * SCEmailAccountValidatorTest.j
 * SCAuth
 *
 * Created by Saikat Chakrabarti on April 7, 2010.
 *
 * See LICENSE file for license information.
 *
 */

@import "../AccountValidators/SCEmailAccountValidator.j"

@implementation SCEmailAccountValidatorTest : OJTestCase
{ }

- (void)testEmailWithNoAtSign
{
    [self assertFalse:[SCEmailAccountValidator validateUsername:"saikatgmail.com"]];
}

- (void)testEmailWithNoDomain
{
    [self assertFalse:[SCEmailAccountValidator validateUsername:"saikat@gmailcom"]];
}

- (void)testEmailWithPlus
{
    [self assertTrue:[SCEmailAccountValidator validateUsername:"saikat+1@gmail.com"]];
}

- (void)testEmailWithHyphen
{
    [self assertTrue:[SCEmailAccountValidator validateUsername:"test-email@gmail.com"]];
}

- (void)testComplexEmail
{
    [self assertTrue:[SCEmailAccountValidator validateUsername:"TeSt_E-mail3a389hus.hello@gmai998e-l.neT"]];
}

- (void)testBadDomain
{
    [self assertFalse:[SCEmailAccountValidator validateUsername:"TeSt_E-mail3a389hus.hello@gmai998e-_l.neTt"]];
}
@end
