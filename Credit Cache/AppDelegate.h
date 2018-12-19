//
//  AppDelegate.h
//  Credit Cache
//
//  Created by Ari Cohen on 3/28/14.
//  Copyright (c) 2014 La Costa Kids. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Transaction.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>

//Assigned Vals
@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSView *tableView;
@property (assign) IBOutlet NSView *balanceSheet;
@property (assign) IBOutlet NSView *blankView;
@property (assign) IBOutlet NSArrayController *tabAC;
@property (assign) IBOutlet NSArrayController *historyAC;
@property (assign) IBOutlet NSTableView *tab;
@property (assign) IBOutlet NSArrayController *verifyAC;
@property (assign) IBOutlet NSArrayController *dayAC;
@property (assign) IBOutlet NSWindow *dayWindow;
@property (assign) IBOutlet NSView *dayView;

@property (assign) IBOutlet NSTableView *customerTab;
@property (assign) IBOutlet NSTextField *firstNameField;
@property (assign) IBOutlet NSTextField *lastNameField;
@property (assign) IBOutlet NSTextField *phoneNumField;
@property (assign) IBOutlet NSTextView *notesView;

@property (assign) IBOutlet NSTextField *valueField;
@property (assign) IBOutlet NSMatrix *updateRadio;
@property (assign) IBOutlet NSTextField *balanceText;

@property (assign) IBOutlet NSWindow *addCustWindow;
@property (assign) IBOutlet NSButton *customerOK;

@property (assign) IBOutlet NSButton *update_button;
@property (assign) IBOutlet NSWindow *verifyWindow;
@property (assign) IBOutlet NSDatePicker *dateSelect;
@property (assign) IBOutlet NSTextField *dayDate;

@property (assign) IBOutlet NSTextField *returnTotal;
@property (assign) IBOutlet NSTextField *resaleTotal;
@property (assign) IBOutlet NSTextField *cashTotal;
@property (assign) IBOutlet NSTextField *purchaseTotal;

@property (assign) IBOutlet NSView *monthView;
@property (assign) IBOutlet NSArrayController *monthAC;

@property (assign) IBOutlet NSWindow *exportWin;
@property (assign) IBOutlet NSTextField *exportStat;
@property (assign) IBOutlet NSProgressIndicator *exportProg;
@property (assign) IBOutlet NSButton *stopButton;


//Actions
- (IBAction)addCustomer:(id)sender;
- (IBAction)checkBalanceSheet:(id)sender;
- (IBAction)customerCancelPressed:(id)sender;
- (IBAction)customerOKPressed:(id)sender;
- (IBAction)deleteCustomer:(id)sender;
- (IBAction)goBack:(id)sender;
- (IBAction)radioButtonPressed:(id)sender;
- (IBAction)updateBalance:(id)sender;
- (IBAction)verifyOKPressed:(id)sender;
- (IBAction)verifyCancelPressed:(id)sender;

- (IBAction)dayCancel:(id)sender;
- (IBAction)dayGo:(id)sender;
- (IBAction)backDay:(id)sender;
- (IBAction)seeDay:(id)sender;
- (IBAction)totalBalance:(id)sender;
- (IBAction)save:(id)sender;

- (IBAction)viewMonths:(id) sender;

- (IBAction)exportClicked:(id)sender;
- (IBAction)stopClicked:(id)sender;

- (IBAction)test:(id)sender;

//Bound Vals
@property NSString *header;
@property NSString *legacyBal;
@property NSString *expiredBal;
@property NSString *modernBal;
@property NSString *balance;
@property NSString *nextExpire;
@property NSString *returns;
@property NSString *resales;
@property BOOL balanceEnabled;
@property NSNumber *upVal;

//Other
@property BOOL info_changed;
@property BOOL notes_changed;
@property NSMutableArray *legacyTrans;
@property double tot_expired;

//Functs
- (void) changeWindowsView:(NSWindow *)currentView to:(NSView *)otherView;
- (void)doEventFetch;


@end
