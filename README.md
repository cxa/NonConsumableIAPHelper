# Non-Consumable In-App Purchase Helper

Tried of writing redundant codes for non-consumable In-App Purchase again and again? To seek a simple and minimum library that doesn't suck? Here you are.

`NCIAPHelper` is a very very lightweight wrapper for non-consumable In-App Purchase, only two methods for almost all circumstances:

```objc
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
```

## Creator

* GitHub: <https://github.com/cxa>
* Twitter: [@_realazy](https://twitter.com/_realazy)
* Apps available in App Store: <http://lazyapps.com>

## License

`NCIAPHelper` is released under the MIT license. In short, it's royalty-free but you must keep the copyright notice in your code or software distribution.
