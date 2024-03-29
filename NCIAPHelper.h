//
//  NCIAPHelper.h
//  NCIAPHelper
//
//  Copyright (c) 2013 CHEN Xian'an <xianan.chen@gmail.com>. All rights
//  reserved.
//
//  NCIAPHelper is available under the MIT license. you can use it into your app
//  royalty-freely, just make sure that you don’t remove above copyright notice.

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

extern NSString* const kNCIAPHelperErrorDomain;
typedef void (^NCIAPHelperCompletionHandler)(NSArray* paymentTransactions);
typedef void (^NCIAPHelperErrorHandler)(
    NSArray* paymentTransactions, NSError* error);

typedef NS_ENUM(NSInteger, NCIAPHelperErrorCode) {
  NCIAPHelperRequestContainsNoProductError = 0,
  NCIAPHelperInvalidProductIDError,
};

@interface NCIAPHelper : NSObject

+ (void)purchaseProductWithID:(NSString*)productID
                  aboveWindow:(UIWindow*)window
            completionHandler:(NCIAPHelperCompletionHandler)completionHandler
                 errorHandler:(NCIAPHelperErrorHandler)errorHandler;
+ (void)restoreCompletedTransactionsAboveWindow:(UIWindow*)window
                              completionHandler:(NCIAPHelperCompletionHandler)
                                                    completionHandler
                                   errorHandler:
                                       (NCIAPHelperErrorHandler)errorHandler;

@end
