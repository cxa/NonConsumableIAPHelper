# NonConsumableIAPHelper

Tried of writing non-consumable In App Purchase again and again? To seek a minimum library that doesn't suck? Here you are.

`NonConsumableIAPHelper` is a very simple wrapper for non-consumable In App Purchase, only one method to rule them all:

	+ (void)purchaseProductWithID:(NSString *)productID completionHandler:(void (^)(BOOL isRestored))completionHandler errorHandler:(void (^)(NSError *error))errorHandler;


## Creator

* GitHub: <https://github.com/cxa>
* Twitter: [@_cxa](https://twitter.com/_cxa)
* Apps available in App Store: <http://lazyapps.com>

## License

NonConsumableIAPHelper is available under the MIT license. In a short word, you can use it into your app royalty-freely, just make sure that you don’t remove above copyright notice.