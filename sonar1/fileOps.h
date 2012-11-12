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
-(void) writeToStringfile:(NSMutableString*)textToWrite;
-(NSString*) readFormFile;
-(NSString*) setFileName;

@end
