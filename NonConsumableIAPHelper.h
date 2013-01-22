//
//  NonConsumableIAPHelper.h
//  NonConsumableIAPHelper
//
//  Copyright (c) 2013 CHEN Xian'an <xianan.chen@gmail.com>. All rights reserved.
//
//  NonConsumableIAPHelper is available under the MIT license. you can use it into your app royalty-freely, just make sure that you don’t remove above copyright notice.

#import <Foundation/Foundation.h>

extern NSString * const kNonConsumableIAPHelperErrorDomain;

typedef NS_ENUM(NSInteger, NonConsumableIAPHelperErrorCode){
  NonConsumableIAPHelperRequestContainsNoProductError = 0,
  NonConsumableIAPHelperInvalidProductIDError,
};

@interface NonConsumableIAPHelper : NSObject

+ (void)purchaseProductWithID:(NSString *)productID completionHandler:(void (^)(BOOL isRestored))completionHandler errorHandler:(void (^)(NSError *error))errorHandler;

@end
