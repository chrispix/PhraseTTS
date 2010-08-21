//
//  PhraseTTSViewController.h
//  PhraseTTS
//
//  Created by Chris Laan on 8/3/10.
//  Copyright Laan Labs 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WordSuggestionsView.h"
#import <CoreText/CoreText.h>
#import "SearchResult.h"



@interface PhraseTTSViewController : UIViewController <UITextFieldDelegate, UISearchBarDelegate , UITableViewDataSource , UITableViewDelegate > {
	
	IBOutlet UISearchBar * searchBar;
	IBOutlet UITextField * searchTextField;
	IBOutlet UITableView * tableView;
	SearchResult *previous;
	
	NSMutableArray * currentSearchResults;
	
	WordSuggestionsView * wordSuggestionsView;
	IBOutlet UIToolbar *toolbar;
	
	
}

@property (nonatomic, retain) UITextField * searchTextField;
@property (nonatomic, retain) IBOutlet UISearchBar * searchBar;
@property (nonatomic, retain) IBOutlet UITableView * tableView;
@property (nonatomic, retain) IBOutlet UIToolbar *toolbar;
@property (nonatomic, retain) NSMutableArray * currentSearchResults;
@property (nonatomic, retain) SearchResult *previous;

- (IBAction)didTouchClearButton;
- (IBAction)speakPrevious;

@end

