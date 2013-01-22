//
//  NonConsumableIAPHelper.m
//  NonConsumableIAPHelper
//
//  Copyright (c) 2013 CHEN Xian'an <xianan.chen@gmail.com>. All rights reserved.
//
//  NonConsumableIAPHelper is available under the MIT license. you can use it into your app royalty-freely, just make sure that you don’t remove above copyright notice.

#import "NonConsumableIAPHelper.h"
#import <StoreKit/StoreKit.h>
#import <objc/objc-runtime.h>

#define SELF                   [self self]
#define INDICATOR_MSG          nil
#define TAG_REQUESTING_PRODUCT 'r'
#define TAG_PURCHASING         'p'

NSString * const kNonConsumableIAPHelperErrorDomain = @"kNonConsumableIAPHelperErrorDomain";

static UIAlertView *alertView;

@interface NonConsumableIAPHelper()

+ (void (^)(BOOL))completionHandler;
+ (void)setCompletionHandler:(void (^)(BOOL))completionHandler;
+ (void (^)(NSError *))errorHandler;
+ (void)setErrorHandler:(void (^)(NSError *))errorHandler;

@end

@implementation NonConsumableIAPHelper

+ (void)load
{
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    [[SKPaymentQueue defaultQueue] addTransactionObserver:SELF];
  });
}

+ (void)purchaseProductWithID:(NSString *)productID
            completionHandler:(void (^)(BOOL))completionHandler
                 errorHandler:(void (^)(NSError *error))errorHandler
{
  if (![SKPaymentQueue canMakePayments]){
    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"In App Purchase Disabled", nil) message:NSLocalizedString(@"Sorry, In App Purchase is disabled on this device. You might need to ask the owner for help or enable it youself in Settings.app.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"Goodbye", nil) otherButtonTitles:nil] show];
    return;
  }
  
  [self setCompletionHandler:completionHandler];
  [self setErrorHandler:errorHandler];
  alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Connecting to Apple...", nil) message:INDICATOR_MSG delegate:SELF cancelButtonTitle:nil otherButtonTitles:nil];
  alertView.tag = TAG_REQUESTING_PRODUCT;
  [alertView show];
  SKProductsRequest *request= [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithObject:productID]];
  request.delegate = SELF;
  [request start];
}

#pragma mark - SKProductsRequestDelegate
+ (void)productsRequest:(SKProductsRequest *)request
     didReceiveResponse:(SKProductsResponse *)response
{
  [alertView dismissWithClickedButtonIndex:-1 animated:YES];
  SKProduct *p = [response.products lastObject];
  if (!p && [self errorHandler]){
    NSString *invalidID = [response.invalidProductIdentifiers lastObject];
    NSInteger code = invalidID ? NonConsumableIAPHelperInvalidProductIDError : NonConsumableIAPHelperRequestContainsNoProductError;
    NSString *desc = invalidID ? [NSString stringWithFormat:NSLocalizedString(@"The purchase to the product ID “%@” is invalid.", nil), invalidID] : NSLocalizedString(@"Fail to get product information.", nil);
    NSError *error = [NSError errorWithDomain:kNonConsumableIAPHelperErrorDomain code:code userInfo:@{NSLocalizedDescriptionKey : desc}];
    [self errorHandler](error);
    return;
  }
  
  SKPayment *pm = [SKPayment paymentWithProduct:p];
  [[SKPaymentQueue defaultQueue] addPayment:pm];
}

#pragma mark - SKPaymentTransactionObserver 
+ (void)paymentQueue:(SKPaymentQueue *)queue
 updatedTransactions:(NSArray *)transactions
{
  for (SKPaymentTransaction *t in transactions){
    if (t.transactionState == SKPaymentTransactionStatePurchased ||
        t.transactionState == SKPaymentTransactionStateRestored){
      [alertView dismissWithClickedButtonIndex:-1 animated:YES];
      [[SKPaymentQueue defaultQueue] finishTransaction:t];
      void (^compHandler)(BOOL) = [self completionHandler];
      if (compHandler)
        compHandler(t.transactionState == SKPaymentTransactionStateRestored);
    } else if (t.transactionState == SKPaymentTransactionStateFailed){
      [alertView dismissWithClickedButtonIndex:-1 animated:YES];
      [[SKPaymentQueue defaultQueue] finishTransaction:t];
      if (t.error.code != SKErrorPaymentCancelled){
        void (^errHandler)(NSError *) = [self errorHandler];
        if (errHandler)
          errHandler(t.error);
      }
    } else if (t.transactionState == SKPaymentTransactionStatePurchasing){
      [alertView dismissWithClickedButtonIndex:-1 animated:YES];
      alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Accepting Payment...", nil) message:INDICATOR_MSG delegate:self cancelButtonTitle:nil otherButtonTitles:nil];
      alertView.tag = TAG_PURCHASING;
      [alertView show];
    }
  }
}

#pragma mark - UIAlertViewDelegate
+ (void)willPresentAlertView:(UIAlertView *)alertView
{
  if (alertView.tag == TAG_REQUESTING_PRODUCT ||
      alertView.tag == TAG_PURCHASING){
    UIActivityIndicatorView *aiv = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    aiv.center = CGPointMake(CGRectGetMidX(alertView.bounds), CGRectGetMidY(alertView.bounds) + 10);
    [aiv startAnimating];
    [alertView addSubview:aiv];
  }
}

#pragma mark - privates

static char kCompletionHandlerKey;
static char kErrorHandlerKey;

+ (void (^)(BOOL))completionHandler
{
  return objc_getAssociatedObject(SELF, &kCompletionHandlerKey);
}

+ (void)setCompletionHandler:(void (^)(BOOL))completionHandler
{
  objc_setAssociatedObject(SELF, &kCompletionHandlerKey, completionHandler, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

+ (void (^)(NSError *error))errorHandler
{
  return objc_getAssociatedObject(SELF, &kErrorHandlerKey);
}

+ (void)setErrorHandler:(void (^)(NSError *error))errorHandler
{
  objc_setAssociatedObject(SELF, &kErrorHandlerKey, errorHandler, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

@end
