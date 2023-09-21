
#import <React/RCTBridgeModule.h>
#import <Mantis/Mantis.h>

@interface RCT_EXTERN_MODULE(MantisCropModule, NSObject)

RCT_EXTERN_METHOD(setBase64ImageCallback: (RCTResponseSenderBlock)callback) // Expose setBase64ImageCallback method
RCT_EXTERN_METHOD(openMantisCrop: (NSString *)imageURL) // Expose openMantisCrop method with a URL argument as an NSString
RCT_EXTERN_METHOD(openImagePicker)
RCT_EXTERN_METHOD(openImagePickerForMultipleImages: (RCTResponseSenderBlock)callback) // Expose openImagePickerForMultipleImages method with a callback
RCT_EXTERN_METHOD(openMantisCropWithURL: (NSString *)imageURL);
@end



REACT-NATIVE-IMAGE-CROPPER/ios/
MantisCropModule.m
MantisCropModule.swift