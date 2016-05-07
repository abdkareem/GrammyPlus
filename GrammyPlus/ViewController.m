//
//  ViewController.m
//  GrammyPlus
//
//  Created by Taiyaba Sultana on 2/19/16.
//  Copyright © 2016 Abdul Kareem. All rights reserved.
//

#import "ViewController.h"
#import "NXOAuth2.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *iViewer;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UIButton *logoutButton;
@property (weak, nonatomic) IBOutlet UIButton *refreshButton;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.logoutButton.enabled = false;
    self.refreshButton.enabled = false;
    // Do any additional setup after loading the view, typically from a nib.
    //NSLog(@"View did load");
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)loginAction:(id)sender {
    [[NXOAuth2AccountStore sharedStore] requestAccessToAccountWithType:@"Instagram"];
    self.logoutButton.enabled = true;
    self.refreshButton.enabled = true;
    self.loginButton.enabled = false;
}
- (IBAction)logoutAction:(id)sender {
    //what exactly is the the below mentioned instruction doing.
    //Is it taking all the accounts that used OAuth2.0 for authentication ?
    
    NXOAuth2AccountStore *store = [NXOAuth2AccountStore sharedStore];
    NSArray *instagramAccounts = [store accountsWithAccountType:@"Instagram"];
    for (id acct in instagramAccounts) {
        [store removeAccount:acct];
    }
    self.loginButton.enabled = true;
    self.refreshButton.enabled = false;
    self.logoutButton.enabled = false;
}

- (IBAction)refreshAction:(id)sender {
    NSArray *instagramAccounts = [[NXOAuth2AccountStore sharedStore] accountsWithAccountType:@"Instagram"];
    if ([instagramAccounts count] == 0) {
        NSLog(@"Warning. %lu accounts logged in", (unsigned long)instagramAccounts.count);
        return;
    }
    
    //extracting access token and appending it to the endpoint API
    NXOAuth2Account *acct = instagramAccounts[0];
    NSString *token = acct.accessToken.accessToken;
    NSString *urlStr = [@"https://api.instagram.com/v1/users/self/media/recent/?access_token=" stringByAppendingString:token];
    //NSURL *url = [NSURL URLWithString:urlStr];
    
    //establishing session and requesting
    
    NSURLSession *session = [NSURLSession sharedSession];
    //[session data]
    //all the work that is in response to request is in completion handler
    
    [[session dataTaskWithURL:[NSURL URLWithString:urlStr] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        //three types of error
        //first check if there is any network error
        if (error) {
            NSLog(@"Error. Could not finish the request: %@",error);
            return;
        }
        //second, check for http error. errors associated with instagram server
        NSHTTPURLResponse *httpResp = (NSHTTPURLResponse *)response;
        if(httpResp.statusCode < 200 || httpResp.statusCode >= 300) {
            NSLog(@"Error. Status code: %ld", httpResp.statusCode);
            return;
        }
        //third, check for parse string
        NSError *parseError;
        id pkg = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
        if (!pkg) {
            NSLog(@"Parse error %@", parseError);
            return;
        }
        NSLog(@"entered block");
        NSString *imageURLStr = pkg[@"data"][0][@"images"][@"standard_resolution"][@"url"];
        [[session dataTaskWithURL:[NSURL URLWithString:imageURLStr] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            //two types of error
            //first check if there is any network error
            if (error) {
                NSLog(@"Error. Could not finish the request: %@",error);
                return;
            }
            //second, check for http error. errors associated with instagram server
            NSHTTPURLResponse *httpResp = (NSHTTPURLResponse *)response;
            if(httpResp.statusCode < 200 || httpResp.statusCode >= 300) {
                NSLog(@"Error. Status code: %ld", httpResp.statusCode);
                return;
            }
            dispatch_async(dispatch_get_main_queue(),^{
                self.iViewer.image = [UIImage imageWithData:data];
            });
        }]resume];
        
    }]resume];

}

@end
