
Embedded data in binaries!
--------------------------

```objc
id plist = [DDEmbeddedDataReader defaultEmbeddedPlist:nil];
NSLog(@"plist: %@", plist);

//text data
NSData *data = [DDEmbeddedDataReader embeddedDataFromSection:@"__testData" error:nil];
NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
NSLog(@"text: %@", string);

//image data
data = [DDEmbeddedDataReader embeddedDataFromSegment:@"__IMG" inSection:@"__testImg" error:nil];
NSLog(@"image data no of bytes: %lu", data.length);

//plist 1 again - (this time passing the segment,section and executable)
uint32_t size = MAXPATHLEN * 2;
char ch[size];
_NSGetExecutablePath(ch, &size);
data = [DDEmbeddedDataReader dataFromSegment:@"__TEXT" inSection:@"__info_plist" ofExecutableAtPath:[NSString stringWithUTF8String:ch] error:nil];
plist = [NSPropertyListSerialization propertyListFromData:data mutabilityOption:NSPropertyListImmutable format:nil errorDescription:
```