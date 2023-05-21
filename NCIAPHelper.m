//
//  NCIAPHelper.m
//  NCIAPHelper
//
//  Copyright (c) 2013 CHEN Xian'an <xianan.chen@gmail.com>. All rights
//  reserved.
//
//  NCIAPHelper is available under the MIT license. you can use it into your app
//  royalty-freely, just make sure that you don’t remove above copyright notice.

#import "NCIAPHelper.h"
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

NSString* const kNCIAPHelperErrorDomain = @"kNCIAPHelperErrorDomain";

@interface NCIAPHelper () <SKProductsRequestDelegate,
    SKPaymentTransactionObserver>

@property (class, readonly, strong) NCIAPHelper* shared;
@property (nonatomic, strong) UIAlertController* alertController;
@property (nonatomic, weak) UIWindow* aboveWindow;
@property (nonatomic, strong) NCIAPHelperCompletionHandler completionHandler;
@property (nonatomic, strong) NCIAPHelperErrorHandler errorHandler;

@end

@implementation NCIAPHelper

+ (instancetype)shared
{
  static dispatch_once_t onceToken;
  static id shared;
  dispatch_once(&onceToken, ^{ shared = [[self alloc] init]; });
  return shared;
}

- (instancetype)init
{
  if (!(self = [super init])) return nil;
  [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
  return self;
}

+ (void)purchaseProductWithID:(NSString*)productID
                  aboveWindow:(UIWindow*)window
            completionHandler:(NCIAPHelperCompletionHandler)completionHandler
                 errorHandler:(NCIAPHelperErrorHandler)errorHandler
{
  self.shared.aboveWindow = window;
  if (![SKPaymentQueue canMakePayments]) {
    NSString* title = NSLocalizedString(@"In App Purchase Disabled", nil);
    NSString* message = NSLocalizedString(
        @"Sorry, In App Purchase is disabled on this device. You might need to "
        @"ask the owner for help or enable it youself in Settings.app.",
        nil);
    UIAlertController* alert = [UIAlertController
        alertControllerWithTitle:title
                         message:message
                  preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction
                         actionWithTitle:NSLocalizedString(@"Goodbye", nil)
                                   style:UIAlertActionStyleCancel
                                 handler:^(UIAlertAction* _Nonnull action) {}]];
    [window.rootViewController presentViewController:alert animated:YES
                                          completion:nil];
    return;
  }

  self.shared.completionHandler = completionHandler;
  self.shared.errorHandler = errorHandler;
  self.shared.alertController = [UIAlertController
      alertControllerWithTitle:NSLocalizedString(@"Connecting to Apple…", nil)
                       message:nil
                preferredStyle:UIAlertControllerStyleAlert];
  [window.rootViewController presentViewController:self.shared.alertController
                                          animated:YES
                                        completion:nil];
  SKProductsRequest* request = [[SKProductsRequest alloc]
      initWithProductIdentifiers:[NSSet setWithObject:productID]];
  request.delegate = self.shared;
  [request start];
}

+ (void)restoreCompletedTransactionsAboveWindow:(UIWindow*)window
                              completionHandler:(NCIAPHelperCompletionHandler)
                                                    completionHandler
                                   errorHandler:
                                       (NCIAPHelperErrorHandler)errorHandler
{
  self.shared.alertController = [UIAlertController
      alertControllerWithTitle:NSLocalizedString(@"Restoring…", nil)
                       message:nil
                preferredStyle:UIAlertControllerStyleAlert];
  [window.rootViewController presentViewController:self.shared.alertController
                                          animated:YES
                                        completion:nil];
  [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
  self.shared.completionHandler = completionHandler;
  self.shared.errorHandler = errorHandler;
}

#pragma mark - SKProductsRequestDelegate
- (void)productsRequest:(SKProductsRequest*)request
     didReceiveResponse:(SKProductsResponse*)response
{
  dispatch_async(dispatch_get_main_queue(), ^{
    [self.alertController dismissViewControllerAnimated:YES completion:nil];
  });
  SKProduct* p = [response.products lastObject];
  if (!p && [self errorHandler]) {
    NSString* invalidID = [response.invalidProductIdentifiers lastObject];
    NSInteger code = invalidID ? NCIAPHelperInvalidProductIDError
                               : NCIAPHelperRequestContainsNoProductError;
    NSString* desc = invalidID
        ? [NSString
            stringWithFormat:
                NSLocalizedString(
                    @"The purchase to the product ID “%@” is invalid.", nil),
            invalidID]
        : NSLocalizedString(@"Fail to get product information.", nil);
    NSError* error =
        [NSError errorWithDomain:kNCIAPHelperErrorDomain code:code
                        userInfo:@{ NSLocalizedDescriptionKey : desc }];
    self.errorHandler(nil, error);
    self.completionHandler = nil;
    self.errorHandler = nil;
    return;
  }

  SKPayment* pm = [SKPayment paymentWithProduct:p];
  [[SKPaymentQueue defaultQueue] addPayment:pm];
}

#pragma mark - SKPaymentTransactionObserver
- (BOOL)paymentQueue:(SKPaymentQueue*)queue
    shouldAddStorePayment:(SKPayment*)payment
               forProduct:(SKProduct*)product
{
  return true;
}

- (void)paymentQueue:(SKPaymentQueue*)queue
    updatedTransactions:(NSArray*)transactions
{
  [self.alertController dismissViewControllerAnimated:YES completion:nil];
  for (SKPaymentTransaction* t in transactions) {
    if (t.transactionState == SKPaymentTransactionStatePurchased) {
      [[SKPaymentQueue defaultQueue] finishTransaction:t];
      NCIAPHelperCompletionHandler compHandler = [self completionHandler];
      if (compHandler) {
        compHandler(@[ t ]);
        [self setCompletionHandler:nil];
      }
    } else if (t.transactionState == SKPaymentTransactionStateFailed) {
      [[SKPaymentQueue defaultQueue] finishTransaction:t];
      if (t.error.code != SKErrorPaymentCancelled) {
        NCIAPHelperErrorHandler errHandler = [self errorHandler];
        if (errHandler) {
          errHandler(@[ t ], t.error);
          [self setErrorHandler:nil];
        }
      }
    } else if (t.transactionState == SKPaymentTransactionStatePurchasing) {
      self.alertController = [UIAlertController
          alertControllerWithTitle:NSLocalizedString(
                                       @"Preparing for Payment…", nil)
                           message:nil
                    preferredStyle:UIAlertControllerStyleAlert];
      [self.aboveWindow.rootViewController
          presentViewController:self.alertController
                       animated:YES
                     completion:nil];
    } else if (t.transactionState == SKPaymentTransactionStateRestored) {
      // Do nothing, handled by
      // `-paymentQueueRestoreCompletedTransactionsFinished:`
    }
  }
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue*)queue
{
  [self.alertController dismissViewControllerAnimated:YES completion:nil];
  NCIAPHelperCompletionHandler compHandler = [self completionHandler];
  // You should check the transactions if they are matching your desired product
  // ids
  if (compHandler) compHandler(queue.transactions);

  for (SKPaymentTransaction* pt in queue.transactions)
    [[SKPaymentQueue defaultQueue] finishTransaction:pt];

  [self setCompletionHandler:nil];
  [self setErrorHandler:nil];
}

- (void)paymentQueue:(SKPaymentQueue*)queue
    restoreCompletedTransactionsFailedWithError:(NSError*)error
{
  [self.alertController dismissViewControllerAnimated:YES completion:nil];
  if (self.errorHandler) self.errorHandler(queue.transactions, error);

  self.completionHandler = nil;
  self.errorHandler = nil;
}

@end
