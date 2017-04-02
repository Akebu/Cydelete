@interface SBApplication : NSObject
-(BOOL)isSystemApplication;
-(NSString *)path;
-(NSString *)iconIdentifier;
-(NSString *)bundleIdentifier;
-(NSString *)displayName;
-(int)pid;
@end

@interface SBApplicationIcon : NSObject
-(SBApplication *)application;
@end

@interface SBIconView : NSObject
-(SBApplicationIcon *)icon;
@end

@interface SBIconController : NSObject
-(BOOL)allowsUninstall;
@end

@interface SBApplicationController : NSObject
-(void)hideSystemApplication:(NSString *)applicationPath forDisplayName:(NSString *)displayName;
-(void)uninstallCydiaPackage:(NSString *)packageName;
-(NSString *)ownerOfApplication:(SBApplication *)application;
-(void)applicationUninstalled;
@end

#define LocalizeString(key, fromTable) [[NSBundle mainBundle] localizedStringForKey:key value:nil table:fromTable]
#define PathToHiddenApps @"/private/var/mobile/Library/Preferences/com.tonyciroussel.CydeleteHiddensApps.plist"

static NSOperationQueue *uninstallQueue;

static BOOL isEnabled = true;
static BOOL AllowApple = true;
static BOOL ProtectCydia = true;
static BOOL ProtectPangu = true;

%hook SBApplicationInfo

-(NSArray *)tags
{
	NSMutableArray *tags = [NSMutableArray arrayWithArray:%orig];

	if ([[NSFileManager defaultManager] fileExistsAtPath:PathToHiddenApps]){

		NSDictionary *hiddenApps = [[NSDictionary alloc] initWithContentsOfFile:PathToHiddenApps];
		if([hiddenApps objectForKey:[self bundleIdentifier]] != nil){
			[tags addObject:@"hidden"];
		}
		[hiddenApps release];
	}

	return [NSArray arrayWithArray:tags];
}

%end

%hook SBApplication

-(BOOL)isUninstallAllowed
{
		// Allow system applications to be uninstalled.
		return isEnabled;
}

%end

%hook SBApplicationController

%new
-(NSString *)ownerOfApplication:(SBApplication *)application
{

	NSString *owner = @"Nobody";
	
	if([application isSystemApplication]){
		if([[application iconIdentifier] hasPrefix:@"com.apple"]){
			return @"Apple";
		}
		else
		{
			NSArray* dpkg = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/var/lib/dpkg/info/" error:NULL];
			NSString* bundleWithList = [NSString stringWithFormat:@"%@.list", [application bundleIdentifier]];

			if([[dpkg valueForKeyPath:@"uppercaseString"] indexOfObjectIdenticalTo:[bundleWithList uppercaseString]] != NSNotFound){
				return [application bundleIdentifier];
			}

			/* Find it manually */
			for(NSString *allPackage in dpkg){
				if([[allPackage pathExtension] isEqualToString:@"list"]){	
					NSString *completePath = [NSString stringWithFormat:@"/var/lib/dpkg/info/%@", allPackage];
					NSString *fileContents = [NSString stringWithContentsOfFile:completePath encoding:NSUTF8StringEncoding error:NULL];
					if([fileContents containsString:[application path]]){
						return [allPackage substringToIndex:[allPackage length] - 5];
					}
				}
			}
		}
	}
	else
	{
		return @"AppStore";
	}
	return owner;
}

%new
-(void)uninstallCydiaPackage:(NSString *)packageName
{
   	NSString *command = [NSString stringWithFormat:@"sudo /usr/libexec/Cydelete/./uninstall_dpkg.sh %@", packageName];
	system([command UTF8String]);
}

%new
-(void)hideSystemApplication:(NSString *)bundleIdentifier forDisplayName:(NSString *)displayName
{
	NSMutableDictionary *hiddenApps;

	if ([[NSFileManager defaultManager] fileExistsAtPath:PathToHiddenApps])
		hiddenApps = [[NSMutableDictionary alloc] initWithContentsOfFile:PathToHiddenApps];
	else
		hiddenApps = [[NSMutableDictionary alloc] init];

	[hiddenApps setValue:displayName forKey:bundleIdentifier];
	[hiddenApps writeToFile:PathToHiddenApps atomically:YES];
	[hiddenApps release];
	
}

%new
-(void)applicationUninstalled
{
	if ([[NSFileManager defaultManager] fileExistsAtPath:@"/tmp/CydeleteError.log"]){
		NSString *alertTitle = LocalizeString(@"Oops", @"Cydelete");
		NSString *alertMessage = LocalizeString(@"The application could not be uninstalled because Cydia seems to be busy at the moment. You can now restart the SpringBoard to make the icon reappear", @"Cydelete");
		NSString *alertCache = LocalizeString(@"Restart", @"Cydelete");
		NSString *alertLater = LocalizeString(@"Later", @"Cydelete");

		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:alertTitle 
                                                 	message:alertMessage 
							delegate:self 
                                                    	cancelButtonTitle:alertCache 
                                                    	otherButtonTitles:alertLater, nil];
  		[alert show];
		[alert release];
			
	}
}

%new
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {

    if (buttonIndex == 0)
    {
	NSString *command = @"killall backboardd";
	system([command UTF8String]);
    }
}

-(void)uninstallApplication:(SBApplication*)application
{
	if(![application isSystemApplication]){
		%orig;
	}
	else
	{

		[uninstallQueue addOperationWithBlock:^{

			NSString *owner = [self ownerOfApplication:application];
			int pid = [application pid];

			if(pid > 0){
				// Kill the application before uninstall it.
				NSString *command = [NSString stringWithFormat:@"kill -9 %i", pid];
				system([command UTF8String]);
			}

			if([owner isEqualToString:@"Apple"] || [owner isEqualToString:@"Nobody"]){

				[self hideSystemApplication:[application bundleIdentifier] forDisplayName:[application displayName]];
	
			}
			else
			{
				[self uninstallCydiaPackage:owner];

				[[NSOperationQueue mainQueue] addOperationWithBlock:^{
					[self applicationUninstalled];				
    				}];
				
			}
		}];	

	}
}

%end

%hook SBApplicationIcon

-(NSString *)uninstallAlertTitle
{
	if([[[self application] iconIdentifier] hasPrefix:@"com.apple"]){
		NSString *alertTitle = [NSString stringWithFormat:LocalizeString(@"Hide \"%@\" ?",@"Cydelete"), [[self application] displayName]];
		return alertTitle;
	}else{
		return [NSString stringWithFormat:LocalizeString(@"UNINSTALL_ICON_TITLE_DELETE_WITH_NAME", @"SpringBoard"), [[self application] displayName]];
	}
}

-(NSString *)uninstallAlertConfirmTitle
{
	if([[[self application] iconIdentifier] hasPrefix:@"com.apple"]){
		return LocalizeString(@"Hide", @"Cydelete");
	}else{
		return LocalizeString(@"UNINSTALL_ICON_BUTTON_DELETE", @"SpringBoard");
	}
}	

-(NSString *)uninstallAlertCancelTitle
{
	return LocalizeString(@"UNINSTALL_ICON_BUTTON_CANCEL", @"SpringBoard");
}

-(NSString *)uninstallAlertBody
{
	if([[[self application] iconIdentifier] hasPrefix:@"com.apple"]){
		return LocalizeString(@"Hidding this application will also hide it from Spotlight", @"Cydelete");
	}else{
		return LocalizeString(@"UNINSTALL_ICON_BODY_DELETE_DATA", @"SpringBoard");
	}
}

-(id)uninstallAlertBodyForAppWithDocumentsInCloud
{
	if([[[self application] iconIdentifier] hasPrefix:@"com.apple"]){
		return LocalizeString(@"Hidding this application will also hide it from Spotlight", @"Cydelete");
	}else{
		return LocalizeString(@"UNINSTALL_ICON_BODY_DELETE_DATA_LEAVES_DOCUMENTS_IN_CLOUD", @"SpringBoard");
	}
}
%end

%hook SBIconController

-(BOOL)isUninstallSupportedForIcon:(SBApplicationIcon*)SBAppIcon
{
	if([[SBAppIcon application] isSystemApplication] && (isEnabled)){
		if( [[[SBAppIcon application] iconIdentifier] isEqualToString:@"com.apple.Preferences"] ){
			return %orig;
		}		
		if(ProtectCydia && [[[SBAppIcon application] iconIdentifier] isEqualToString:@"com.saurik.Cydia"]){
			return %orig;
		}
		else if(!AllowApple && [[[SBAppIcon application] iconIdentifier] hasPrefix:@"com.apple"]){
				return %orig;
		}else{
			return true;
		}
	}
	else if( (ProtectPangu) && [[[SBAppIcon application] iconIdentifier] isEqualToString:@"com.wanmei.mini.condorpp-532-8"]){
		return false;
	}
	else
	{
		return %orig;
	}
}

%end

static void loadPrefs() {

	CFPreferencesAppSynchronize(CFSTR("com.tonyciroussel.cydelete"));

	if (CFBridgingRelease(CFPreferencesCopyAppValue(CFSTR("isEnabled"), CFSTR("com.tonyciroussel.cydelete")))) {
		isEnabled = [(id)CFBridgingRelease(CFPreferencesCopyAppValue(CFSTR("isEnabled"), CFSTR("com.tonyciroussel.cydelete"))) boolValue];
	}

	if (CFBridgingRelease(CFPreferencesCopyAppValue(CFSTR("ProtectCydia"), CFSTR("com.tonyciroussel.cydelete")))) {
		ProtectCydia = [(id)CFBridgingRelease(CFPreferencesCopyAppValue(CFSTR("ProtectCydia"), CFSTR("com.tonyciroussel.cydelete"))) boolValue];
	}

	if (CFBridgingRelease(CFPreferencesCopyAppValue(CFSTR("ProtectPangu"), CFSTR("com.tonyciroussel.cydelete")))) {
		ProtectPangu = [(id)CFBridgingRelease(CFPreferencesCopyAppValue(CFSTR("ProtectPangu"), CFSTR("com.tonyciroussel.cydelete"))) boolValue];
	}

	if (CFBridgingRelease(CFPreferencesCopyAppValue(CFSTR("isAppleModificationEnabled"), CFSTR("com.tonyciroussel.cydelete")))) {
		AllowApple = [(id)CFBridgingRelease(CFPreferencesCopyAppValue(CFSTR("isAppleModificationEnabled"), CFSTR("com.tonyciroussel.cydelete"))) boolValue];
	}
}

%ctor {
	%init;
	uninstallQueue = [[NSOperationQueue alloc] init];
	[uninstallQueue setMaxConcurrentOperationCount:1];

	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)loadPrefs, CFSTR("com.tonyciroussel.cydelete/reloadSettings"), NULL, CFNotificationSuspensionBehaviorCoalesce);
	loadPrefs();
}
