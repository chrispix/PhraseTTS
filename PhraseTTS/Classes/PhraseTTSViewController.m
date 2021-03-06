//
//  PhraseTTSViewController.m
//  PhraseTTS
//
//  Created by Chris Laan on 8/3/10.
//  Copyright Laan Labs 2010. All rights reserved.
//

#import "PhraseTTSViewController.h"
#import "SearchResultCell.h"
#import "Model.h"
#import "Constants.h"


@interface PhraseTTSViewController()

-(void) phraseDbReady;
-(void) searchTable;

@end


@implementation PhraseTTSViewController

@synthesize searchBar , tableView, currentSearchResults , searchTextField, toolbar, previous, 
 clearButton, repeatButton, sequentialKeyboardView, landscapeKeyboard;


/*
// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/



// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	
	// TODO: add non-qwerty keyboard
	// this is where we could add a non-QWERT keyboard based on prefs:
	//searchTextField.inputView = [[UIView alloc] init];
	
	// Observe keyboard hide and show notifications to resize the text view appropriately.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
	
}

-(void) viewWillAppear:(BOOL)animated {
	
	if ( [Model instance].updatingIndex ) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(phraseDbReady) name:@"PhraseDatabaseReady" object:nil];
	} else {
		[self phraseDbReady];
	}
	
	
	NSUserDefaults * defs = [NSUserDefaults standardUserDefaults];
	BOOL ac = [defs boolForKey:kAutoCorrectKey];
	
	if ( ac ) {
		searchTextField.autocorrectionType = UITextAutocorrectionTypeYes;
	} else {
		searchTextField.autocorrectionType = UITextAutocorrectionTypeNo;
	}
	[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(receivedRotate:) name: UIDeviceOrientationDidChangeNotification object: nil];
	
}
-(void) receivedRotate: (NSNotification*) notification
{
	if ([searchTextField isEditing]) {
		[searchTextField resignFirstResponder];
		[searchTextField becomeFirstResponder];
	}
}

	

-(void) phraseDbReady {
	
	[self searchTable];
	
}


-(void) searchTable {
	
	if ( [Model instance].updatingIndex ) {
		NSLog(@"model is updating... %3.2f " , [Model instance].updateProgress );
		[self performSelector:@selector(searchTable) withObject:nil afterDelay:0.1];
		return;
	}
	
	NSString * query = searchTextField.text;
	
	NSMutableArray * arr = nil;
	
	if ( [query length] == 0 ) {
		
		arr = (NSMutableArray*)[[SearchResult getTopUsedPhrases] retain];
		
	} else {
		
		arr = (NSMutableArray*)[[SearchResult sortedSearchForQuery: query ] retain];
		
	}
	
	self.currentSearchResults = arr;
	[tableView reloadData];
	
	
}


#pragma mark -
#pragma mark Responding to keyboard events

- (void)keyboardWillShow:(NSNotification *)notification {
    
    /*
     Reduce the size of the text view so that it's not obscured by the keyboard.
     Animate the resize so that it's in sync with the appearance of the keyboard.
     */
	
    NSDictionary *userInfo = [notification userInfo];

    // Get the origin of the keyboard when it's displayed.
    NSValue* aValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];	
	
    // Get the top of the keyboard as the y coordinate of its origin in self's view's coordinate system. The bottom of the text view's frame should align with the top of the keyboard's final position.
    CGRect keyboardRect = [aValue CGRectValue];
    
	keyboardRect = [self.view convertRect:keyboardRect fromView:nil];

    CGFloat keyboardTop = keyboardRect.origin.y;
	
	self.toolbar = nil;
	
	if (!self.toolbar) {
		//if portrait
		if ([self interfaceOrientation] == UIInterfaceOrientationPortrait) {
			self.toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, keyboardTop - 40, 768, 40)];
		}
		else {
			self.toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, keyboardTop - 40, 1024, 40)];
		}
	}
	UIBarButtonItem *space = [[UIBarButtonItem alloc] init];
	
	space.width = 100;
	NSMutableArray *items = [NSMutableArray arrayWithObjects:space, clearButton, repeatButton, nil];
	[[self toolbar] setItems:items];
	[[self toolbar] setHidden:NO];
	
	[self.view addSubview:toolbar];
    CGRect newTextViewFrame = tableView.frame;
    
    // Get the duration of the animation.
    NSValue *animationDurationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval animationDuration;
    [animationDurationValue getValue:&animationDuration];
    
    // Animate the resize of the text view's frame in sync with the keyboard's appearance.
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:animationDuration];
    
    tableView.frame = newTextViewFrame;
		
    [UIView commitAnimations];
}


- (void)keyboardWillHide:(NSNotification *)notification {
    
    NSDictionary* userInfo = [notification userInfo];
    
    /*
     Restore the size of the text view (fill self's view).
     Animate the resize so that it's in sync with the disappearance of the keyboard.
     */
    NSValue *animationDurationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval animationDuration;
    [animationDurationValue getValue:&animationDuration];
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:animationDuration];
    
    tableView.frame = CGRectMake(0, 44, self.view.bounds.size.width, self.view.bounds.size.height - 44);
    toolbar.hidden = YES;
    [UIView commitAnimations];
}

#pragma mark -
#pragma mark UITextField Delegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
	
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(searchTable) object:nil];
	[self performSelector:@selector(searchTable) withObject:nil afterDelay:0.1];
	
	if ( USE_WORD_LIST ) {
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(delayedWordCheck) object:nil];
		[self performSelector:@selector(delayedWordCheck) withObject:nil afterDelay:0.5];
	}
	return YES;
}

-(void) delayedWordCheck {
	[wordSuggestionsView displaySuggestionsForWord:searchTextField.text];
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
	
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(searchTable) object:nil];
	[self performSelector:@selector(searchTable) withObject:nil afterDelay:0.06];
	
	return YES;
}

- (void) selectKeyboard {
	NSUserDefaults * defs = [NSUserDefaults standardUserDefaults];
	
	NSString *key = [defs objectForKey:kKeyboardTypeKey];
	searchTextField.inputView = nil;
	
	if ([key isEqualToString:@"ABCD"]) {
		if (([[UIDevice currentDevice] orientation] == UIInterfaceOrientationPortrait) || 
			([[UIDevice currentDevice] orientation] == UIInterfaceOrientationPortraitUpsideDown)) {
			[[NSBundle mainBundle] loadNibNamed:@"SequentialKeyboardView"
										  owner:self options:nil];
			searchTextField.inputView = self.sequentialKeyboardView;
			searchTextField.inputView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
		}
		else {	 
			[[NSBundle mainBundle] loadNibNamed:@"LandscapeSequentialKeyboard"
										  owner:self options:nil];
			searchTextField.inputView = self.landscapeKeyboard;
			searchTextField.inputView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
		}
	}
	else {
		searchTextField.inputView = nil;
	}
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
	
	[self selectKeyboard];
	if ( USE_WORD_LIST ) {
		if (searchTextField.inputAccessoryView == nil) {
			wordSuggestionsView = [[WordSuggestionsView alloc] init];
			searchTextField.inputAccessoryView = wordSuggestionsView;    
		}
	}	
	return YES;	
}

#pragma mark -
#pragma mark Accessory view action

// not used..
- (IBAction)tappedMe:(id)sender {
    /*
    // When the accessory view button is tapped, add a suitable string to the text view.
    NSMutableString *text = [textView.text mutableCopy];
    NSRange selectedRange = textView.selectedRange;
    
    [text replaceCharactersInRange:selectedRange withString:@"You tapped me.\n"];
    textView.text = text;
    [text release];
	 */
	
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
	//[searchTextField resignFirstResponder];
	return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	
	if ( [searchTextField.text length] > 0 ) {
		
		
		SearchResult * sr = [[SearchResult alloc] init];
		
		sr.body = textField.text;
		
		
		if ( [sr checkIfExistsAndPopulateIfSo] ) {
			[sr incrementUsesAndSave];
			
		} else {
			sr.uses = 1;
			[sr insertIntoDb];
		}
		
		if (!previous) {
			previous = [[SearchResult alloc] init];
		}
		[previous copy:sr];

		[sr release];
		
		[[Model instance] speakText:searchTextField.text];
		self.searchTextField.text=@"";
		self.currentSearchResults = (NSMutableArray*)[[SearchResult getTopUsedPhrases] retain];
		[tableView reloadData];
		
	}
	
	return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
	
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
	
}

- (IBAction)didTouchClearButton {
	[searchTextField setText:@""];
	self.currentSearchResults = (NSMutableArray*)[[SearchResult getTopUsedPhrases] retain];
	[tableView reloadData];
}
-(void) resultClicked:(SearchResult*) result {
	
	
	[[Model instance] speakText: result.body ];
	
	[result incrementUsesAndSave];
	previous = result;
	
}

- (IBAction)speakPrevious{
	if (self.previous) {
		[self resultClicked:previous];
	}
		
}
	



#pragma mark -
#pragma mark Search Bar Delegate 

- (BOOL)searchBar:(UISearchBar *)searchBar shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
	return YES;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(searchTable) object:nil];
	[self performSelector:@selector(searchTable) withObject:nil afterDelay:0.06];
	 
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
	return YES;
}


- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar
{
	return YES;
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
	
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
	
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return CELL_HEIGHT;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
 
	if ( currentSearchResults == nil ) {
		
		return 0;
		
	} else {
		
		return ceil([currentSearchResults count] / 2.0 );
		
	}
	
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)_tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    SearchResultCell *cell = (SearchResultCell*)[_tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[SearchResultCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
		cell.clickDelegate = self;
    }
    
	// each cell has two items...
	[cell setLeftSearchResult:[currentSearchResults objectAtIndex:(indexPath.row*2)]];
	
	// make sure there is an item on the right side of the cell...
	if ( (indexPath.row+1)*2 <= [currentSearchResults count] ) {
		[cell setRightSearchResult:[currentSearchResults objectAtIndex:(indexPath.row*2 + 1)]];
	} else {
		[cell setRightSearchResult:nil];
	}
	
    return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
	/*
	 <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
	 [self.navigationController pushViewController:detailViewController animated:YES];
	 [detailViewController release];
	 */
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
    
	[super dealloc];
	
	[searchBar release];
	searchBar = nil;
	
	[tableView release];
	tableView = nil;
	
	[currentSearchResults release];
	currentSearchResults = nil;
	
}
#pragma mark sequentialKeyboardStrokes
-(IBAction) didTapAKey {
	self.searchTextField.text = [self.searchTextField.text stringByAppendingString:@"A"];
	[self searchTable];
}
-(IBAction) didTapBKey {
	self.searchTextField.text = [self.searchTextField.text stringByAppendingString:@"B"];
	[self searchTable];
}
-(IBAction) didTapCKey {
	self.searchTextField.text = [self.searchTextField.text stringByAppendingString:@"C"];
	[self searchTable];
}
-(IBAction) didTapDKey {
	self.searchTextField.text = [self.searchTextField.text stringByAppendingString:@"D"];
	[self searchTable];
}
-(IBAction) didTapEKey {
	self.searchTextField.text = [self.searchTextField.text stringByAppendingString:@"E"];
	[self searchTable];
}
-(IBAction) didTapFKey {
	self.searchTextField.text = [self.searchTextField.text stringByAppendingString:@"F"];
	[self searchTable];
}
-(IBAction) didTapGKey {
	self.searchTextField.text = [self.searchTextField.text stringByAppendingString:@"G"];
	[self searchTable];
}
-(IBAction) didTapHKey {
	self.searchTextField.text = [self.searchTextField.text stringByAppendingString:@"H"];
	[self searchTable];
}
-(IBAction) didTapIKey {
	self.searchTextField.text = [self.searchTextField.text stringByAppendingString:@"I"];
	[self searchTable];
}
-(IBAction) didTapJKey {
	self.searchTextField.text = [self.searchTextField.text stringByAppendingString:@"J"];
	[self searchTable];
}
-(IBAction) didTapKKey {
	self.searchTextField.text = [self.searchTextField.text stringByAppendingString:@"K"];
	[self searchTable];
}
-(IBAction) didTapLKey {
	self.searchTextField.text = [self.searchTextField.text stringByAppendingString:@"L"];
	[self searchTable];
}
-(IBAction) didTapMKey {
	self.searchTextField.text = [self.searchTextField.text stringByAppendingString:@"M"];
	[self searchTable];
}
-(IBAction) didTapNKey {
	self.searchTextField.text = [self.searchTextField.text stringByAppendingString:@"N"];
	[self searchTable];
}
-(IBAction) didTapOKey {
	self.searchTextField.text = [self.searchTextField.text stringByAppendingString:@"O"];
	[self searchTable];
}
-(IBAction) didTapPKey {
	self.searchTextField.text = [self.searchTextField.text stringByAppendingString:@"P"];
	[self searchTable];
}
-(IBAction) didTapQKey {
	self.searchTextField.text = [self.searchTextField.text stringByAppendingString:@"Q"];
	[self searchTable];
}
-(IBAction) didTapRKey {
	self.searchTextField.text = [self.searchTextField.text stringByAppendingString:@"R"];
	[self searchTable];
}
-(IBAction) didTapSKey {
	self.searchTextField.text = [self.searchTextField.text stringByAppendingString:@"S"];
	[self searchTable];
}
-(IBAction) didTapTKey {
	self.searchTextField.text = [self.searchTextField.text stringByAppendingString:@"T"];
	[self searchTable];
}
-(IBAction) didTapUKey {
	self.searchTextField.text = [self.searchTextField.text stringByAppendingString:@"U"];
	[self searchTable];
}
-(IBAction) didTapVKey {
	self.searchTextField.text = [self.searchTextField.text stringByAppendingString:@"V"];
	[self searchTable];
}
-(IBAction) didTapWKey {
	self.searchTextField.text = [self.searchTextField.text stringByAppendingString:@"W"];
	[self searchTable];
}
-(IBAction) didTapXKey {
	self.searchTextField.text = [self.searchTextField.text stringByAppendingString:@"X"];
	[self searchTable];
}
-(IBAction) didTapYKey {
	self.searchTextField.text = [self.searchTextField.text stringByAppendingString:@"Y"];
	[self searchTable];
}
-(IBAction) didTapZKey {
	self.searchTextField.text = [self.searchTextField.text stringByAppendingString:@"Z"];
	[self searchTable];
}
-(IBAction) didTapReturnKey {
	[self textFieldShouldReturn:searchTextField];
	[searchTextField resignFirstResponder];
}
-(IBAction) didTapSpaceKey {
	self.searchTextField.text = [self.searchTextField.text stringByAppendingString:@" "];
	[self searchTable];
}
-(IBAction) didTapDropKey {
	[searchTextField resignFirstResponder];
}
-(IBAction) didTapDeleteKey {
	NSString *backspace = searchTextField.text;
	int lengthofstring = backspace.length;
	if (lengthofstring >0) {
		backspace = [backspace substringToIndex:lengthofstring - 1];
	}
	searchTextField.text = backspace;
	[self searchTable];
}
@end
