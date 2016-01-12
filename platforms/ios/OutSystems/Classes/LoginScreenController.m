//
//  LoginScreenController.m
//  HubApp
//
//  Created by engineering on 01/04/14.
//  Copyright (c) 2014 OutSystems. All rights reserved.
//

#import "LoginScreenController.h"
#import "ApplicationTileListController.h"
#import "UIInsetTextField.h"
#import "OutSystemsAppDelegate.h"
#import "ApplicationViewController.h"
#import "OSNavigationController.h"
#import "OfflineSupportController.h"
#import "ApplicationSettingsController.h"

@interface LoginScreenController ()
@property (strong, nonatomic) IBOutlet UIView *loginScreenMainView;
@property (weak, nonatomic) IBOutlet UIImageView *backgroungImageView;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loginActivityIndicator;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UILabel *errorMessageLabel;
@property (weak, nonatomic) IBOutlet UIInsetTextField *usernameInput;
@property (weak, nonatomic) IBOutlet UIInsetTextField *passwordInput;
@property (weak, nonatomic) IBOutlet UILabel *infrastructureLabel;

@property (weak, nonatomic) NSUserDefaults *userSettings;

@property (strong, nonatomic) NSData *loginResponseData;
@property (weak, nonatomic) IBOutlet UILabel *applicationsAtLabel;
@property (weak, nonatomic) IBOutlet UIImageView *applicationLogoImageView;

@property NSArray* trustedHosts;
@property (strong, nonatomic) NSArray *applicationList;

@end

@implementation LoginScreenController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    

    self.applicationLogoImageView.hidden = YES;
    self.applicationsAtLabel.font = [UIFont fontWithName:@"OpenSans" size:self.applicationsAtLabel.font.pointSize];
    self.infrastructureLabel.font = [UIFont fontWithName:@"OpenSans" size:self.infrastructureLabel.font.pointSize];
    self.loginButton.titleLabel.font = [UIFont fontWithName:@"OpenSans" size:self.loginButton.titleLabel.font.pointSize];
    
    self.usernameInput.font = [UIFont fontWithName:@"OpenSans" size:self.usernameInput.font.pointSize];
    self.passwordInput.font = [UIFont fontWithName:@"OpenSans" size:self.passwordInput.font.pointSize];
    
    [self.loginButton.layer setBorderWidth:0.5];
    [self.loginButton.layer setBorderColor:[UIColor whiteColor].CGColor];
    
    
    self.usernameInput.text = self.infrastructure.username;
    self.passwordInput.text = self.infrastructure.password;
    self.infrastructureLabel.text = self.infrastructure.name;
    
    self.usernameInput.layer.cornerRadius = 5;
    self.passwordInput.layer.cornerRadius = 5;
    self.loginButton.layer.cornerRadius = 5;
    
    self.trustedHosts = [[NSArray alloc] initWithObjects:@"outsystems.com", @"outsystems.net", @"outsystemscloud.com", nil];
    
    // login is readonly when the credentials are set on the application settings (bundle)
    if(self.loginReadonly) {
        self.usernameInput.enabled = NO;
        self.passwordInput.enabled = NO;
        
        self.usernameInput.backgroundColor = [UIColor colorWithWhite:1 alpha:0.8];
        self.passwordInput.backgroundColor = [UIColor colorWithWhite:1 alpha:0.8];
    }
    
    // hide the keyboard when the user clicks outside the hostname textbox
    // set the tap gesture recognizer
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    singleTap.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:singleTap];
        
    // Application Settings
  
    if([ApplicationSettingsController hasValidSettings]){
        self.applicationLogoImageView.hidden = NO;
        self.applicationsAtLabel.hidden = YES;
        self.infrastructureLabel.hidden = YES;

        
        UIColor *backgroundColor = [ApplicationSettingsController backgroundColor];
        if(backgroundColor){
            // TODO: not sure if this is the best approach...
            self.backgroungImageView.image = [self.backgroungImageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            [self.backgroungImageView setTintColor:backgroundColor];
            
        }
        
        UIColor *foregroundColor = [ApplicationSettingsController foregroundColor];
        if(foregroundColor){
            [self.loginButton setTitleColor:foregroundColor forState:UIControlStateNormal];
            [[self.loginButton layer] setBorderColor:foregroundColor.CGColor];
            [self.errorMessageLabel setTextColor:foregroundColor];
            [self.loginActivityIndicator setColor:foregroundColor];
            
        }
        
        UIColor *tintColor = [ApplicationSettingsController tintColor];
        if(tintColor){
            // Navigation Bar tint color
            [[self.navigationController navigationBar] setTintColor:tintColor];
            
            // Input texts tint color
            [self.usernameInput setTintColor:tintColor];
            [self.passwordInput setTintColor:tintColor];
        }
        
    }
}


-(void)handleSingleTap:(UITapGestureRecognizer *)sender{
    [self.view endEditing:YES];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // infrastructure is readonly when the credentials are set on the application settings (bundle)
    if(self.infrastructureReadonly || ([[ApplicationSettingsController defaultHostname] length] > 0)) {
        self.navigationController.navigationBar.hidden = YES;
    } else {
        self.navigationController.navigationBar.hidden = NO;
    }
    

    // check if deep link is valid
    if(self.deepLinkController && [self.deepLinkController hasValidSettings]){
        // proceed according to the deep link operation
        [self.deepLinkController resolveOperation:self];
    }
    
    
    self.navigationController.toolbar.hidden = YES;
    
    bool iPhoneDevice = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone;
    
    if(iPhoneDevice){
        // Force orientation to Portrait
        NSNumber *value = [NSNumber numberWithInt:UIInterfaceOrientationPortrait];
        [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
    }
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if([self.infrastructure.username length] > 0 && [self.infrastructure.password length] > 0 && [OutSystemsAppDelegate hasAutoLoginPerformed] == NO) {
        
        [self.loginButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    }
    

    bool iPhoneDevice = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone;
    
    if(iPhoneDevice){
        // Lock screen to Portrait orientation
        OSNavigationController *navController = (OSNavigationController*)self.navigationController;
        [navController lockCurrentOrientation:YES];
    }

}

-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    self.view.hidden = NO;
}

-(BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)didEndOnExitUsername:(id)sender {
    [_passwordInput becomeFirstResponder];
}

- (IBAction)didEndOnExitPassword:(id)sender {
    [self OnLoginClick:_loginButton];
}

-(NSString *) addPercentEscapesAndReplaceAmpersand: (NSString *) stringToEncode
{
    NSString *encodedString = [stringToEncode stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
    return [encodedString stringByReplacingOccurrencesOfString: @"&" withString: @"%26"];
}

- (IBAction)OnLoginClick:(UIButton *)sender {
    
    [self.view endEditing:YES];
    
    // Offline Support
    [OfflineSupportController prepareForLogin];
    
    [_loginActivityIndicator startAnimating];
    [_errorMessageLabel setHidden:YES];
    [_loginButton setHidden:YES];
    
    _infrastructure.username = _usernameInput.text;
    _infrastructure.password = _passwordInput.text;
    
    // get the device dimensions
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    
    NSError *error = nil;
    // Save the object to persistent store
    
    if (![_infrastructure.managedObjectContext save:&error]) {
        NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
    }
    
    int timeoutInSeconds = 30;
    
    NSURL *myURL = [NSURL URLWithString:[_infrastructure getHostnameForService:@"login"]];
    
    _loginResponseData = nil;
    
    NSString *deviceUDID = [UIDevice currentDevice].identifierForVendor.UUIDString;
    
    NSString *post = [NSString stringWithFormat:@"username=%@&password=%@&devicetype=%@&screenWidth=%d&screenHeight=%d&deviceHwId=%@",
                      [self addPercentEscapesAndReplaceAmpersand:_usernameInput.text],
                      [self addPercentEscapesAndReplaceAmpersand:_passwordInput.text],
                      @"ios",
                      (int)screenBounds.size.width,
                      (int)screenBounds.size.height,
                      deviceUDID]; // hardware unique idenfifier
    
    NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[postData length]];
    
    NSMutableURLRequest *myRequest = [NSMutableURLRequest requestWithURL:myURL cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:timeoutInSeconds];
    
    [myRequest setHTTPMethod:@"POST"];
    [myRequest setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [myRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [myRequest setHTTPBody:postData];
    
    NSLog(@"Logging in: %@", myURL);
    
    [NSURLConnection connectionWithRequest:myRequest delegate:self];
    
    
    [OutSystemsAppDelegate setAutoLoginPerformed]; // setting the flag to true, even if it's a normal login so the app won't try to auto login the user again (in this app session)
    
    // set the url to register the device push notifications token (in case it is received later)
    [OutSystemsAppDelegate setURLForPushNotificationTokenRegistration:[NSString stringWithFormat:@"%@?&deviceHwId=%@&device=",
                                                                       [_infrastructure getHostnameForService:@"registertoken"],
                                                                       deviceUDID]];
    

}


- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
    return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        for (NSString *trustedHost in self.trustedHosts) {
            
            // currently trusting all certificates for beta release, remove true condition to validate untrusted certificates with list for trusted servers
            if(true || [challenge.protectionSpace.host rangeOfString:trustedHost options:NSBackwardsSearch].location == (challenge.protectionSpace.host.length - trustedHost.length)) {
                [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
                break;
            }
        }
    }
    
    [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*) response;
    NSInteger errorCode = httpResponse.statusCode;
    NSString *fileMIMEType = [[httpResponse MIMEType] lowercaseString];
    NSLog(@"response is %ld, %@", (long)errorCode, fileMIMEType);
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {

    _loginResponseData = [data copy];
    NSLog(@"received: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    // inform the user
    NSLog(@"Connection failed! Error - %@ %@", [error localizedDescription], [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]);
    
    BOOL offlineSupport = NO;
    _loginResponseData = nil;
    
    if(offlineSupport){
        // Get Login Applications
        self.applicationList = [OfflineSupportController getLoginApplications:_infrastructure];
        
        // Open Applications
        
        //check if the view is still active - user could have pressed back
        if(self.view.window != nil) {
            /*
            // check if only one app
            if([self.applicationList count] == 1){
                if(self.navigationController.visibleViewController == self)
                    [self performSegueWithIdentifier:@"GoToSingleApplicationSegue" sender:self];
            }
            else {
                if(self.navigationController.visibleViewController == self)
                    [self performSegueWithIdentifier:@"GoToAppListSegue" sender:self];
            }
             */
            if(self.navigationController.visibleViewController == self){
                [self pushNextViewController:([self.applicationList count] == 1)];
            }
        }
        
    }
    else{

        _errorMessageLabel.text = error.localizedDescription;
        
        [_loginActivityIndicator stopAnimating];
        [_errorMessageLabel setHidden:NO];
        [_loginButton setHidden:NO];
        
    }

}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    // do something with the data
    // receivedData is declared as a method instance elsewhere
    NSLog(@"connection finished");
    
    NSError *e = nil;
    NSDictionary *response = nil;
    BOOL success = NO;
    NSString *moduleVersion;
    
    if(self.loginResponseData != nil) {
        response = [NSJSONSerialization JSONObjectWithData:_loginResponseData options:NSJSONReadingMutableContainers error:&e];
        NSLog(@"obj: %@ ; error: %@", response,e);
        if([[response objectForKey:@"success"] isKindOfClass:[NSNumber class]]) {
            success = [[response objectForKey:@"success"] boolValue];
        }
        
        _loginResponseData = nil;
    }
    
    // check OutSystemsNowService compatibility
    if([[response objectForKey:@"version"] isKindOfClass:[NSString class]]) {
        moduleVersion = [response objectForKey:@"version"];
    }
    
    if(moduleVersion == nil || [moduleVersion rangeOfString:OutSystemsNowRequiredVersion].location != 0) {
        success = NO;
        [response setValue:@"Incompatible module version in your installation, please contact your system administrator to update the OutSystems Now modules" forKey:@"errorMessage"];
    }
    
    _infrastructure.isValid = success;
    
    if(success) {
        [_loginActivityIndicator stopAnimating];
        [_loginButton setHidden:NO];
        [_errorMessageLabel setHidden:YES];
            
        [OutSystemsAppDelegate registerPushToken]; // send the push token to the server
        
        // get list of applications
        self.applicationList = [response valueForKey:@"applications"];
        
        // Store login applications
        [OfflineSupportController addApplications:_applicationList forInfrastructure:_infrastructure];
        
        // Offline Support
        // Check current session
        [OfflineSupportController checkCurrentSession:_infrastructure];
        
        // Clear cache if needed
        [OfflineSupportController clearCacheIfNeeded];

        
        //check if the view is still active - user could have pressed back
        if(self.view.window != nil) {
            /*
            // check if only one app
            if([self.applicationList count] == 1){
                if(self.navigationController.visibleViewController == self)
                    [self performSegueWithIdentifier:@"GoToSingleApplicationSegue" sender:self];
            }
            else {
                if(self.navigationController.visibleViewController == self)
                    [self performSegueWithIdentifier:@"GoToAppListSegue" sender:self];
            }
            
            */
            if(self.navigationController.visibleViewController == self){
                [self pushNextViewController:([self.applicationList count] == 1)];
            }
            
        }
   
        
    } else {
        [_loginActivityIndicator stopAnimating];
        [_errorMessageLabel setHidden:NO];
        [_loginButton setHidden:NO];

        if([[response objectForKey:@"errorMessage"] isKindOfClass:[NSString class]] > 0) {
            _errorMessageLabel.text = [response objectForKey:@"errorMessage"];
        }
        else {
            _errorMessageLabel.text = @"Error trying to connect to your environment";
        }
        
        // shake on error
        CAKeyframeAnimation * anim = [ CAKeyframeAnimation animationWithKeyPath:@"transform" ] ;
        anim.values = @[ [ NSValue valueWithCATransform3D:CATransform3DMakeTranslation(-5.0f, 0.0f, 0.0f) ], [ NSValue valueWithCATransform3D:CATransform3DMakeTranslation(5.0f, 0.0f, 0.0f) ] ] ;
        anim.autoreverses = YES ;
        anim.repeatCount = 2.0f ;
        anim.duration = 0.07f ;
        
        [self.view.layer addAnimation:anim forKey:nil ] ;
    }
}


-(void)pushNextViewController:(BOOL)singleApp{
    
    UINavigationController *navControler = self.navigationController;
    UIStoryboard *storyboard = navControler.storyboard;
    UIViewController *targetVC = nil;
    
    if(singleApp){
        // GoToSingleApplicationSegue
        ApplicationViewController *appViewController = [storyboard instantiateViewControllerWithIdentifier:@"ApplicationViewController"];
        
        appViewController.infrastructure = self.infrastructure;
        appViewController.isSingleApplication = YES;
        
        if ([self.deepLinkController hasValidSettings] && [self.deepLinkController hasApplication]) {
            appViewController.application = self.deepLinkController.destinationApp;
            
            [self.deepLinkController.deepLinkSettings invalidate];
            
        }else{
            appViewController.application = [Application initWithJSON: self.applicationList[0] forHost:self.infrastructure.hostname];
        }
        
        targetVC = appViewController;
    }
    else{
        targetVC = [ApplicationSettingsController nextViewController:self];
    }
    
    
    if(targetVC){
        
        if([targetVC isKindOfClass:[ApplicationTileListController class]]){
            ApplicationTileListController *appListVC = (ApplicationTileListController*)targetVC;
            
            // clear previous applications
            [appListVC.applicationList removeAllObjects];
            
            // create new list of applications
            [appListVC.applicationList addObjectsFromArray:self.applicationList];
        }
        
        
        [navControler pushViewController:targetVC animated:YES];
    }
    
}

/*
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([[segue identifier] isEqualToString:@"GoToAppListSegue"]) {
        ApplicationTileListController *viewController = [segue destinationViewController];
        viewController.infrastructure = self.infrastructure;
        viewController.isDemoEnvironment = NO;
        viewController.deepLinkController = self.deepLinkController;
        
        // clear previous applications
        [viewController.applicationList removeAllObjects];
       
        // create new list of applications
        [viewController.applicationList addObjectsFromArray:self.applicationList];
        
    } else {
        // GoToSingleApplicationSegue
        ApplicationViewController *appViewController =
        [segue destinationViewController];

        appViewController.infrastructure = self.infrastructure;
        appViewController.isSingleApplication = YES;
        
        if ([self.deepLinkController hasValidSettings] && [self.deepLinkController hasApplication]) {
            appViewController.application = self.deepLinkController.destinationApp;
            
            [self.deepLinkController.deepLinkSettings invalidate];
            
        }else{
            appViewController.application = [Application initWithJSON: self.applicationList[0] forHost:self.infrastructure.hostname];
        }
    }
}
 */

-(void)setUserCredentials:(NSString*)user password: (NSString*)pass{
    self.infrastructure.username = user;
    self.infrastructure.password = pass;
    self.usernameInput.text = user;
    self.passwordInput.text = pass;
}


@end
