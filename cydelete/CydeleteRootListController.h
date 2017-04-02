#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <Preferences/PSSwitchTableCell.h>
#import <MessageUI/MessageUI.h>
#include <UIKit/UIApplication.h>

@interface CydeleteRootListController : PSListController <MFMailComposeViewControllerDelegate>
{
}
- (id) specifiers;
- (id)localizedSpecifiersWithSpecifiers:(NSArray *)specifiers;
- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error;

@end

@interface CydeleteTranslationController : PSListController
{
}
- (id) specifiers;
- (NSMutableDictionary *)getTranslators;
- (id)countryForTranslator:(PSSpecifier *)specifier;

@end

@interface CydeleteUnHideController : PSListController
{
	NSMutableArray *bundleIDToRemove;
}
- (id) specifiers;

@end

@interface CydeleteTools : NSObject
{
}
+ (NSMutableDictionary *)getIconsFromBundleID:(NSArray *)bundleIDs;
+ (UIImage *)RoundUIImage:(UIImage *)icon;
@end
