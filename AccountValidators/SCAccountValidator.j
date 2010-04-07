@import <Foundation/CPObject.j>

@implementation SCAccountValidator : CPObject
+ (BOOL)validateUsername:(CPString)username
{
    return YES;
}

+ (CPString)validatePassword:(CPString)password
             withConfirmPassword:(CPString)confirmPassword
{
  var retVal = nil;
  if (!password || password === "") 
    retVal = "Password can't be blank.";
  else if ([password length] < 4) 
    retVal = "Password must be at least 4 characters long.";
  else if (password !== confirmPassword) 
    retVal = "Passwords don't match.";

  return retVal;
}
@end
