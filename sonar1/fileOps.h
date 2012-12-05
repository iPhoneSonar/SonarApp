//
//  fileOps.h
//  sonar1
//
//  Created by lio 123 on 11/11/2012.
//
//

#import <Foundation/Foundation.h>

@interface fileOps : NSObject{
    
    NSFileManager *fileMgr;
    NSString *homeDir;
    NSString *fileName;
    NSString *filePath;
}

@property(nonatomic,retain) NSFileManager *fileMgr;
@property(nonatomic,retain) NSString *homeDir;
@property(nonatomic,retain) NSString *fileName;
@property(nonatomic,retain) NSString *filePath;

-(NSString*) getDocumentDir;
-(void) WriteString:(NSMutableString*)textToWrite ToFile:(NSString*)ToFileName;
-(NSString*) readFormFile:(NSString*)Name;
-(NSString*) setFileName;
-(NSMutableString*) FloatArrayToString:(float*)AIn OfArraySize:(int)SizeA;
-(NSMutableString*) Sint16ArrayToString:(SInt16*)AIn OfArraySize:(int)SizeA;

@end
