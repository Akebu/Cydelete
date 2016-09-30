@interface SBApplication : NSObject
-(BOOL)isSystemApplication;
-(NSString *)path;
-(NSString *)iconIdentifier;
-(NSString *)bundleIdentifier;
-(NSString *)displayName;
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
-(void)uninstallApplication:(SBApplication*)application;
-(void)uninstallCydiaPackage:(NSString *)packageName;
-(NSString *)fromWhereComeThisApplication:(SBApplication *)application;
@end


#define LocalizeString(key) [[NSBundle mainBundle] localizedStringForKey:key value:@"None" table:@"SpringBoard"]
static NSOperationQueue *uninstallQueue;

%hook SBApplication

-(BOOL)isUninstallAllowed	// Allow system application to be uninstalled
{
		return true;
}

%end

%hook SBApplicationController

%new(v@:)
-(NSString *)fromWhereComeThisApplication:(SBApplication *)application
{
	NSString *whereItComeFrom = @"Orphan";
	
	if([application isSystemApplication]){
		if([[application iconIdentifier] hasPrefix:@"com.apple"]){
			whereItComeFrom = @"Apple";
		}
		else
		{
			NSArray* dpkg = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/var/lib/dpkg/info/" error:NULL];
			
			if([whereItComeFrom isEqualToString:@"Orphan"]){
				for(NSString *allPackage in dpkg){
	
					if([[allPackage pathExtension] isEqualToString:@"list"]){
						
						NSString *completeWay = [NSString stringWithFormat:@"/var/lib/dpkg/info/%@", allPackage];
						NSString *fileContents = [NSString stringWithContentsOfFile:completeWay encoding:NSUTF8StringEncoding error:NULL];
						NSArray *linesOfFile = [fileContents componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
						
						for(NSString *line in linesOfFile){
							if([line isEqualToString:[application path]]){
								whereItComeFrom = [allPackage substringToIndex:[allPackage length] - 5];;
								break;
							}
						}
					}
				}
			}
		}
	}
	else
	{
		whereItComeFrom = @"AppStore";
	}
	return whereItComeFrom;
}

%new(v@:)
-(void)uninstallCydiaPackage:(NSString *)packageName
{
	NSString *command = [NSString stringWithFormat:@"sudo /usr/libexec/Cydelete/uninstall_dpkg.sh %@", packageName];
	system([command UTF8String]);
	// Add Installation Queue
}


-(void)uninstallApplication:(SBApplication*)application
{
	if(![application isSystemApplication])
	{
		// AppStore go here
		%orig;
	}
	else
	{
		// All other apps go here
		
		NSString *whereItComeFrom = [self fromWhereComeThisApplication:application];
		if([whereItComeFrom isEqualToString:@"Apple"]){
			// Apple application
		}
		else if([whereItComeFrom isEqualToString:@"Orphan"])
		{
			// Probably user application
		}
		else
		{
			// Cydia application
			[self uninstallCydiaPackage:whereItComeFrom];
			
		}
	}
}

%end

%hook SBApplicationIcon

-(NSString *)uninstallAlertTitle
{
	return [NSString stringWithFormat:LocalizeString(@"UNINSTALL_ICON_TITLE_DELETE_WITH_NAME"), [[self application] displayName]];
}

-(NSString *)uninstallAlertConfirmTitle
{
	return LocalizeString(@"UNINSTALL_ICON_BUTTON_DELETE");
}

-(NSString *)uninstallAlertCancelTitle
{
	return LocalizeString(@"UNINSTALL_ICON_BUTTON_CANCEL");
}

-(NSString *)uninstallAlertBody
{
	return LocalizeString(@"UNINSTALL_ICON_BODY_DELETE_DATA");
}

-(id)uninstallAlertBodyForAppWithDocumentsInCloud
{
	return LocalizeString(@"UNINSTALL_ICON_BODY_DELETE_DATA_LEAVES_DOCUMENTS_IN_CLOUD");
}
%end

%hook SBIconController

-(BOOL)isUninstallSupportedForIcon:(SBApplicationIcon*)SBAppIcon
{
	if([[SBAppIcon application] isSystemApplication]){
		return true;
	}
	else
	{
		return %orig;
	}
}

%end

%ctor {
	%init;
	uninstallQueue = [[NSOperationQueue alloc] init];
	[uninstallQueue setMaxConcurrentOperationCount:1];
}