
/*  NSNib+XMLBase64.h  *  AtoZCodeFactory */

//@import Cocoa;
#import <Cocoa/Cocoa.h>


@interface			             NSNib (XMLBase64)
+    (NSString*) base64FromXMLPath:(NSString*)p;
+      (NSData*)   dataFromXMLPath:(NSString*)p;
+    (NSString*)     xmlFromBase64:(NSString*)p;
+ (instancetype)    nibFromXMLPath:(NSString*)s
														 owner:(id)owner
												topObjects:(NSArray**)objs;
@end

@interface NSData (Base64)
+   (NSData*)      dataFromInfoKey:(NSString*)k;
+   (NSData*) dataFromBase64String:(NSString*)s;
- (NSString*)  base64EncodedString;
- (NSString*) base64EncodedStringWithSeparateLines:(BOOL)separateLines; // added by Hiroshi Hashiguchi
@end
