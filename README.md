# Non-Consumable In-App Purchase Helper

Tried of writing redundant codes for non-consumable In-App Purchase again and again? To seek a simple and minimum library that doesn't suck? Here you are.

`NCIAPHelper` is a very very lightweight wrapper for non-consumable In-App Purchase, only one method to rule them all:

	+ (void)purchaseProductWithID:(NSString *)productID completionHandler:(NCIAPHelperCompletionHandler)completionHandler errorHandler:(NCIAPHelperErrorHandler)errorHandler;

The `typedef` for completion handler and error handler:

    typedef void (^NCIAPHelperCompletionHandler)(SKPaymentTransaction *paymentTransaction);
    typedef void (^NCIAPHelperErrorHandler)(SKPaymentTransaction *paymentTransaction, NSError *error);
    
Notice: the `paymentTransaction` in `NCIAPHelperErrorHandler` may be `nil` if the error is occurred before payment.

## Creator

* GitHub: <https://github.com/cxa>
* Twitter: [@_cxa](https://twitter.com/_cxa)
* Apps available in App Store: <http://lazyapps.com>

## License

`NCIAPHelper` is released under the MIT license. In short, it's royalty-free but you must keep the copyright notice in your code or software distribution.
