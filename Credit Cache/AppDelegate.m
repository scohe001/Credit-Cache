//
//  AppDelegate.m
//  Credit Cache
//
//  Created by Ari Cohen on 3/28/14.
//  Copyright (c) 2014 La Costa Kids. All rights reserved.
//

#import "AppDelegate.h"
#import "test.h"
#import "PriorityQueue.h"
#import "Transaction.h"

@interface delegateAppDelegate : NSObject <NSApplicationDelegate, NSTextViewDelegate> {
    NSWindow *window;
}
@end

@implementation AppDelegate

//- (NSComparisonResult)compare:(Car *)car1 with:(Car *)car2 {
//    return [car1.model compare:car2.model];
//}

- (void)test:(id)sender {
    NSLog(@"Trying to open or close!");
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [_window setContentView:_tableView];
    [self doEventFetch];
    
    [_window makeKeyAndOrderFront:self];
    
    [_tab setDoubleAction:@selector(checkBalanceSheet:)];
    [_tab selectColumnIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:FALSE];
    self.balanceEnabled = TRUE;
    self.legacyTrans = [[NSMutableArray alloc] init];
    [_dateSelect setMaxDate:[NSDate date]];
    [_dateSelect setDateValue:[NSDate date]];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    //Save and then copy over
    [self save:sender];
    NSString *srcPath = [[NSBundle mainBundle]pathForResource:@"Credits" ofType:@"json"];
    NSString *dstPath = [NSHomeDirectory() stringByAppendingString:@"/Dropbox/Credits.json"];
    NSError *error;
    if([[NSFileManager defaultManager] fileExistsAtPath:dstPath])
        [[NSFileManager defaultManager] removeItemAtPath:dstPath error:&error];
    [[NSFileManager defaultManager] copyItemAtPath:srcPath toPath:dstPath error:&error];
    if(error) NSLog(@"%@", error);
    return NSTerminateNow;
}

bool ran_once = false;
//- (void)windowDidBecomeMain:(NSNotification *)notification {
- (void)applicationDidBecomeActive:(NSApplication *)application {
    if(!ran_once) {
        //Do the update table after the window becomes visible instead of in
        //applicationDidFinishLaunching for the drop down with the progress bar
        if(!ran_once) { [self updateTable]; }
        ran_once = !ran_once;
    }
}

//NSTableView's
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
    self.balanceEnabled = ([[_tabAC selectedObjects] count] != 0);
}

//NSTextField's
- (void)controlTextDidChange:(NSNotification *)notification
{
    [_customerOK setEnabled:!([[_firstNameField stringValue] isEqualToString:@""] ||
                              [[_lastNameField stringValue] isEqualToString:@""]) ];
}

//NSTextView's
-(void)textDidChange:(NSNotification *)notification
{
    _notes_changed = TRUE;
}

- (void)save:(id)sender
{
    NSString *path = [[NSBundle mainBundle]pathForResource:@"Credits" ofType:@"json"];
    NSError *error;
    NSData *jsonData2 = [NSJSONSerialization dataWithJSONObject:[_tabAC content] options:NSJSONWritingPrettyPrinted error:&error];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData2 encoding:NSUTF8StringEncoding];
    [jsonString writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&error];
}

- (void)updateTable
{
    NSString *path = [[NSBundle mainBundle]pathForResource:@"Credits" ofType:@"json"];
    NSData *returnedData = [NSData dataWithContentsOfFile:path];
    
    NSError *error = nil;
    id object = [NSJSONSerialization JSONObjectWithData:returnedData options:NSJSONReadingMutableContainers error:&error];
    if(error) { NSLog(@"ERROR"); }
    
    NSLog(@"%lu", (unsigned long)[object count]); //How many customers do we have?
    [_tabAC setContent:object];
    //AS OF UPDATE 2.2 BUILD 1, BALANCES ARE NO LONGER STATIC
    //THIS MEANS THEY NEED TO BE RECALCULATED FOR EVERY RUN OF THE PROGRAM /cries/
    
    [self doEventFetch];
    [_stopButton setTitle:@"Stop"];
    [_stopButton setKeyEquivalent:@""];
    [_stopButton setEnabled:false];
    [_exportStat setStringValue:@"Setting up Excel..."];
    [_exportProg setIndeterminate:false];
    [_exportProg setMaxValue:[object count]];
    [_exportProg startAnimation:self];
    [_window beginSheet:_exportWin completionHandler:nil];
    
    double a, b, c, ret, res;
    int x=0; //First row is for specifying what's to come
    _tot_expired = 0; //going to update, so 0 out first
    for(NSMutableDictionary *cust in [_tabAC content]) {
        [_exportStat setStringValue:[NSString stringWithFormat:@"Updating balances for customer %i/%lu",
                                     x++, [[_tabAC content] count]]];
        [_exportProg setDoubleValue:x];
        [self doEventFetch];
        
        calcBalances(cust[@"Actions"], &a, &b, &c, &ret, &res);
        [cust setValue:[NSNumber numberWithDouble:(a+b)] forKey:@"balance"];
        [cust setValue:[NSString stringWithString:[self moneyString:(a+b)]] forKey:@"theBalance"];
        _tot_expired += c; //for Robin
    }
    [_window endSheet:_exportWin returnCode:0];
}

double LT, NT, E, RET, RES;
- (IBAction)checkBalanceSheet:(id)sender
{
    if([[_tabAC selectedObjects] count] == 0) return;
    
    NSMutableDictionary *selected_object = [_tabAC selectedObjects][0];
    
    self.header = selected_object[@"firstName"];
    self.header = [ _header stringByAppendingString:[@" " stringByAppendingString:selected_object[@"lastName"]] ];
    self.header = [ _header stringByAppendingString:[@" (" stringByAppendingString:
                ([selected_object[@"phoneNumber"] isEqualToString:@""]) ? @"N/A" : selected_object[@"phoneNumber"]]];
    self.header = [ _header stringByAppendingString:@")" ];
    
    for (unsigned long x=[[_historyAC arrangedObjects] count]; x>0; x--)
        [_historyAC removeObjectAtArrangedObjectIndex:0];
    
    [_legacyTrans removeAllObjects];
    
    int y = 0;
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MM/dd/yy"];
    for(NSMutableDictionary *transaction in selected_object[@"Actions"]) {
        //Convert to NSDate
        NSString *dateString = transaction[@"date"];
        NSDate *transDate = [[NSDate alloc] init];
        transDate = [dateFormatter dateFromString:dateString];
        if([Trans isLegacyDate:transDate]) [_legacyTrans addObject:[NSNumber numberWithInt:y]];
        y++;

        [_historyAC addObject:transaction];
    }
    [_historyAC setSelectionIndexes:[NSIndexSet indexSet]];
    
    NSDate *nexpire = calcBalances(selected_object[@"Actions"], &LT, &NT, &E, &RET, &RES);
    self.nextExpire = nexpire ? [dateFormatter stringFromDate:nexpire] : @"N/A";
    self.legacyBal = [self moneyString:LT];
    self.expiredBal = [self moneyString:E];
    self.modernBal = [self moneyString:NT];
    
    self.balance = [ self moneyString:(LT + NT) ];
    //self.returns = [ self moneyString:[selected_object[@"returns"] doubleValue] ];
    //self.resales = [ self moneyString:[selected_object[@"resales"] doubleValue] ];
    self.returns = [ self moneyString:RET ];
    self.resales = [ self moneyString:RES ];
    [_balanceText setToolTip:[NSString stringWithFormat:@"%@ (Return) + %@ (Resale) = %@\n %@ (Legacy) + %@ (Modern) \n %@ Expired",
                              self.returns, self.resales, self.balance, self.legacyBal, self.modernBal, self.expiredBal]];
    
    [_updateRadio selectCellAtRow:0 column:0];
    [_valueField setStringValue:@"0"];
    [_valueField setEnabled:TRUE];
    
    NSString *notes = selected_object[@"notes"];
    if([notes isEqualToString:@""]) notes = @"Notes...";
    [_notesView setString:notes];
    _notes_changed = FALSE;
    
    
    [self changeWindowsView:_window to:_balanceSheet];
    _info_changed = [sender isKindOfClass:[NSButton class]] && [ [sender title] isEqualToString:@"Create!" ];
    
    [_valueField setStringValue:@""];
    [_valueField becomeFirstResponder];
}

- (IBAction)addCustomer:(id)sender
{
    [_firstNameField setStringValue:@""];
    [_lastNameField setStringValue:@""];
    [_phoneNumField setStringValue:@""];
    [_customerOK setEnabled:FALSE];
    [_window beginSheet:_addCustWindow completionHandler:nil];
}

- (IBAction)customerCancelPressed:(id)sender
{
    [_window endSheet:_addCustWindow returnCode:1];
}

- (IBAction)customerOKPressed:(id)sender
{
    NSString *phone = ([[_phoneNumField stringValue] isEqualToString:@""]) ? @"" : [_phoneNumField stringValue];
    NSMutableDictionary *new_cust = [@{
                               @"firstName": [_firstNameField stringValue],
                               @"lastName": [_lastNameField stringValue],
                               @"phoneNumber": phone,
                               @"balance": @0,
                               @"notes": @"",
                               @"Actions": [NSMutableArray array]
                               } mutableCopy];
    [_tabAC addObject:new_cust];
    [_window endSheet:_addCustWindow returnCode:0];
    [_tab scrollRowToVisible: [_tab selectedRow]];
    [self performSelector:@selector(checkBalanceSheet:) withObject:sender afterDelay:0];
}

- (IBAction)deleteCustomer:(id)sender
{
    NSAlert *alrt = [[NSAlert alloc] init];
    [alrt setAlertStyle:NSWarningAlertStyle];
    [alrt addButtonWithTitle:@"Delete!"];
    [alrt addButtonWithTitle:@"Cancel"];
    [alrt setMessageText:@"Are you sure you want to delete?"];
    [alrt setInformativeText:@"This action cannot be undone"];
    if([alrt runModal] == 1000)
        [_tabAC removeObjectAtArrangedObjectIndex:[_tab selectedRow]];
}

- (IBAction)goBack:(id)sender
{
    if (_info_changed || _notes_changed) {
        if(_notes_changed)
            [[_tabAC selectedObjects][0] setObject:[ NSString stringWithString:[[_notesView textStorage] string] ] forKey:@"notes"];
        [self performSelector:@selector(save:) withObject:sender afterDelay:0];
    }
    
    [self changeWindowsView:_window to:_tableView];
}

- (IBAction)radioButtonPressed:(id)sender
{
    [_valueField setStringValue:@""];
    [_update_button setEnabled:true];
    NSMutableDictionary *selected_object = [_tabAC selectedObjects][0];
    if([[[sender selectedCell] title] isEqualToString:@"Cash Out"]) {
        double val = RES;
        [_valueField setStringValue: [NSString stringWithFormat:@"%f", (val * .8) + .005 ]];
        
        if(RET != 0) {
            NSAlert *alrt = [[NSAlert alloc] init];
            [alrt setAlertStyle:NSInformationalAlertStyle];
            [alrt addButtonWithTitle:@"Ok"];
            [alrt setMessageText:@"Cash Out will not wipe this customer's credit"];
            [alrt setInformativeText:[NSString stringWithFormat:@"The customer's credit is split between Returns and Resales as follows:\n\n%@ (Resale) + %@ (Return) = %@\n\nThe Cash Out will only draw 80%% from the Resales, leaving the Returns intact.", [self moneyString:RES], [self moneyString:RET], selected_object[@"theBalance"]]];
            [alrt beginSheetModalForWindow:_window completionHandler:NULL];
        }
        if(val == 0) [_update_button setEnabled:false];
    }
    [_valueField setEnabled:!([[[sender selectedCell] title] isEqualToString:@"Cash Out"])];
    [_valueField becomeFirstResponder];
}

- (IBAction)updateBalance:(id)sender
{
    NSString *transaction_type = [[_updateRadio selectedCell] title];
    
    NSString *val_string = [_valueField stringValue];
    val_string = [ val_string substringWithRange:NSMakeRange(2, val_string.length - 2)];
    double val = [self moneyRound:[val_string doubleValue] ] / 100.0;
    double bal = [ self moneyRound:LT + NT ] / 100.0;
    NSLog(@"Balance: %f", bal);
    
    if([_updateRadio selectedRow] == 0) { //Return or Resale
        bal += val;
    } else if([_updateRadio selectedColumn] == 0) { //Purchase
        bal -= val;
        if (bal < 0) {
            NSAlert *alrt = [[NSAlert alloc] init];
            [alrt setAlertStyle:NSCriticalAlertStyle];
            [alrt addButtonWithTitle:@"Ok"];
            [alrt setMessageText:@"Customer does not have the required funds!"];
            [alrt setInformativeText:@"Please check that you've entered the correct value."];
            [alrt beginSheetModalForWindow:_window completionHandler:NULL];
            return;
        }
    } else if([_updateRadio selectedColumn] == 1) { //Cashout
        bal = RET;
    }
    
    bal = [self moneyRound:bal] / 100.0;
    NSDateFormatter *DateFormatter=[[NSDateFormatter alloc] init];
    [DateFormatter setDateFormat:@"MM/dd/yy"];
    NSMutableDictionary *dict = [@{
                                   @"transaction" : transaction_type,
                                   @"value" : [self moneyString:val],
                                   @"theValue" : [NSNumber numberWithFloat:val],
                                   @"newBal" : [NSNumber numberWithFloat:bal],
                                   @"newBalance" : [self moneyString:bal],
                                   @"date" : [DateFormatter stringFromDate:[NSDate date]]
                                   } mutableCopy];
    [_verifyAC addObject:dict];
    [_window beginSheet:_verifyWindow completionHandler:nil];
}

- (IBAction)verifyOKPressed:(id)sender
{
    [_verifyAC setSelectionIndex:0];
    NSMutableDictionary *selected_object = [_tabAC selectedObjects][0];
    NSMutableDictionary *transaction = [_verifyAC selectedObjects][0];
    [_historyAC addObject: transaction];
    [selected_object[@"Actions"] addObject:transaction ];
    
    [selected_object setObject:[transaction objectForKey:@"newBal"] forKey:@"balance"];
    [selected_object setObject:[transaction objectForKey:@"newBalance"] forKey:@"theBalance"];
    
//    double resales = [selected_object[@"resales"] doubleValue],
//            returns = [selected_object[@"returns"] doubleValue];
//    
//    if([transaction[@"transaction"]  isEqualToString: @"Resale"]) {
//        resales += [transaction[@"theValue"] doubleValue];
//    } else if([transaction[@"transaction"] isEqualToString:@"Return"]) {
//        returns += [transaction[@"theValue"] doubleValue];
//    } else if([transaction[@"transaction"] isEqualToString:@"Cash Out"]) {
//        resales = 0;
//        [_update_button setEnabled:false];
//    } else if([transaction[@"transaction"] isEqualToString:@"Purchase"]) {
//        double val = [transaction[@"theValue"] doubleValue];
//        returns -= val;
//        if(returns < 0) {
//            resales += returns, returns = 0;
//        }
//    }

    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MM/dd/yy"];
    NSDate *nexpire = calcBalances(selected_object[@"Actions"], &LT, &NT, &E, &RET, &RES);
    self.nextExpire = nexpire ? [dateFormatter stringFromDate:nexpire] : @"N/A";
    self.legacyBal = [self moneyString:LT];
    self.expiredBal = [self moneyString:E];
    self.modernBal = [self moneyString:NT];
    
    self.balance = [ self moneyString:(LT + NT) ];
    self.returns = [self moneyString:RET];
    self.resales = [self moneyString:RES];
    selected_object[@"returns"] = [NSNumber numberWithDouble:RET];
    selected_object[@"resales"] = [NSNumber numberWithDouble:RES];
    [_balanceText setToolTip:[NSString stringWithFormat:@"%@ (Return) + %@ (Resale) = %@\n %@ (Legacy) + %@ (Modern) \n %@ Expired",
                              self.returns, self.resales, self.balance, self.legacyBal, self.modernBal, self.expiredBal]];
    
    _info_changed = TRUE;
    [self verifyCancelPressed:sender]; //End sheet
    [_valueField setStringValue:@""];
}

- (IBAction)verifyCancelPressed:(id)sender
{
    [_verifyAC removeObjectAtArrangedObjectIndex:0];
    [_window endSheet:_verifyWindow returnCode:1];
}

- (NSString*)moneyString:(double)val
{
    if (val == 0) return @"$0.00";
    if (val + .01 < 0) val -= .01;
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setMaximumFractionDigits:2];
    [formatter setMinimumFractionDigits:2];
    [formatter setRoundingMode: NSNumberFormatterRoundDown];
    if (val < 1 && val >= 0)
        return [ @"$0" stringByAppendingString:[formatter stringFromNumber:[NSNumber numberWithFloat:(val + .005)]] ];
    return [ @"$" stringByAppendingString:[formatter stringFromNumber:[NSNumber numberWithFloat:(val + .005)]] ];
}

- (NSString*)toMoney:(id)val
{
    return [self moneyString:[val doubleValue]];
}

- (IBAction)totalBalance:(id)sender
{
    double total = 0;
    for(NSDictionary *dict in [_tabAC content])
    {
        total += [[dict objectForKey:@"balance"] doubleValue];
    }
    
    
    NSAlert *alrt = [[NSAlert alloc] init];
    [alrt setAlertStyle:NSInformationalAlertStyle];
    [alrt addButtonWithTitle:@"Ok"];
    NSString *msg = [NSString stringWithFormat:@"The grand total of all balances comes out to be: %@\nTotal expired credit is: %@", [self moneyString:total], [self moneyString:_tot_expired]];
    [alrt setMessageText:msg];
    if (total > 10000)
        [alrt setInformativeText:@"Wow, such monies"];
    [alrt beginSheetModalForWindow:_window completionHandler:NULL];
}

bool excelSelected;
- (IBAction)seeDay:(id)sender
{
    excelSelected = false;
    [_window beginSheet:_dayWindow completionHandler:nil];
}

- (IBAction)exportClicked:(id)sender
{
    excelSelected = true;
    [_window beginSheet:_dayWindow completionHandler:nil];
}

bool STOP;
- (IBAction)stopClicked:(id)sender
{
    STOP = true;
    [_window endSheet:_exportWin returnCode:0];
}

- (void) export:(id) sender
{
    [_stopButton setTitle:@"Stop"];
    [_stopButton setKeyEquivalent:@""];
    [_stopButton setEnabled:false];
    [self goBack:sender];
    [_exportStat setStringValue:@"Setting up Excel..."];
    [_exportProg setIndeterminate:true];
    [_exportProg startAnimation:sender];
    [_window beginSheet:_exportWin completionHandler:nil];
    
    setupExcel();
    
    //Create mutable copy, call it `customers`
    NSMutableArray *customers = [[NSMutableArray alloc] init];
    NSDate *cutoff = [_dateSelect dateValue];
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"MM/dd/yy"];
    //NSDate *myDate = [df dateFromString: myDateAsAStringValue];
    for(NSMutableDictionary *orig_customer in [_tabAC content]) {
        NSMutableDictionary *customer = (NSMutableDictionary *)CFBridgingRelease(CFPropertyListCreateDeepCopy(kCFAllocatorDefault, (CFDictionaryRef)orig_customer, kCFPropertyListMutableContainers));
        NSMutableArray *actions = [[NSMutableArray alloc] init];
        for (NSMutableDictionary *action in customer[@"Actions"]) {
            NSDate *trans_date = [df dateFromString:action[@"date"]];
            if([[trans_date earlierDate:cutoff] isEqualToDate:trans_date]) {
                [actions addObject:action];
            }
        }
        customer[@"Actions"] = actions;
        [customers addObject:customer];
    }
    
    [_stopButton setEnabled:true];
    int x=2; //First row is for specifying what's to come
    STOP = false;
    for(NSMutableDictionary *customer in customers) {
        [_exportProg setIndeterminate:false]; //Put in loop to make sure it's not
        [_exportProg setMaxValue:[customers count]]; //Run while setting up animation
        [_exportProg incrementBy:1];
        [_exportStat setStringValue:[NSString stringWithFormat:@"Exporting Customer %i/%lu...", x-2, (unsigned long)[customers count]]];
        if(STOP || ![self inputCustomer:customer :x++]) {
            if(!STOP) [_exportStat setStringValue:@"Export Halted due to error"];
            [_stopButton setStringValue:@"OK"];
            return;
        }
        [self doEventFetch];
    }
    
    [_exportStat setStringValue:@"Finishing up..."];
    [_exportProg setIndeterminate:true];
    [_exportProg startAnimation:sender];
    finishExcel([customers count]);
    
    if(!STOP) [_exportStat setStringValue:@"Export finished successfully"];
    [_stopButton setTitle:@"OK"];
    [_stopButton setKeyEquivalent:@"\r"];
    [self doEventFetch];
}

- (bool) inputCustomer:(NSDictionary*) customer :(int) num
{
    NSMutableString *script = [NSMutableString stringWithFormat:@"tell application \"Microsoft Excel\"\ntell active sheet of active workbook\n"];
    [script appendFormat:@"set the value of cell \"A%i\" to \"%@\"\n", num, customer[@"lastName"]];
    [script appendFormat:@"set the value of cell \"B%i\" to \"%@\"\n", num, customer[@"firstName"]];
    [script appendFormat:@"set the value of cell \"C%i\" to \"%@\"\n", num, customer[@"phoneNumber"]];
    if([customer[@"Actions"] count] == 0) {
        [script appendFormat:@"set the value of cell \"D%i\" to \"N/A\"\n", num];
        [script appendFormat:@"set the value of cell \"E%i\" to \"N/A\"\n", num];
    } else {
        [script appendFormat:@"set the value of cell \"D%i\" to \"%@\"\n", num, customer[@"Actions"][0][@"date"]];
        [script appendFormat:@"set the value of cell \"E%i\" to \"%@\"\n", num, customer[@"Actions"][[customer[@"Actions"] count]-1][@"date"]];
    }
    
    double legacy_balance = calcLegacy(customer[@"Actions"]);
    double curr_bal;
    if([customer[@"Actions"] count] == 0)
        curr_bal = 0;
    else
        curr_bal = [customer[@"Actions"][[customer[@"Actions"] count]-1][@"newBal"] doubleValue];
    [script appendFormat:@"set the value of cell \"F%i\" to \"%@\"\n", num, [self moneyString:legacy_balance]];
    [script appendFormat:@"set the value of cell \"G%i\" to \"%@\"\n", num,
        [self moneyString:[self moneyRound:(curr_bal - legacy_balance)]/100.0]];
    [script appendFormat:@"set the value of cell \"H%i\" to \"%@\"\n", num, [self moneyString:curr_bal]];
    [script appendFormat:@"set the value of cell \"I%i\" to \"%@\"\n", num, [customer[@"notes"] stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""]];
    //[NSString stringWithFormat:@"%lu", (unsigned long)5];
    
    
    [script appendString:@"end tell\nend tell"];
    
    NSDictionary* errorDict;
    NSAppleEventDescriptor* returnDescriptor = NULL;
    NSAppleScript* scriptObject = [[NSAppleScript alloc] initWithSource:script];
    returnDescriptor = [scriptObject executeAndReturnError: &errorDict];
    if(returnDescriptor == nil) {
        NSLog(@"Error writing to Excel:\n%@", errorDict);
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"Error writing to Excel."];
        [alert setInformativeText:@"Export was cancelled."];
        [alert runModal];
        return false;
    }
    return true;
}

void setupExcel()
{
    NSDictionary* errorDict;
    NSAppleEventDescriptor* returnDescriptor = NULL;
    
    NSAppleScript* scriptObject = [[NSAppleScript alloc] initWithSource:
                                   @"\
                                   tell application \"Microsoft Excel\"\n\
                                   make new workbook\n\
                                   tell active sheet of active workbook\n\
                                   set the value of cell \"A1\" to \"Last\"\n\
                                   set the value of cell \"B1\" to \"First\"\n\
                                   set the value of cell \"C1\" to \"Phone\"\n\
                                   set the value of cell \"D1\" to \"First Active\"\n\
                                   set the value of cell \"E1\" to \"Last Active\"\n\
                                   set the value of cell \"F1\" to \"Legacy Balance\"\n\
                                   set the value of cell \"G1\" to \"Valid Balance\"\n\
                                   set the value of cell \"H1\" to \"Total Balance\"\n\
                                   set the value of cell \"I1\" to \"Notes\"\n\
                                   end tell\n\
                                   end tell"];
    
    returnDescriptor = [scriptObject executeAndReturnError: &errorDict];
}

void finishExcel(unsigned long count)
{
    NSMutableString *script = [NSMutableString stringWithFormat:@"tell application \"Microsoft Excel\"\ntell active sheet of active workbook\n"];
    [script appendFormat:@"set the value of cell \"E%lu\" to \"TOTAL:\"\n", count + 3];
    [script appendFormat:@"set the value of cell \"F%lu\" to \"=SUM(F2:F%lu)\"\n", count + 3, count + 1];
    [script appendFormat:@"set the value of cell \"G%lu\" to \"=SUM(G2:G%lu)\"\n", count + 3, count + 1];
    [script appendFormat:@"set the value of cell \"H%lu\" to \"=SUM(H2:H%lu)\"\n", count + 3, count + 1];
    [script appendString:@"end tell\nend tell"];
    
    NSDictionary* errorDict;
    NSAppleEventDescriptor* returnDescriptor = NULL;
    NSAppleScript* scriptObject = [[NSAppleScript alloc] initWithSource:script];
    returnDescriptor = [scriptObject executeAndReturnError: &errorDict];
    if(returnDescriptor == nil) {
        NSLog(@"Error writing to Excel:\n%@", errorDict);
    }
}

bool isBefore(NSString *date, int month, int year)
{
    //True if date is before 1/17, the date of legacy credit
    NSArray *comps = [date componentsSeparatedByString:@"/"];
    if([comps[2] intValue] > year) {
        return false;
    } else if([comps[2] intValue] < year) {
        return true;
    } else if(([comps[0] intValue] + 1) % 12 > month){
        return false;
    } else {
        return true;
    }
}

NSDate* calcBalances(NSArray *transactions, double *legacyTotal, double *newTotal, double *expired, double *returns, double *resales) {
    *legacyTotal = *newTotal = *expired = *returns = *resales = 0.0;
    
    PriorityQueue *earned = [[PriorityQueue alloc] initWithCompare:@selector(transCompare:)];
    for(NSDictionary *transaction in transactions) {
        //Construct transaction object
        NSString *dateString = transaction[@"date"];
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"MM/dd/yy"];
        NSDate *transDate = [[NSDate alloc] init];
        transDate = [dateFormatter dateFromString:dateString];
        Trans *t = [[Trans alloc] initWithValue:[transaction[@"theValue"] doubleValue] Date:transDate Type:PURCHASE];
        if([transaction[@"transaction"] isEqualToString:@"Cash Out"]) [t setType:CASH_OUT];
        if([transaction[@"transaction"] isEqualToString:@"Resale"]) [t setType:RESALE];
        if([transaction[@"transaction"] isEqualToString:@"Return"]) [t setType:RETURN];
        
        
        //If it's a gain, throw it in the pq
        if([t type] == RETURN || [t type] == RESALE) {
            [earned push:t];
            continue;
        }
        
        //Set cutoff to a year before the date of this transaction
        NSDate *cutoff = [NSDate dateWithTimeInterval:-31622400 sinceDate:[t date]];
        
        //Removing legacy really only matters when trying to pay off a purchase, so do it here
        PriorityQueue *tmp = [[PriorityQueue alloc] initWithCompare:@selector(transCompare:)];
        while(![earned empty]) { //Run through all transactions, only adding unexpired to tmp
            Trans *trans = [earned pop];
            if([[cutoff laterDate:[trans date]] isEqualToDate:cutoff]
               && ![Trans isLegacyDate:[trans date]]) {
                *expired += [trans value];
            } else {
                [tmp push:trans];
            }
        }
        [earned clear];
        while(![tmp empty]) { //Add back all unexpired transactions
            [earned push:[tmp pop]];
        }
        
        while([[cutoff laterDate:[[earned top] date]] isEqualToDate:cutoff]
              && ![Trans isLegacyDate:[[earned top] date]]) {
            Trans *trans = [earned pop];
            *expired += [trans value];
        }
        
        if([t type] == CASH_OUT) {
            //Returns aren't wiped out by cash out, so need to do a little more work than just clear earned here...
            PriorityQueue *tmp = [[PriorityQueue alloc] initWithCompare:@selector(transCompare:)];
            while(![earned empty]) { //collect all returns into tmp
                Trans *t = [earned pop];
                if(t.type == RETURN) {
                    [tmp push:t];
                }
            }
            [earned clear];
            while(![tmp empty]) { //Add back all returns
                [earned push:[tmp pop]];
            }
            continue;
        }
        
        //NSLog(@"Extracting for purchase on %@", [t date]);
        //If we have a purchase, figure out how much to extract
        double tot = [t value];
        while(tot > 0 && ![earned empty]) {
            Trans *trans = [earned pop];
            //NSLog(@"Pulling from %@", [trans date]);
            if(fabs([trans value] - tot) < .005) break;//{ NSLog(@"Got the perfect amount!"); break; } //We're perf!
            if([trans value] >= tot) {
                [trans setValue:[trans value] - tot];
                [earned push:trans];
                //NSLog(@"A little over, %.2f was left", [trans value]);
                break;
            }
            tot -= [trans value];
            //NSLog(@"Not enough, %.2f left", tot);
        }
    }

    
    NSDate *cutoff = [NSDate dateWithTimeIntervalSinceNow:-31622400]; //A year ago today
    bool foundNext = false;
    NSDate *nextExpire = NULL;
    while(![earned empty]) {
        Trans *trans = [earned pop];
        bool isExpired = ([[cutoff laterDate:[trans date]] isEqualToDate:cutoff] && ![Trans isLegacyDate:[trans date]]);
        
        if([trans type] == RETURN && !isExpired) {
            *returns += [trans value];
        } else if([trans type] == RESALE && !isExpired) {
            *resales += [trans value];
        }
        
        if([Trans isLegacyDate:[trans date]]) {
            *legacyTotal += [trans value];
        } else if(isExpired) {
            *expired += [trans value];
        } else {
            *newTotal += [trans value];
            if(!foundNext) {
                nextExpire = [NSDate dateWithTimeInterval:31622400 sinceDate:[trans date]];
                foundNext = true;
            }
        }
    }
    return foundNext ? nextExpire : NULL;
}

double calcLegacy(NSArray *transactions)
{
    //Looking at how current balance is from legacy
    double total;
    
    for(NSDictionary *transaction in transactions) {
        //Check if it's grandfathered
        NSString *dateString = transaction[@"date"];
        if(!isBefore(dateString, 4, 14)) {
            if([transaction[@"transaction"]  isEqualToString: @"Purchase"]) {
                total -= [transaction[@"theValue"] doubleValue];
            } else if([transaction[@"transaction"] isEqualToString:@"Cash Out"]) {
                total -= [transaction[@"theValue"] doubleValue] * 1.25;
            }
            continue;
        }
        
        //Add it to the total if it is
        if([transaction[@"transaction"]  isEqualToString: @"Purchase"]) {
            total -= [transaction[@"theValue"] doubleValue];
        } else if([transaction[@"transaction"] isEqualToString:@"Cash Out"]) {
            total -= [transaction[@"theValue"] doubleValue] * 1.25;
        } else {
            total += [transaction[@"theValue"] doubleValue];
        }
    }
    
    return total > 0 ? total : 0;
}

- (IBAction)dayGo:(id)sender
{
    [_window endSheet:_dayWindow returnCode:0];
    if(excelSelected) {
        [self export:sender];
    } else {
        [self setupDay:sender];
    }
}

- (void) setupDay: (id)sender
{
    for (unsigned long x=[[_dayAC arrangedObjects] count]; x>0; x--)
        [_dayAC removeObjectAtArrangedObjectIndex:0];
    
    NSMutableDictionary *total = [@{@"Cash Out" : @0, @"Purchase" : @0, @"Resale" : @0, @"Return" : @0} mutableCopy];
    NSDateFormatter *DateFormatter=[[NSDateFormatter alloc] init];
    [DateFormatter setDateFormat:@"MM/dd/yy"];
    NSString *dateSelected = [DateFormatter stringFromDate:[_dateSelect dateValue]];
    for(NSDictionary *custDict in [_tabAC content]) {
        for(NSDictionary *dict in custDict[@"Actions"]) {
            if ([dict[@"date"] isEqualToString:dateSelected]) {
                [_dayAC addObject:[@{
                                     @"firstName" : custDict[@"firstName"],
                                     @"lastName" : custDict[@"lastName"],
                                     @"phoneNumber" : custDict[@"phoneNumber"],
                                     @"transaction" : dict[@"transaction"],
                                     @"amount" : dict[@"value"]
                                     } mutableCopy]];
                //NSLog(@"%@: %f,\t%f", dict[@"transaction"], [dict[@"theValue"] doubleValue], total);
                total[dict[@"transaction"]] = [NSNumber numberWithDouble: ([dict[@"theValue"] doubleValue] +
                                                                           [total[dict[@"transaction"]] doubleValue])];
            }
        }
    }
    //[_dayTotal setStringValue:[self moneyString:total]];
    [_returnTotal setStringValue:[self moneyString:[total[@"Return"] doubleValue]]];
    [_resaleTotal setStringValue:[self moneyString:[total[@"Resale"] doubleValue]]];
    [_cashTotal setStringValue:[self moneyString:[total[@"Cash Out"] doubleValue]]];
    [_purchaseTotal setStringValue:[self moneyString:[total[@"Purchase"] doubleValue]]];
    [_dayDate setStringValue:dateSelected];

    [self changeWindowsView:_window to:_dayView];
}

- (IBAction)dayCancel:(id)sender
{
    [_window endSheet:_dayWindow returnCode:1];
}

- (IBAction)backDay:(id)sender
{
    [self changeWindowsView:_window to:_tableView];
}

- (int) moneyRound:(double) val
{
    if(val > 0)
        return (int)((val*100) + .5);
    else
        return (int)((val*100) - .5);
}

- (IBAction)viewMonths:(id) sender
{
    //Find all monthly totals
    NSMutableDictionary *months = [[NSMutableDictionary alloc] init];
    for(NSDictionary *customer in [_tabAC content]) {
        for(NSDictionary *action in customer[@"Actions"]) {
            NSMutableString *date = [NSMutableString stringWithString: action[@"date"]];
            [date deleteCharactersInRange: NSMakeRange(2, 3)]; //Strip out day, left with MM/YY
            if([months objectForKey:date] == nil) { //Create an empty item
                months[date] = [@{@"Cash Out" : @0, @"Purchase" : @0, @"Resale" : @0, @"Return" : @0, @"month" : date} mutableCopy];
            }
            months[date][action[@"transaction"]] = [NSNumber numberWithDouble:([action[@"theValue"] doubleValue] + [months[date][action[@"transaction"]] doubleValue])];
        }
    }
    
    //Wipe table
    for (unsigned long x=[[_monthAC arrangedObjects] count]; x>0; x--)
        [_monthAC removeObjectAtArrangedObjectIndex:0];
    
    //Sort by date
    NSArray *sortedKeys = [months keysSortedByValueUsingComparator: ^(id obj1, id obj2) {
        NSString *s1 = [NSString stringWithString:obj1[@"month"]];
        NSString *s2 = [NSString stringWithString:obj2[@"month"]];
        if([[s1 substringFromIndex:4] integerValue] > [[s2 substringFromIndex:4] integerValue]) {
            return (NSComparisonResult)NSOrderedDescending;
        } else if([[s1 substringFromIndex:4] integerValue] < [[s2 substringFromIndex:4] integerValue]) {
            return (NSComparisonResult)NSOrderedAscending;
        }
        
        if([[s1 substringToIndex:3] integerValue] > [[s2 substringToIndex:3] integerValue]) {
            return (NSComparisonResult)NSOrderedDescending;
        } else if([[s1 substringToIndex:3] integerValue] < [[s2 substringToIndex:3] integerValue]) {
            return (NSComparisonResult)NSOrderedAscending;
        }
        
        return (NSComparisonResult)NSOrderedSame;
    }];
    
    //Add items to table
    for(id month_name in sortedKeys) {
        NSMutableDictionary *month = months[month_name];
        month[@"month"] = month_name;
        [_monthAC addObject:[@{
                             @"month" : month_name,
                             @"Cash Out" : [self moneyString:[month[@"Cash Out"] doubleValue]],
                             @"Purchase" : [self moneyString:[month[@"Purchase"] doubleValue]],
                             @"Resale" : [self moneyString:[month[@"Resale"] doubleValue]],
                             @"Return" : [self moneyString:[month[@"Return"] doubleValue]],
                             } mutableCopy]];
    }
    
    //switch views
    [self changeWindowsView:_window to:_monthView];
}

//Called whenever constructing a NSTableView
- (NSCell *)tableView:(NSTableView *)tableView dataCellForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSTextFieldCell *cell = [tableColumn dataCell];
    if(tableView == [self tab]) return cell;
    //if([cell objectValue] == NULL) return cell;
    //if(![(NSString *)[cell objectValue] containsString:@"/"]) return cell;
    
    if([_legacyTrans containsObject:[NSNumber numberWithInteger:row]]) {
        //[cell setEnabled:false];
        [cell setTextColor: [NSColor colorWithRed:0.1490 green:0.5725 blue:0.1647 alpha:1]];
    } else {
        [cell setEnabled:true];
        [cell setTextColor: [NSColor blackColor]];
    }
    return cell;
}

- (void) changeWindowsView:(NSWindow *)currentView to:(NSView *)otherView
{
    CGRect theFrame, oldFrame;
    oldFrame = [currentView frame];
    theFrame = [otherView frame];
    theFrame = [_window frameRectForContentRect:theFrame];
    theFrame.origin = NSMakePoint(oldFrame.origin.x, oldFrame.origin.y + oldFrame.size.height - theFrame.size.height);
    [_window setContentView:_blankView];
    [_window setFrame:theFrame display:true animate:true];
    [_window setContentView:otherView];
}

- (void)doEventFetch
{
    unsigned x = 0;
    while (true) {
        NSEvent* event = [NSApp nextEventMatchingMask:NSUIntegerMax untilDate:nil inMode:NSEventTrackingRunLoopMode dequeue:YES];
        if(!event) break;
        [NSApp sendEvent:event];
        x++;
    }
}

@end
