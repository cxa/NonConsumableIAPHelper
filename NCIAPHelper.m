//
//  NCIAPHelper.m
//  NCIAPHelper
//
//  Copyright (c) 2013 CHEN Xian'an <xianan.chen@gmail.com>. All rights reserved.
//
//  NCIAPHelper is available under the MIT license. you can use it into your app royalty-freely, just make sure that you don’t remove above copyright notice.

#import "NCIAPHelper.h"
#import <objc/runtime.h>
#import <CXAFoundation/CXAAlertController.h>

#define SELF                      [self self]

NSString * const kNCIAPHelperErrorDomain = @"kNCIAPHelperErrorDomain";

static CXAAlertController *alertController;

@interface NCIAPHelper()

+ (NCIAPHelperCompletionHandler)completionHandler;
+ (void)setCompletionHandler:(NCIAPHelperCompletionHandler)completionHandler;
+ (NCIAPHelperErrorHandler)errorHandler;
+ (void)setErrorHandler:(NCIAPHelperErrorHandler)errorHandler;

@end

@implementation NCIAPHelper

+ (void)load
{
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note){
      [[SKPaymentQueue defaultQueue] addTransactionObserver:SELF];
    }];
  });
}

+ (void)purchaseProductWithID:(NSString *)productID
            completionHandler:(NCIAPHelperCompletionHandler)completionHandler
                 errorHandler:(NCIAPHelperErrorHandler)errorHandler
{
  if (![SKPaymentQueue canMakePayments]){
    [CXAAlertController showAlertWithTitle:NSLocalizedString(@"In App Purchase Disabled", nil) message:NSLocalizedString(@"Sorry, In App Purchase is disabled on this device. You might need to ask the owner for help or enable it youself in Settings.app.", nil) cancelTitle:NSLocalizedString(@"Goodbye", nil) inViewController:[UIApplication sharedApplication].delegate.window.rootViewController];
    return;
  }
  
  [self setCompletionHandler:completionHandler];
  [self setErrorHandler:errorHandler];
  alertController = [CXAAlertController showAlertWithTitle:NSLocalizedString(@"Connecting to Apple…", nil) message:nil cancelTitle:nil inViewController:[UIApplication sharedApplication].delegate.window.rootViewController];
  SKProductsRequest *request= [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithObject:productID]];
  request.delegate = SELF;
  [request start];
}

+ (void)restoreCompletedTransactionsWithCompletionHandler:(NCIAPHelperCompletionHandler)completionHandler
                                             errorHandler:(NCIAPHelperErrorHandler)errorHandler
{
  alertController = [CXAAlertController showAlertWithTitle:NSLocalizedString(@"Restoring…", nil) message:nil cancelTitle:nil inViewController:[UIApplication sharedApplication].delegate.window.rootViewController];
  [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
  [self setCompletionHandler:completionHandler];
  [self setErrorHandler:errorHandler];
}

#pragma mark - SKProductsRequestDelegate
+ (void)productsRequest:(SKProductsRequest *)request
     didReceiveResponse:(SKProductsResponse *)response
{
  [alertController dismiss];
  SKProduct *p = [response.products lastObject];
  if (!p && [self errorHandler]){
    NSString *invalidID = [response.invalidProductIdentifiers lastObject];
    NSInteger code = invalidID ? NCIAPHelperInvalidProductIDError : NCIAPHelperRequestContainsNoProductError;
    NSString *desc = invalidID ? [NSString stringWithFormat:NSLocalizedString(@"The purchase to the product ID “%@” is invalid.", nil), invalidID] : NSLocalizedString(@"Fail to get product information.", nil);
    NSError *error = [NSError errorWithDomain:kNCIAPHelperErrorDomain code:code userInfo:@{NSLocalizedDescriptionKey : desc}];
    [self errorHandler](nil, error);
    [self setCompletionHandler:nil];
    [self setErrorHandler:nil];
    return;
  }
  
  SKPayment *pm = [SKPayment paymentWithProduct:p];
  [[SKPaymentQueue defaultQueue] addPayment:pm];
}

#pragma mark - SKPaymentTransactionObserver 
+ (void)paymentQueue:(SKPaymentQueue *)queue
 updatedTransactions:(NSArray *)transactions
{
  [alertController dismiss];
  for (SKPaymentTransaction *t in transactions){
    if (t.transactionState == SKPaymentTransactionStatePurchased){
      [[SKPaymentQueue defaultQueue] finishTransaction:t];
      NCIAPHelperCompletionHandler compHandler = [self completionHandler];
      if (compHandler){
        compHandler(@[t]);
        [self setCompletionHandler:nil];
      }
    } else if (t.transactionState == SKPaymentTransactionStateFailed){
      [[SKPaymentQueue defaultQueue] finishTransaction:t];
      if (t.error.code != SKErrorPaymentCancelled){
        NCIAPHelperErrorHandler errHandler = [self errorHandler];
        if (errHandler){
          errHandler(@[t], t.error);
          [self setErrorHandler:nil];
        }
      }
    } else if (t.transactionState == SKPaymentTransactionStatePurchasing){
      alertController = [CXAAlertController showAlertWithTitle:NSLocalizedString(@"Preparing for Payment…", nil) message:nil cancelTitle:nil inViewController:[UIApplication sharedApplication].delegate.window.rootViewController];
    } else if (t.transactionState == SKPaymentTransactionStateRestored){
      // Do nothing, let it be handled with `+paymentQueueRestoreCompletedTransactionsFinished:`
    }
  }
}

+ (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
  [alertController dismiss];
  NCIAPHelperCompletionHandler compHandler = [self completionHandler];
  // You should check the transactions if they are matching your desired product ids
  if (compHandler)
    compHandler(queue.transactions);
  
  for (SKPaymentTransaction *pt in queue.transactions)
    [[SKPaymentQueue defaultQueue] finishTransaction:pt];
  
  [self setCompletionHandler:nil];
  [self setErrorHandler:nil];
}

+ (void)paymentQueue:(SKPaymentQueue *)queue
restoreCompletedTransactionsFailedWithError:(NSError *)error
{
  [alertController dismiss];
  NCIAPHelperErrorHandler errHandler = [self errorHandler];
  if (errHandler)
    errHandler(queue.transactions, error);
  
  [self setCompletionHandler:nil];
  [self setErrorHandler:nil];
}

//#pragma mark - UIAlertViewDelegate
//+ (void)willPresentAlertView:(UIAlertView *)alertView
//{
//  if (alertView.tag == TAG_REQUESTING_PRODUCT ||
//      alertView.tag == TAG_PREPARING_FOR_PAYMENT ||
//      alertView.tag == TAG_RESTORING){
//    UIActivityIndicatorView *aiv = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
//    aiv.center = CGPointMake(CGRectGetMidX(alertView.bounds), CGRectGetMidY(alertView.bounds) + 10);
//    [aiv startAnimating];
//    [alertView addSubview:aiv];
//  }
//}

#pragma mark - privates

static char kCompletionHandlerKey;
static char kErrorHandlerKey;

+ (NCIAPHelperCompletionHandler)completionHandler
{
  return objc_getAssociatedObject(SELF, &kCompletionHandlerKey);
}

+ (void)setCompletionHandler:(NCIAPHelperCompletionHandler)completionHandler
{
  objc_setAssociatedObject(SELF, &kCompletionHandlerKey, completionHandler, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

+ (NCIAPHelperErrorHandler)errorHandler
{
  return objc_getAssociatedObject(SELF, &kErrorHandlerKey);
}

+ (void)setErrorHandler:(NCIAPHelperErrorHandler)errorHandler
{
  objc_setAssociatedObject(SELF, &kErrorHandlerKey, errorHandler, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

@end
