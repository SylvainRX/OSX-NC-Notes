//
//  TodayViewController.m
//  Notes
//
//  Created by Sylvain on 22/01/2016.
//  Copyright © 2016 SylvainRoux. All rights reserved.
//

#import "TodayViewController.h"
#import <NotificationCenter/NotificationCenter.h>

@interface TodayViewController () <NCWidgetProviding, NSTabViewDelegate, NSTextViewDelegate> {
    NSTabViewItem *adderTab;
}

@end

@implementation TodayViewController

- (id)init {
    if ( self = [super init] ) {
        self.preferredContentSize = CGSizeMake(0, 148);
    }
    return self;
}

- (void)fixDefaultsIfNeeded {
    //http://stackoverflow.com/questions/22242106/mac-sandbox-created-but-no-nsuserdefaults-plist
    NSArray *domains = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,NSUserDomainMask,YES);
    //File should be in library
    NSString *libraryPath = [domains firstObject];
    if (libraryPath) {
        NSString *preferensesPath = [libraryPath stringByAppendingPathComponent:@"Preferences"];
        
        //Defaults file name similar to bundle identifier
        NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
        
        //Add correct extension
        NSString *defaultsName = [bundleIdentifier stringByAppendingString:@".plist"];
        
        NSString *defaultsPath = [preferensesPath stringByAppendingPathComponent:defaultsName];
        
        NSFileManager *manager = [NSFileManager defaultManager];
        
        if (![manager fileExistsAtPath:defaultsPath]) {
            //Create to fix issues
            [manager createFileAtPath:defaultsPath contents:nil attributes:nil];
            
            //And restart defaults at the end
            [NSUserDefaults resetStandardUserDefaults];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }
}

- (void)viewDidAppear {
    [self fixDefaultsIfNeeded];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.noteView.tabViewItems.lastObject.view];
    adderTab = self.noteView.tabViewItems.lastObject;
    [self.noteView removeTabViewItem:self.noteView.tabViewItems.firstObject];
    [self.noteView removeTabViewItem:adderTab];
    NSUserDefaults *shared = [NSUserDefaults standardUserDefaults];
    NSInteger count = 0;
    NSString *content;
    do {
        content = [shared objectForKey:[NSString stringWithFormat:@"note%ld", count]];
        if(content && ![content isEqualToString:@" "]) {
            if(content.length > 20)
                NSLog(@"note %ld : \"%@...\"", count, [content substringToIndex:20]);
            else
                NSLog(@"note %ld : \"%@...\"", count, content);
            
            NSView *newView = (NSView *) [NSKeyedUnarchiver unarchiveObjectWithData:data];
            NSTabViewItem *newTab = [[NSTabViewItem alloc] init];
            NSTextView *textView = newView.subviews.firstObject.subviews.firstObject.subviews.lastObject;
            textView.delegate = self;
            newTab.view = newView;
            textView.string = content;
            [self.noteView addTabViewItem:newTab];
            
            NSInteger location = [textView.string rangeOfString:@"\n"].location;
            NSInteger length = [textView.string rangeOfString:@"\n"].length;
            if(length)
                if(location < 10)
                    newTab.label = [textView.string substringToIndex:location];
                else
                    newTab.label = [textView.string substringToIndex:10];
                else
                    if(textView.string.length < 10)
                        newTab.label = textView.string;
                    else
                        newTab.label = [textView.string substringToIndex:10];
        }
        count++;
    } while(content);
    [self.noteView removeTabViewItem:self.noteView.tabViewItems.firstObject];
    
    if(self.noteView.tabViewItems.count < 4) {
        [self.noteView addTabViewItem:adderTab];
    }
    
    content = [shared objectForKey:@"selectedTabItem"];
    if(content) {
        [self.noteView selectTabViewItemAtIndex:[content integerValue]];
        NSLog(@"selectedTabItem : %@", content);
    }
}

- (void)viewDidDisappear {
    [self fixDefaultsIfNeeded];
    NSUserDefaults *shared = [NSUserDefaults standardUserDefaults];
    [shared setPersistentDomain:[NSDictionary dictionary] forName:[[NSBundle mainBundle] bundleIdentifier]];
    NSInteger count = 0;
    for(NSTabViewItem *tabViewItem in self.noteView.tabViewItems) {
        if(self.noteView.selectedTabViewItem == tabViewItem) {
            [shared setObject:[NSString stringWithFormat:@"%ld", count] forKey:@"selectedTabItem"];
            NSLog(@"saved selectedTabItem : %ld", count);
        }
        NSTextView *textView = tabViewItem.view.subviews.firstObject.subviews.firstObject.subviews.lastObject; //quick and dirty...
        [shared setObject:textView.string forKey:[NSString stringWithFormat:@"note%ld", count]];
        [shared synchronize];
        if(textView.string.length > 20)
            NSLog(@"saved %@ : \"%@...\"", [NSString stringWithFormat:@"note%ld", count], [textView.string substringToIndex:20]);
        else
            NSLog(@"saved %@ : \"%@\"", [NSString stringWithFormat:@"note%ld", count], textView.string);
        count++;
    }
    
//    NSLog( @"%@", [[NSUserDefaults standardUserDefaults] dictionaryRepresentation] );
    [shared synchronize];
}

- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult result))completionHandler {
    // Update your data and prepare for a snapshot. Call completion handler when you are done
    // with NoData if nothing has changed or NewData if there is new data since the last
    // time we called you
    completionHandler(NCUpdateResultNoData);
}


- (void)tabViewDidChangeNumberOfTabViewItems:(NSTabView *)tabView {
}

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem {
    if([tabViewItem.label compare:@"+"] == NSOrderedSame) {
        if(tabView.tabViewItems.count > 4) {
            [tabView selectTabViewItem:tabView.tabViewItems.firstObject];
            return;
        }
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:tabViewItem.view];
        NSView *newView = (NSView *) [NSKeyedUnarchiver unarchiveObjectWithData:data];
        NSTabViewItem *newTab = [[NSTabViewItem alloc] init];
        newTab.view = newView;
        NSTextView *newTextView = (NSTextView *) newView.subviews.firstObject.subviews.firstObject.subviews.firstObject;
        newTextView.delegate = self;
        [tabView removeTabViewItem:tabViewItem];
        [tabView addTabViewItem:newTab];
        [tabView addTabViewItem:tabViewItem];
        [tabView selectTabViewItem:newTab];
        
        if(tabView.tabViewItems.count > 4) {
            adderTab = tabViewItem;
            [tabView removeTabViewItem:tabViewItem];
        }
    }
}

- (void)textDidChange:(NSNotification *)notification {
    NSTextView *textView = (NSTextView *) notification.object;
    NSTabView *tabView = (NSTabView *) textView.superview.superview.superview.superview;
    if([textView.string hasPrefix:@" "])
        textView.string = [textView.string substringFromIndex:1];
    NSInteger location = [textView.string rangeOfString:@"\n"].location;
    NSInteger length = [textView.string rangeOfString:@"\n"].length;
    if(length)
        if(location < 15)
            tabView.selectedTabViewItem.label = [textView.string substringToIndex:location];
        else
            tabView.selectedTabViewItem.label = [textView.string substringToIndex:15];
    else
        if(textView.string.length < 15)
            tabView.selectedTabViewItem.label = textView.string;
        else
            tabView.selectedTabViewItem.label = [textView.string substringToIndex:15];
}

- (IBAction)removeTabViewItem:(id)sender {
    [self.noteView removeTabViewItem:self.noteView.selectedTabViewItem];
    if(![self.noteView.tabViewItems.lastObject.label isEqualToString:@"+"] && self.noteView.tabViewItems.count < 4)
        [self.noteView addTabViewItem:adderTab];
}

@end

