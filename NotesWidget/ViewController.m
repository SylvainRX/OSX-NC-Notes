//
//  ViewController.m
//  NotesWidget
//
//  Created by Sylvain on 22/01/2016.
//  Copyright © 2016 SylvainRoux. All rights reserved.
//

#import "ViewController.h"

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

- (IBAction)close:(id)sender {
    [NSApp terminate:self];
}
@end
