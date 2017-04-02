#include "CydeleteRootListController.h"

#define LocalizedString(key) [[self bundle] localizedStringForKey:key value:key table:nil]
#define PathToHiddenApps @"/private/var/mobile/Library/Preferences/com.tonyciroussel.CydeleteHiddensApps.plist"


@interface SRSwitchTableCell : PSSwitchTableCell
@end

@implementation SRSwitchTableCell

-(id)initWithStyle:(int)style reuseIdentifier:(id)identifier specifier:(id)specifier {
	self = [super initWithStyle:style reuseIdentifier:identifier specifier:specifier];
	if (self) {
		[((UISwitch *)[self control]) setOnTintColor:[UIColor orangeColor]];
	}
	return self;
}

@end

@implementation CydeleteTools

+ (NSMutableDictionary *)getIconsFromBundleID:(NSArray *)bundleIDs
{
	NSMutableDictionary *informations = [[NSMutableDictionary alloc] init];
	NSArray* applicationsPath = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/Applications" error:Nil];
	
	for(NSString *application in applicationsPath){
		NSString *pathToInfo = [NSString stringWithFormat:@"/Applications/%@/Info.plist", application];
		NSDictionary *infoPlist = [NSDictionary dictionaryWithContentsOfFile:pathToInfo];

		NSString *bundleIdentifier = [infoPlist objectForKey:@"CFBundleIdentifier"];
		for(NSString *bundleID in bundleIDs){
			if([bundleID isEqualToString:bundleIdentifier]){
				NSArray *bundleIcons = [[[infoPlist objectForKey:@"CFBundleIcons"] objectForKey:@"CFBundlePrimaryIcon"] objectForKey:@"CFBundleIconFiles"];
				if([bundleIcons count] == 0){
					bundleIcons = [infoPlist objectForKey:@"CFBundleIconFiles"];
				}
				UIImage *icon;
				for(NSString *iconName in bundleIcons){
					NSString *pathToImage = [NSString stringWithFormat:@"/Applications/%@/%@", application, iconName];
					if(![[pathToImage substringFromIndex:[pathToImage length] - 4] isEqualToString:@".png"]){
						pathToImage = [NSString stringWithFormat:@"%@.png", pathToImage];
					}
					icon = [UIImage imageWithContentsOfFile:pathToImage];
					int iconSize = icon.size.width * icon.scale;
					if(iconSize == 120)
						break;

				}
				if(icon != nil){
					UIImage *roundedIcon = [CydeleteTools RoundUIImage:icon];
					[informations setObject:roundedIcon forKey:bundleID];
				}
				break;
			}
		}
	}
	return informations;
}

+ (UIImage *)RoundUIImage:(UIImage *)icon
{
	CGRect frame = CGRectMake(0, (icon.size.height*0.2)/2, icon.size.width*0.8, icon.size.height*0.8);
	UIGraphicsBeginImageContextWithOptions(icon.size, NO, icon.scale);
   	[[UIBezierPath bezierPathWithRoundedRect:frame cornerRadius:12] addClip];
	[icon drawInRect:frame];
	UIImage *roundedIcon = UIGraphicsGetImageFromCurrentImageContext();
   	UIGraphicsEndImageContext();
	return roundedIcon;
}

@end

@implementation CydeleteUnHideController

- (id)specifiers {

	NSMutableArray *specifiers = [[NSMutableArray alloc] init];
	bundleIDToRemove = [[NSMutableArray alloc] init];

	if(_specifiers == nil){
		NSDictionary *hiddenApps = [[NSDictionary alloc] initWithContentsOfFile:PathToHiddenApps];
		if([hiddenApps count] > 0){

			NSArray *allBundleIDs = [hiddenApps allKeys];
			NSMutableDictionary *allIcons = [CydeleteTools getIconsFromBundleID:allBundleIDs];

			PSSpecifier *specifier = [PSSpecifier groupSpecifierWithName:LocalizedString(@"Hidden apps")];		
			[specifier setProperty:LocalizedString(@"Tap anywhere to unhide") forKey:@"footerText"];
			[specifier setIdentifier:@"applicationView"];
			[specifiers addObject:specifier];

			for(NSString *bundleID in allBundleIDs){
				NSString *iconLabel = [hiddenApps objectForKey:bundleID];
				PSSpecifier *specifier = [PSSpecifier preferenceSpecifierNamed:iconLabel target:self set:NULL get:NULL detail:Nil cell:PSButtonCell edit:Nil];
				[specifier setIdentifier:bundleID];
				specifier->action = @selector(buttonPressedForSpecifier:);
				[specifier setProperty:[allIcons objectForKey:bundleID] forKey:@"iconImage"];
				[specifiers addObject:specifier];
			} 
		} 
		else 
		{
				
			PSSpecifier *specifier = [PSSpecifier groupSpecifierWithName:nil];
			[specifier setProperty:LocalizedString(@"Hide your useless application directly from the SpringBoard ! Hidden applications will be displayed here.") forKey:@"footerText"];
			[specifier setProperty:@"1" forKey:@"footerAlignment"];
			[specifiers addObject:specifier];
		}
	}

	_specifiers = specifiers;
	return _specifiers;
}

- (void)buttonPressedForSpecifier:(PSSpecifier *)specifier
{
	NSString *identifier = specifier.identifier;

	NSMutableDictionary *hiddenApps = [[NSMutableDictionary alloc] initWithContentsOfFile:PathToHiddenApps];
	[hiddenApps removeObjectForKey:identifier];
	[hiddenApps writeToFile:PathToHiddenApps atomically:YES];

	[self removeSpecifier:specifier animated:YES];
}
	

@end

@implementation CydeleteRootListController

- (id)specifiers {

	if(_specifiers == nil){

		_specifiers = [self localizedSpecifiersWithSpecifiers:[self loadSpecifiersFromPlistName:@"Root" target:self]];
	}

	return _specifiers;
}


- (id)localizedSpecifiersWithSpecifiers:(NSArray *)specifiers {
	for(PSSpecifier *curSpec in specifiers) {
		NSString *name = [curSpec name];
		if(name) {
			[curSpec setName:[[self bundle] localizedStringForKey:name value:name table:nil]];
		}
		NSString *footerText = [curSpec propertyForKey:@"footerText"];
		if(footerText)
			[curSpec setProperty:[[self bundle] localizedStringForKey:footerText value:footerText table:nil] forKey:@"footerText"];
		id titleDict = [curSpec titleDictionary];
		if(titleDict) {
			NSMutableDictionary *newTitles = [[NSMutableDictionary alloc] init];
			for(NSString *key in titleDict) {
				NSString *value = [titleDict objectForKey:key];
				[newTitles setObject:[[self bundle] localizedStringForKey:value value:value table:nil] forKey: key];
			}
			[curSpec setTitleDictionary: newTitles];
		}
	}
	return specifiers;
}

- (void) applylButtonTapped
{
	NSString *command = @"killall backboardd";
	system([command UTF8String]);
}

- (void) viewSource
{
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://github.com/Akebu/Cydelete"]];
}

- (void) mail
{
	if ([MFMailComposeViewController canSendMail])
	{
		MFMailComposeViewController *mail = [[MFMailComposeViewController alloc] init];
		mail.mailComposeDelegate = self;
		[mail setSubject:@"Cydelete 9"];
		[mail setToRecipients:@[@"tony.ciroussel@riseup.net"]];

    		[self presentViewController:mail animated:YES completion:NULL];
	}
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
	if(result == MFMailComposeResultSent){
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Cydelete "
                                                 	message:LocalizedString(@"Thank you for your support <3 !\r“You have not lived today until you have done something for someone who can never repay you.”\r― John Bunyan" )
							delegate:self 
                                                    	cancelButtonTitle:@"Ok"
                                                    	otherButtonTitles:nil];
  		[alert show];
	}
	[self dismissViewControllerAnimated:YES completion:NULL];
}

@end

@implementation CydeleteTranslationController

- (id)specifiers {
	NSMutableArray *specifiers;
	if(_specifiers == nil){
		specifiers = [[NSMutableArray alloc] init];
		PSSpecifier *specifier = [PSSpecifier groupSpecifierWithName:nil];
		[specifier setProperty:LocalizedString(@"♥ A big THANKS to everyone ♥") forKey:@"footerText"];
		[specifier setProperty:@"1" forKey:@"footerAlignment"];
		[specifiers addObject:specifier];

		[specifiers addObject:[PSSpecifier groupSpecifierWithName:nil]];

		NSDictionary *translators = [self getTranslators];
		for(NSString *translator in translators){
			NSString *country = [translators objectForKey:translator];
			PSSpecifier *specifier = [PSSpecifier preferenceSpecifierNamed:country target:self set:NULL get:@selector(countryForTranslator:) detail:Nil cell:PSTitleValueCell edit:Nil];
			[specifier setIdentifier:translator];
			[specifiers addObject:specifier];
		}
	}

	_specifiers = specifiers;
	return _specifiers;
}

- (id)countryForTranslator:(PSSpecifier *)specifier
{
	return specifier.identifier;
}

- (NSDictionary *)getTranslators
{
	    return @{	@"Sarah Mathan": @"English",
			@"Tony Ciroussel ": @"Français",
			@"Mohammed Alteraiqi": @"العربية",
			@"Dani Winter": @"Nederlands",
			@"@ijapija00" : @"Svenska",
			@"Natalie Meiki Wong": @"繁體中文",
			@"m3ftwz" : @"Italiano",
			@"Manuel Antonio López" : @"Español"};
}

@end
